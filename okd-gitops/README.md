# OKD GitOps

Argo CD Applications for the OKD prod cluster. Service definitions live in `../okd-services/`.

## Layout

```
projects/           AppProjects (RBAC boundaries)
clusters/okd/       Bootstrap app-of-apps
environments/prod/  Platform + application Applications
```

## Bootstrap (Phase C — not applied yet)

```bash
# After Argo CD is configured:
oc apply -f projects/
oc apply -f clusters/okd/bootstrap.yaml
```

See [docs/GITOPS_STRUCTURE.md](../docs/GITOPS_STRUCTURE.md).

## Status

| Item | State |
|------|-------|
| AppProjects | Scaffolded, not applied |
| Bootstrap app | Scaffolded |
| Platform apps | Placeholder Applications |
| Application apps | Empty |

Hand-applied services (Phase A) will be imported under GitOps in Phase C3.
