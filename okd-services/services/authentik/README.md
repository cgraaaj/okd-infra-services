# Authentik (prod)

Prod identity provider for OKD at `auth.cgraaaj.in`.

## Install

```bash
export KUBECONFIG=/path/to/okd/kubeconfig
oc adm policy add-scc-to-group anyuid system:serviceaccounts:authentik
helm upgrade --install authentik authentik/authentik -n authentik --version 2025.12.4 -f helm/values.yaml --wait
oc apply -f manifests/route.yaml
```

Secrets: `.secrets/authentik.env` (not in git)

## OKD OAuth

- Issuer: `https://auth.cgraaaj.in/application/o/okd`
- Redirect: `https://oauth-openshift.apps.okd.cgraaaj.in/oauth2callback/okd`

## TLS

Route uses `spec.tls.externalCertificate.name: authentik-tls` (cert-manager, DNS-01).  
See `../cert-manager/README.md` — do not embed certs inline on the Route.
