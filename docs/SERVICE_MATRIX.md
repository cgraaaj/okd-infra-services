# SERVICE_MATRIX

Decision engine for every platform component. Status as of 2026-09-01.

| Component | Exists today | OKD native? | Required? | Phase | Priority | Decision |
|-----------|--------------|-------------|-----------|-------|----------|----------|
| openshift-router | yes | yes | yes | — | — | **Use** |
| Routes | yes | yes | yes | A | done | **Use** |
| OAuth / RBAC / SCC | yes | yes | yes | — | — | **Use** |
| Built-in Prometheus | yes | yes | yes | B | high | **Use** (no 2nd Prometheus) |
| local-path-provisioner | yes (OKD) | no | yes | A | done | **Installed** |
| NAS NFS CSI | no | no | later | C | medium | **Defer** |
| cert-manager | yes (K3s+OKD) | no | yes | A.5 | done | **Installed on OKD** |
| Authentik prod | yes (OKD) | no | yes | A | done | **Installed** `auth.cgraaaj.in` |
| Authentik dev | yes (K3s) | no | yes | — | — | **Keep on K3s** |
| Argo CD prod | partial (OKD) | no | yes | C | high | **Bootstrap** (step 7) |
| Argo CD dev | yes (K3s) | no | yes | — | — | **Keep on K3s** |
| Harbor | yes (Docker) | no | yes | — | — | **Keep shared** |
| Vault | yes (K3s) | no | yes | C | medium | **Keep** + ESO on OKD |
| External Secrets Operator | no (OKD) | no | yes | C | medium | **Install later** |
| Traefik on OKD | no | no | no | — | — | **Do not install** |
| Istio on OKD | no | partial | no | — | low | **Do not install** (K3s only) |
| Longhorn on OKD | no | no | no | — | — | **Do not install** |
| Loki on OKD | no | no | maybe | D | low | **Evaluate** vs HyperDX |
| OTel Collector | no (OKD) | no | yes | D | medium | **Install later** |
| HyperDX + ClickHouse | no (OKD) | no | yes | D | medium | **Fresh prod install** |
| Langfuse | no (OKD) | no | app-specific | D | low | **When LLM apps land** |
| Velero | no (OKD) | no | yes | D | medium | **Install later** |
| Kyverno / Gatekeeper | no | partial | no | — | — | **Do not install** (yet) |
| Gitea / alt SCM | no | no | no | — | — | **Do not install** |
| GitHub Actions | yes | no | yes | — | — | **Use** |
| GitLab Runner | yes (K3s) | no | optional | — | low | **Keep or replace** |

## Classification Summary

### DONE (Phase A / A.5)
- Master taints, local-path, Authentik prod, OAuth, cert-manager

### DO NEXT (Phase C)
- Argo CD prod bootstrap, AppProjects, wire `okd-gitops`
- ESO + Vault integration
- Route + cert pattern for `argocd.cgraaaj.in`

### DO LATER (Phase D)
- OTel, HyperDX, ClickHouse, Velero, NAS NFS
- Prod app deployments (mediaradar, tickerflow, etc.)

### DO NOT INSTALL
- Traefik/NGINX ingress on OKD, second Prometheus, Istio (initially), Longhorn on OKD, Kyverno (until policy need), Gitea
