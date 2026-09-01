# SECURITY

## Identity

| Layer | Dev | Prod |
|-------|-----|------|
| IdP | Authentik `auth.dev.cgraaaj.in` (K3s) | Authentik `auth.cgraaaj.in` (OKD) |
| OKD cluster login | — | OAuth → Authentik (`okd-prod` client) |
| MFA | Duo (via Authentik) | Same Authentik policies |

**Never share** OAuth clients or Postgres between dev and prod Authentik instances.

## TLS

| Surface | Mechanism |
|---------|-----------|
| Public routes (`*.cgraaaj.in`) | cert-manager DNS-01 (Cloudflare) + Route `externalCertificate` |
| `*.apps.okd.cgraaaj.in` | openshift-router default cert |
| Internal service mesh | Not deployed on OKD |

## Secrets management

| Phase | Approach |
|-------|----------|
| Now | `.secrets/` locally (gitignored); `oc create secret` for bootstrap |
| Phase C | **External Secrets Operator** on OKD → **HashiCorp Vault on K3s** (`hashicorpvault.cgraaaj.in`, KV `okd/platform/*`) — see [VAULT_ESO.md](VAULT_ESO.md) |
| Not now | Sealed Secrets, SOPS in git (add if team/gitops need grows) |

## RBAC

- OKD cluster: `cluster-admin` limited to platform admins
- Argo CD: AppProjects per team/env (bootstrap in step 7)
- Harbor: robot accounts per cluster (pull-only for OKD `regcred`)

## Network

- Masters tainted; apps on workers
- Docker Traefik: TLS passthrough to OKD VIP for prod hostnames
- Future: NetworkPolicies per namespace when multi-tenant apps land

## SCC (Security Context Constraints)

| Service | SCC notes |
|---------|-----------|
| local-path-provisioner | Custom SCC + privileged helper pods |
| authentik | `anyuid` for namespace SAs |
| cert-manager | Default restricted (verify on install) |

## Policies (`okd-policies/`)

**Not deploying Kyverno/Gatekeeper yet.** Add when concrete requirements exist (e.g. require `nodeSelector: worker`, disallow `latest` tag).

## Known security debt

1. `authentication.operator.openshift.io` = `Unmanaged` (oauth-openshift toleration) — restore when OKD ships fix
2. Kubeadmin password in installer dir — rotate; prefer OAuth-only admin access
3. Cloudflare API token in `.secrets/` — scope to DNS edit only
