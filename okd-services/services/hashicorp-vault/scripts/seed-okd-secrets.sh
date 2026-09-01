#!/usr/bin/env bash
# Seed OKD platform secrets from local .secrets/ into Vault kv-v2.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib.sh"

ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
SECRETS="${ROOT}/.secrets"

require() { command -v "$1" >/dev/null || { echo "missing: $1" >&2; exit 1; }; }
require vault

vault_check_unsealed
vault_check_token

put() {
  local path="$1"; shift
  vault kv put "kv-v2/${path}" "$@"
  echo "  wrote kv-v2/${path}"
}

echo "== seeding okd/platform secrets =="

if [[ -f "${SECRETS}/argocd-oidc.env" ]]; then
  # shellcheck disable=SC1090
  source "${SECRETS}/argocd-oidc.env"
  put "okd/platform/argocd/oidc" \
    client_id="${ARGOCD_OIDC_CLIENT_ID:-argocd-prod}" \
    client_secret="${ARGOCD_OIDC_CLIENT_SECRET:?missing in argocd-oidc.env}"
fi

if [[ -f "${SECRETS}/cloudflare-token" ]]; then
  CF_TOKEN="$(tr -d '\n' < "${SECRETS}/cloudflare-token")"
  put "okd/platform/cert-manager/cloudflare" api-token="${CF_TOKEN}"
fi

if [[ -f "${SECRETS}/authentik.env" ]]; then
  # shellcheck disable=SC1090
  source "${SECRETS}/authentik.env"
  put "okd/platform/authentik/core" \
    secret_key="${AUTHENTIK_SECRET_KEY:-}" \
    postgres_password="${PG_PASSWORD:-}"
fi

echo "done"
