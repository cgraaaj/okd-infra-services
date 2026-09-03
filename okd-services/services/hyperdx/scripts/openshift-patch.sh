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

if oc get deploy hyperdx-hdx-oss-v2-clickhouse -n "${NAMESPACE}" >/dev/null 2>&1; then
  oc patch deployment hyperdx-hdx-oss-v2-clickhouse -n "${NAMESPACE}" --type=merge -p \
    '{"spec":{"template":{"spec":{"securityContext":{"fsGroup":101,"runAsUser":101,"runAsGroup":101,"seLinuxOptions":{"type":"spc_t"}}}}}}'
fi

if oc get deploy hyperdx-hdx-oss-v2-mongodb -n "${NAMESPACE}" >/dev/null 2>&1; then
  oc patch deployment hyperdx-hdx-oss-v2-mongodb -n "${NAMESPACE}" --type=merge -p \
    '{"spec":{"template":{"spec":{"securityContext":{"fsGroup":999,"runAsUser":999,"runAsGroup":999,"seLinuxOptions":{"type":"spc_t"}}}}}}'
fi

if oc get deploy hyperdx-hdx-oss-v2-app -n "${NAMESPACE}" >/dev/null 2>&1; then
  oc patch deployment hyperdx-hdx-oss-v2-app -n "${NAMESPACE}" --type=merge -p \
    '{"spec":{"template":{"spec":{"securityContext":{"fsGroup":1000,"runAsUser":1000}}}}}'
fi

echo "done — openshift patches applied"
