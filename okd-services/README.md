# okd-services

Service definitions for OKD prod — **how** to deploy each component.

```
services/
├── _template/           Copy for new services
├── local-path-provisioner/
├── authentik/
└── cert-manager/
```

Each service should include:
- `README.md` — install, secrets, OKD notes
- `helm/values.yaml` — Helm values (if chart-based)
- `manifests/` — Routes, RBAC, Certificates, raw YAML

GitOps Applications live in `../okd-gitops/`.
