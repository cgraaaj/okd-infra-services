# OpenTelemetry Collector (Phase D1)

Prod app traces/logs/metrics export path toward HyperDX (D2).

## Architecture

```
App pods → OTel SDK (or agent sidecar)
         → otel-agent DaemonSet (workers, OTLP :4317/:4318)
         → otel-gateway Deployment
         → debug exporter (D1) → HyperDX OTLP HTTP (D2)
```

OKD cluster metrics stay on **openshift-monitoring** Prometheus — do not duplicate.

## Status

| Component | Status |
|-----------|--------|
| `otel-gateway` Deployment | ✅ Running (`observability` ns) |
| `otel-agent` DaemonSet | ✅ 1/agent per worker |
| HyperDX export | ⏳ D2 — gateway uses `debug` exporter until ingest endpoint exists |

## Endpoints (in-cluster)

| Service | OTLP gRPC | OTLP HTTP |
|---------|-----------|-----------|
| Agent (node-local) | `otel-agent-agent.observability.svc:4317` | `:4318` |
| Gateway | `otel-gateway.observability.svc:4317` | `:4318` |

Apps on workers can use the **agent** service (DaemonSet-backed ClusterIP) or talk directly to the **gateway**.

## Install

```bash
export KUBECONFIG=/path/to/okd/kubeconfig
./scripts/install.sh
```

## OpenShift notes

- DaemonSet **must not** use `hostPort` (restricted SCC blocks it). Values disable Jaeger/Zipkin ports and set `hostPort: 0`.
- Do not set a fixed `runAsUser` — let the namespace UID range assign it.

## GitOps

Registered in `okd-gitops/environments/prod/platform/otel-collector.yaml` (gateway wave 0, agent wave 1).

## Next (D2)

1. Deploy HyperDX + ClickHouse (see `docs/RESOURCE_PLAN.md` sizing)
2. Uncomment `otlphttp/hyperdx` exporter in `helm/values-gateway.yaml`
3. Store HyperDX API key in Vault → ESO → gateway env
