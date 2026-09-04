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

# LiteLLM (ns llm). Langfuse project keys are shared with okd/platform/langfuse/core
# so the headless-init project and the LiteLLM callback use the same pair.
if [[ -f "${SECRETS}/litellm.env" && -f "${SECRETS}/langfuse.env" ]]; then
  # shellcheck disable=SC1090
  source "${SECRETS}/litellm.env"
  # shellcheck disable=SC1090
  source "${SECRETS}/langfuse.env"
  put "okd/platform/litellm/core" \
    master_key="${LITELLM_MASTER_KEY:?missing in litellm.env}" \
    langfuse_host="https://langfuse.apps.okd.cgraaaj.in" \
    langfuse_public_key="${LANGFUSE_INIT_PROJECT_PUBLIC_KEY:?missing in langfuse.env}" \
    langfuse_secret_key="${LANGFUSE_INIT_PROJECT_SECRET_KEY:?missing in langfuse.env}"
  put "okd/platform/litellm/db" \
    username="${LITELLM_PG_USERNAME:-litellm}" \
    password="${LITELLM_PG_PASSWORD:?missing in litellm.env}" \
    postgres_password="${LITELLM_PG_ADMIN_PASSWORD:?missing in litellm.env}"
fi

if [[ -f "${SECRETS}/langfuse.env" ]]; then
  # shellcheck disable=SC1090
  source "${SECRETS}/langfuse.env"
  put "okd/platform/langfuse/core" \
    nextauth_secret="${LANGFUSE_NEXTAUTH_SECRET:?missing in langfuse.env}" \
    salt="${LANGFUSE_SALT:?missing in langfuse.env}" \
    encryption_key="${LANGFUSE_ENCRYPTION_KEY:?missing in langfuse.env}" \
    pg_password="${LANGFUSE_PG_PASSWORD:?missing in langfuse.env}" \
    clickhouse_password="${LANGFUSE_CLICKHOUSE_PASSWORD:?missing in langfuse.env}" \
    redis_password="${LANGFUSE_REDIS_PASSWORD:?missing in langfuse.env}" \
    minio_root_user="${LANGFUSE_MINIO_ROOT_USER:-langfuse-minio}" \
    minio_root_password="${LANGFUSE_MINIO_ROOT_PASSWORD:?missing in langfuse.env}" \
    init_user_email="${LANGFUSE_INIT_USER_EMAIL:-admin@cgraaaj.in}" \
    init_user_name="${LANGFUSE_INIT_USER_NAME:-Admin}" \
    init_user_password="${LANGFUSE_INIT_USER_PASSWORD:?missing in langfuse.env}" \
    init_project_public_key="${LANGFUSE_INIT_PROJECT_PUBLIC_KEY:?missing in langfuse.env}" \
    init_project_secret_key="${LANGFUSE_INIT_PROJECT_SECRET_KEY:?missing in langfuse.env}"
fi

echo "done"
