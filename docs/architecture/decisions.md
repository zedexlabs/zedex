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

## ADR-012 Local ASR *(superseded by ADR-023)*

**Decision.**
- whisper.cpp (Metal on Apple Silicon) with built-in Silero VAD and quantized `small.en`/`base.en`.
- Parakeet-TDT 0.6B via sherpa-onnx is benchmarked behind the same `transcriber.h` interface.
- The choice per target is made from Gate 1 measurements.
- Models are verified by checksum before load.

**Superseded.** ADR-023 replaces local ASR with cloud STT as the default. The `transcriber.h` interface is retained. A local engine may return as an enterprise privacy mode in a future ADR.

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

---

## ADR-023 Cloud speech-to-text (supersedes ADR-012)

**Context.** ADR-012 chose local ASR (whisper.cpp + Parakeet-TDT). Founder review: online meetings do not need offline capability; a local model costs CPU, battery, and ~80–300 MB of installer size; cloud STT accuracy on names and numbers is better and continuously improving; Granola ships with cloud transcription and it is commercially viable.

**Decision.**
- The native helper streams the mic ("You") and system-audio ("Others") channels separately over WebSocket directly to the cloud STT provider. Audio never passes through Zedex servers and is never stored or retained by Zedex.
- The helper obtains a **short-lived provider session token** from `ingest` (`POST /speech-sessions`), which enforces policy, consent, and per-workspace budget before issuing. Provider keys never reach client devices.
- Network blips: the helper keeps ≤ 30 s of audio in a RAM ring buffer, reconnects, and resends on reconnect. Outages longer than 30 s are recorded as capture gaps and shown to the user.
- The `transcriber.h` interface is retained so a local engine (enterprise privacy mode, offline fallback) can be added later without protocol changes.
- Provider chosen from the Gate 1 benchmark. Candidates: **AssemblyAI Universal-Streaming** ($0.15/h, +$0.12/h speaker separation), **Deepgram Nova-3** (~$0.46/h). Estimated $3–5 per user/month at 20 meeting-hours.
- Requirements for any selected provider: zero audio retention, a signed DPA, and an EU data-processing region for Gate 6.
- Keyterm prompting supplies project vocabulary (customer names, product names) to reduce misrecognitions.

**Consequences.**
- Installer no longer bundles a model (drops ~80–300 MB).
- A provider outage degrades transcription; the helper must report gap state clearly.
- Cost scales with usage; per-workspace budget enforcement is mandatory.
- A second provider must be benchmarked as a failover.

**Revisit.** Add local engine as admin-configurable privacy mode if a paying enterprise customer requires it, or if provider costs exceed $8/user/month at average usage.

## ADR-024 Value verification (amends ADR-020)

**Context.** Cloud STT occasionally mishears numbers, dates, money amounts, and proper names. Commitments and decisions built on wrong values damage trust.

**Decision.**
- The STT provider returns word-level confidence scores. Segments store these at the word level.
- The intelligence pipeline flags words below a configurable threshold (`unverified`) in summaries, agendas, and commitment proposals when they match the patterns: numbers, currency, dates, durations, proper nouns.
- A flagged value is displayed with a visual indicator. The user must explicitly verify or correct it before the item is treated as confirmed.
- The user's typed notes (ADR-026) serve as a second-witness signal; if the user typed the same number, confidence in the transcribed value rises.
- Local audio clips as evidence remain in the backlog for a later opt-in phase; they are not part of Phase 1.

**Consequences.** Users see slightly more friction on ambiguous values, but trust in confirmed commitments is higher.

## ADR-025 Web-first product and thin desktop shell (amends ADR-010, ADR-016, ADR-019)

**Context.** Frequent web-app releases for early testers become painful if each requires a desktop-app update. Most Zedex UI is not desktop-specific.

**Decision.**
- All application UI lives in the **web app**, deployed continuously.
- The desktop shell (`apps/desktop`) loads the remote web app origin inside a locked-down `BrowserView` / `WebContentsView`. It does not bundle the web app.
- Shell hardening: `sandbox: true`, `contextIsolation: true`, no `nodeIntegration` in content, a strict origin allowlist and CSP, a narrow preload API that exposes only: capture start/stop, popup show/hide, overlay show/hide, and desktop health status.
- Native capture helper (`native/capture-asr`) continues to run as a separate C++ child process; it is the only reason to install the desktop app.
- Shell and helper releases are rare, signed, and staged (electron-updater). Web UI changes require no new installer.
- No Chrome extension. Capture runs in the native process, which Chrome cannot throttle.

**Consequences.**
- The installer shrinks significantly (no bundled model, no bundled web app).
- Desktop requires network access to function as a full product; the capture helper works offline and buffers locally.
- UI testing shifts almost entirely to web. Desktop-specific test surface covers only IPC, capture, and shell security.

## ADR-026 Typed notes steer summaries

**Decision.**
- User keystrokes during a meeting are timestamped segments with `kind = user_note`.
- The intelligence pipeline preserves the user's own headings, bullets, and order in the meeting card and summary. AI-generated text fills gaps around them.
- User text and AI text are visually distinct in every rendered view.
- Every AI-generated sentence links to at least one transcript segment as evidence.

**Consequences.** Users who write even a few notes get a much more accurate summary with lower chance of hallucinated structure.

## ADR-027 Layered summarisation for long transcripts and rollups

**Context.** A 2-hour meeting is ~18–20 k words (~25–30 k tokens). While this fits a single LLM call, quality degrades in the middle of very long input, regeneration cost repeats on every revision, latency grows, and multi-meeting rollups (project summaries, period summaries) do not fit at all without chunking.

**Decision.** Three-tier pipeline:

1. **Chunk notes** — built continuously as the meeting runs: every ~5 minutes of finalized transcript (with overlap) is condensed into a small structured chunk (key points, open questions, flagged values). The user's typed notes in that window are merged in.
2. **Meeting card** — structured topics, decisions, open questions, next steps, and flagged values, each with segment-level evidence references. Built from all chunk notes, the user's notes, and the accepted agenda. This is the canonical record of one meeting.
3. **Rollups** — project summaries, date-range digests, and multi-meeting briefs are built only from meeting cards, never from raw transcripts.
4. **Evidence retrieval** — when an exact transcript quote is needed (citation, evidence panel), the relevant segment is fetched by ID.

- Short meetings (≤ ~40 k tokens) may use a single-pass meeting-card path; the pipeline chooses by evaluation.
- When a transcript revision arrives (correction, late segment), only the affected chunks are rebuilt; downstream cards and rollups are invalidated and queued for rebuild.
- Prompt caching applies to the system prompt and shared context.
- Per-workspace token budget is enforced at the meeting-card pipeline; rollups are rate-limited by tier.

**Consequences.**
- Rollup quality is bounded by meeting-card quality; chunk accuracy matters.
- Rebuilding a meeting card after a revision is cheap (only affected chunks re-run).
- Raw transcripts are never sent to the model in bulk; search and evidence use segment IDs.

## ADR-028 Stay on Azure; Service Bus Standard for Phase 1 (amends ADR-003, ADR-009)

**Context.** GCP was evaluated as an alternative to Azure. The key question was whether Service Bus Premium (~$700/month per namespace unit) made Azure uneconomical. It does not: **Service Bus Standard** costs ~$0.0135/h base and is appropriate for Phase 1 volumes. Premium is justified only by network isolation or high-throughput needs that do not exist in Phase 1. A full GCP migration would cost weeks of re-platforming with no product progress and would complicate Windows code-signing (Azure Artifact Signing is native).

**Decision.**
- Azure is retained as the cloud platform.
- Phase 1 uses **Azure Service Bus Standard** tier. Upgrade to Premium only when load tests or network-isolation requirements demand it.
- **Azure Container Apps** on the consumption (scale-to-zero) plan; promote to dedicated when a service has sustained baseline load.
- One **Azure Database for PostgreSQL Flexible Server** per cell with a logical database per service; separate servers when a service's CPU or IO budget is exceeded.
- No Azure Cache for Redis and no Azure AI Search in Phase 1; Postgres full-text search and pgvector serve search until Phase 2.
- **Azure OpenAI** for text models. Google Gemini and Google ADK are not used.
- GCP can be revisited for specific services if a compelling technical reason emerges, but a mixed-cloud architecture requires its own ADR.

**Consequences.** Phase 1 cell cost is ~$30–50/month base; scales with usage. No re-platforming cost.
