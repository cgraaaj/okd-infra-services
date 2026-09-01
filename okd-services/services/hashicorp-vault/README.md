# HashiCorp Vault (OKD integration)

Vault **runs on K3s** (`k3s-projects/hashicorpvault`). This folder contains OKD-side bootstrap scripts only.

See [docs/VAULT_ESO.md](../../../docs/VAULT_ESO.md) for architecture.

## Credentials

Store admin API access in **`.secrets/hashicorpvault.env`** (gitignored):

```bash
VAULT_ADDR=https://hashicorpvault.cgraaaj.in
VAULT_TOKEN=hvs.xxxxxxxxxxxxxxxx
```

Scripts auto-load this file. Test anytime:

```bash
./scripts/check-vault.sh
```

## Invalid token (`403 permission denied / invalid token`)

The token in `.secrets/hashicorpvault.env` is **not** the unseal keys — it is the **root or admin API token** from `vault operator init`. If it was revoked or rotated, bootstrap will fail.

**Option A — use saved root token (easiest)**

1. Find the root token from your password manager (saved at `vault operator init`).
2. Update `.secrets/hashicorpvault.env` with that token.
3. Run `./scripts/check-vault.sh` — should print `Vault token OK`.

**Option B — generate a new root token** (if you still have 3+ unseal keys)

```bash
export KUBECONFIG=~/.kube/config
kubectl config use-context dev
kubectl exec -n hashicorpvault hashicorpvault-0 -it -- sh

# inside the pod:
export VAULT_ADDR=http://127.0.0.1:8200
vault operator generate-root -init     # save OTP + Nonce from output
vault operator generate-root           # enter OTP, then one unseal key per prompt (3x)
# decode the output token:
vault operator generate-root -decode=<encoded-token-from-last-step> -otp=<OTP>
```

Put the decoded token in `.secrets/hashicorpvault.env`, then `./scripts/check-vault.sh`.

## Install order

```bash
# 0. Vault unsealed on K3s (vault status → Sealed: false)
./scripts/check-vault.sh

# 1. ESO on OKD (if not already)
../external-secrets/scripts/install.sh

# 2. Vault auth for OKD
./scripts/bootstrap-okd-auth.sh

# 3. Seed secrets from .secrets/
./scripts/seed-okd-secrets.sh

# 4. ESO manifests
oc apply -k ../external-secrets/manifests/
```

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/check-vault.sh` | Validate token + unseal status |
| `scripts/bootstrap-okd-auth.sh` | `kubernetes-okd` auth + ESO role/policy |
| `scripts/seed-okd-secrets.sh` | Upload `.secrets/*` → `kv-v2/okd/platform/...` |
