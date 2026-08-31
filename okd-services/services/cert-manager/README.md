# cert-manager (OKD prod)

Let's Encrypt TLS via **DNS-01 (Cloudflare)** — same issuer pattern as K3s dev.

## What this replaces

- No manual copy of `wildcard-cgraaaj-in-tls` from K3s
- Route uses `spec.tls.externalCertificate.name: authentik-tls` (OKD-native)
- cert-manager renews the secret automatically (~30 days before expiry)

## Prerequisites

- `oc` logged in to OKD
- `helm` 3.x
- Cloudflare API token with DNS edit on `cgraaaj.in` (stored locally, not in git)

```bash
mkdir -p .secrets
kubectl --context dev get secret cloudflare-token-secret -n cert-manager \
  -o jsonpath='{.data.cloudflare-token}' | base64 -d > .secrets/cloudflare-token
chmod 600 .secrets/cloudflare-token
```

## Install

```bash
export KUBECONFIG=/path/to/okd/kubeconfig
./okd-services/services/cert-manager/scripts/install.sh
```

## Layout

| Path | Purpose |
|------|---------|
| `helm/values.yaml` | cert-manager chart values (v1.20.2, DNS resolvers) |
| `manifests/00-namespace.yaml` | `cert-manager` namespace |
| `manifests/01-clusterissuer-*.yaml` | `letsencrypt-production` ClusterIssuer |
| `manifests/02-certificate-*.yaml` | `auth.cgraaaj.in` → secret `authentik-tls` |
| `manifests/03-route-tls-rbac.yaml` | Router SA read access to `authentik-tls` |

## Authentik Route

`okd-services/services/authentik/manifests/route.yaml` references:

```yaml
tls:
  termination: edge
  externalCertificate:
    name: authentik-tls
```

## Verify

```bash
oc get certificate -n authentik
oc describe route authentik -n authentik
curl -sk https://auth.cgraaaj.in/application/o/okd/.well-known/openid-configuration | jq .issuer
```
