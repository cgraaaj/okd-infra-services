#!/usr/bin/env bash
# Apply AppProjects and bootstrap Application after GIT_REPO_URL is reachable by Argo CD.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GIT_REPO_URL="${GIT_REPO_URL:-}"
GIT_TARGET_REVISION="${GIT_TARGET_REVISION:-main}"

require() { command -v "$1" >/dev/null || { echo "missing: $1" >&2; exit 1; }; }
require oc

if ! oc whoami >/dev/null 2>&1; then
  echo "login to OKD first" >&2
  exit 1
fi

if [[ -z "${GIT_REPO_URL}" ]]; then
  echo "Set GIT_REPO_URL to the remote git URL Argo CD can reach, e.g.:" >&2
  echo "  export GIT_REPO_URL=https://github.com/cgraaaj/okd-infra-services.git" >&2
  exit 1
fi

echo "== AppProjects =="
oc apply -f "${ROOT}/projects/"

echo "== register repository (public HTTPS; add credentials secret for private repos) =="
if [[ -n "${GIT_USERNAME:-}" && -n "${GIT_PASSWORD:-}" ]]; then
  oc create secret generic repo-okd-infra-services \
    -n argocd \
    --from-literal=type=git \
    --from-literal=url="${GIT_REPO_URL}" \
    --from-literal=username="${GIT_USERNAME}" \
    --from-literal=password="${GIT_PASSWORD}" \
    --dry-run=client -o yaml | oc apply -f -
  oc label secret repo-okd-infra-services -n argocd argocd.argoproj.io/secret-type=repository --overwrite
fi

echo "== bootstrap Application =="
tmp="$(mktemp)"
sed "s|https://github.com/cgraaaj/okd-infra-services.git|${GIT_REPO_URL}|g; s|targetRevision: main|targetRevision: ${GIT_TARGET_REVISION}|g" \
  "${ROOT}/clusters/okd/bootstrap.yaml" > "${tmp}"
oc apply -f "${tmp}"
rm -f "${tmp}"

echo "bootstrap applied — check: oc get applications -n argocd"
