#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHART_VERSION="${OTEL_CHART_VERSION:-0.172.0}"
NAMESPACE="${OTEL_NAMESPACE:-observability}"

require() { command -v "$1" >/dev/null || { echo "missing: $1" >&2; exit 1; }; }
require helm
require oc

if ! oc whoami >/dev/null 2>&1; then
  echo "login to OKD first" >&2
  exit 1
fi

helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts 2>/dev/null || true
helm repo update open-telemetry

echo "== OpenTelemetry gateway ${CHART_VERSION} =="
helm upgrade --install otel-gateway open-telemetry/opentelemetry-collector \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --version "${CHART_VERSION}" \
  -f "${ROOT}/helm/values-gateway.yaml" \
  --wait --timeout 5m

echo "== OpenTelemetry agent (DaemonSet) ${CHART_VERSION} =="
helm upgrade --install otel-agent open-telemetry/opentelemetry-collector \
  --namespace "${NAMESPACE}" \
  --version "${CHART_VERSION}" \
  -f "${ROOT}/helm/values-agent.yaml" \
  --wait --timeout 5m

oc rollout status deployment/otel-gateway -n "${NAMESPACE}" --timeout=120s
oc rollout status daemonset/otel-agent-agent -n "${NAMESPACE}" --timeout=180s

echo "done — gateway: otel-gateway.${NAMESPACE}.svc.cluster.local:4317"
