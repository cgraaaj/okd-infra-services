# CI_CD

## Pipeline flow

```
GitHub (push/PR)
    → GitHub Actions (build, test, lint)
    → Harbor (push image by digest)
    → K3s DEV (Argo CD auto-sync or manual)
    → Validation (smoke tests, integration)
    → Promote digest (git tag / values bump in prod gitops)
    → OKD PROD (Argo CD sync)
```

## Principles

1. **Immutable digests** — prod references `@sha256:…`, not `:latest`
2. **Dev proves, prod promotes** — no direct prod builds
3. **Harbor is single registry** — both clusters pull from Docker host Harbor
4. **OCI Helm** — optional; charts can live in git or Harbor OCI

## GitHub Actions

| Concern | Pattern |
|---------|---------|
| Auth to Harbor | `HARBOR_ROBOT` secret in GitHub |
| Auth to OKD | not needed in CI — Argo CD pulls from git |
| Reusable workflows | build → scan → push per repo |

## Image promotion

```yaml
# okd-gitops example (future)
image:
  repository: harbor.cgraaaj.in/project/app
  tag: "sha256:abc123..."  # promoted from dev validation
```

Use **argocd-image-updater** on OKD (optional, phase C+) or manual PR to bump digest.

## Environments

| Env | Cluster | Argo CD | Authentik |
|-----|---------|---------|-----------|
| dev | K3s | argocd-qa | auth.dev |
| prod | OKD | argocd (OKD) | auth.cgraaaj.in |

## Not using

- GitLab CI as primary (runner exists on K3s but GitHub is source of truth)
- Jenkins on OKD
- Manual `kubectl apply` for prod (target: all via Argo CD)
