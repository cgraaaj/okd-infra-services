#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "${ROOT}/../../.." && pwd)"
CERT_MANAGER_VERSION="${CERT_MANAGER_VERSION:-v1.20.2}"

require() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing required command: $1" >&2
    exit 1
  }
}

require oc
require helm

if ! oc whoami >/dev/null 2>&1; then
  echo "not logged in to OKD — run: oc login https://api.okd.cgraaaj.in:6443" >&2
  exit 1
fi

CF_TOKEN_FILE="${REPO_ROOT}/.secrets/cloudflare-token"
if [[ ! -f "${CF_TOKEN_FILE}" ]]; then
  echo "create ${CF_TOKEN_FILE} with the Cloudflare DNS API token (one line, no export)" >&2
  echo "or copy from K3s: kubectl --context dev get secret cloudflare-token-secret -n cert-manager -o jsonpath='{.data.cloudflare-token}' | base64 -d > ${CF_TOKEN_FILE}" >&2
  exit 1
fi

echo "== namespace =="
oc apply -f "${ROOT}/manifests/00-namespace.yaml"

echo "== cloudflare token secret =="
oc create secret generic cloudflare-token-secret \
  --from-file=cloudflare-token="${CF_TOKEN_FILE}" \
  -n cert-manager \
  --dry-run=client -o yaml | oc apply -f -

echo "== cert-manager helm (${CERT_MANAGER_VERSION}) =="
helm repo add jetstack https://charts.jetstack.io >/dev/null 2>&1 || true
helm repo update jetstack >/dev/null
helm upgrade --install cert-manager jetstack/cert-manager \
  -n cert-manager \
  --version "${CERT_MANAGER_VERSION}" \
  -f "${ROOT}/helm/values.yaml" \
  --wait --timeout 10m

echo "== wait for cert-manager deployments =="
oc rollout status deployment/cert-manager -n cert-manager --timeout=300s
oc rollout status deployment/cert-manager-webhook -n cert-manager --timeout=300s
oc rollout status deployment/cert-manager-cainjector -n cert-manager --timeout=300s

echo "== cluster issuer =="
oc apply -f "${ROOT}/manifests/01-clusterissuer-letsencrypt-production.yaml"

echo "== certificate (authentik) =="
oc apply -f "${ROOT}/manifests/02-certificate-auth-cgraaaj-in.yaml"

echo "== route TLS RBAC =="
oc apply -f "${ROOT}/manifests/03-route-tls-rbac.yaml"

echo "== authentik route (externalCertificate) =="
# Remove legacy inline tls.certificate/key if present (copied-cert hack).
if oc get route authentik -n authentik -o jsonpath='{.spec.tls.certificate}' 2>/dev/null | grep -q 'BEGIN'; then
  oc patch route authentik -n authentik --type=json -p='[
    {"op":"remove","path":"/spec/tls/certificate"},
    {"op":"remove","path":"/spec/tls/key"}
  ]' 2>/dev/null || true
fi
oc apply -f "${REPO_ROOT}/okd-services/services/authentik/manifests/route.yaml"

echo "waiting for Certificate Ready..."
for i in $(seq 1 60); do
  ready="$(oc get certificate auth-cgraaaj-in -n authentik -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)"
  if [[ "${ready}" == "True" ]]; then
    echo "certificate ready"
    break
  fi
  sleep 10
done

oc get certificate auth-cgraaaj-in -n authentik
oc describe route authentik -n authentik | rg -i 'externalCertificate|TLS|certificate' || true

echo "done — verify: curl -sk https://auth.cgraaaj.in/ -o /dev/null -w '%{http_code}\n'"
