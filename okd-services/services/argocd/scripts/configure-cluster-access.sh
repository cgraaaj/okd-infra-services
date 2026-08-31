#!/usr/bin/env bash
# Allow Argo CD to manage platform namespaces + cluster-scoped resources.
# The operator defaults the in-cluster secret to namespaces=argocd only.
set -euo pipefail

require() { command -v "$1" >/dev/null || { echo "missing: $1" >&2; exit 1; }; }
require oc

if ! oc whoami >/dev/null 2>&1; then
  echo "login to OKD first" >&2
  exit 1
fi

NAMESPACES="${ARGOCD_MANAGED_NAMESPACES:-argocd,authentik,cert-manager,local-path-storage}"

echo "== cluster RBAC =="
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
oc apply -f "${ROOT}/manifests/cluster-rbac.yaml"

echo "== in-cluster secret =="
if ! oc get secret in-cluster -n argocd >/dev/null 2>&1; then
  oc apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: in-cluster
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
type: Opaque
stringData:
  name: in-cluster
  server: https://kubernetes.default.svc
  config: '{"tlsClientConfig":{"insecure":false}}'
  clusterResources: "true"
  namespaces: "${NAMESPACES}"
EOF
else
  oc patch secret in-cluster -n argocd --type merge -p "$(jq -nc --arg ns "$NAMESPACES" '{stringData:{namespaces:$ns,clusterResources:"true"}}')"
fi

oc delete secret argocd-default-cluster-config -n argocd --ignore-not-found

echo "== restart application controller =="
oc delete pod -n argocd -l app.kubernetes.io/name=argocd-application-controller --wait=false

echo "done — managed namespaces: ${NAMESPACES}"
