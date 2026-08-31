# BACKUP

## What is Git-recreatable

| Asset | Recovery |
|-------|----------|
| Helm values, manifests | This repo + Argo CD |
| Routes, SCC, RBAC | `okd-services/` + `okd-gitops/` |
| cert-manager issuers | Git |
| Application code | GitHub |

## What must be backed up

| Asset | Location | Method |
|-------|----------|--------|
| Authentik Postgres | OKD PVC (`local-path-retain`) | Velero or pg_dump cron |
| Argo CD state | OKD PVC | Velero |
| Harbor images/blobs | Docker host | Harbor backup / filesystem snapshot |
| Vault data | K3s | Vault snapshot / raft backup |
| TimescaleDB | Docker host | pg_dump / volume backup |
| Let's Encrypt accounts | cert-manager secrets | Velero or secret export |
| `.secrets/` | Workstation | password manager / encrypted backup |

## Velero (Phase D)

- Target: OKD namespaces (`authentik`, `argocd`, `cert-manager`, app NS)
- Backend: NAS S3-compatible (MinIO on K3s or NAS) or NFS path
- Schedule: daily full namespace backup; weekly restore drill

## Disaster recovery order

1. OKD cluster rebuild (installer)
2. Apply platform GitOps bootstrap
3. Restore Velero backups for stateful namespaces
4. Re-point DNS (unchanged if VIP stable)
5. Verify Harbor pull + Authentik OAuth

## RPO / RTO (homelab targets)

| Tier | RPO | RTO |
|------|-----|-----|
| Platform config | 0 (git) | 1–2 h |
| Authentik / Argo state | 24 h | 4 h |
| Harbor images | 7 d | 1 h (re-pull from upstream) |
