# Argo CD (OKD prod)

GitOps control plane via the **Argo CD Operator** (`ArgoCD` CR in namespace `argocd`).

## Public URL

`https://argocd.cgraaaj.in` — Route edge TLS via cert-manager (`argocd-tls`).

## Install / configure

```bash
export KUBECONFIG=/path/to/okd/kubeconfig
./scripts/configure.sh
```

## Admin login

```bash
# bcrypt password from secret (reset if unknown):
oc get secret argocd-secret -n argocd -o jsonpath='{.data.admin\.password}' | base64 -d; echo
```

Or use Authentik OIDC once configured (Phase C+).

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
| `manifests/route.yaml` | `argocd.cgraaaj.in` + externalCertificate |
| `manifests/argocd-cm-patch.yaml` | Public URL + server.insecure |
| `manifests/route-tls-rbac.yaml` | Router read access to TLS secret |
