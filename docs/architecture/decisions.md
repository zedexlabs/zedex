> **Plan document — do not modify.**
> This file is the agreed plan and architecture. Treat it as source of truth.
> Changes must go through a new ADR or an explicit plan revision — do not edit in place.

---

> **Production target** — this is not a prototype or MVP. Every decision here targets a production product shipped in cycles.


# Architecture Decision Records

Format: context → decision → consequences → revisit trigger. Status of all records: **Accepted (4 Oct 2026)** unless noted. A new service, datastore, or vendor requires a new ADR.

## ADR-001 Architecture style

**Context.** The founders require an architecture that scales. For Zedex, "scales" means:

1. Throughput: many capturing desktops, transcript ingest, end-of-hour summary bursts, live suggestions every 20–30 s per meeting.
2. Data growth: transcripts, revisions, embeddings.
3. Tenant isolation and noisy-neighbour control.
4. Failure isolation: model, connector, or calendar outages must not stop capture, sync, or the app.
5. Team scaling: several squads shipping every cycle.
6. Data residency and dedicated enterprise tenancy.
7. Cost proportional to usage.

| Option | Throughput & data | Failure isolation | Team scaling | Residency / dedicated | Cost & complexity |
|---|---|---|---|---|---|
| Modular monolith | Good | Weak (shared process and DB) | Weak beyond ~10 engineers | Weak | Lowest |
| Fine-grained microservices (20+, DB each) | Good | Good | Good | Medium | Very high; distributed transactions; slow cycles |
| Serverless-first | Medium | Medium | Medium | Medium | Cold starts on the live path; execution limits |
| **Right-sized services + event backbone + cells** | **Excellent** | **Excellent** | **Excellent** | **Excellent** | Higher baseline, phased in |

**Decision.** Use nine cell services plus one global account service, each owning its data. They communicate asynchronously through Azure Service Bus and are deployed as identical cells (Azure deployment stamps) behind a global control plane.

**Consequences.**
- Eventual consistency between services; UIs show sync state.
- More pipelines and dashboards, reduced by a shared `service-kit`, a monorepo, and shared contracts.
- Higher baseline cost, controlled by:
  - Starting with one cell and one PostgreSQL server holding separate logical databases.
  - Small SKUs outside production.
  - Introducing services only at the gate that needs them.

**Revisit trigger.** Split a service when one module's load or ownership demands it. Merge two services if they always change together for three or more cycles.

## ADR-002 Cell-based deployment

**Decision.**
- Each cell is a complete stack: Container Apps environment, per-service databases, Service Bus namespace, AI Search, Redis, Web PubSub, OpenFGA, and model deployments.
- The global account service maps each workspace to a cell. Clients receive the cell base URL at sign-in.
- Start with `us-1` in East US 2. Add `eu-1` for residency, dedicated cells for enterprise, and new cells when load tests show a cell is at capacity.

**Consequences.** A failure, bad deploy, or noisy tenant affects one cell. Deploys roll out cell by cell. Tooling to move workspaces between cells is built in Gate 6.

## ADR-003 Event backbone

**Decision.**
- Azure Service Bus Premium:
  - One topic per producing service, with filtered subscriptions per consumer.
  - Command queues.
  - Sessions keyed by meeting or run for ordering.
  - Duplicate detection, dead-lettering, and scheduled messages for durable timers.
- Every service writes events through a transactional outbox and dedupes consumption through an inbox table.
- Event schemas are Zod in `packages/contracts`, published as AsyncAPI.

**Revisit.** Use Event Hubs for analytics-scale streams if they appear.

## ADR-004 Data ownership and sharding

**Decision.**
- Database per service on Azure Database for PostgreSQL Flexible Server, with no cross-service queries.
- `ingest` uses an elastic cluster (managed Citus) distributed by `workspace_id`.
- Workspace RLS stays as defense in depth.
- Drizzle schemas with generated, reviewed SQL migrations.

**Revisit.** Move a logical database to its own server when its CPU or IO budget is exceeded.

## ADR-005 Authorization

**Decision.** OpenFGA (relationship-based, Zanzibar-style) per cell, backed by PostgreSQL.
- Owning services write relationship tuples through their outbox.
- Calls use Check, BatchCheck, and ListObjects.
- Search pre-filters by principal set, then batch-checks results before showing or citing them.

**Why.** Permissions span services (membership, team, project share, audience). Centralizing the relationship graph avoids duplicating permission logic in every service.

## ADR-006 Search and retrieval

**Decision.** Azure AI Search (hybrid keyword + vector) is the retrieval index. It is derived, rebuildable, and security-trimmed. PostgreSQL stays the source of truth.

**Revisit.** Reconsider if cost per workspace exceeds budget at pilot scale.

## ADR-007 Workflow engine

**Decision.** An in-house typed DAG interpreter in the `workflow` service:
- Versioned definitions.
- Runs, steps, approvals, and an operation ledger in PostgreSQL.
- Execution via Service Bus sessions; timers via scheduled messages.

**Why.** Exact-payload approval and uncertain-write reconciliation must be first-class domain data. Temporal Cloud is not offered in Azure regions.

**Revisit.** Use self-hosted Temporal if workflows need nested orchestration or very large timer volumes.

## ADR-008 Realtime

**Decision.** Azure Web PubSub for server-to-client updates (agenda collaboration, job status, notifications), grouped per workspace and meeting. Services publish after commit.

## ADR-009 Compute

**Decision.** Azure Container Apps with workload profiles and KEDA scaling on HTTP concurrency, Service Bus queue length, and CPU. Managed identities and revision-based rollouts.

**Revisit.** Move to AKS if operators, a service mesh, or self-hosted Temporal become necessary.

## ADR-010 Desktop shell

**Decision.** Electron (electron-vite, electron-builder, electron-updater) with sandboxed renderers, context isolation, a narrow preload bridge, and validated IPC.

**Why.** Consistent rendering on macOS and Windows, a mature updater, and proven use in this product category.

**Revisit.** Reconsider if the memory budget fails qualification.

## ADR-011 Native capture helper

**Decision.** A separate C++20 process:
- Objective-C++ with Core Audio taps on macOS; WASAPI loopback on Windows.
- CMake presets.
- Versioned newline-delimited JSON over stdio carrying text, levels, and health only.

**Why.** Crash isolation, real-time audio handling, and no FFI into the ASR engines.

## ADR-012 Local ASR

**Decision.**
- whisper.cpp (Metal on Apple Silicon) with built-in Silero VAD and quantized `small.en`/`base.en`.
- Parakeet-TDT 0.6B via sherpa-onnx is benchmarked behind the same `transcriber.h` interface.
- The choice per target is made from Gate 1 measurements.
- Models are verified by checksum before load.

## ADR-013 Local store

**Decision.**
- SQLite with whole-database encryption (SQLite3MultipleCiphers via better-sqlite3-multiple-ciphers).
- The key is protected by Electron safeStorage.
- FTS5 provides offline search.
- Data is partitioned per identity and workspace.

## ADR-014 Desktop sync

**Decision.**
- Client-generated UUIDv7 IDs and append-only segment revisions.
- Idempotent batches; ACK only after commit.
- A local outbox, flushed about every 10 s and on stop/reconnect.
- A cursor-based change feed for small editable records (agendas, ticks, projects) using optimistic versions.

**Revisit.** Use Yjs if live co-editing of notes is required.

## ADR-015 Server runtime and contracts

**Decision.** Node 24 LTS, Fastify 5, Zod 4 shared schemas (OpenAPI and AsyncAPI generated), TypeScript strict ESM, in a pnpm + Turborepo monorepo.

## ADR-016 Web front end

**Decision.** React 19, Vite, TanStack Router and Query, Tailwind CSS v4, Radix primitives, TipTap editor, React Flow canvas. A shared `packages/ui` serves both web and desktop renderers.

## ADR-017 Identity

**Decision.**
- WorkOS AuthKit with Google/Microsoft sign-in; SSO and SCIM later.
- Desktop: system-browser authorization code + PKCE on loopback.
- Web: HTTP-only session plus CSRF protection.
- Calendar consent is separate from sign-in.

## ADR-018 AI gateway

**Decision.**
- Azure-hosted text models behind a provider adapter in `packages/ai-kit`.
- Separate deployments for summary, chat, live, and embeddings.
- Structured outputs from Zod schemas; a versioned prompt registry.
- Model choice is decided by the evaluation corpus.
- Baseline provisioned throughput plus pay-as-you-go spillover.

## ADR-019 Release and signing

**Decision.** Apple Developer ID with notarization; Azure Artifact Signing for Windows; staged updater rollouts; a signed model manifest.

## ADR-020 Text-only product

**Decision.**
- No audio or video storage, playback, or clips.
- Fathom-style clips are replaced by timestamped transcript quote cards with deep links.
- Rejected: opt-in recording, which brings legal exposure, storage cost, and conflict with the product promise.

## ADR-021 Feature cycles

**Decision.**
- Per-workspace entitlements and feature flags in the account service.
- A connector capability registry, a workflow node catalog, and a prompt registry.
- Features land by extending these registries or a service, not by rewiring.

## ADR-022 Billing

**Decision.** Stripe per-seat subscriptions from paid pilots (Gate 4), with usage metering for model-heavy features.
