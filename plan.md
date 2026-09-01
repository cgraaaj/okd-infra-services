You are a senior Kubernetes / OpenShift platform architect.

I am building an OKD-based homelab platform and want to turn it into a properly structured development and production platform.

IMPORTANT:

Do NOT blindly install everything I mention.

Do NOT make changes to the cluster yet.

Do NOT delete or migrate anything yet.

First inspect the existing environment, understand what is already available, identify duplication, and produce an architecture and migration plan.

The goal is to build a maintainable platform rather than simply installing a large collection of operators.

============================================================
HIGH-LEVEL PLATFORM GOAL
============================================================

I want the platform to provide:

- GitHub for source control
- GitHub Actions for CI
- Harbor for container/artifact registry
- Argo CD for GitOps
- OKD native ingress/router
- Authentik with Duo MFA for authentication
- Prometheus
- Grafana
- OpenTelemetry Collector
- HyperDX
- ClickHouse
- Langfuse
- Proper secrets management
- Backup and disaster recovery
- Security policies
- Application lifecycle management
- Development and production environments

I also have applications and infrastructure currently running in a K3s environment.

K3s should initially remain my development/experimental environment.

OKD should gradually become the production platform.

============================================================
IMPORTANT ARCHITECTURAL PRINCIPLE
============================================================

Do not assume every component listed above is required.

For every proposed component determine:

1. Does OKD already provide this functionality?
2. Is another component already providing it?
3. Does this component solve a real requirement?
4. What operational overhead does it introduce?
5. Is there a simpler alternative?
6. Is it appropriate for a homelab?
7. Is it mature and compatible with the current OKD version?

Avoid duplicate functionality.

Prefer native OKD functionality when it is sufficient.

============================================================
SOURCE CONTROL
============================================================

Use GitHub as the primary source-control platform.

Do NOT introduce:

- Gitea
- self-hosted Git servers
- another SCM platform

Evaluate:

- GitHub repositories
- GitHub Actions
- self-hosted GitHub Actions runners
- repository organization
- branch strategy
- release/version strategy
- environment promotion

============================================================
ARTIFACT MANAGEMENT
============================================================

Harbor already exists.

Harbor should be evaluated as the primary private artifact/container registry.

Do NOT deploy another registry unless there is a strong architectural reason.

Evaluate:

- container images
- OCI artifacts
- Helm charts
- robot accounts
- CI authentication
- Kubernetes image pull authentication
- vulnerability scanning
- SBOMs
- image signing
- immutable tags/digests
- retention policies
- replication
- backup and restore

Design:

GitHub
    |
    v
GitHub Actions
    |
    v
Build / Test
    |
    v
Harbor
    |
    +--> Scan
    +--> SBOM
    +--> Sign
    |
    v
Argo CD
    |
    v
OKD

============================================================
GITOPS
============================================================

Argo CD is already installed.

Argo CD should be the GitOps control plane.

GitHub should be the source of truth.

Evaluate:

- App of Apps
- ApplicationSet
- Kustomize
- Helm
- Helm OCI
- environment overlays
- dev/staging/prod separation
- application projects
- RBAC
- sync policies
- automated synchronization
- rollback
- drift detection

Propose a clean GitOps repository structure.

For example:

platform-gitops/
    clusters/
    platform/
    infrastructure/
    applications/
    policies/
    environments/

Do not assume this exact structure is correct.

Recommend the simplest structure that remains scalable.

============================================================
OKD NATIVE SERVICES
============================================================

Before deploying anything, inventory what OKD already provides.

Evaluate:

- ingress/router
- Routes
- OAuth
- RBAC
- ServiceAccounts
- Secrets
- ConfigMaps
- monitoring
- Prometheus
- Alertmanager
- ServiceMonitor
- PodMonitor
- Operators
- OLM
- NetworkPolicy
- SCC
- Pod security
- CSI
- storage
- snapshots
- cluster autoscaling
- machine management
- DNS
- cluster logging capabilities
- internal registry
- certificate capabilities

Clearly identify:

OKD provides this
vs
we need an external component

============================================================
INGRESS
============================================================

Use the native OKD ingress/router by default.

Do NOT deploy:

- Traefik
- NGINX Ingress
- another ingress controller

unless a specific application requirement demonstrates that the native OKD ingress is insufficient.

Evaluate how existing K3s applications using Traefik should be migrated.

Convert them to appropriate OKD Routes or supported ingress mechanisms.

============================================================
AUTHENTICATION
============================================================

Authentik with Duo MFA already exists.

Use Authentik as the central identity provider where practical.

Evaluate OIDC integration for:

- OKD
- Argo CD
- Grafana
- Harbor
- HyperDX
- Langfuse
- other user-facing platform services

Do not create multiple independent authentication systems.

Use separate OIDC clients/applications where appropriate.

============================================================
SECRETS
============================================================

Evaluate the existing secret-management approach.

I have previously used Vault.

Compare:

- Vault
- External Secrets Operator
- Kubernetes Secrets
- SOPS
- Sealed Secrets

Do NOT deploy all of them.

Recommend one primary architecture.

The desired principle is:

Git
  |
  | no plaintext secrets
  v
Secret management
  |
  v
Kubernetes Secrets

Clearly distinguish:

- configuration
- secrets
- credentials
- certificates
- encryption keys

============================================================
OBSERVABILITY
============================================================

I want to evaluate:

- Prometheus
- Grafana
- Alertmanager
- OpenTelemetry Collector
- HyperDX
- ClickHouse
- Langfuse

Do not assume these should all coexist without overlap.

Clearly define the role of each.

Separate:

1. Cluster metrics
2. Kubernetes metrics
3. Application metrics
4. Application logs
5. Distributed traces
6. Infrastructure logs
7. AI/LLM telemetry
8. Token usage
9. LLM traces
10. LLM evaluation
11. Cost/usage tracking

First determine whether OKD's existing monitoring stack is sufficient for cluster monitoring.

Do not deploy another Prometheus stack unnecessarily.

Evaluate whether HyperDX + ClickHouse can provide the required logs/traces.

Evaluate whether Loki would be redundant.

Treat Langfuse specifically as the LLM/AI observability platform.

Propose an architecture similar to:

Applications
    |
    v
OpenTelemetry Collector
    |
    +--> metrics
    +--> logs
    +--> traces
    |
    v
Observability backend

Cluster monitoring
    |
    v
OKD Prometheus
    |
    +--> Grafana
    +--> Alertmanager

AI/LLM applications
    |
    v
Langfuse

Avoid duplicate telemetry pipelines.

============================================================
AI / LLM PLATFORM
============================================================

I plan to run local AI/LLM workloads.

Evaluate future requirements for:

- model serving
- GPU scheduling
- GPU nodes
- OpenAI-compatible APIs
- embedding services
- vector databases
- LLM gateways
- Langfuse
- OpenTelemetry
- evaluation
- token tracking
- model metrics

Do not install an LLM platform until the actual workloads are identified.

Separate:

platform infrastructure

from:

application-specific AI infrastructure.

============================================================
STORAGE
============================================================

Evaluate the storage architecture before deploying storage operators.

Consider:

- existing storage infrastructure
- NAS
- NFS
- S3-compatible storage
- local storage
- CSI
- snapshots
- backup storage
- replicated storage
- databases

I have storage infrastructure outside OKD.

Do not automatically introduce Longhorn, Ceph, or another distributed storage platform.

Determine whether the existing infrastructure is sufficient.

Pay special attention to workloads running across remote/WireGuard-connected nodes.

Do not place latency-sensitive or critically replicated storage across a WAN without a strong reason.

============================================================
BACKUP / DISASTER RECOVERY
============================================================

Design a real backup strategy.

Evaluate:

- OADP / Velero
- S3-compatible object storage
- NAS
- volume snapshots
- database-native backups

Determine what must be backed up.

Examples:

- Kubernetes resources
- persistent volumes
- databases
- Harbor
- Argo CD configuration
- secrets
- Grafana configuration
- observability data
- Langfuse data

Git should be the source of truth for declarative configuration.

Backups should protect state that cannot simply be recreated from Git.

Define:

- RPO
- RTO
- retention
- restore testing

A backup system is not considered complete until a restore procedure exists.

============================================================
SECURITY
============================================================

Evaluate:

- RBAC
- least privilege
- ServiceAccounts
- NetworkPolicies
- SCC
- Pod Security
- non-root containers
- resource quotas
- LimitRanges
- PodDisruptionBudgets
- image scanning
- image signing
- SBOMs
- secret management
- admission policies

Consider Kyverno or another policy engine only if there is a concrete requirement.

Do not install a policy engine just because it is popular.

============================================================
SERVICE MESH
============================================================

I am considering:

- Istio
- Gloo Mesh
- OpenShift Service Mesh

Do NOT install a service mesh initially.

First determine whether workloads actually require:

- mTLS
- service-to-service authorization
- traffic splitting
- advanced routing
- retries
- fault injection
- east-west traffic
- multi-cluster networking
- service-level telemetry

If these requirements do not exist, explicitly recommend NOT deploying a service mesh.

============================================================
REMOTE WORKER
============================================================

The cluster contains a remote worker connected through WireGuard.

Evaluate how this node should be used.

Consider:

- scheduling
- labels
- taints
- topology spread
- anti-affinity
- ingress placement
- storage placement
- latency
- network failures
- workload resilience

Do not automatically schedule critical infrastructure on the remote node.

Do not place ingress there unless there is a reason.

Prefer workloads that tolerate temporary connectivity loss.

============================================================
K3S DEVELOPMENT ENVIRONMENT
============================================================

K3s currently hosts several services.

Treat K3s as the development/experimental environment.

Before migrating anything:

INVENTORY EVERYTHING.

For each K3s workload collect:

- service name
- namespace
- purpose
- image
- version
- Helm chart
- manifest source
- CPU requests
- CPU limits
- memory requests
- memory limits
- persistent storage
- storage class
- ingress
- DNS
- secrets
- ConfigMaps
- dependencies
- databases
- external services
- authentication
- monitoring
- logging
- backup requirements
- network requirements

Then classify every workload:

KEEP IN K3S
MIGRATE TO OKD
REPLACE WITH OKD NATIVE
REBUILD
RETIRE
EXTERNALIZE

Create:

K3S -> OKD migration matrix.

============================================================
K3S TO OKD COMPATIBILITY
============================================================

For every application currently using K3s, check:

- Traefik dependencies
- Ingress resources
- NodePort
- LoadBalancer
- hostNetwork
- hostPath
- privileged containers
- root containers
- filesystem assumptions
- storage class assumptions
- Docker-specific behavior
- kernel dependencies
- node selectors
- tolerations
- security context
- persistent volumes
- secrets
- external dependencies

Do not assume that a Helm chart working on K3s will automatically work on OKD.

Identify changes required for OKD security and networking.

============================================================
DEV -> PROD PROMOTION
============================================================

Design a controlled promotion workflow.

Preferred conceptual flow:

Developer
    |
    v
GitHub
    |
    v
CI
    |
    v
K3s DEV
    |
    v
Testing
    |
    v
Release
    |
    v
Harbor
    |
    v
Argo CD
    |
    v
OKD PROD

Use immutable versions or image digests for production.

Do not use mutable "latest" tags for production deployments.

Explain how application promotion should work.

============================================================
RESOURCE PLANNING
============================================================

This is a homelab.

Resource efficiency matters.

For every proposed platform service estimate:

- CPU request
- CPU limit
- memory request
- memory limit
- storage
- replicas

Identify memory-heavy services.

Identify services that can be consolidated.

Identify services that should run on dedicated nodes only if justified.

Create a resource budget before deployment.

============================================================
OPERATOR STRATEGY
============================================================

Do not install operators blindly.

For every operator evaluate:

- maturity
- compatibility
- maintenance
- resource usage
- CRD complexity
- upgrade path
- backup requirements
- community/support
- whether native OKD functionality is sufficient

Prefer stable, mature operators for critical infrastructure.

Avoid alpha/experimental components for critical services unless there is a specific reason.

============================================================
TARGET PLATFORM
============================================================

The target platform should conceptually look like:

                    GitHub
                       |
                       v
                GitHub Actions
                       |
                       v
                    Harbor
                 /          \
              Scan          Sign
                \            /
                       |
                       v
                    Argo CD
                       |
                       v
                      OKD
                       |
        +--------------+--------------+
        |              |              |
      Apps          Platform      Observability
        |              |              |
        |              |              |
      Routes        Authentik       OTel
        |           + Duo             |
        |                              |
        |                    +---------+---------+
        |                    |                   |
        |                 HyperDX           ClickHouse
        |
        +------------------> Langfuse for AI

OKD native capabilities should be used wherever they are sufficient.

============================================================
DOCUMENTS TO PRODUCE
============================================================

Do not modify the cluster.

Produce these planning documents:

1. CURRENT_STATE.md

Current cluster architecture.

2. K3S_INVENTORY.md

Complete K3s workload inventory.

3. TARGET_ARCHITECTURE.md

Target architecture with Mermaid diagrams.

4. SERVICE_MATRIX.md

Include:

Service
Purpose
Existing?
OKD native alternative
Required?
Recommended?
Namespace
Dependencies
Storage
CPU
Memory
Priority
Phase

5. GITOPS_STRUCTURE.md

Recommended GitHub repository structure.

6. CI_CD.md

GitHub Actions -> Harbor -> Argo CD workflow.

7. SECURITY.md

Authentication, RBAC, secrets, policies, image security.

8. OBSERVABILITY.md

Prometheus, Grafana, Alertmanager, OTel, HyperDX, ClickHouse and Langfuse architecture.

9. STORAGE.md

Storage strategy.

10. BACKUP.md

Backup and restore strategy.

11. MIGRATION_PLAN.md

K3s -> OKD migration plan.

12. RESOURCE_PLAN.md

Resource requirements.

13. PHASED_ROLLOUT.md

Implementation phases.

14. RISKS.md

Architectural and operational risks.

============================================================
FINAL CLASSIFICATION
============================================================

At the end provide these exact sections:

DO NOW

DO LATER

DO NOT INSTALL

OKD NATIVE — NO EXTRA COMPONENT

MIGRATE FROM K3S

KEEP IN K3S

OPTIONAL / ONLY IF NEEDED

RECOMMENDED IMPLEMENTATION ORDER

============================================================
MOST IMPORTANT RULE
============================================================

The goal is NOT to install as many services as possible.

The goal is to build a clean, reliable, observable, secure and maintainable OKD platform.

Every component must justify its existence.

Avoid duplicate functionality.

Prefer native OKD functionality.

Use GitHub + GitHub Actions + Harbor + Argo CD as the core software delivery chain.

Use OKD's native ingress instead of Traefik.

Use Authentik + Duo as the identity layer.

Use OKD's native monitoring capabilities where sufficient.

Use OpenTelemetry as the telemetry standard.

Use HyperDX/ClickHouse where they provide capabilities beyond native monitoring.

Use Langfuse specifically for LLM observability.

Treat K3s as DEV and OKD as PROD.

Do not change anything until the architecture review is complete and approved.

============================================================
REPOSITORY ARCHITECTURE
============================================================

Design the repository as an enterprise-style platform repository.

I want a clean parent repository called:

okd-services

Each service should have its own directory.

For example:

okd-services/
    services/
        argocd/
        harbor/
        hyperdx/
        clickhouse/
        grafana/
        opentelemetry/
        langfuse/

Each service directory should contain:

- README.md
- Helm configuration
- values files where appropriate
- manifests where necessary
- configuration files
- dashboards where applicable
- scripts only for development/debugging
- documentation
- backup/restore information

Every service must document:

- purpose
- version
- Helm chart
- Helm repository
- namespace
- dependencies
- resource requirements
- storage
- networking
- authentication
- secrets
- monitoring
- backup
- installation
- upgrade
- rollback
- troubleshooting

The README must document the Helm deployment command that reproduces the deployment.

However:

DO NOT use manual Helm commands as the production deployment mechanism.

Argo CD should perform the actual deployment.

The Helm command should exist for:
- local testing
- debugging
- disaster recovery
- validating chart configuration

============================================================
SEPARATION OF CONCERNS
============================================================

Design the repository architecture around:

SERVICE DEFINITION
    =
How a service is deployed

GITOPS CONFIGURATION
    =
Where a service is deployed

APPLICATION REPOSITORY
    =
What the application is

POLICY REPOSITORY
    =
What rules must be enforced

Evaluate whether these should eventually be separated into:

okd-services
okd-gitops
okd-policies
application repositories

Do not force everything into one repository if that creates poor separation of concerns.

============================================================
ENTERPRISE PLATFORM MODEL
============================================================

Design an enterprise-style platform hierarchy:

Layer 0:
OKD native platform

Layer 1:
Platform foundation

Layer 2:
Artifact and GitOps

Layer 3:
Data/platform dependencies

Layer 4:
Observability

Layer 5:
AI platform

Layer 6:
Applications

Clearly define dependencies between layers.

============================================================
PROMOTION MODEL
============================================================

Design:

GitHub
  ->
CI
  ->
Harbor
  ->
K3s DEV
  ->
validation
  ->
promotion
  ->
Argo CD
  ->
OKD PROD

Use immutable image versions/digests.

Do not rebuild artifacts between DEV and PROD.

============================================================
ARgo CD ORCHESTRATION
============================================================

Design Argo CD as the deployment orchestrator.

Use:

- AppProjects
- Applications
- ApplicationSets
- sync waves or dependency mechanisms where appropriate

Define deployment ordering.

Do not rely on alphabetical application deployment order.

For example:

foundation
    ->
storage/secrets
    ->
databases
    ->
observability
    ->
applications

Only use dependencies where they are genuinely required.

============================================================
SERVICE TEMPLATE
============================================================

Create a standard service template.

Every service should follow:

services/<service>/

    README.md

    helm/
        values.yaml

    manifests/

    config/

    dashboards/

    docs/

    scripts/

Do not create empty directories unless required.

============================================================
DOCUMENTATION
============================================================

Generate a standard README template for every platform service.

Include:

Purpose
Architecture
Dependencies
Prerequisites
Version
Helm chart
Configuration
Resources
Storage
Networking
Authentication
Secrets
Monitoring
Backup
Installation
Argo CD deployment
Upgrade
Rollback
Troubleshooting
Disaster recovery

============================================================
ENVIRONMENT CONFIGURATION
============================================================

Avoid duplicating complete values files for every environment.

Prefer:

services/<service>/
    common configuration

and:

environments/
    dev/
    prod/

for environment-specific configuration.

Evaluate Helm values layering, Kustomize overlays, or another appropriate mechanism.

Avoid configuration duplication.

============================================================
PLATFORM GOVERNANCE
============================================================

Define ownership boundaries:

OKD:
cluster-native infrastructure

Platform team:
shared platform services

Application teams:
application workloads

GitOps:
desired state

CI:
build/test/security validation

Harbor:
artifact lifecycle

Observability:
metrics/logs/traces

Security:
identity/RBAC/policies/secrets

============================================================
ENTERPRISE OPERATING MODEL
============================================================

Design:

- development
- staging
- production
- promotion
- approvals
- rollback
- change management
- incident response
- backup
- disaster recovery
- monitoring
- alerting
- ownership
- service lifecycle
- upgrade lifecycle

Keep the design appropriate for a homelab but use enterprise-grade architectural principles.

Do not introduce bureaucracy that provides no value.

The objective is:

Enterprise architecture
without
enterprise-sized operational overhead.