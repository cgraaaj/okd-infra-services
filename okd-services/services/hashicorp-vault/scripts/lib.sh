#!/usr/bin/env bash
# Shared Vault CLI setup for okd-infra-services scripts.
set -euo pipefail

_vault_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_vault_repo_root="$(cd "${_vault_script_dir}/../../../.." && pwd)"
_vault_env_file="${VAULT_ENV_FILE:-${_vault_repo_root}/.secrets/hashicorpvault.env}"

if [[ -f "${_vault_env_file}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${_vault_env_file}"
  set +a
fi

export VAULT_ADDR="${VAULT_ADDR:-https://hashicorpvault.cgraaaj.in}"
export VAULT_SKIP_VERIFY="${VAULT_SKIP_VERIFY:-true}"

vault_require_token() {
  if [[ -z "${VAULT_TOKEN:-}" ]]; then
    echo "VAULT_TOKEN missing. Set it or create ${_vault_env_file} with:" >&2
    echo "  VAULT_ADDR=https://hashicorpvault.cgraaaj.in" >&2
    echo "  VAULT_TOKEN=<root-or-admin-token>" >&2
    exit 1
  fi
  # Trim accidental whitespace
  VAULT_TOKEN="$(printf '%s' "${VAULT_TOKEN}" | tr -d '\r\n')"
  export VAULT_TOKEN
}

vault_check_token() {
  vault_require_token
  if ! vault token lookup >/dev/null 2>&1; then
    echo "VAULT_TOKEN is invalid or revoked (vault token lookup failed)." >&2
    echo "" >&2
    echo "Fix:" >&2
    echo "  1. Use the root token from 'vault operator init' (password manager)" >&2
    echo "  2. Update ${_vault_env_file}" >&2
    echo "  3. Or generate a new root token: see hashicorp-vault/README.md#invalid-token" >&2
    exit 1
  fi
  local policies
  policies="$(vault token lookup -format=json | jq -r '.data.policies[]' | tr '\n' ' ')"
  echo "Vault token OK (policies: ${policies})"
  if ! vault token lookup -format=json | jq -e '.data.policies[] | select(. == "root" or . == "default")' >/dev/null 2>&1; then
    if ! vault token lookup -format=json | jq -e '.data.policies[] | select(test("admin";"i"))' >/dev/null 2>&1; then
      echo "warning: token may lack permission to write policies/auth mounts" >&2
    fi
  fi
}

vault_check_unsealed() {
  local sealed
  sealed="$(vault status -format=json | jq -r '.sealed')"
  if [[ "${sealed}" == "true" ]]; then
    echo "Vault is sealed. Unseal on K3s first (see hashicorp-vault/README.md)." >&2
    exit 1
  fi
}
