---
name: zedex-observability
description: Add logging, tracing, metrics, health endpoints, alerts, SLOs, and performance budgets to Zedex code without leaking content. Use for any new flow, failure mode, or service lifecycle work.
---

# Observability

Reference: `docs/architecture/09-infrastructure-operations.md` (observability, SLOs), `08-security-privacy.md`. Implemented in `packages/service-kit` (`telemetry`, `health`, `shutdown`) and `apps/desktop/src/main/telemetry.ts`.

## Content rule (P0)

Spans, logs, metrics, error reports, and analytics carry **identifiers, revisions, counts, and durations**. Never transcript text, note text, commitment text, prompt or model output, email bodies, or tokens. Use `segment_id`, `meeting_id`, `workspace_id`, `capture_id`. The OTel exporter scrubs known content fields as a backstop; do not rely on it. No session replay on transcripts. Add a test that a flow seeded with a sentinel string never emits it.

## Per new flow

- At least one trace span and one metric. Span names are `service.operation`; attributes are IDs and sizes. Context propagates through HTTP, Service Bus message properties, and the desktop sync client.
- Structured JSON logs. ERROR = actionable failure; INFO = lifecycle events; DEBUG = dev only. Include correlation ID; the same ID is returned in error responses.
- Metrics: request rate/errors/latency (RED), queue depth and age, outbox lag, dead-letter count, retry count, model latency/tokens/cost per deployment, cache hit rate, DB pool saturation. Avoid unbounded label cardinality (no user or meeting IDs as metric labels).
- Every new failure mode gets an alert with a runbook link, or an explicit note on why none is needed.

## Service lifecycle

- `/healthz` (liveness, no dependencies) and `/readyz` (dependencies: DB, bus). Graceful shutdown: stop accepting, drain in-flight, flush outbox relay and telemetry, then exit; honor termination grace.
- Timeouts on every remote call; circuit breakers on provider calls; bulkheads between services. Degradation order under load: live suggestions -> chat -> summaries -> sync (last). Capture is never degraded by cloud failure.

## SLOs and budgets (state the budget of the path you touch; measure it)

| SLO | Target |
|---|---|
| Sync ACK p95 | < 1 s |
| Final text after window closes | <= 15 s |
| Live suggestion p95 | <= 10 s |
| Summary ready p95 | < 2 min |
| Meeting card after finalize | < 60 s |
| Availability per cell | 99.9% (GA) |
| Deletion purge | <= 24 h |

Alerts page on error-budget burn, queue age, dead letters, uncertain external operations, certificate and token expiry. Dashboards cover capture gaps, sync backlog and ACK latency, queue depth per service, model quota and cost, calendar freshness, DB saturation, deletion SLA, cost per workspace.
