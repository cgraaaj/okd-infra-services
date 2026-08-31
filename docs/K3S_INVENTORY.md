# K3S_INVENTORY — Dev Cluster

> Context: `kubectl --context dev` (`10.19.94.251:6443`)  
> Last updated: 2026-09-01

## Cluster Summary

| Item | Value |
|------|-------|
| Purpose | Development, validation, reference patterns |
| Nodes | 8 (mixed RAM; Longhorn dedicated nodes) |
| GitOps | Argo CD in `argocd-qa` (23 apps) + bootstrap app-of-apps |
| Ingress | Traefik (in-cluster) + Docker Traefik (Wraithking) |
| Storage | Longhorn (primary) + local-path |

## StorageClasses

| Name | Provisioner | Notes |
|------|-------------|-------|
| `longhorn` | driver.longhorn.io | Default (review dual-default with local-path) |
| `longhorn-retain` | driver.longhorn.io | Authentik Postgres |
| `longhorn-static` | driver.longhorn.io | Static PVs |
| `local-path` | rancher.io/local-path | Ephemeral |

## Infrastructure (Argo CD `infrastructure` project)

| App | Namespace | OKD disposition |
|-----|-----------|-----------------|
| cert-manager | cert-manager | **Replicate pattern** on OKD (done) |
| authentik | authentik | **Separate prod** on OKD (`auth.cgraaaj.in`) |
| hashicorpvault | hashicorpvault | **Keep on K3s**; OKD consumes via ESO (later) |
| traefik | traefik | **Do not install** on OKD (use Routes) |
| longhorn | longhorn-system | **Keep on K3s** only |
| istio-* / kiali | istio-system | **Keep on K3s** until mesh need on OKD |
| prometheus | monitoring | **Do not duplicate** (use OKD monitoring) |
| loki | loki | Evaluate vs HyperDX on OKD |
| minio | minio | Keep / evaluate per app |
| kubernetes-replicator | kubernetes-replicator | Optional on OKD if wildcard cert sharing needed |
| gitlab-runner | gitlab-runner | Keep or migrate to GHA runners |
| argocd-image-updater | argocd-qa | Replicate on OKD Argo CD (later) |

## Applications (Argo CD `apps` project)

| App | Namespace | OKD disposition |
|-----|-----------|-----------------|
| mediaradar | mediaradar | **Fresh prod deploy** on OKD (later) |
| mediaradar-svc | mediaradar-svc | Fresh prod deploy |
| optionscope | optionscope | Fresh prod deploy |
| stockx-svc | stockx | Fresh prod deploy |
| tickerflow | tickerflow | Fresh prod deploy |

## Classification Legend

- **Keep on K3s** — dev/experimental only
- **Replicate on OKD** — new prod instance, same patterns/charts
- **Fresh prod deploy** — promote image digest from Harbor after K3s validation
- **Do not install on OKD** — native alternative or no requirement
