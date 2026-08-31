# RISKS

| ID | Risk | Impact | Likelihood | Mitigation |
|----|------|--------|------------|------------|
| R1 | OKD oauth-openshift vs `control-plane` taint | Cluster login breaks | Medium | Toleration patch; operator `Unmanaged`; upstream OKD fix |
| R2 | Worker disk full (local-path) | PVC bind failures | Medium | Monitor disk; NAS tier; Retain policy awareness |
| R3 | Remote worker-03 latency (WireGuard) | Slow pulls / scheduling | Low | Keep heavy workloads on worker-01/02; monitor |
| R4 | cert-manager DNS-01 failure | TLS expiry, OAuth break | Low | cert-manager alerts; Cloudflare token rotation doc |
| R5 | Copied/manual config drift | Prod inconsistency | Medium | **Addressed** — GitOps in Phase C |
| R6 | HyperDX/ClickHouse memory on 16 Gi workers | OOM, eviction | High | Size before install; dedicated node or NAS |
| R7 | Harbor single point of failure | No image pulls | Medium | Harbor backup; retain upstream fallbacks |
| R8 | Vault on K3s only | OKD secret bootstrap if K3s down | Medium | ESO cache; break-glass secrets in `.secrets/` |
| R9 | Dual Authentik user bases | Auth confusion | Low | Clear hostname separation; SSO only via intended IdP |
| R10 | Master schedulable label (`worker` on masters) | Accidental master scheduling | Medium | Taints + `nodeSelector: worker` on all apps |
| R11 | Authentication operator `Unmanaged` | Missed OKD upgrades for auth | Low | Document; revisit each OKD upgrade |
| R12 | No Velero yet | Data loss on PVC failure | High | Phase D priority after Argo CD |

## Accepted risks (homelab)

- Single Harbor instance (no geo-redundancy)
- kubeadmin break-glass account
- Manual `.secrets/` for bootstrap tokens

## Review cadence

Revisit this register at each phase gate (M1–M4) and after OKD minor upgrades.
