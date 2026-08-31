# OBSERVABILITY

## Split responsibilities (avoid duplication)

| Signal | Dev (K3s) | Prod (OKD) |
|--------|-----------|------------|
| Cluster metrics | Prometheus (Istio stack) | **OKD built-in Prometheus** |
| Cluster alerts | Prometheus + Alertmanager | **OKD Alertmanager** |
| App logs/traces | Loki + Istio | **OTel Collector → HyperDX** |
| LLM telemetry | — | **Langfuse** (when apps need it) |
| Dashboards | Grafana (dev) | Grafana (prod instance, later) |

## OKD native (use, do not replace)

- `openshift-monitoring` Prometheus
- ServiceMonitor / PodMonitor CRDs
- ClusterOperator health alerts
- Console observability plugins

## To deploy on OKD (Phase D)

1. **OpenTelemetry Collector** — DaemonSet + gateway, export to HyperDX
2. **HyperDX + ClickHouse** — prod sizing on workers (memory-heavy; plan in RESOURCE_PLAN)
3. **Grafana** — optional; can query OKD Prometheus + ClickHouse

## Do not install initially

- **Second Prometheus stack** on OKD
- **Loki** — unless HyperDX gap analysis fails
- **Istio telemetry stack** on OKD

## Instrumentation standard

- Apps expose Prometheus metrics on `/metrics` where applicable
- Use OTel SDK for traces; collector handles export
- Langfuse SDK only for LLM-facing services

## Alerting path

```
OKD Prometheus → Alertmanager → (future) Telegram/Slack webhook
HyperDX → built-in alerts for APM
```
