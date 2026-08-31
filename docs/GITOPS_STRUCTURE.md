# GITOPS_STRUCTURE

## Repositories

| Repo / path | Role |
|-------------|------|
| `okd-infra-services` (this repo) | Monorepo: service defs + gitops + docs |
| `k3s-infra` (GitHub) | K3s dev Argo CD manifests (`argo-registry`) |
| App repos | Helm charts + app source (mediaradar, tickerflow, …) |

K3s dev GitOps **stays separate**. OKD prod uses `okd-gitops/` in this repo (may split to own GitHub repo later).

## OKD GitOps layout

```
okd-gitops/
├── README.md
├── projects/                    # Argo CD AppProjects
│   ├── platform.yaml
│   └── applications.yaml
├── clusters/
│   └── okd/
│       ├── bootstrap.yaml       # App-of-apps root
│       └── kustomization.yaml
└── environments/
    └── prod/
        ├── platform/            # cert-manager, local-path, authentik, argocd
        │   └── kustomization.yaml
        └── applications/        # business apps (empty until Phase D)
            └── kustomization.yaml
```

## Sync waves (recommended)

| Wave | Components |
|------|------------|
| -1 | AppProjects, namespaces |
| 0 | local-path-provisioner, cert-manager, ClusterIssuer |
| 1 | Authentik, cert-manager Certificates, Routes |
| 2 | Argo CD self-management (optional) |
| 3 | ESO, monitoring exporters |
| 4+ | Applications |

## Patterns

- **Service definition** lives in `okd-services/services/<name>/`
- **Argo Application** in `okd-gitops/environments/prod/platform/<name>.yaml` points to that path or Helm repo
- Prefer **Helm** for third-party charts; **Kustomize** for OKD Routes/RBAC overlays
- **No secrets in git** — ExternalSecrets or manual bootstrap secrets documented in service README

## Bootstrap sequence (step 7)

1. Ensure Argo CD server reachable (`argocd.cgraaaj.in`)
2. Create AppProjects (`platform`, `applications`)
3. Apply bootstrap Application (app-of-apps)
4. Migrate hand-applied services (authentik, cert-manager) under GitOps sync
5. Enable automated sync + self-heal for platform apps

## Argo CD on OKD today

Partial install detected: `argocd` namespace with server/repo-server/redis; `argocd-operator` namespace. Step 7 completes configuration, ingress route, and GitOps wiring.
