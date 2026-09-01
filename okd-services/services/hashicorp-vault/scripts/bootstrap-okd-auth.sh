#!/usr/bin/env bash
# Configure Vault kubernetes-okd auth for External Secrets Operator on OKD.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib.sh"

require() { command -v "$1" >/dev/null || { echo "missing: $1" >&2; exit 1; }; }
require vault
require oc
require jq

OKD_KUBECONFIG="${OKD_KUBECONFIG:-/home/cgraaaj/Projects/okd-homelab/installer/auth/kubeconfig}"
VAULT_K8S_AUTH_PATH="${VAULT_K8S_AUTH_PATH:-kubernetes-okd}"
ESO_NAMESPACE="${ESO_NAMESPACE:-external-secrets}"
ESO_SA="${ESO_SA:-external-secrets}"
VAULT_REVIEWER_SA="${VAULT_REVIEWER_SA:-vault-auth-reviewer}"
VAULT_ROLE="${VAULT_ROLE:-external-secrets-okd}"
VAULT_POLICY="${VAULT_POLICY:-okd-platform-read}"

vault_check_unsealed
vault_check_token

echo "== ensure kv-v2 enabled =="
vault secrets enable -path=kv-v2 kv-v2 2>/dev/null || true

echo "== policy ${VAULT_POLICY} =="
vault policy write "${VAULT_POLICY}" - <<'EOF'
# OKD platform secrets (ESO sync only)
path "kv-v2/data/okd/platform/*" {
  capabilities = ["read"]
}
path "kv-v2/metadata/okd/platform/*" {
  capabilities = ["read", "list"]
}
EOF

echo "== kubernetes auth mount ${VAULT_K8S_AUTH_PATH} =="
if ! vault auth list -format=json | jq -e --arg p "${VAULT_K8S_AUTH_PATH}/" '.[$p]' >/dev/null; then
  vault auth enable -path="${VAULT_K8S_AUTH_PATH}" kubernetes
fi

echo "== K3s DNS for OKD API (Vault TokenReview) =="
"${SCRIPT_DIR}/ensure-k3s-okd-dns.sh"

export KUBECONFIG="${OKD_KUBECONFIG}"
OKD_HOST="$(oc config view --minify -o jsonpath='{.clusters[0].cluster.server}')"
OKD_CA="$(oc config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d 2>/dev/null || true)"
if [[ -z "${OKD_CA}" ]]; then
  # OKD kubeconfig often uses insecure-skip-tls-verify without embedded CA.
  OKD_CA="$(oc get configmap kube-root-ca.crt -n kube-public -o jsonpath='{.data.ca\.crt}')"
fi
if [[ -z "${OKD_CA}" ]]; then
  echo "Could not determine OKD API server CA certificate" >&2
  exit 1
fi

echo "== Vault auth reviewer RBAC on OKD =="
oc apply -f "${SCRIPT_DIR}/../../external-secrets/manifests/00-vault-auth-reviewer-rbac.yaml"

REVIEWER_TOKEN="${REVIEWER_TOKEN:-$(oc create token "${VAULT_REVIEWER_SA}" -n "${ESO_NAMESPACE}" --duration=8760h 2>/dev/null || true)}"
if [[ -z "${REVIEWER_TOKEN}" ]]; then
  echo "Could not create token for ${VAULT_REVIEWER_SA} in ${ESO_NAMESPACE}" >&2
  exit 1
fi

vault write "auth/${VAULT_K8S_AUTH_PATH}/config" \
  kubernetes_host="${OKD_HOST}" \
  kubernetes_ca_cert="${OKD_CA}" \
  token_reviewer_jwt="${REVIEWER_TOKEN}" \
  disable_iss_validation=true

vault write "auth/${VAULT_K8S_AUTH_PATH}/role/${VAULT_ROLE}" \
  bound_service_account_names="${ESO_SA}" \
  bound_service_account_namespaces="${ESO_NAMESPACE}" \
  policies="${VAULT_POLICY}" \
  ttl=1h

echo "done — Vault role auth/${VAULT_K8S_AUTH_PATH}/role/${VAULT_ROLE}"
