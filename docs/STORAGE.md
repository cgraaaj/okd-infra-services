# STORAGE

## Current State (OKD)

| StorageClass | Provisioner | Reclaim | Use case |
|--------------|-------------|---------|----------|
| `local-path-retain` (default) | rancher.io/local-path | Retain | Stateful prod (Authentik PG, Argo CD) |
| `local-path` | rancher.io/local-path | Delete | Ephemeral / test PVCs |

Provisioner: `local-path-provisioner` in `local-path-storage`, `nodeSelector: worker`, path `/var/local-path-provisioner`.

## Phase 1 — DONE

- Deploy local-path-provisioner on workers
- Verify test PVC bind
- Use for Authentik PostgreSQL (8 Gi, `local-path-retain`)

## Phase 2 — NAS NFS (deferred)

**When:** bulk RWX workloads, shared config, backup targets, or worker disk pressure.

| Tier | Backend | Access | Workloads |
|------|---------|--------|-----------|
| Fast RWO | local-path on workers | RWO | DBs, Argo CD, small stateful |
| Bulk RWX | NAS NFS CSI | RWX | shared assets, Velero, large PVCs |

### NAS prerequisites (not started)
- NFS export from N300 Pro on dedicated VLAN
- `nfs-subdir-external-provisioner` or CSI driver on OKD
- StorageClasses: `nfs-retain`, `nfs-delete`
- Firewall: workers → NAS only

## K3s vs OKD mapping

| K3s | OKD prod equivalent |
|-----|---------------------|
| `longhorn` / `longhorn-retain` | `local-path` / `local-path-retain` (phase 1) |
| Longhorn RWX | NAS NFS (phase 2) |

## Do not install on OKD (initially)

- **Longhorn** — duplicates local-path; WAN worker caution
- **Ceph/Rook** — operational overhead exceeds homelab need
- **OpenShift Data Foundation** — overkill for 3-worker homelab

## Backup implications

- `local-path-retain`: PVs survive PVC delete; still need Velero/filesystem backup
- NAS: snapshot/replication at array level when deployed
