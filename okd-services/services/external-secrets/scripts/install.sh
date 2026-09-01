#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHART_VERSION="${ESO_CHART_VERSION:-0.14.2}"

require() { command -v "$1" >/dev/null || { echo "missing: $1" >&2; exit 1; }; }
require helm
require oc

if ! oc whoami >/dev/null 2>&1; then
  echo "login to OKD first" >&2
  exit 1
fi

helm repo add external-secrets https://charts.external-secrets.io 2>/dev/null || true
helm repo update external-secrets

echo "== External Secrets Operator ${CHART_VERSION} =="
helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --version "${CHART_VERSION}" \
  -f "${ROOT}/helm/values.yaml" \
  --wait --timeout 5m

oc rollout status deployment/external-secrets -n external-secrets --timeout=120s
echo "done — next: Vault bootstrap + oc apply -k ${ROOT}/manifests/"
