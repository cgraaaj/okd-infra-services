# <service-name>

One-line description.

## Install (manual)

```bash
export KUBECONFIG=/path/to/okd/kubeconfig
# oc apply / helm upgrade --install ...
```

## Secrets

Document required secrets in `.secrets/` (never commit).

## OKD specifics

- `nodeSelector: worker` for user workloads
- Route + cert-manager pattern for public hostnames
- SCC requirements (if any)

## GitOps

Argo CD Application: `okd-gitops/environments/prod/platform/<service-name>.yaml`
