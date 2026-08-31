# MIGRATION_PLAN

> This is **not** a pod migration plan. K3s dev stays; OKD gets fresh prod installs.

## Strategy

| From (K3s dev) | To (OKD prod) | Method |
|----------------|---------------|--------|
| Helm chart / pattern | Same chart, prod values | Copy structure, new values overlay |
| Image `:tag` | Image `@digest` | Promote after dev validation |
| Traefik Ingress | OKD Route | New manifest per service |
| Longhorn PVC | local-path-retain PVC | **New empty DB** — migrate data only if required |
| cert-manager DNS-01 | Same ClusterIssuer pattern | Replicate issuer + per-host Certificate |
| Authentik | Separate instance | New DB, new OAuth clients |

## Per-component mapping

| Component | K3s | OKD action |
|-----------|-----|------------|
| Ingress | Traefik IngressRoute | Route + optional `externalCertificate` |
| TLS | cert-manager secret | cert-manager on OKD (done for auth) |
| Storage class | `longhorn-retain` | `local-path-retain` |
| Pull secret | `regcred` | Same Harbor robot, new secret in NS |
| Service account | default | Dedicated SA + SCC if needed |
| Scheduling | various | `nodeSelector: worker` for user apps |

## Application rollout order (Phase D)

1. Stateless services first (APIs with external DB)
2. Stateful with external DB (TimescaleDB on Docker)
3. Stateful with in-cluster DB (last — backup plan required)

## Apps queue (priority TBD)

| App | Dev ready | Prod blockers |
|-----|-----------|---------------|
| mediaradar | yes | Argo CD, Route, regcred |
| tickerflow | yes | same |
| optionscope | yes | same |
| stockx-svc | yes | same |

## Data migration

**Default: no data migration.** Export/import only when business requires continuity (e.g. Authentik users → export blueprint; Postgres → pg_dump).

## Decommission criteria (K3s app)

Only retire K3s prod-like paths when:
- OKD prod serves traffic for 30+ days
- Backups verified
- DNS cutover complete
