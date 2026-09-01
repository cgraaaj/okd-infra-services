# HyperDX + ClickHouse (Phase D2)

Observability UI and storage for OKD prod traces/logs/metrics. Uses the **existing OTel gateway** (bundled chart collector disabled).

## Architecture

```
App → otel-agent → otel-gateway → ClickHouse (otel_* tables)
                                      ↑
HyperDX UI ───────────────────────────┘
```

Public UI: `https://hyperdx.cgraaaj.in` (OKD Route + cert-manager)

## Status

| Component | Status |
|-----------|--------|
| HyperDX app | ✅ Running |
| ClickHouse | ✅ Running (emptyDir — see storage note) |
| MongoDB | ✅ Running (emptyDir) |
| OTel → CH export | ✅ via `otel-gateway` clickhouse exporter |

## Storage note (homelab)

PVCs via `local-path-retain` hit **SELinux/hostPath permission** issues on OKD workers. Current values use **`persistence.enabled: false`** (emptyDir). Telemetry works but **data is lost on pod reschedule**.

**Enterprise path:** NAS NFS CSI (Phase D4) or dedicated ClickHouse node with proper volume permissions.

## Install

```bash
export KUBECONFIG=/path/to/okd/kubeconfig
./scripts/install.sh

# Wire OTel gateway (if not via GitOps):
helm upgrade otel-gateway open-telemetry/opentelemetry-collector \
  -n observability --version 0.172.0 \
  -f ../otel-collector/helm/values-gateway.yaml
```

## OpenShift requirements

- `observability` namespace labeled `pod-security.kubernetes.io/enforce=privileged`
- `privileged` SCC on `default` service account (`scripts/openshift-patch.sh`)
- Fully qualified image names (`docker.io/...`) for CRI-O short-name mode
- **local-path-provisioner** RBAC + helper pod fix (see `local-path-provisioner` service)

## API key

Default ingest/UI key in `helm/values.yaml`: `hyperdx.apiKey`. Rotate and move to Vault → ESO when ready.

## GitOps

`okd-gitops/environments/prod/platform/hyperdx.yaml` (chart + `hyperdx-config` manifests).
