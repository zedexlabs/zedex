> **Plan document — do not modify.**
> This file is the agreed plan and architecture. Treat it as source of truth.
> Changes must go through a new ADR or an explicit plan revision — do not edit in place.

---

> **Production target** — this is not a prototype or MVP. Every decision here targets a production product shipped in cycles.

---

# Udula — Phase 1 Task Assignment

Hi Udula. You are assigned the most critical and most technically complex tasks in Phase 1. The reason is simple: the foundation, the desktop capture pipeline, and the AI service are the parts that can silently fail in ways that are hard to fix later. Getting them right the first time is worth the investment. You have Claude Code available — use it actively for every step below.

Read these documents before starting anything:
- [`ARCHITECTURE.md`](../../ARCHITECTURE.md) — full system overview and non-negotiables
- [`docs/PHASE_1_PLAN.md`](../PHASE_1_PLAN.md) — what ships in Phase 1
- [`docs/TEAM_TASKS.md`](../TEAM_TASKS.md) — branch management rules and dependency order
- [`docs/architecture/02-desktop-native.md`](../architecture/02-desktop-native.md) — desktop shell detail
- [`docs/architecture/05-intelligence.md`](../architecture/05-intelligence.md) — AI pipeline detail
- [`docs/UI_PAGES.md`](../UI_PAGES.md) — all desktop surfaces (DS-1 to DS-6) you need to build

---

## Pre-build benchmarks (before Step 1)

These benchmarks feed decisions that the rest of Phase 1 depends on. Do them before writing any service code.

---

### B1 — STT provider bake-off: AssemblyAI vs Deepgram

**Why:** Every transcript in Zedex comes from the STT provider. Choosing wrong wastes months of integration work.

**What to do:**

1. Collect a benchmark corpus of 10 hours of consented English business meetings. Mix of 2+ accents, crosstalk, product names, numbers, dates, and dollar amounts.
2. Write `scripts/benchmark-stt.ts` that sends each audio file to AssemblyAI and Deepgram and collects:
   - WER (word error rate) — target < 5 %
   - Entity accuracy: names, numbers, dates, dollar amounts
   - First-partial latency (time to first word)
   - Final-text latency p50 and p95
   - Reconnect behaviour on dropped connection
   - Cost per hour at current pricing
3. Output: a markdown scorecard at `scripts/benchmark-stt-results.md` with both providers side by side.
4. Record the decision in a new ADR (ADR-030) in `docs/architecture/decisions.md`.

**Done when:** Scorecard written, one provider chosen, ADR committed.

---

### B2 — Capture matrix

**Why:** The desktop capture pipeline must work on every supported platform and meeting tool before we commit to the architecture.

**What to do:**

1. On macOS 14.2+ arm64, macOS 14.2+ x64, and Windows 11 x64:
   - Open Zoom, then Teams, then Google Meet
   - Verify mic track and system audio track captured separately
   - Check echo: mic track must not contain the system audio
   - Measure CPU during a 10-min capture: must stay within the budget
   - Measure RAM: ring buffer must stay ≤ 30 s of audio
2. On each platform + meeting tool combination (6 total), verify the overlay is hidden from screen share. Record a screenshot of what the other participants see.
3. Fill in the capture matrix table and save it as `docs/CAPTURE_MATRIX.md`.

**Done when:** All 6 combinations tested, matrix table complete.

---

### B3 — Model eval baseline

**Why:** The intelligence service uses two Azure OpenAI model tiers. We need to confirm which models to use before writing the prompts.

**What to do:**

1. Pick 5 sample meetings from the benchmark corpus (varied lengths: 20 min, 40 min, 60 min, 60 min with crosstalk, 30 min multi-speaker).
2. Run the small model candidate and the large model candidate on each meeting with a draft "extract decisions and next steps" prompt.
3. Score manually:
   - Grounding: each output claim has a supporting transcript segment
   - Decision recall: decisions in the gold label that appear in the output
   - Hallucination count: claims with no supporting segment
   - Cost per meeting
   - Latency (time to complete)
4. Confirm model choices and record in a note at the top of `docs/architecture/05-intelligence.md`.

**Done when:** Both models scored on 5 meetings, choices confirmed.

---

## Step 1 — Foundation (M1, cycle 4)

**Branch:** `feat/foundation` → PR to `dev`

**Why this is yours:** Everything every other developer does depends on this being correct. If the monorepo structure, service-kit patterns, or Bicep IaC are wrong, every service built on top of them is wrong too. Claude Code can accelerate all of this significantly.

**Tasks:**

### 1a — Monorepo

- Initialise pnpm workspaces + Turborepo
- TypeScript strict config shared across all packages and services
- ESLint + Prettier with shared config
- `turbo.json` pipeline: `build`, `test`, `lint`
- `.gitignore`, `.editorconfig`, `pnpm-workspace.yaml`

### 1b — `packages/contracts`

Zod v4 schemas for every domain event envelope. Every service imports from here — do not duplicate schemas.

Events to define from day one (add more as services are built):
- `calendar.event.upserted`
- `calendar.event.cancelled`
- `ingest.segment.finalized`
- `ingest.meeting.finalized`
- `workspace.meeting.created`
- `workspace.project.membership.changed`
- `account.workspace.created`
- `account.member.invited`
- `authz.tuple.written`

Each envelope: `{ id, type, workspaceId, timestamp, payload }` — payload is the Zod-typed body.

### 1c — `packages/service-kit`

Shared Fastify 5 kit that every service uses. Build this first; every service imports it.

Modules:
- **Bootstrap:** `createApp(config)` — Fastify instance with OTel distro (Azure Monitor), `fastify-sensible`, `@fastify/cors`, content-type checks
- **Auth middleware:** validates the JWT from WorkOS, extracts `userId`, `workspaceId`, `cellId`, attaches to request context
- **Idempotency middleware:** reads `Idempotency-Key` header, short-circuits with a cached 2xx response if the key was seen in the last 24 h (Postgres-backed)
- **Transactional outbox:** `publishEvent(tx, event)` — writes to `_outbox` table inside the same DB transaction; a relay worker picks up and publishes to Service Bus
- **Inbox deduplication:** `deduplicateInbox(messageId)` — idempotent message handler using `_inbox` table; call before processing any Service Bus message
- **Structured error model:** `ZedexError` with `code`, `message`, `httpStatus`; Fastify error handler maps to JSON `{ error: { code, message } }`
- **OTel content scrubbing:** exporter strips any field matching `transcriptText`, `noteText`, `commitmentText` before sending to Azure Monitor

Tests: outbox duplicate test (same event ID twice → one row), inbox out-of-order test, idempotency key replay test.

### 1d — Bicep IaC

Two stacks:

**Global stack** (`infra/azure/global/`):
- Azure Front Door Standard with custom WAF rules
- Blob Storage static web hosting (for `packages/ui` build output)
- Key Vault (for encrypted tokens, secrets)
- Web PubSub Free tier

**Cell stack** (`infra/azure/cell/`):
- Container Apps environment
- Container Apps Jobs (for cron tasks)
- Service Bus Standard namespace with one topic per service, managed-identity only (SAS disabled)
- PostgreSQL Flexible Server (Burstable B2ms for dev, General Purpose for staging/prod)
- Managed identity per service

**Naming convention:** `zedex-{env}-{component}` e.g. `zedex-dev-ingest-ca`

### 1e — GitHub Actions

Three workflows:

1. **`ci.yml`** — triggers on every PR: `turbo run build test lint`, then CodeQL
2. **`preview.yml`** — triggers on PR to `dev` or `staging`: deploy static web preview to a PR-specific Blob container
3. **`deploy-cell.yml`** — triggered manually or on push to `staging`/`main`: bicep what-if then deploy, container image build and push to Azure Container Registry, Container Apps update

Use OIDC role (no stored secrets). Federated identity on the GitHub repo.

**Done when:** An empty Fastify service (just a `GET /healthz`) deploys to the dev cell from `feat/foundation` PR CI. All service-kit unit tests pass.

---

## Step 4 — Desktop shell + C++ capture helper + ingest (M4, cycles 6–7)

**Branch:** `feat/desktop-capture` → PR to `dev` (after Step 2 is merged)

**Why this is yours:** The native C++ audio pipeline is the hardest technical piece in the whole project. It involves OS-level audio APIs on two platforms, a WebSocket streaming protocol, a ring buffer, and gap recovery. A mistake here silently loses meeting data. Claude Code should be open the whole time you work on this.

**Tasks:**

### 4a — Electron thin shell

Reference: `docs/architecture/02-desktop-native.md` and `docs/UI_PAGES.md` (DS-1 to DS-6)

- `BaseWindow` + `WebContentsView` — **not** the deprecated `BrowserView`
- Origin allowlist: only load remote routes from `app.zedex.io`. Any other origin is blocked.
- CSP headers on every frame
- Contextual isolation on, node integration off in renderer
- Tray icon with menu (DS-5): Open Zedex, Start capture (if a meeting is in progress), Upcoming event, Preferences, Quit
- Meeting popup (DS-1): calendar event trigger or mic-activity trigger. Actions: Start Notes, Open Prep, Dismiss. Never auto-starts capture.
- Full floating overlay (DS-2): agenda ticks, quick-note input, live suggestions strip placeholder (Gate 3), collapse/resize/drag. Positioned outside screen-share capture region.
- Status strip (DS-3): minimized overlay with Expand and Stop
- Post-capture notification (DS-4): session duration, segment count, ACK status
- Offline/error page (DS-6): locally bundled HTML, shows outbox status

**Auth handoff:**
1. Main process opens system browser with WorkOS PKCE authorize URL (loopback redirect)
2. `account` service issues a one-time handoff code
3. Main process POSTs the code to get a web session token
4. WebContentsView loads `https://app.zedex.io/app?session=<token>`

Main process holds the `ingest` service token. The helper never holds Zedex credentials.

### 4b — C++ capture helper (`native/capture-asr/`)

Reference: `docs/architecture/02-desktop-native.md`

The helper is a native process that the main Electron process spawns. It communicates over a local IPC socket (stdin/stdout JSON protocol — nlohmann/json).

**macOS (`src/platform/macos/`):**
- Core Audio tap for system audio (`kAudioHardwarePropertyDefaultOutputDevice`)
- AVAudioSession / voice-processing I/O for microphone with OS AEC
- `URLSessionWebSocketTask` for WebSocket streaming to the STT provider
- Entitlements: `com.apple.security.device.audio-input`

**Windows (`src/platform/windows/`):**
- WASAPI loopback for system audio (`eRender` endpoint)
- WASAPI mic capture with `AUDCLNT_STREAMFLAGS_LOOPBACK` off, communications category for OS AEC
- WinHTTP WebSocket API for streaming
- COM initialization on capture thread

**Shared (`src/core/`):**
- `stream_client.h` — interface: `connect(url, token)`, `send(frame)`, `disconnect()`
- `capture_session.h` — manages two tracks (mic + system), mixes, resamples, gates on libfvad
- speexdsp resampler: resample both tracks to 16 kHz mono
- libfvad VAD: gate on voice activity; silence gap > 300 ms → suppress; silence > 5 min → auto-stop
- 30 s ring buffer: on reconnect, replay the last 30 s with gap markers
- nlohmann/json for all IPC and protocol framing
- vcpkg manifest mode for pinned dependencies

**Build:** CMake presets — `debug-mac`, `release-mac`, `debug-win`, `release-win`. CI builds both platforms.

**IPC protocol (JSON over stdin/stdout):**
```json
// Commands to helper
{ "cmd": "configure", "url": "wss://...", "token": "...", "sampleRate": 16000 }
{ "cmd": "start" }
{ "cmd": "stop" }
{ "cmd": "pause" }
{ "cmd": "resume" }

// Events from helper
{ "event": "ready" }
{ "event": "segment", "id": "...", "track": "mic|system", "startMs": 0, "endMs": 5000, "text": "..." }
{ "event": "gap", "startMs": 0, "endMs": 5000, "reason": "reconnect|network" }
{ "event": "error", "code": "...", "message": "..." }
{ "event": "stopped" }
```

### 4c — `ingest` service

Reference: `docs/architecture/03-services-and-communication.md`

- `POST /speech-sessions` — validates the meeting exists and is owned by the workspace, calls the STT provider's session endpoint, returns a short-lived token. Provider keys never leave this service.
- `POST /segments` — idempotent by `segmentId`; inserts finalized text into `transcript_segment` table sharded by `workspace_id`. Returns 200 if already exists (duplicate).
- `POST /meetings/:id/finalize` — marks the meeting transcript as complete, publishes `ingest.meeting.finalized` via outbox
- `GET /meetings/:id/segments` — returns all segments for a meeting (auth required, via authz BatchCheck)

**Schema:** `workspace_id` is the first column of every PK and index. No global sequences. No cross-workspace joins.

### 4d — Encrypted outbox (Electron main process)

- SQLite3MultipleCiphers: whole-database encryption, key from `safeStorage.encryptString`
- Schema: `segment_outbox (id TEXT, meeting_id TEXT, workspace_id TEXT, payload BLOB, created_at INTEGER, acked_at INTEGER)`
- Flush loop: every 10 s, on stop, on reconnect — POST to `ingest /segments`
- On ACK from ingest: set `acked_at`, purge rows older than 24 h with `acked_at` set
- On app crash before ACK: rows survive; flush runs on next start

**Tests:**
- Kill network mid-meeting (10 segments sent, 3 ACKed) → reconnect → all 10 eventually ACKed, none duplicated
- Kill app process before any ACK → restart → all segments retried and ACKed
- Helper JSON fuzzing: send malformed JSON from a test harness, helper must not crash

**Benchmark targets:**
- Segment text arrives in the web app ≤ 3 s after the STT provider returns it (p95)
- Reconnect gap < 30 s with no data loss
- Capture CPU < 8 % on Apple Silicon, < 12 % on x64

---

## Step 5 — Intelligence service (M5, cycles 7–8)

**Branch:** `feat/intelligence` → PR to `dev` (after Step 4 is merged)

**Why this is yours:** You built the ingest service and understand the segment data model. The intelligence service consumes ingest events and turns segments into structured meeting knowledge. It also owns the pgvector index and the agenda draft pipeline.

**Tasks:**

### 5a — Service scaffold

- Fastify + Drizzle + Postgres (logical DB on the shared cell server)
- Service Bus subscription on `ingest.segment.finalized` and `ingest.meeting.finalized`
- Azure OpenAI client (Data Zone deployment, US region for Phase 1)

### 5b — Chunk notes pipeline

Trigger: `ingest.segment.finalized` arrives.

1. Buffer segments for ~5 min of meeting time
2. When the buffer is full (or meeting ends): send buffered segments to the small Azure OpenAI model with a "extract brief notes from this chunk" prompt
3. Store `chunk_note { id, meeting_id, workspace_id, start_ms, end_ms, text, segment_evidence_ids[] }` in the intelligence DB
4. Embed the chunk text with `text-embedding-3-small`, store vector in pgvector HNSW index

### 5c — Meeting card pipeline

Trigger: `ingest.meeting.finalized` arrives.

1. Load all `chunk_note` rows for this meeting
2. Map-reduce with the large model:
   - Map: from each chunk note, extract candidate topics, decisions, open questions, next steps
   - Reduce: deduplicate and consolidate across chunks into a final `meeting_card`
3. Each card item carries `segment_evidence_ids[]` pointing to the source segments in ingest
4. Confidence flags: scan each item for numbers, dates, names, dollar amounts; if they appear uncertain in the STT (via confidence score from provider) or differ from the surrounding transcript, mark `{ flagged: true, reason: "verify" }`
5. Store `meeting_card { id, meeting_id, workspace_id, topics[], decisions[], open_questions[], next_steps[], generated_at }`
6. Publish `intelligence.meeting_card.ready` via outbox → `workspace` subscribes and updates the meeting status

### 5d — `card_edit` table

User edits must survive regeneration:
- `card_edit { id, card_item_id, meeting_id, workspace_id, user_id, edited_text, created_at }`
- When regenerating a card, any item with a matching `card_edit` row keeps the user's text; AI text is replaced only for items with no edit
- Expose via `PATCH /meetings/:id/card/items/:itemId` on the workspace service (workspace calls intelligence to merge)

### 5e — Agenda draft pipeline

Trigger: Service Bus **scheduled message** at T-24 h before each recurring meeting.

1. Load the previous meeting's card from this series (or same-customer/same-project fallback)
2. Load any items from the previous meeting's agenda that were not ticked
3. Prompt the small model: "Given these carry-over items and open questions, draft an agenda"
4. Store `agenda_draft { id, meeting_id, workspace_id, previous_section[], this_section[], next_section[], drafted_at }`
5. Publish `intelligence.agenda.drafted` → workspace subscribes, surfaces for human review
6. Nothing is auto-accepted. The organizer must click Accept.

### 5f — pgvector HNSW index

- `retrieval_chunk { id, meeting_id, workspace_id, chunk_note_id, embedding vector(1536), created_at }`
- HNSW index: `CREATE INDEX ON retrieval_chunk USING hnsw (embedding vector_cosine_ops) WITH (m = 16, ef_construction = 64)`
- Security trim before every query: filter by `workspace_id` first, then call `authz.BatchCheck` to verify the caller can read each meeting
- Hybrid search: Postgres FTS rank + pgvector cosine similarity, combined score

### 5g — Eval and CI gate

Every PR to `services/intelligence/` runs the eval corpus:
- Grounding: ≥ 95 % of card item claims have a supporting segment
- Decision recall: ≥ 85 % of gold-labelled decisions appear in the card
- Flag catch rate: ≥ 90 % of seeded number and date errors are flagged
- If any metric drops > 2 points from the previous baseline, the PR is blocked

**Benchmark:**
- Meeting card ready < 60 s after a 1-hour meeting finalizes
- Agenda draft available T-24 h ± 5 min for 100 % of test recurring meetings

---

## Step 8 — Preference summaries extension (M8, cycles 8–9)

**Branch:** `feat/preference-summaries` → PR to `dev` (after Steps 6 and 7 are merged)

**Why this is yours:** This extends the intelligence service you built in Step 5.

**Tasks:**

1. `summary_run { id, workspace_id, user_id, scope_meeting_ids[], scope_project_id, scope_date_range, style, focus, generated_at, result_text }`
2. `summary_preference { id, workspace_id, user_id, name, scope, style, focus, created_at }` — saved preference sets
3. API: `POST /summaries` — takes scope + style + focus, calls authz BatchCheck for each meeting in scope, map-reduces meeting cards with large model
4. API: `GET /summaries/:id` — returns completed or in-progress summary
5. API: `POST /summary-preferences` / `GET /summary-preferences` — save and retrieve preference sets
6. Privacy: a meeting that the caller cannot read (BatchCheck fails) is silently excluded, never an error

**Benchmark:** < 30 s for a scope of 20 meetings.

---

## Step 9 — Hardening (shared, cycle 9)

Work with Sinthujan and the founder:
- Run the cell load test: simulate 50 concurrent meeting captures across 10 workspaces
- OWASP checklist on ingest and intelligence endpoints
- CodeQL: resolve any critical or high findings before M9 sign-off
- Help founder record dogfood exit criteria evidence in `IMPLEMENTATION_STATUS.md`

---

## Useful references

| Document | Why you need it |
|---|---|
| [`docs/architecture/02-desktop-native.md`](../architecture/02-desktop-native.md) | Full spec for the desktop shell, C++ helper, and outbox |
| [`docs/architecture/03-services-and-communication.md`](../architecture/03-services-and-communication.md) | Service Bus topics, outbox/inbox pattern, backpressure |
| [`docs/architecture/04-data-model.md`](../architecture/04-data-model.md) | Schema for ingest and intelligence |
| [`docs/architecture/05-intelligence.md`](../architecture/05-intelligence.md) | AI pipeline detail |
| [`docs/architecture/09-infrastructure-operations.md`](../architecture/09-infrastructure-operations.md) | Bicep tiers, Container Apps, Service Bus config |
| [`docs/architecture/10-repository-structure.md`](../architecture/10-repository-structure.md) | Where every file lives |
| [`docs/RESOURCES.md`](../RESOURCES.md) | Links to libfvad, speexdsp, URLSessionWebSocketTask, WinHTTP WebSocket, Electron WebContentsView, vcpkg, pgvector |
| [`docs/UI_PAGES.md`](../UI_PAGES.md) | All desktop surface specs (DS-1 to DS-6) |
