# okd-policies

Admission, RBAC, and network policies for OKD prod.

**Status:** Empty until a concrete policy requirement emerges.

## When to add policies here

- Require `nodeSelector: worker` on all Deployments in app namespaces
- Deny `image: latest` in prod
- Mandate NetworkPolicy for multi-tenant apps
- Pod Security Standards / SCC wrappers

## Preferred order

1. Document requirement in `docs/SECURITY.md`
2. Try native OKD RBAC / SCC first
3. Add Kyverno or Gatekeeper only if native controls are insufficient

See `docs/SERVICE_MATRIX.md` — Kyverno/Gatekeeper: **do not install yet**.
