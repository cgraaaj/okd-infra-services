# RESOURCE_PLAN

## OKD cluster capacity (2026-09-01)

| Pool | Nodes | RAM each | Approx free (requests) |
|------|-------|----------|------------------------|
| Masters | 3 | 16 Gi | Platform only (tainted) |
| Workers | 3 | 16 Gi | ~29 Gi for workloads |

Worker-03: remote via WireGuard (`10.0.200.33`).

## Reserved (platform)

| Service | CPU req | Memory req | Notes |
|---------|---------|------------|-------|
| Authentik + PG | ~500m | ~1.5 Gi | Running |
| cert-manager | ~200m | ~256 Mi | Running |
| local-path | ~100m | ~128 Mi | Running |
| Argo CD (target) | ~500m | ~1 Gi | Partial install |
| openshift-router | spread | ~512 Mi/pod | 3 replicas on workers |

## Planned additions

| Service | Est. memory | Worker fit? |
|---------|-------------|-------------|
| ESO | 128 Mi | yes |
| OTel Collector (DS) | 200 Mi/node | yes |
| HyperDX + ClickHouse | 4–8 Gi | **tight** — may need worker RAM upgrade or NAS offload |
| Langfuse | 2–4 Gi | evaluate |
| Per app (avg) | 512 Mi–2 Gi | 3–5 apps feasible |

## Memory-heavy — flag before install

- ClickHouse (HyperDX backend)
- Langfuse stack
- Istio (not planned on OKD)
- Multiple Prometheus instances (avoided)

## CPU

Workers: 4 vCPU each. OKD + 5 modest apps fits; batch/ML workloads should stay on K3s or external.

## Storage (worker disk)

~120 Gi per worker Proxmox volume. local-path uses `/var/local-path-provisioner`. Monitor per-node usage; NAS defers disk pressure for bulk data.

## Scaling triggers

| Signal | Action |
|--------|--------|
| Worker memory >80% | Add worker or move HyperDX to dedicated node |
| PVC >70% on worker | NAS NFS tier |
| Router saturation | Scale router shards (OKD ingress operator) |
