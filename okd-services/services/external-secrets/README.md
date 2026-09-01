# External Secrets Operator — sync HashiCorp Vault (K3s) → OKD Secrets

See [docs/VAULT_ESO.md](../../../docs/VAULT_ESO.md).

## Prerequisites

1. Vault **unsealed** on K3s
2. `bootstrap-okd-auth.sh` + `seed-okd-secrets.sh` run with `VAULT_TOKEN`

## Install

```bash
export KUBECONFIG=/path/to/okd/kubeconfig
./scripts/install.sh
# then Vault bootstrap (from workstation):
export VAULT_ADDR=https://hashicorpvault.cgraaaj.in VAULT_TOKEN=...
../hashicorp-vault/scripts/bootstrap-okd-auth.sh
../hashicorp-vault/scripts/seed-okd-secrets.sh
oc apply -k manifests/
```

Verify:

```bash
oc get clustersecretstore vault-kv
oc get externalsecret -A
```
