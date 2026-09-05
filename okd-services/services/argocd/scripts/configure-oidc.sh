#!/usr/bin/env bash
# Create Authentik OIDC app for Argo CD and configure the Argo CD operator.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "${ROOT}/../../.." && pwd)"
SECRETS_DIR="${REPO_ROOT}/.secrets"
ENV_FILE="${SECRETS_DIR}/argocd-oidc.env"

require() { command -v "$1" >/dev/null || { echo "missing: $1" >&2; exit 1; }; }
require oc
require openssl
require jq

if ! oc whoami >/dev/null 2>&1; then
  echo "login to OKD first" >&2
  exit 1
fi

mkdir -p "${SECRETS_DIR}"

if [[ -f "${ENV_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
fi

if [[ -z "${ARGOCD_OIDC_CLIENT_SECRET:-}" ]]; then
  ARGOCD_OIDC_CLIENT_SECRET="$(openssl rand -base64 32 | tr -d '/+=' | head -c 40)"
fi

CLIENT_ID="${ARGOCD_OIDC_CLIENT_ID:-argocd-prod}"
ISSUER="https://auth.cgraaaj.in/application/o/argocd/"
REDIRECT_URI="https://argocd.apps.okd.cgraaaj.in/auth/callback"

echo "== Authentik OAuth2 provider (ak shell) =="
pod="$(oc get pod -n authentik -l app.kubernetes.io/component=server -o jsonpath='{.items[0].metadata.name}')"
oc exec -n authentik "${pod}" -c server -- env OIDC_SECRET="${ARGOCD_OIDC_CLIENT_SECRET}" REDIRECT_URI="${REDIRECT_URI}" CLIENT_ID="${CLIENT_ID}" ak shell -c "
from authentik.providers.oauth2.models import OAuth2Provider, RedirectURI, RedirectURIMatchingMode, ScopeMapping
from authentik.core.models import Application
from authentik.flows.models import Flow
from authentik.crypto.models import CertificateKeyPair
import os
secret = os.environ['OIDC_SECRET']
redirect = os.environ['REDIRECT_URI']
client_id = os.environ['CLIENT_ID']
auth_flow = Flow.objects.get(slug='default-provider-authorization-implicit-consent')
inv_flow = Flow.objects.get(slug='default-provider-invalidation-flow')
signing_key = CertificateKeyPair.objects.get(name='authentik Self-signed Certificate')
provider, _ = OAuth2Provider.objects.update_or_create(
    name='argocd-prod',
    defaults={
        'authorization_flow': auth_flow,
        'invalidation_flow': inv_flow,
        'client_type': 'confidential',
        'client_id': client_id,
        'client_secret': secret,
        'redirect_uris': [RedirectURI(RedirectURIMatchingMode.STRICT, redirect)],
        'signing_key': signing_key,
        'sub_mode': 'user_username',
        'issuer_mode': 'per_provider',
    },
)
provider.property_mappings.set(ScopeMapping.objects.filter(managed__startswith='goauthentik.io/providers/oauth2/scope-'))
Application.objects.update_or_create(
    slug='argocd',
    defaults={'name': 'Argo CD Prod', 'provider': provider, 'meta_launch_url': 'https://argocd.apps.okd.cgraaaj.in/'},
)
print('authentik provider ready')
"

cat > "${ENV_FILE}" <<EOF
ARGOCD_OIDC_CLIENT_ID=${CLIENT_ID}
ARGOCD_OIDC_CLIENT_SECRET=${ARGOCD_OIDC_CLIENT_SECRET}
EOF
chmod 600 "${ENV_FILE}"

echo "== Kubernetes secret (argocd namespace) =="
oc create secret generic argocd-oidc \
  -n argocd \
  --from-literal=oidc.clientSecret="${ARGOCD_OIDC_CLIENT_SECRET}" \
  --dry-run=client -o yaml | oc apply -f -

OIDC_CONFIG="$(jq -nc \
  --arg name "Authentik" \
  --arg issuer "${ISSUER}" \
  --arg clientID "${CLIENT_ID}" \
  '{
    name: $name,
    issuer: $issuer,
    clientID: $clientID,
    clientSecret: "$argocd-oidc:oidc.clientSecret",
    requestedScopes: ["openid", "profile", "email", "groups"],
    requestedIDTokenClaims: {groups: {essential: true}}
  }')"

RBAC_POLICY=$'p, role:platform-admin, applications, *, */*, allow\np, role:platform-admin, clusters, get, *, allow\np, role:platform-admin, repositories, *, *, allow\np, role:platform-admin, projects, *, *, allow\np, role:platform-admin, logs, get, *, allow\np, role:platform-admin, exec, create, */*, allow\ng, authentik Admins, role:admin\ng, argocd-admins, role:admin\ng, argocd-platform, role:platform-admin'

echo "== Argo CD OIDC + RBAC =="
oc patch argocd argocd -n argocd --type merge -p "$(jq -nc \
  --arg oidc "${OIDC_CONFIG}" \
  --arg policy "${RBAC_POLICY}" \
  '{
    spec: {
      extraConfig: {
        "oidc.config": $oidc
      },
      rbac: {
        policy: $policy,
        scopes: "[groups]",
        defaultPolicy: "role:readonly"
      }
    }
  }')"

echo "waiting for OIDC discovery..."
for i in $(seq 1 12); do
  if curl -sf "${ISSUER}.well-known/openid-configuration" >/dev/null; then
    break
  fi
  sleep 5
done
curl -sf "${ISSUER}.well-known/openid-configuration" | jq -r '.issuer'

oc rollout restart deployment/argocd-server -n argocd
oc rollout status deployment/argocd-server -n argocd --timeout=120s

echo "done — use LOG IN VIA AUThentik on https://argocd.apps.okd.cgraaaj.in"
echo "admin groups: authentik Admins, argocd-admins | platform: argocd-platform"
