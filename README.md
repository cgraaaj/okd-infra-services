# OKD Platform — Planning & Service Definitions

Homelab production platform on OKD 4.21. K3s remains dev.

## Quick links

| Doc | Purpose |
|-----|---------|
| [CURRENT_STATE.md](docs/CURRENT_STATE.md) | Live OKD snapshot |
| [PHASED_ROLLOUT.md](docs/PHASED_ROLLOUT.md) | What's done / what's next |
| [SERVICE_MATRIX.md](docs/SERVICE_MATRIX.md) | Install / skip decisions |

## Repository structure

```
okd-infra-services/
├── docs/              14 planning documents
├── okd-services/      Helm values + manifests per service
├── okd-gitops/        Argo CD Applications (Phase C)
├── okd-policies/      Admission policies (when needed)
└── plan.md            Original architecture brief
```

## Phase status

- **Phase A / A.5** — Done (storage, Authentik, OAuth, cert-manager)
- **Phase B** — Done (this documentation)
- **Phase C** — Next: Argo CD bootstrap

## Services deployed

| Service | Path |
|---------|------|
| local-path-provisioner | `okd-services/services/local-path-provisioner/` |
| Authentik | `okd-services/services/authentik/` |
| cert-manager | `okd-services/services/cert-manager/` |
