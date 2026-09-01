#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHART_VERSION="${HYPERDX_CHART_VERSION:-0.8.4}"
NAMESPACE="${HYPERDX_NAMESPACE:-observability}"

require() { command -v "$1" >/dev/null || { echo "missing: $1" >&2; exit 1; }; }
require helm
require oc

if ! oc whoami >/dev/null 2>&1; then
  echo "login to OKD first" >&2
  exit 1
fi

helm repo add hyperdx https://hyperdxio.github.io/helm-charts 2>/dev/null || true
helm repo update hyperdx

echo "== HyperDX (hdx-oss-v2) ${CHART_VERSION} =="
helm upgrade --install hyperdx hyperdx/hdx-oss-v2 \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --version "${CHART_VERSION}" \
  -f "${ROOT}/helm/values.yaml" \
  --wait --timeout 15m

"${ROOT}/scripts/openshift-patch.sh"

oc rollout status deployment/hyperdx-hdx-oss-v2-clickhouse -n "${NAMESPACE}" --timeout=300s
oc rollout status deployment/hyperdx-hdx-oss-v2-mongodb -n "${NAMESPACE}" --timeout=300s
oc rollout status deployment/hyperdx-hdx-oss-v2-app -n "${NAMESPACE}" --timeout=300s

echo "== Route + TLS =="
oc apply -k "${ROOT}/manifests/"

echo "done — UI: https://hyperdx.cgraaaj.in (ingest via otel-gateway.observability.svc:4317)"
