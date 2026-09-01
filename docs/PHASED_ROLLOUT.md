# PHASED_ROLLOUT

## Completed

### Phase A — Foundation ✅
1. Taint masters (`control-plane:NoSchedule`)
2. local-path-provisioner + StorageClasses
3. Prod Authentik (`auth.cgraaaj.in`)
4. OKD OAuth (issuer + secret)
5. Authentication operator functional (oauth-openshift toleration workaround)

### Phase A.5 — TLS ✅
6. cert-manager on OKD (LE DNS-01, Cloudflare)
7. Route `externalCertificate` for Authentik (no copied certs)

### Phase B — Planning ✅ (this step)
8. 14 planning documents
9. Repo scaffold (`okd-gitops`, `okd-policies`, service template)

### Phase C — GitOps platform ✅
| # | Task | Status |
|---|------|--------|
| C1 | Argo CD route, cm, AppProjects | ✅ |
| C5 | `argocd.cgraaaj.in` Route + cert | ✅ |
| C2 | Bootstrap `okd-gitops` app-of-apps | ✅ |
| C3 | GitOps-manage cert-manager, local-path, authentik | ✅ |
| C7 | Authentik OIDC for Argo CD | ✅ |
| C4 | External Secrets Operator + Vault | ✅ |
| C6 | Restore Authentication operator `Managed` | optional |

## In progress / next

### Phase D — Observability & backup ← **in progress**
| # | Task | Status |
|---|------|--------|
| D1 | OTel Collector | ✅ gateway + agent |
| D2 | HyperDX + ClickHouse | ✅ (emptyDir; NAS persistence in D4) |
| D3 | Velero + backup schedules | ⏳ next |
| D4 | NAS NFS CSI (if storage pressure) | |

### Phase E — Applications
| # | Task |
|---|------|
| E1 | First prod app (e.g. mediaradar) — digest promotion |
| E2 | Remaining apps per SERVICE_MATRIX |

## Milestone gates

| Gate | Criteria |
|------|----------|
| **M1 Platform** | Argo CD syncs platform apps; login via Authentik | ✅ |
| **M2 Observable** | OTel + HyperDX receiving prod traces | ✅ (validate ingest in UI) |
| **M3 Apps** | ≥1 prod app on OKD with CI promotion |
| **M4 DR** | Velero restore tested |

## Timeline (indicative)

| Phase | Effort |
|-------|--------|
| C (Argo CD) | 1–2 sessions |
| D (observability) | 2–3 sessions |
| E (per app) | 0.5–1 session each |
