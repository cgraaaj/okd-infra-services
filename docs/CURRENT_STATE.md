# CURRENT_STATE — OKD Prod Cluster

> Last updated: 2026-09-01 (post Phase C partial)

## Cluster Summary

| Item | Value |
|------|-------|
| Cluster API | `https://api.okd.cgraaaj.in:6443` |
| Version | OKD 4.21.0-okd-scos.0 / Kubernetes v1.34.2 |
| Nodes | 3 masters (tainted) + 3 workers (16 Gi each) |
| Network | `10.0.200.0/24`, ingress VIP `10.0.200.11` |
| Ingress domain | `*.apps.okd.cgraaaj.in` |
| Public prod hostname pattern | `*.cgraaaj.in` via Docker Traefik → OKD VIP |

## Nodes

```
NAME        ROLES                         TAINTS              RAM (alloc)
master-01   control-plane,master,worker   control-plane       ~16 Gi
master-02   control-plane,master,worker   control-plane       ~16 Gi
master-03   control-plane,master,worker   control-plane       ~16 Gi
worker-01   worker                        <none>              ~16 Gi
worker-02   worker                        <none>              ~16 Gi
worker-03   worker                        <none>              ~16 Gi  (10.0.200.33)
```

Masters have `node-role.kubernetes.io/control-plane:NoSchedule`. User workloads use `nodeSelector: worker`.

## Platform Workloads (non-OpenShift)

| Namespace | Workload | Purpose | Node |
|-----------|----------|---------|------|
| `authentik` | server, worker, postgresql | Prod IdP | workers |
| `cert-manager` | controller, webhook, cainjector | TLS (LE DNS-01) | workers |
| `local-path-storage` | provisioner | Dynamic local PVs | workers |
| `argocd` | server, repo-server, redis, controller | Argo CD (operator) | workers |

## StorageClasses

| Name | Provisioner | Reclaim | Default |
|------|-------------|---------|---------|
| `local-path-retain` | rancher.io/local-path | Retain | yes |
| `local-path` | rancher.io/local-path | Delete | no |

NAS NFS CSI: **not deployed** (deferred).

## Authentication

- **Prod IdP:** Authentik at `https://auth.cgraaaj.in`
- **Dev IdP:** Authentik at `https://auth.dev.cgraaaj.in` (K3s)
- **OAuth issuer:** `https://auth.cgraaaj.in/application/o/okd`
- **Secret:** `openshift-config/authentik-secret`
- **Route TLS:** cert-manager `Certificate` `auth-cgraaaj-in` → `authentik-tls` → Route `externalCertificate`
- **Known issue:** `authentication.operator.openshift.io` is `Unmanaged` (oauth-openshift `control-plane` toleration patch). ClusterOperator shows `Unknown` until restored.

## External Traffic Path (auth.cgraaaj.in)

```
Internet → Traefik (10.19.94.72, TLS passthrough)
         → OKD HAProxy VIP (10.0.200.11)
         → openshift-router (edge TLS, LE cert from cert-manager)
         → authentik-server
```

Same passthrough path for `argocd.cgraaaj.in` → `argocd-server` (Route `externalCertificate: argocd-tls`).

## GitOps (Argo CD)

| Item | Status |
|------|--------|
| URL | `https://argocd.cgraaaj.in` |
| AppProjects | `platform`, `applications` applied |
| Bootstrap Application | **pending** — needs git remote |
| Platform Applications | defined in `okd-gitops/environments/prod/platform/` |
| Local git | `git init` on this repo; push to GitHub/Cursor remote required |

Run after remote is available:

```bash
export GIT_REPO_URL=https://github.com/cgraaaj/okd-infra-services.git
./okd-gitops/scripts/bootstrap-gitops.sh
```

**Traefik note:** live config is mounted from `~/Backups/Docker/home-lab-docker-setup/.../main-routes.yaml` (not `~/Projects/...`).

## Docker Host (Wraithking) Dependencies

| Service | Role |
|---------|------|
| Traefik | Public L4/L7 entry, `*.cgraaaj.in` passthrough |
| Harbor | Container registry (shared dev + prod) |
| TimescaleDB / Redis / NATS | External data plane (apps connect over network) |

## Credentials (local, gitignored)

`.secrets/authentik.env`, `.secrets/cloudflare-token`
