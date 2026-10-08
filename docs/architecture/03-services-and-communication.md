> **Plan document — do not modify.**
> This file is the agreed plan and architecture. Treat it as source of truth.
> Changes must go through a new ADR or an explicit plan revision — do not edit in place.

---

> **Production target** — this is not a prototype or MVP. Every decision here targets a production product shipped in cycles.


# 03 — Services and Communication

## Service catalogue

| Service | Plane | Owns | Scales on | Gate |
|---|---|---|---|---|
| `account` | Global | Users, identities, sessions, workspaces, teams, memberships, roles, invitations, entitlements, feature flags, subscriptions, usage, cell directory | HTTP | 2 |
| `workspace` | Cell | Projects/folders, accounts, people/companies, series, meetings, associations, shares, notes, agendas, contributions, ticks, highlights, decisions, commitments, routing rules, tracking codes, saved views, coverage, consent notices, audit, deletion saga | HTTP | 2 |
| `ingest` | Cell | Captures, sources, transcript segments and revisions, sync batches, gaps, finalization; STT session tokens (`POST /speech-sessions` — checks policy, consent, budget, issues short-lived provider token) | HTTP, write volume | 2 |
| `integration` | Cell | Connections, encrypted tokens, calendar subscriptions/cursors/events, external refs, operation attempts, inbound webhooks, provider transcript imports | Queue depth | 2 |
| `authz` | Cell | OpenFGA store and model | Checks/s | 2 |
| `intelligence` | Cell | Chunk notes, meeting cards, agenda drafts, preference summaries, embeddings and retrieval index (Gate 2); proposals, briefs, catch-ups, alert rules/matches, chat threads (Gate 3); prompt-run metadata | Queue depth, model quota | 2 |
| `live` | Cell | Stateless suggestion API; Redis budgets and short-lived meeting context | HTTP | 3 |
| `notification` | Cell | Preferences, deliveries, digests, templates, brief scheduling | Queue depth | 3 |
| `reporting` | Cell | Report definitions/runs, exports, analytics read models | Queue depth | 3 (exports), 4 (analytics) |
| `workflow` | Cell | Workflow definitions/versions, triggers, runs, steps, approvals, operation ledger, schedules, templates | Queue depth | 4 |

## Internal structure of every service

```text
services/<name>/src/
  main.ts            process entry: config, telemetry, server/consumers, graceful shutdown
  app.ts             composition root; no listener (testable)
  config.ts          typed env (Zod), Key Vault references
  http/              Fastify routes: validate → call application → map errors
  application/       use cases; transactions; authorization calls; emits events via outbox
  domain/            pure rules and state machines (no I/O)
  infrastructure/
    db/              Drizzle schema, RLS session helpers
    repositories/    persistence per aggregate
    adapters/        external providers (models, connectors, email)
    messaging/       outbox relay, inbox, Service Bus publishers/consumers
  consumers/         event and command handlers → application layer
migrations/          reviewed SQL (forward-only, expand → migrate → contract)
test/                unit, integration, contract
```

**Dependency rules:**
- `domain` imports nothing from infrastructure.
- `http` and `consumers` call only `application`.
- Services never import each other's code; they share only `packages/*`.

## Communication rules

1. **Client → service.** HTTPS through Front Door to the cell host, path-routed (`/v1/workspace/*`, `/v1/ingest/*`, …). Each request carries a WorkOS access token. `service-kit` validates it and resolves the actor; permissions come from OpenFGA.
2. **Events (facts)** are published after commit through the transactional outbox, one topic per producer. Consumers subscribe with filters and dedupe through an inbox table keyed by message ID.
3. **Commands (requests for work)** go to queues owned by the receiving service. They carry the initiating actor; the receiver rechecks permission before acting.
4. **Ordering:** Service Bus sessions keyed by `meetingId` (ingest, intelligence) or `runId` (workflow).
5. **Synchronous service-to-service calls** are allowed only for reads that cannot be replicated by events. They use internal ingress, managed identity tokens, a 2 s timeout, jittered retries for idempotent reads, and circuit breakers.
6. **Realtime:** services publish to Web PubSub groups (`ws:{id}`, `meeting:{id}`, `agenda:{id}`) after commit.
7. **Versioning:**
   - Event types are `domain.entity.verb.v{n}`.
   - Changes are additive; a breaking change publishes a new version alongside the old one until all consumers migrate.
   - HTTP is `/v1`, with additive changes and deprecation headers.

## Event catalogue

Payloads carry identifiers, revision numbers, and workspace ID only — never content.

| Event | Producer | Main consumers |
|---|---|---|
| `workspace.meeting.registered.v1` | workspace | ingest, intelligence, notification |
| `workspace.meeting.associated.v1` | workspace | authz (tuples), intelligence (index), reporting |
| `workspace.agenda.accepted.v1` | workspace | notification, live |
| `workspace.agenda.item.covered.v1` | workspace | intelligence, reporting |
| `workspace.decision.confirmed.v1` | workspace | intelligence, reporting, workflow |
| `workspace.commitment.confirmed.v1` | workspace | workflow, reporting, notification |
| `workspace.commitment.closed.v1` | workspace | reporting, intelligence |
| `workspace.coverage.gap.v1` | workspace | notification |
| `workspace.share.changed.v1` | workspace | authz, intelligence (re-trim) |
| `workspace.content.deleted.v1` | workspace | all services (deletion saga) |
| `ingest.transcript.finalized.v1` | ingest | intelligence, workspace |
| `ingest.transcript.corrected.v1` | ingest | intelligence (invalidate), workspace |
| `intelligence.summary.ready.v1` | intelligence | workspace, notification |
| `intelligence.proposals.ready.v1` | intelligence | workspace, notification |
| `intelligence.agenda.drafted.v1` | intelligence | workspace, notification |
| `intelligence.alert.matched.v1` | intelligence | notification |
| `integration.calendar.event.changed.v1` | integration | workspace, notification |
| `integration.external.status.changed.v1` | integration | workspace, workflow, intelligence |
| `integration.operation.settled.v1` | integration | workflow |
| `workflow.approval.requested.v1` | workflow | notification |
| `workflow.run.completed.v1` | workflow | workspace, reporting |
| `account.membership.changed.v1` | account | authz, workspace, all services |
| `account.entitlement.changed.v1` | account | all services (cache) |

## Commands

| Command queue | Sent by | Purpose |
|---|---|---|
| `intelligence.generate-summary` | ingest/workspace | Summarize an authorized final transcript |
| `intelligence.draft-agenda` | workspace/scheduler | Draft agenda for next occurrence |
| `intelligence.build-meeting-card` | ingest | Build or rebuild the meeting card from chunk notes (ADR-027) |
| `intelligence.index` / `intelligence.deindex` | workspace | Maintain the PostgreSQL retrieval index |
| `integration.execute-operation` | workflow | Perform one approved external write |
| `integration.sync-calendar` | webhook/scheduler | Incremental calendar sync |
| `notification.send` | any | Deliver a notification |
| `reporting.generate-export` | workspace | Build a report or export |

## Sagas

| Saga | Coordinator | Steps | Compensation |
|---|---|---|---|
| Deletion | workspace | Block access → emit `content.deleted` → each service purges and acknowledges → tombstone recorded | Retry until all acknowledge; tombstones replayed after restore |
| External write | workflow | Approve exact payload → recheck permission → `execute-operation` → settle or reconcile | Ambiguous outcome becomes `uncertain`; reconcile by lookup, never blind retry |
| Workspace cell move (Gate 6) | account | Freeze → copy → verify → switch directory → unfreeze | Roll back directory pointer |

## Reliability patterns (all services via `service-kit`)

- **Outbox:** the domain change and the outbox row commit in one transaction; a relay publishes with at-least-once delivery.
- **Inbox:** the handler inserts the message ID first. A duplicate is skipped.
- **Idempotency:** `Idempotency-Key` header on every mutating call, stored with a request hash. The same key with a different body returns a conflict.
- **Retries:** exponential backoff with jitter, bounded attempts, then dead-letter with an alert.
- **Backpressure:** per-workspace fair queuing and rate limits. Until Redis arrives with `live` (Gate 3), rate limits run at Front Door and per-workspace budgets are PostgreSQL counters checked off the hot path; then Redis token buckets. Overload degrades suggestions before capture or sync.
- **Timers:** Service Bus scheduled messages for per-entity timers (agenda draft at T-24 h); Container Apps Jobs (cron) for fleet tasks such as calendar watch renewal, nightly reconcile, budget resets, and retention purges.
- **Never hold a database transaction across a network or model call.**

## API conventions

- OpenAPI generated from Zod. Cursor pagination, optimistic versions (`If-Match`), structured non-sensitive errors with correlation IDs.
- The actor comes from the verified token; a workspace ID in the URL is a scope, not authority.
- Additive older-client compatibility; deprecation windows are announced in headers and docs.

## Authorization model sketch (OpenFGA)

```text
type user
type workspace    relations: owner, admin, member, viewer
type team         relations: workspace, manager, member
type project      relations: team, owner, editor, viewer
type meeting      relations: project, organizer, capturer, attendee_with_access, shared_with
type agenda       relations: meeting, editor, viewer
type report       relations: audience
```

Owning services write tuples through their outbox. `ListObjects` powers library views; `BatchCheck` guards search results, citations, chat sources, reports, and exports. Admins hold no implicit access to private notes.
