#!/usr/bin/env bash
# Vault on K3s must resolve the OKD API for kubernetes-okd TokenReview.
set -euo pipefail

K3S_KUBECONFIG="${K3S_KUBECONFIG:-${HOME}/.kube/config}"
K3S_CONTEXT="${K3S_CONTEXT:-dev}"
OKD_API_HOST="${OKD_API_HOST:-api.okd.cgraaaj.in}"
OKD_API_IP="${OKD_API_IP:-10.0.200.11}"

require() { command -v "$1" >/dev/null || { echo "missing: $1" >&2; exit 1; }; }
require kubectl
require rg

export KUBECONFIG="${K3S_KUBECONFIG}"
kubectl config use-context "${K3S_CONTEXT}" >/dev/null

current="$(kubectl -n kube-system get configmap coredns -o jsonpath='{.data.NodeHosts}')"
if printf '%s' "${current}" | rg -q "^${OKD_API_IP}[[:space:]]+${OKD_API_HOST}$"; then
  echo "CoreDNS already has ${OKD_API_HOST} -> ${OKD_API_IP}"
  exit 0
fi

updated="$(printf '%s\n%s %s\n' "${current}" "${OKD_API_IP}" "${OKD_API_HOST}")"
kubectl -n kube-system patch configmap coredns --type merge \
  --patch "$(jq -n --arg hosts "${updated}" '{data: {NodeHosts: $hosts}}')"

kubectl -n kube-system rollout restart deployment/coredns
kubectl -n kube-system rollout status deployment/coredns --timeout=120s
echo "added ${OKD_API_HOST} -> ${OKD_API_IP} to K3s CoreDNS NodeHosts"
