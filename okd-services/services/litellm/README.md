# LiteLLM (prod)

OpenAI-compatible LLM gateway on OKD. Fronts the llama.cpp backend on the
Proxmox AI VM (`ai-server`, AMD Radeon AI PRO R9700) and records every call
(tokens, latency, cost) to Langfuse.

## Architecture

```
VPN/LAN clients ──► https://litellm.apps.okd.cgraaaj.in (native OKD Route)
              │  Authorization: Bearer <MASTER_KEY>
              ▼
            litellm proxy (ns llm, ClusterIP :4000)
              ├──► llama-server http://10.19.94.73:8080/v1  (Qwen3.8-27B Q4_K_M)
              ├──► Langfuse  (success_callback/failure_callback, LANGFUSE_* env)
              └──► PostgreSQL litellm-postgresql (virtual keys, budgets, spend)
```

## Model backend (ai-server)

`llama-server` runs as systemd unit `llama-server.service` on `10.19.94.73`,
bound to `0.0.0.0:8080` (rebound from 127.0.0.1 so OKD pods can reach it;
verified from cluster pods). The backend has **no auth** — LiteLLM is the only
authenticated entry point. Keep port 8080 off any untrusted network.

Model alias exposed by the proxy: `qwen3.8-27b`
(upstream `openai/Qwen3.8-27B-Q4_K_M` with explicit zero-cost `model_info`).

## Secrets (Vault → ESO)

| Vault path | Secret (ns llm) | Keys |
|---|---|---|
| `okd/platform/litellm/core` | `litellm-core` | `MASTER_KEY`, `LANGFUSE_HOST`, `LANGFUSE_PUBLIC_KEY`, `LANGFUSE_SECRET_KEY` |
| `okd/platform/litellm/db` | `litellm-db` | `username`, `password`, `postgres-password` |

Seed/rotate: edit `.secrets/litellm.env` (gitignored), then
`okd-services/services/hashicorp-vault/scripts/seed-okd-secrets.sh`.

## GitOps

`okd-gitops/environments/prod/platform/litellm.yaml`:

- `litellm-config` (wave 0) — `manifests/`: ExternalSecrets and native OKD
  Route `litellm.apps.okd.cgraaaj.in`. The router's `*.apps.okd.cgraaaj.in`
  certificate is used; no Traefik or external certificate is involved.
- `litellm` (wave 1) — multi-source: bitnami `postgresql` (OCI 14.3.1,
  `helm/values-postgres.yaml`) + `litellm-helm` (OCI ghcr.io/berriai, 1.99.0,
  `helm/values.yaml`). PostgreSQL is a separate chart source so its password
  comes from ESO, not from helm values (the chart's standalone mode would
  render the password into a helm-managed secret from plaintext values).

## OKD notes

- Everything runs under the **restricted** SCC: bitnami `podSecurityContext` /
  `containerSecurityContext` / `volumePermissions` are disabled so OKD assigns
  UID/fsGroup (fsGroup handles PVC permissions).
- PostgreSQL image pinned to `bitnamilegacy/postgresql:16.2.0-debian-12-r6`
  (docker.io/bitnami versioned tags are retired; never float the tag across a
  PG major version).
- No `otel` callback is configured on purpose: LLM spans go to Langfuse only
  (no duplicate telemetry pipelines). Infra/log telemetry for the cluster
  already flows via otel-agent → otel-gateway → HyperDX.

## Smoke test

```bash
source .secrets/litellm.env   # or pull MASTER_KEY from Vault
curl -s https://litellm.apps.okd.cgraaaj.in/v1/chat/completions \
  -H "Authorization: Bearer ${LITELLM_MASTER_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen3.8-27b","messages":[{"role":"user","content":"Say OK"}],"max_tokens":10}'
# then confirm the trace appears in https://langfuse.apps.okd.cgraaaj.in (project: default)
```
