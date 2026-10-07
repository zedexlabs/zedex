# Zedex — Complete Project Briefing

**Use this document to brief any AI agent, co-founder, or collaborator on Zedex end-to-end.**
**Last updated:** October 2026 · **Status:** Planning complete, development not yet started (Gate 1)

---

## 1. What Zedex Is

Zedex is a **B2B SaaS meeting intelligence product** for teams of 20–100 people. It is not a note-taker or a transcript recorder. It is a **commitment-tracking and accountability loop** built around meetings.

The core value: teams make promises in meetings and those promises get lost. Zedex captures what was agreed, routes each commitment to the right tool (Linear, HubSpot, Google Docs, Slack) with a human approving the exact payload, tracks delivery, and carries the status into the next meeting's preparation automatically.

**Meeting lifecycle Zedex owns:**
```
Prep → Capture → Live → Confirm → Approve → Execute → Reconcile → Report → Prep
```

**Initial customer:** English-speaking B2B SaaS companies, 20–100 employees.

---

## 2. Non-Negotiables (Privacy Invariants — Never Change These)

These are product commitments to customers, not implementation details. Any code that violates one is a P0 bug.

| Invariant | Rule |
|---|---|
| Cloud STT, zero retention | Speech-to-text runs on a contracted streaming cloud provider with zero retention; Zedex never stores meeting audio, never uploads audio files, never records, and never joins as a bot. Uncertain values require human verification. |
| No recording | Zedex does not record audio or video |
| No meeting bot | Zedex never joins a meeting as a participant |
| No training on customer data | Customer content is never used to train models |
| Logs carry IDs not content | No transcript text, note text, or commitment text appears in any log, trace, or metric |
| Humans approve external writes | No data is written to any external system (Linear, HubSpot, Slack, Google Docs) without the user seeing the exact payload and clicking Approve |

**Other non-negotiables:**
- AI proposes; humans tick, confirm, close, and approve. Nothing is auto-ticked or auto-executed.
- Calendars are read-only by default; optional write only at Gate 5 with explicit consent.
- Association ≠ access. Being grouped with a meeting does not grant access to its content.
- Admins have no implicit access to private notes.

---

## 3. Product Features (End to End)

### Desktop shell (macOS + Windows) — thin shell, full capture

- **Meeting popup:** Appears when a calendar event starts (or microphone activity is detected on a known meeting app). Shows title, attendees, and three actions: Start notes, Open prep, Dismiss. Never starts capture without an explicit click.
- **Cloud STT capture:** The native C++ helper captures mic ("You") and system audio ("Others") via Core Audio (macOS) or WASAPI (Windows) and streams them over WebSocket to the cloud STT provider. Audio never passes through Zedex servers and is never stored. The helper obtains a short-lived session token from `ingest`; provider keys never reach devices.
- **Compact overlay:** Agenda and notes panel hidden from screen share.
- **Encrypted local store:** SQLite with whole-database encryption (SQLite3MultipleCiphers), key protected by Electron safeStorage, FTS5 for offline search.
- **Sync:** Batches transcript segments to the ingest service every ~10 s, on stop, and on reconnect. ACK only after server commit.
- The shell loads the **web app** from our domain inside a locked-down window; all UI other than the popup/overlay is web. Shell and helper update rarely; UI ships through web deploys.

### Web app (all features)

- Sign-in, workspace, calendar connect
- Meetings list, meeting view with transcript and typed notes
- **Projects** with drag-and-drop grouping, auto-rules, and access control
- **Agenda editor** (previous meeting summary / this meeting / next-meeting plan)
- **Preference summaries** — chosen meetings, date ranges, projects, and styles, generated on request
- Approval queue, commitments board (Gate 4+)
- Admin, billing, onboarding
- Share links (viral growth path)
- Transcript upload/paste for non-desktop users (TXT / VTT / SRT)

**Architecture rule:** Desktop is the only place that captures. Web is where everything else lives. One React codebase (`packages/ui`) shared across both shells.

### AI features

- **Chunk notes:** Built continuously during the meeting every ~5 min; used to build meeting cards.
- **Meeting card:** Structured summary (topics, decisions, open questions, next steps) with segment evidence. Humans confirm each item.
- **Preference summaries:** Generated on request from meeting cards, not raw transcripts (ADR-027).
- **AI agenda draft:** 24 h before the next meeting, drafted from carry-over items, open commitments, and context. Humans edit and accept; nothing auto-accepted.
- **Live tick suggestions (Gate 3):** Soft highlights with evidence; only humans tick.
- **Catch-up brief (Gate 3):** Built from authorized sources only. Says "Not captured" if no authorized artifact exists.
- **Search and chat (Gate 3):** Scoped, security-trimmed, re-authorized with BatchCheck.
- **Commitments to delivery (Gate 4):** Exact-payload approval before any external write.

### Integrations

- Gate 2: Google Calendar and Microsoft Outlook (read-only sync)
- Gate 4: HubSpot, Linear, Slack, Google Docs
- Gate 5: Notion, Jira, Teams, calendar write (opt-in), public API, MCP server, webhooks, Salesforce/Attio

---

## 4. Architecture — The Big Picture

### Style
Right-sized services split on workload and failure boundaries, communicating through an event backbone, deployed as **cells** (Azure deployment stamps) behind a small global control plane.

### Infrastructure — Azure

| Component | Service |
|---|---|
| Compute | Azure Container Apps (consumption plan, scale to zero) |
| Events | Azure Service Bus Standard (Phase 1); Premium later if needed |
| Database | Azure Database for PostgreSQL Flexible Server (one server, logical DB per service) |
| Search (Phase 2+) | Azure AI Search |
| Realtime | Azure Web PubSub |
| AI models | Azure OpenAI |
| Secrets | Azure Key Vault |
| CDN / WAF | Azure Front Door |
| Object storage | Azure Blob Storage |
| Windows signing | Azure Artifact Signing |

### Global control plane

One per environment:
- Azure Front Door + WAF (TLS, routing, rate limits)
- `account` service: users, sessions, workspaces, teams, roles, entitlements, billing (Stripe), cell directory

### Cell (one identical stack per region)

Start with `us-1` in East US 2. Add `eu-1` for residency, dedicated cells for enterprise.

| Service | Responsibility | Gate |
|---|---|---|
| `workspace` | Projects, meetings, notes, agendas, decisions, commitments, routing, codes, audit, deletion | 2 |
| `ingest` | Transcript sync, STT session tokens, revisions, finalization (sharded by workspace_id) | 2 |
| `integration` | Calendar sync, connector adapters, token vault, egress limits | 2 |
| `authz` (OpenFGA) | Relationship-based permissions | 2 |
| `intelligence` | Chunk notes, meeting cards, summaries, agenda drafts, search/chat, alerts | 3 |
| `live` | Low-latency in-meeting tick suggestions (stateless) | 3 |
| `notification` | Email, Slack DM, in-app, brief scheduling | 3 |
| `reporting` | Exports, reports, analytics read models | 3–4 |
| `workflow` | Workflow DAGs, approvals, operation ledger, canvas backend | 4 |

### Communication rules
1. Clients → cell: HTTPS, WorkOS JWT, authorized by OpenFGA
2. Events (facts): transactional outbox → Service Bus → inbox dedup table
3. Commands: queues owned by the receiving service; receiver rechecks permission
4. Realtime: services publish to Web PubSub after commit
5. Database per service. No cross-service joins. RLS on `workspace_id` in every database.

---

## 5. Tech Stack

### Backend
- **Runtime:** Node.js 24 LTS, TypeScript strict ESM
- **Framework:** Fastify 5
- **Validation:** Zod 4 (schemas in `packages/contracts` are source of truth)
- **ORM:** Drizzle with reviewed SQL migrations (forward-only: expand → migrate → contract)
- **Messaging:** Azure Service Bus with transactional outbox + inbox dedup pattern
- **Auth:** WorkOS AuthKit (Google/Microsoft identity). Desktop uses PKCE loopback. Web uses HTTP-only sessions.
- **Authorization:** OpenFGA (Zanzibar-style relationship-based permissions)
- **Billing:** Stripe
- **Monorepo:** pnpm + Turborepo

### Frontend
- **Framework:** React 19 + Vite
- **Routing/data:** TanStack Router + TanStack Query
- **Styling:** Tailwind v4
- **Components:** Radix UI primitives
- **Rich text:** TipTap (notes editor)
- **Workflow canvas:** React Flow
- **Design system:** `packages/ui` (shared between desktop and web)

### Desktop
- **Shell:** Electron — thin shell loading the remote web app; sandboxed renderers, validated IPC
- **Capture:** C++ native helper (`native/capture-asr/`)
  - macOS: Core Audio process taps (system + microphone)
  - Windows: WASAPI (microphone + output loopback)
  - Pipeline: PCM → mono → resample 16 kHz → Silero VAD → bounded windows → cloud STT stream
- **STT:** Cloud provider (AssemblyAI or Deepgram; Gate 1 benchmark decides). Short-lived tokens from `ingest`.
- **Distribution:** electron-updater staged rollouts; macOS: Developer ID + notarization; Windows: Azure Artifact Signing

### Estimated download sizes (Phase 1, no bundled model)
- macOS DMG: ~80–100 MB (Electron only, no ASR model)
- Windows installer: ~70–90 MB

---

## 6. Repository Structure

```
Zedex/                          # pnpm workspace + Turborepo
  AGENTS.md                     # engineering rules + Definition of Done
  CLAUDE.md                     # AI agent instructions
  ARCHITECTURE.md               # authoritative index
  README.md
  package.json  pnpm-workspace.yaml  turbo.json
  tsconfig.base.json  eslint.config.mjs  vitest.workspace.ts
  compose.yaml  .env.example  .gitignore

  apps/
    desktop/                    # Electron thin shell (Gate 2+)
      src/main/
        windows/                # main (loads web app), meeting-popup, live-overlay
        ipc/                    # validated IPC handlers (Zod schemas)
        auth/                   # PKCE loopback, session
        capture/                # helper supervision, protocol, gap tracking
        detection/              # calendar + mic-activity triggers
        storage/                # encrypted SQLite, key provider, migrations
        sync/                   # queue, engine, changefeed
        live/                   # tick suggestion client (Gate 3)
        realtime/               # Web PubSub client
        updates/                # app updater (no model updater)
        telemetry.ts
      src/preload/              # narrow validated bridge
      src/renderer/             # popup, overlay (app UI is web)

    web/                        # React SPA (all features)
      src/routes/               # workspace, teams, projects, meetings, prep,
                                # chat, commitments, reports, workflows,
                                # settings, admin
      src/features/             # agenda, projects, search, canvas (Gate 5)

  services/                     # one directory per service
    account/ workspace/ ingest/ integration/      # Gate 2
    intelligence/ live/ notification/ reporting/  # Gate 3
    workflow/                                     # Gate 4

  packages/
    contracts/                  # Zod schemas: http/, events/, commands/, ipc/
    domain/                     # Pure rules: state machines, routing, agenda
    service-kit/                # Bootstrap, auth, authz client, errors,
                                # idempotency, outbox, inbox, bus, telemetry
    ai-kit/                     # Model gateway (Azure OpenAI), prompt registry,
                                # structured output, evidence validation, budgets
    connector-sdk/              # Capability contract + test harness
    ui/                         # Shared design system (desktop + web)

  authz/                        # OpenFGA model + tests
  native/capture-asr/           # C++ capture helper
    src/platform/mac/           # Core Audio capture
    src/platform/win/           # WASAPI capture
    src/core/                   # Cloud STT streaming protocol, VAD, health

  infra/azure/                  # Bicep IaC: global/, cell/, modules/, env/
  docker/

  tests/
    contract/  e2e/  security/  performance/  resilience/
    evaluations/  desktop/

  .github/workflows/
    ci.yml  native.yml  desktop-release.yml
    deploy-global.yml  deploy-cell.yml  codeql.yml

  docs/
    DELIVERY_PLAN.md  IMPLEMENTATION_STATUS.md  PRODUCT_WORKFLOWS.md
    PHASE_1_PLAN.md  TECHNICAL_RISKS.md
    MARKET_RESEARCH.md  RESOURCES.md  BRANCHING.md
    PRODUCTION_STANDARD.md  ZEDEX_BRIEFING.md (this file)
    architecture/  01-overview … 11-quality-testing  decisions.md
```

---

## 7. Delivery Gates

Gates do not close on a schedule. They close when exit criteria are met with evidence. Cycles are ~2 weeks. No gate has passed yet.

### Gate 1 — Validate and qualify (Cycles 1–3)
- 15 buyer interviews, 5 design-partner journeys
- Cloud STT provider benchmark (AssemblyAI vs Deepgram): accuracy, latency, cost, fallover
- Meeting popup and overlay: screen-share protection matrix and meeting-detection spike
- Consent and legal review started. Google Cloud Workspace verification started.
- Azure cost baseline priced with pricing calculator.

**Exit:** Measured hardware support, partner commitments, approved cost baseline, STT provider chosen.

### Gate 2 — Foundation / Phase 1 (Cycles 4–9)
- Repository, CI/CD, global and cell infrastructure as code, `service-kit`, contracts
- Services: `account`, `workspace`, `ingest` (with `speech-sessions`), `integration` (Google/Microsoft calendars), `authz`
- Service Bus with outbox/inbox, Web PubSub
- Desktop thin shell, meeting popup, capture (cloud STT), durable sync
- **Projects** with drag-and-drop grouping, series auto-add, rules and tracking-code detection
- **Agenda** (previous/current/next) with draft and human accept
- **Preference summaries** on request
- **Typed notes** steering the summary
- Consent basics; RLS and audit
- Web app: sign-in, onboarding, all Phase 1 surfaces

**Exit:** founders dogfood their own meetings across Zoom, Teams, and Meet on macOS and Windows; offline restart, idempotency, tenant isolation, and revocation tests pass; first cell live.

### Gate 3 — Meeting intelligence (Cycles 10–15)
- Services: `intelligence`, `live`, `notification`, `reporting` (exports); Azure AI Search
- Notes editor and templates, scoped search and chat, briefs, catch-up, coverage honesty
- AI agenda with collaboration, live tick suggestions, highlights, prompts, personal alerts

### Gate 4 — Execution loop (Cycles 16–21)
- `workflow` service, exact-payload approvals, confirmed commitments
- HubSpot, Linear, Slack, Google Docs
- Analytics read models, tracking-code attribution; Stripe billing

### Gate 5 — Automation (Cycles 22–27)
- Canvas, Notion, Jira, Teams; opt-in calendar write; public API, MCP server, webhooks

### Gate 6 — Enterprise and expansion (demand-led)
- EU cell, dedicated cells, SSO/SCIM, scorecards, mobile, more languages, Salesforce/Attio/Confluence

---

## 8. Current Status

**All documentation is complete. No code has been written. No gate has passed.**

The repo at `github.com/zedexlabs/zedex` contains:
- Full folder and file scaffold (318 files) — each file has a description comment, no real code
- All architecture docs, including ADR-001 through ADR-028

**What is needed to start Gate 2:**
1. pnpm install (root package.json + workspace packages)
2. Turborepo pipeline (build, test, lint)
3. tsconfig.base.json + per-package tsconfigs
4. Azure Bicep infrastructure (Container Apps, PostgreSQL, Service Bus)
5. `account` service running locally with real database
6. CI pipeline (ci.yml)

**Known open items:**
- Google Workspace Cloud API verification: start in week 1 of Gate 1 (takes weeks)
- Screen-share protection on macOS is unqualified (best-effort claim only)
- Legal and consent review not started
- STT provider (AssemblyAI vs Deepgram) undecided until Gate 1 benchmark

---

## 9. Engineering Rules (Definition of Done)

A feature is **done** when ALL of the following are true:
- All acceptance criteria from the gate plan are met
- Contract tests pass for every new or changed endpoint
- Unit tests cover all new domain logic (target: 100% branch coverage on `domain/`)
- Integration tests cover the happy path and at least one error/retry path
- Privacy invariants are not violated (checked by author + reviewer)
- No new critical/high CodeQL findings
- Telemetry added (at least one trace span + one metric for the new flow)
- `docs/IMPLEMENTATION_STATUS.md` updated
- PR reviewed and approved (1 teammate for `develop`, 2 for `main`)
- No placeholder comments (`// Gate N — placeholder`) left in shipped code

---

## 10. Branching Strategy

- **Trunk-based development:** one `develop` branch for both macOS and Windows
- **Branch types:** `feat/g2-*`, `fix/g3-*`, `chore/*`, `docs/*`, `perf/*`, `refactor/*`, `hotfix/*`
- **Gate label in branch name** (e.g. `feat/g2-desktop-popup`)
- **Merge strategy:** squash to `develop`; merge commit to `main`
- **`main` protection:** 2 approvals + CodeQL pass; force-push blocked
- **Conventional Commits** enforced

---

## 11. Competitors and Differentiation

| Competitor | What they do | Zedex advantage |
|---|---|---|
| Granola | Desktop-first AI notes, cloud transcription, web viewer for summaries, iOS app, team Spaces | Zedex adds team accountability loop, commitment routing, and approval-before-write |
| Fathom | Meeting recorder + notes | Zedex: no recording, no bot, no cloud audio storage; team commitments |
| Fireflies | Cloud bot + transcription | Zedex: no bot, no cloud audio storage, privacy-first |
| Notion AI / Confluence | Docs with AI | Not meeting-first; no live capture; no commitment routing |
| Otter.ai | Cloud transcription + notes | Zedex: audio streams to STT only, never stored; consent-first |

**Key differentiators:**
1. Commitment tracking and routing — not just notes; closes the loop to delivery tools
2. Team accountability — shared commitment board; not just personal notes
3. Approval before external writes — trust with IT/security buyers
4. No meeting bot — natural meetings, no creepy participant
5. Audio never stored — streams to STT provider, never persisted anywhere

---

## 12. Key Decisions Made (ADRs 001–028)

| Decision | Choice | Reason |
|---|---|---|
| Architecture style | Cell-based services | Failure isolation, team scaling, data residency |
| Cloud | Azure | Existing plan, Windows signing, M365-heavy B2B customers |
| Compute | Azure Container Apps (consumption) | Scale to zero, Phase 1 cost ~$30–50/month base |
| Events | Azure Service Bus Standard (Phase 1) | ~$0.0135/h; Premium only when needed |
| Speech-to-text | Cloud provider (AssemblyAI / Deepgram, Gate 1 benchmark) | No model to ship, better accuracy, ~$3–5/user/month |
| AI models | Azure OpenAI | Enterprise data processing terms; no Google ADK |
| Desktop shell | Electron — thin shell loading remote web app | UI ships via web; installer shrinks; no Chrome extension |
| Authorization | OpenFGA (Zanzibar-style) | Fine-grained relationship permissions |
| Auth | WorkOS AuthKit | B2B SSO path, managed PKCE |
| Summarisation | Layered (chunk notes → meeting card → rollups) | Long transcripts, incremental rebuild, cost control |
| Clients | Desktop (capture) + Web (all features) | Desktop can't approve commits; web teammates need full access |
| Workflow engine | Custom DAG interpreter (Postgres + Service Bus) | Exact-payload approval is domain data; Temporal has no managed Azure offering |
| Billing | Stripe | Standard B2B path |

---

## 13. Cost Model (Phase 1 / Gate 2 estimate, Azure)

| Component | Est. monthly |
|---|---|
| Container Apps (6 services, consumption) | ~$15–25 |
| PostgreSQL Flexible Server (1 server) | ~$12–18 |
| Service Bus Standard | ~$10 |
| Web PubSub | ~$5 |
| Azure OpenAI (text models) | Pay-per-use |
| STT (AssemblyAI or Deepgram) | ~$3–5/user at 20 hr/month |
| **Phase 1 cell base** | **~$40–60/month** |

---

## 14. GitHub Organization

- **Organization:** `zedexlabs`
- **Repo:** `github.com/zedexlabs/zedex`
- **Default branch:** `main`
- **Development branch:** `develop`
- **Git user:** Zedex Labs

---

*This document is a briefing, not a plan document. It may be updated freely as decisions change.*
