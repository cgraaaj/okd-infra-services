#!/usr/bin/env bash
# OpenShift-specific post-helm patches for HyperDX (chart lacks securityContext hooks).
set -euo pipefail

NAMESPACE="${HYPERDX_NAMESPACE:-observability}"

require() { command -v "$1" >/dev/null || { echo "missing: $1" >&2; exit 1; }; }
require oc

echo "== namespace pod-security (privileged for DB init) =="
oc label namespace "${NAMESPACE}" \
  pod-security.kubernetes.io/enforce=privileged \
  pod-security.kubernetes.io/audit=privileged \
  pod-security.kubernetes.io/warn=privileged \
  security.openshift.io/scc.podSecurityLabelSync=false \
  --overwrite

echo "== SCC for default service account =="
oc adm policy add-scc-to-user privileged -z default -n "${NAMESPACE}" 2>/dev/null || true

for deploy in hyperdx-hdx-oss-v2-clickhouse hyperdx-hdx-oss-v2-mongodb hyperdx-hdx-oss-v2-app; do
  if oc get deploy "${deploy}" -n "${NAMESPACE}" >/dev/null 2>&1; then
    oc patch deployment "${deploy}" -n "${NAMESPACE}" --type=merge -p \
      '{"spec":{"template":{"spec":{"securityContext":{"runAsUser":0,"fsGroup":0}}}}}'
  fi
done

echo "done — openshift patches applied"
