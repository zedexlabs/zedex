> **Plan document — do not modify.**
> This file is the agreed plan and architecture. Treat it as source of truth.
> Changes must go through a new ADR or an explicit plan revision — do not edit in place.

---
# 09 — Infrastructure and Operations

## Topology

**Global control plane** (per environment, DR in a paired region)
- Azure Front Door Premium + WAF: TLS, routing to cells, rate limits.
- `account` service on Container Apps with its own PostgreSQL.
- Key Vault, Application Insights, Log Analytics, Blob for app/model assets.
- Static hosting for the web app behind Front Door.

**Cell** (identical, one Bicep module, parameterized by name, region, and scale)

| Component | Azure service |
|---|---|
| Services (9) | Container Apps environment with workload profiles |
| Databases | PostgreSQL Flexible Server (one server, separate logical databases per service at first; `ingest` on an elastic cluster) |
| Messaging | Service Bus Premium |
| Realtime | Web PubSub |
| Cache and budgets | Azure Managed Redis |
| Retrieval | Azure AI Search |
| Models | Azure OpenAI deployments: summary, chat, live, embeddings |
| Authorization | OpenFGA on Container Apps with its own PostgreSQL database |
| Storage | Blob (private exports, 7-day expiry) |
| Secrets/identity | Key Vault, managed identities |
| Email | Azure Communication Services |
| Network | Private endpoints and VNet integration; no public database access |

First cell: `us-1` in East US 2, subject to capacity and model quota. Declare storage and model geography per workspace.

## Environments

`dev`, `staging`, `prod`, isolated by subscription or resource group with separate identities. Only synthetic or approved data outside production. Infrastructure is Bicep deployed by GitHub Actions with OIDC workload identity (no stored cloud credentials).

## CI/CD

| Pipeline | Purpose |
|---|---|
| `ci` | Install, lint, type-check, unit + contract + integration tests (Postgres and Service Bus emulator), Turborepo caching |
| `native` | Build and test the capture helper on four targets |
| `desktop-release` | Package, sign, notarize, staged update feed |
| `deploy-global` | Control plane rollout |
| `deploy-cell` | Rollout cell by cell: canary cell first, bake, then the rest; automatic rollback on SLO breach |
| `codeql` | Static analysis and dependency/secret scans |

Database migrations are forward-only (expand → migrate → contract) and run by a separate migration role before the new revision receives traffic.

## Scaling

| Concern | Mechanism |
|---|---|
| Stateless services | KEDA on HTTP concurrency, CPU, and Service Bus queue length; minimum replicas on latency-critical paths (`ingest`, `live`, `workspace`) |
| Bursts at :00/:30 | Queue levelling, per-workspace fair queuing, Redis token buckets |
| Model capacity | Provisioned throughput baseline + spillover; second deployment for failover; per-workspace budgets |
| Writes | `ingest` on a sharded elastic cluster by `workspace_id` |
| Search | AI Search partitions and replicas |
| Realtime | Web PubSub units |
| Tenancy | **Add cells**; size limits come from load tests (qualification target: 100 workspaces, 1,000 concurrent capturing clients, 1M segments per cell) |
| Connection budgets | Pools per service sized below server limits with headroom |

## Cell routing and placement

- The `account` service stores `workspace → cell`. Sign-in returns the cell base URL; Front Door routes by host.
- Placement policy: residency first, then least-loaded cell, with dedicated cells for contracted enterprise customers.
- Cell migration (Gate 6): freeze, copy, verify, switch directory, unfreeze.

## Observability

- OpenTelemetry traces, metrics, and logs to Application Insights; trace context flows through HTTP, Service Bus, and the desktop sync client.
- No content in telemetry.
- Dashboards: capture gaps and helper failures, sync backlog and ACK latency, queue age and depth per service, dead-letter counts, model latency/quota/cost per deployment, live-suggestion latency, calendar freshness, uncertain operations, database saturation, deletion SLA, cost per workspace and feature.

## SLOs and alerts

| SLO | Target |
|---|---|
| Sync ACK p95 | < 1 s |
| Final text after window closes | ≤ 15 s |
| Live suggestion p95 | ≤ 10 s |
| Summary ready p95 | < 2 min |
| Availability per cell | 99.9% (GA) |
| Deletion purge | ≤ 24 h |

Alerts page on error-budget burn, queue age, dead letters, uncertain operations, and certificate/token expiry.

## Reliability

- A cloud or model outage never stops local capture; the desktop queues and syncs later.
- Bulkheads between services and cells; circuit breakers on provider calls; graceful degradation order: live suggestions → chat → summaries → sync (last).
- Backups for 30 days with tested restore. RPO ≤ 15 min, RTO ≤ 4 h, proven by drills. Tombstones are replayed after restore.

## Cost

- Free local ASR removes ASR fees but not Azure, model, identity, distribution, and support costs.
- Price the baseline (Service Bus Premium, AI Search, Redis, databases, models) with the Azure Pricing Calculator in Gate 1–2 and track cost per workspace.
- Small SKUs outside production; start with one cell; scale-to-zero for non-critical workers where safe.
- Cache valid results, process incrementally, use smaller qualified models, and enforce allowances without silent overages.

## Incident response

Severity matrix, on-call rotation, runbooks per alert, status page, customer notification template, blameless postmortem within five working days.

## Disaster recovery

Paired-region replicas for the control plane, geo-redundant backups for cells, and infrastructure-as-code rebuild of a cell. Quarterly restore and failover drills with evidence recorded in the status document.
