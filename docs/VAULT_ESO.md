# Vault + External Secrets (OKD prod)

## What we use

| Component | Where | Role |
|-----------|-------|------|
| **HashiCorp Vault** | K3s (`hashicorpvault` namespace) | Central secret store (KV v2) |
| **External Secrets Operator (ESO)** | OKD (`external-secrets` namespace) | Sync Vault → native Kubernetes `Secret` objects |
| **Bootstrap secrets** | `.secrets/` (local, gitignored) | One-time seed into Vault; not committed |

This matches [TARGET_ARCHITECTURE.md](TARGET_ARCHITECTURE.md): Vault stays on K3s; OKD **does not** run Vault. OKD workloads never talk to Vault directly — only ESO does.

## Why not only K8s Secrets?

Bootstrap `oc create secret` is fine for day-0, but it does not scale:

- No rotation path, no audit trail, secrets duplicated per cluster
- GitOps cannot safely hold plaintext (we use `$secret` refs in Argo CD + ESO materialization)
- Same Vault already serves K3s apps (Redis creds, API keys)

**Production path:** write secrets to Vault once → ESO keeps OKD `Secret` objects in sync.

## Network path

```
OKD worker → https://hashicorpvault.cgraaaj.in (Docker Traefik → K3s Traefik → Vault)
          or → http://10.19.94.181:8200 (if L3 route from 10.0.200.0/24 is open)
```

ESO `ClusterSecretStore` uses the public URL with TLS verification (Let's Encrypt on Traefik).

## Vault KV layout (OKD prod)

Engine: **`kv-v2`** (already enabled on dev Vault)

| Vault path | K8s Secret | Namespace |
|------------|------------|-----------|
| `okd/platform/argocd/oidc` | `argocd-oidc` | `argocd` |
| `okd/platform/cert-manager/cloudflare` | `cloudflare-api-token` | `cert-manager` |
| `okd/platform/authentik/core` | (future) helm values refs | `authentik` |
| `okd/apps/<app>/<key>` | per-app | app NS |

Example read path for ESO: `okd/platform/argocd/oidc` with property `client_secret`.

## Vault auth for OKD (Kubernetes)

K3s already uses `auth/kubernetes` for in-cluster pods. OKD is a **second cluster**, so we add a dedicated mount:

| Mount | Cluster | Used by |
|-------|---------|---------|
| `auth/kubernetes` | K3s | Vault Agent, mediaradar-svc, etc. |
| `auth/kubernetes-okd` | OKD | ESO service account only |

ESO authenticates as `system:serviceaccount:external-secrets:external-secrets` with Vault role `external-secrets-okd` and policy `okd-platform-read`.

## Prerequisites (must be green before ESO syncs)

1. **Vault unsealed** on K3s (`vault status` → `Sealed: false`)
2. **K3s DNS for OKD API** — Vault TokenReview needs `api.okd.cgraaaj.in` resolvable from K3s pods (`./okd-services/services/hashicorp-vault/scripts/ensure-k3s-okd-dns.sh`; called by bootstrap)
3. **OKD kubeconfig CA** — bootstrap reads `kube-root-ca.crt` when kubeconfig uses `insecure-skip-tls-verify`
4. **Vault reachable** from OKD workers (`curl https://hashicorpvault.cgraaaj.in/v1/sys/health`)
5. **Bootstrap script run**: `./okd-services/services/hashicorp-vault/scripts/bootstrap-okd-auth.sh`
6. **Secrets seeded**: `./okd-services/services/hashicorp-vault/scripts/seed-okd-secrets.sh`

## Install order

```bash
export KUBECONFIG=/path/to/okd/kubeconfig

# 1. Vault (on K3s) — unseal + bootstrap auth + seed paths
export VAULT_ADDR=https://hashicorpvault.cgraaaj.in
export VAULT_TOKEN=<root-or-admin>
./okd-services/services/hashicorp-vault/scripts/bootstrap-okd-auth.sh
./okd-services/services/hashicorp-vault/scripts/seed-okd-secrets.sh

# 2. ESO on OKD
./okd-services/services/external-secrets/scripts/install.sh

# 3. ClusterSecretStore + ExternalSecrets
oc apply -k okd-services/services/external-secrets/manifests/
```

## Enterprise evolution

| Stage | Approach |
|-------|----------|
| **Now** | Shared Vault on K3s + ESO on OKD |
| **Later** | Vault HA replica or dedicated prod Vault VM; same ESO pattern |
| **Avoid** | Long-lived root token in ESO; use K8s auth only |
| **Optional** | Auto-unseal (cloud KMS / HSM) if Vault uptime becomes critical |

## Known risk (R8)

If K3s is down, OKD cannot refresh secrets from Vault. ESO keeps last-synced K8s Secrets until TTL/rotation forces failure. Keep break-glass copies in `.secrets/` for disaster recovery.
