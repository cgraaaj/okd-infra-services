# Langfuse (prod)

LLM observability platform on OKD: traces, generations, token/cost tracking,
prompt management for everything served through the LiteLLM gateway.

UI: `https://langfuse.cgraaaj.in` (OKD Route + cert-manager edge TLS)

## Stack (chart langfuse/langfuse 1.5.41, release name `langfuse`)

| Component | What | Storage |
|---|---|---|
| `langfuse-web` | UI + API | — |
| `langfuse-worker` | async trace ingestion | — |
| PostgreSQL | transactional data (bitnami, PG 17) | 5 Gi `local-path-retain` |
| ClickHouse | OLAP traces/observations/scores — **dedicated**, not shared with HyperDX | 20 Gi `local-path-retain` |
| Valkey | queue + cache | 2 Gi |
| MinIO | raw events, batch export, media | 10 Gi `local-path-retain` |

Single-node ClickHouse (`replicaCount: 1`, `clusterEnabled: false`, ZooKeeper
off). Chart v1.x is pinned deliberately: v2 requires the ClickHouse operator +
Keeper CRDs, which we do not run yet.

## Auth

Email/password only (SSO deferred). Public sign-up is disabled; the admin
user, org (`okd`), project (`default`) and project API keys are created by
headless init (`LANGFUSE_INIT_*` env from the `langfuse-core` secret).

Login: see `init_user_email` / `init_user_password` in Vault
`okd/platform/langfuse/core`.

## Secrets (Vault → ESO)

One Vault path `okd/platform/langfuse/core` → one secret `langfuse-core`
(ns langfuse) referenced by every component (`existingSecret` / `secretKeyRef`
/ `additionalEnv`). The project API keys are shared with
`okd/platform/litellm/core` so LiteLLM's callback and the headless-init
project use the same pair.

Rotate: edit `.secrets/langfuse.env` (gitignored), re-run
`okd-services/services/hashicorp-vault/scripts/seed-okd-secrets.sh`, then
restart affected workloads (ESO refreshes the secret; pods need a rollout to
pick up new env values).

## GitOps

`okd-gitops/environments/prod/platform/langfuse.yaml`:

- `langfuse-config` (wave 0) — `manifests/`: ExternalSecret, Certificate,
  Route, router TLS RoleBinding.
- `langfuse` (wave 1) — chart 1.5.41 + `helm/values.yaml`.

## OKD notes

- All bitnami subcharts run under restricted SCC (securityContext helpers
  disabled; OKD assigns UID/fsGroup; `volumePermissions` off).
- The chart renders port-only NetworkPolicies (no source restrictions), so
  router and in-namespace traffic work unchanged.
- Postgres and ClickHouse run with container-default UTC — required by
  Langfuse (non-UTC breaks time-filtered queries).

## Resource budget

~4.5 Gi requests total (web 512Mi + worker 512Mi + CH 1Gi + PG 256Mi +
valkey 128Mi + minio 256Mi + overheads). Watch worker memory per
`docs/RESOURCE_PLAN.md` (>80% → offload CH or add RAM).
