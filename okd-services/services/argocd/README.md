# Argo CD (OKD prod)

GitOps control plane via the **Argo CD Operator** (`ArgoCD` CR in namespace `argocd`).

## Public URL

`https://argocd.apps.okd.cgraaaj.in` — native OKD Route on the cluster ingress domain (VPN/LAN only).

## Install / configure

```bash
export KUBECONFIG=/path/to/okd/kubeconfig
./scripts/configure.sh
```

## Admin login

**Preferred:** Authentik OIDC — click **LOG IN VIA AUThentik** at https://argocd.apps.okd.cgraaaj.in

```bash
./scripts/configure-oidc.sh   # (re)create Authentik provider + Argo CD config
```

RBAC (Authentik groups → Argo CD roles):

| Authentik group | Argo CD role |
|-----------------|--------------|
| `authentik Admins` | admin |
| `argocd-admins` | admin |
| `argocd-platform` | platform-admin (sync platform apps) |

**Break-glass local admin:** reset bcrypt hash in `argocd-secret` (not the plaintext password):

```bash
NEW_PASS='...'
BCRYPT=$(argocd account bcrypt --password "$NEW_PASS")
oc patch secret argocd-secret -n argocd --type merge -p "$(jq -nc --arg p "$BCRYPT" --arg t "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '{stringData:{"admin.password":$p,"admin.passwordMtime":$t}}')"
```

## GitOps bootstrap

After pushing this repo to a remote Git URL:

```bash
export GIT_REPO_URL=https://github.com/YOU/okd-infra-services.git
./scripts/bootstrap-gitops.sh
```

## Layout

| File | Purpose |
|------|---------|
| `manifests/argocd-instance.yaml` | Disable operator default Route |
| `manifests/route.yaml` | `argocd.apps.okd.cgraaaj.in` (native ingress TLS) |
| `manifests/argocd-cm-patch.yaml` | Public URL + server.insecure |
