#!/usr/bin/env bash
# Configure Authentik OIDC for Grafana and seed all secrets into Vault.
# Run once before ArgoCD syncs Grafana. Re-running is safe (idempotent).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "${ROOT}/../../.." && pwd)"
SECRETS_DIR="${REPO_ROOT}/.secrets"
ENV_FILE="${SECRETS_DIR}/grafana.env"

require() { command -v "$1" >/dev/null || { echo "missing: $1" >&2; exit 1; }; }
require oc
require openssl
require jq
require vault

if ! oc whoami >/dev/null 2>&1; then
  echo "login to OKD first" >&2
  exit 1
fi

mkdir -p "${SECRETS_DIR}"

if [[ -f "${ENV_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
fi

if [[ -z "${GRAFANA_OIDC_CLIENT_SECRET:-}" ]]; then
  GRAFANA_OIDC_CLIENT_SECRET="$(openssl rand -base64 32 | tr -d '/+=' | head -c 40)"
fi

if [[ -z "${GRAFANA_ADMIN_PASSWORD:-}" ]]; then
  GRAFANA_ADMIN_PASSWORD="$(openssl rand -base64 32 | tr -d '/+=' | head -c 40)"
fi

CLIENT_ID="grafana-prod"
REDIRECT_URI="https://grafana.apps.okd.cgraaaj.in/login/generic_oauth"
ISSUER="https://auth.cgraaaj.in/application/o/grafana/"

echo "== Prometheus reader SA + token =="
oc apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: grafana
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: grafana-prometheus-reader
  namespace: grafana
---
apiVersion: v1
kind: Secret
metadata:
  name: grafana-prometheus-token
  namespace: grafana
  annotations:
    kubernetes.io/service-account.name: grafana-prometheus-reader
type: kubernetes.io/service-account-token
EOF

echo "Waiting for OKD to populate the SA token..."
PROMETHEUS_TOKEN=""
for i in $(seq 1 30); do
  PROMETHEUS_TOKEN="$(oc get secret grafana-prometheus-token -n grafana -o jsonpath='{.data.token}' 2>/dev/null | base64 -d 2>/dev/null)" || true
  if [[ -n "${PROMETHEUS_TOKEN}" ]]; then
    break
  fi
  sleep 2
done
if [[ -z "${PROMETHEUS_TOKEN}" ]]; then
  echo "ERROR: timed out waiting for SA token in grafana-prometheus-token" >&2
  exit 1
fi
echo "  token ready (${#PROMETHEUS_TOKEN} chars)"

echo "== Authentik OAuth2 provider (ak shell) =="
pod="$(oc get pod -n authentik -l app.kubernetes.io/component=server -o jsonpath='{.items[0].metadata.name}')"
oc exec -n authentik "${pod}" -c server -- \
  env OIDC_SECRET="${GRAFANA_OIDC_CLIENT_SECRET}" \
      REDIRECT_URI="${REDIRECT_URI}" \
      CLIENT_ID="${CLIENT_ID}" \
  ak shell -c "
from authentik.providers.oauth2.models import OAuth2Provider, RedirectURI, RedirectURIMatchingMode, ScopeMapping
from authentik.core.models import Application
from authentik.flows.models import Flow
from authentik.crypto.models import CertificateKeyPair
import os
secret    = os.environ['OIDC_SECRET']
redirect  = os.environ['REDIRECT_URI']
client_id = os.environ['CLIENT_ID']
auth_flow    = Flow.objects.get(slug='default-provider-authorization-implicit-consent')
inv_flow     = Flow.objects.get(slug='default-provider-invalidation-flow')
signing_key  = CertificateKeyPair.objects.get(name='authentik Self-signed Certificate')
provider, _ = OAuth2Provider.objects.update_or_create(
    name='grafana-prod',
    defaults={
        'authorization_flow': auth_flow,
        'invalidation_flow':  inv_flow,
        'client_type':   'confidential',
        'client_id':     client_id,
        'client_secret': secret,
        'redirect_uris': [RedirectURI(RedirectURIMatchingMode.STRICT, redirect)],
        'signing_key':   signing_key,
        'sub_mode':      'user_username',
        'issuer_mode':   'per_provider',
    },
)
# Reuse the groups scope mapping (created by ArgoCD configure script) so that
# Grafana receives group membership in the token for role_attribute_path.
groups_map, _ = ScopeMapping.objects.get_or_create(
    name='Grafana groups',
    defaults={
        'scope_name':  'groups',
        'description': 'Group names for Grafana RBAC',
        'expression':  'return [group.name for group in request.user.ak_groups.all()]',
    },
)
mappings = list(ScopeMapping.objects.filter(managed__startswith='goauthentik.io/providers/oauth2/scope-'))
mappings.append(groups_map)
provider.property_mappings.set(mappings)
Application.objects.update_or_create(
    slug='grafana',
    defaults={
        'name':             'Grafana',
        'provider':         provider,
        'meta_launch_url':  'https://grafana.apps.okd.cgraaaj.in/',
        'meta_description': 'OKD metrics dashboards',
    },
)
print('authentik grafana provider ready')
"

echo "== Vault: seeding okd/platform/grafana/core =="
vault kv put kv-v2/okd/platform/grafana/core \
  admin_user="admin" \
  admin_password="${GRAFANA_ADMIN_PASSWORD}" \
  client_secret="${GRAFANA_OIDC_CLIENT_SECRET}" \
  prometheus_token="${PROMETHEUS_TOKEN}"

cat > "${ENV_FILE}" <<EOF
GRAFANA_OIDC_CLIENT_ID=${CLIENT_ID}
GRAFANA_OIDC_CLIENT_SECRET=${GRAFANA_OIDC_CLIENT_SECRET}
GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
EOF
chmod 600 "${ENV_FILE}"

echo ""
echo "done."
echo "  OIDC issuer:    ${ISSUER}"
echo "  Redirect URI:   ${REDIRECT_URI}"
echo "  Admin password: stored in Vault + .secrets/grafana.env"
echo ""
echo "Next: commit all files, then ArgoCD will sync grafana-config (wave 0)"
echo "      followed by grafana (wave 1)."
echo "      Login at https://grafana.apps.okd.cgraaaj.in via 'Sign in with Authentik'"
