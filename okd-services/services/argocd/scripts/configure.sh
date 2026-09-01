#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "${ROOT}/../../.." && pwd)"

require() { command -v "$1" >/dev/null || { echo "missing: $1" >&2; exit 1; }; }
require oc

if ! oc whoami >/dev/null 2>&1; then
  echo "login to OKD first: oc login https://api.okd.cgraaaj.in:6443" >&2
  exit 1
fi

echo "== ArgoCD CR (disable default route, public URL, insecure) =="
oc patch argocd argocd -n argocd --type merge -p '{
  "spec": {
    "server": {
      "route": { "enabled": false },
      "ingress": { "enabled": false },
      "extraCommandArgs": ["--insecure"]
    },
    "cmdParams": {
      "server.insecure": "true"
    },
    "extraConfig": {
      "url": "https://argocd.cgraaaj.in",
      "server.insecure": "true"
    }
  }
}'

echo "== cert-manager Certificate =="
oc apply -f "${REPO_ROOT}/okd-services/services/cert-manager/manifests/04-certificate-argocd-cgraaaj-in.yaml"

echo "== route TLS RBAC =="
oc apply -f "${ROOT}/manifests/route-tls-rbac.yaml"

echo "== Route =="
oc apply -f "${ROOT}/manifests/route.yaml"

echo "waiting for Certificate Ready..."
for i in $(seq 1 36); do
  ready="$(oc get certificate argocd-cgraaaj-in -n argocd -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)"
  [[ "$ready" == "True" ]] && break
  sleep 10
done
oc get certificate argocd-cgraaaj-in -n argocd

echo "== restart argocd-server to pick up cm url =="
oc rollout restart deployment/argocd-server -n argocd
oc rollout status deployment/argocd-server -n argocd --timeout=120s

echo "done — https://argocd.cgraaaj.in"
