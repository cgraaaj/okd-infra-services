# OKD Platform Documentation

Planning artifacts for the OKD prod homelab platform. Approve these before major cluster changes.

## Index (14 documents)

| # | Document | Description |
|---|----------|-------------|
| 1 | [CURRENT_STATE.md](CURRENT_STATE.md) | Live OKD cluster inventory |
| 2 | [K3S_INVENTORY.md](K3S_INVENTORY.md) | Dev cluster workloads + classifications |
| 3 | [TARGET_ARCHITECTURE.md](TARGET_ARCHITECTURE.md) | Target topology and principles |
| 4 | [SERVICE_MATRIX.md](SERVICE_MATRIX.md) | Component install/skip decisions |
| 5 | [GITOPS_STRUCTURE.md](GITOPS_STRUCTURE.md) | Argo CD repo layout and sync waves |
| 6 | [CI_CD.md](CI_CD.md) | GitHub → Harbor → promote → OKD |
| 7 | [SECURITY.md](SECURITY.md) | IdP, TLS, secrets, SCC |
| 8 | [OBSERVABILITY.md](OBSERVABILITY.md) | Metrics, logs, traces split |
| 9 | [STORAGE.md](STORAGE.md) | local-path now, NAS later |
| 10 | [BACKUP.md](BACKUP.md) | Velero and DR |
| 11 | [MIGRATION_PLAN.md](MIGRATION_PLAN.md) | K3s patterns → OKD fresh installs |
| 12 | [RESOURCE_PLAN.md](RESOURCE_PLAN.md) | RAM/CPU budget |
| 13 | [PHASED_ROLLOUT.md](PHASED_ROLLOUT.md) | Phase A–E timeline |
| 14 | [RISKS.md](RISKS.md) | Risk register |

## Related paths

| Path | Purpose |
|------|---------|
| [../okd-services/](../okd-services/) | Service Helm values and manifests |
| [../okd-gitops/](../okd-gitops/) | Argo CD Applications |
| [../okd-policies/](../okd-policies/) | Future admission policies |
| [../plan.md](../plan.md) | Master architecture brief |

## Maintenance

Update `CURRENT_STATE.md` after each platform change. Review `RISKS.md` at phase gates.
