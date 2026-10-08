> **Plan document — do not modify.**
> This file is the agreed plan and architecture. Treat it as source of truth.
> Changes must go through a new ADR or an explicit plan revision — do not edit in place.

---

> **Production target** — this is not a prototype or MVP. Every decision here targets a production product shipped in cycles.

---

# Sinthujan — Phase 1 Task Assignment

Hi Sinthujan. You are building the backend services that handle user accounts, access control, calendar data, projects, and agenda logic. These are the services every other part of Zedex depends on — the security boundary, the calendar pipeline, and the meeting organisation layer all live here. Build them solidly and test every edge case.

Read these documents before starting anything:
- [`ARCHITECTURE.md`](../../ARCHITECTURE.md) — full system overview and non-negotiables
- [`docs/PHASE_1_PLAN.md`](../PHASE_1_PLAN.md) — what ships in Phase 1
- [`docs/TEAM_TASKS.md`](../TEAM_TASKS.md) — branch management rules and dependency order
- [`docs/architecture/03-services-and-communication.md`](../architecture/03-services-and-communication.md) — service communication patterns
- [`docs/architecture/04-data-model.md`](../architecture/04-data-model.md) — data model for your services
- [`docs/architecture/06-integrations.md`](../architecture/06-integrations.md) — calendar integration detail
- [`docs/architecture/08-security-privacy.md`](../architecture/08-security-privacy.md) — security and RLS rules

**Important:** Your steps can only start after Udula's Step 1 (foundation) is merged to `dev`. Check TEAM_TASKS.md for the dependency order.

---

## Pre-build tasks (before Step 2)

---

### B4 — Calendar edge-case fixtures

**Why:** The calendar integration must handle real-world calendar quirks correctly. Building fixtures for these edge cases before writing the service means the tests are honest.

**What to do:**

Create recorded API response fixtures in `services/integration/tests/fixtures/calendar/`. One JSON file per case. Use Google Calendar API and Microsoft Graph API response formats.

Cases to cover:

| Case | File name |
|---|---|
| Recurring series — normal instance | `recurring-normal.json` |
| Recurring series — moved instance (rescheduled) | `recurring-moved.json` |
| Recurring series — cancelled instance | `recurring-cancelled.json` |
| Recurring series — exception (one occurrence changed) | `recurring-exception.json` |
| Time zone change (organizer in UTC+5, attendee in UTC-5) | `timezone-cross.json` |
| DST transition (event crosses spring-forward boundary) | `dst-transition.json` |
| All-day event | `all-day.json` |
| Multi-day event | `multi-day.json` |
| Two attendees with the same event (dedup case) | `dedup-same-event.json` |
| Private event (no title, no attendees visible) | `private-event.json` |
| Event with no conferencing link | `no-conferencing.json` |
| Event with two conferencing links | `multi-conferencing.json` |

**Done when:** All 12 fixture files created and committed to the test directory.

---

### B5 — Azure cost baseline

**Why:** The founder needs a confirmed cost figure before the first cell is provisioned.

**What to do:**

1. Open the [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/)
2. Add these components using the specs from `docs/architecture/09-infrastructure-operations.md`:
   - Front Door Standard
   - Blob Storage (static web, ~1 GB, 100k requests/month)
   - PostgreSQL Flexible Server — Burstable B2ms tier
   - PostgreSQL Flexible Server — General Purpose D2s v3 + zone-redundant HA (for staging/prod estimate)
   - Container Apps (consumption, 5 replicas per service, 0.5 vCPU / 1 GB each)
   - Container Apps Jobs (3 jobs, light cron work)
   - Service Bus Standard (1 namespace, 5 topics, ~1M messages/month)
   - Key Vault (standard, ~1k secrets operations/month)
   - Web PubSub Free tier
3. Record the monthly estimate at both Burstable and General Purpose HA in `docs/IMPLEMENTATION_STATUS.md` under "Known open items".

**Done when:** Cost estimate recorded with both tier scenarios.

---

## Step 2 — Auth, workspace, and permissions (M2, cycle 5)

**Branch:** `feat/auth-workspace` → PR to `dev` (after Udula's Step 1 is in `dev`)

**Why this is yours:** Auth and permissions are standard, well-documented patterns with no novel technical risk. The OpenFGA model defines the security boundary for the whole product — getting it right protects every service built later.

**Tasks:**

### 2a — `account` service

- Fastify + Drizzle + Postgres (logical DB on shared cell server)
- WorkOS AuthKit integration: Google and Microsoft OAuth, session token issuance, session revocation
- Tables:
  - `user { id, email, name, created_at }`
  - `workspace { id, slug, name, cell_id, created_at }`
  - `workspace_member { workspace_id, user_id, role (member|admin), invited_at, joined_at }`
  - `invite { id, workspace_id, email, role, token, expires_at, used_at }`
  - `session { id, user_id, workspace_id, token_hash, expires_at, revoked_at }`
- APIs:
  - `POST /auth/callback` — WorkOS callback, create session, return JWT
  - `POST /workspaces` — create workspace, emit `account.workspace.created`
  - `POST /workspaces/:id/invites` — create invite, send email via WorkOS
  - `POST /invites/:token/accept` — accept invite, add member, emit `account.member.joined`
  - `DELETE /sessions/:id` — revoke session
  - `GET /workspaces/:id/members` — list members (admin only)
  - `PATCH /workspaces/:id/members/:userId` — change role (admin only)
  - `DELETE /workspaces/:id/members/:userId` — remove member

### 2b — `authz` service (OpenFGA)

- Deploy OpenFGA in a Container App
- Define the authorization model:

```
model
  schema 1.1

type user

type workspace
  relations
    define admin: [user]
    define member: [user] or admin

type team
  relations
    define workspace: [workspace]
    define member: [user]
    define admin: [user] or admin from workspace

type project
  relations
    define workspace: [workspace]
    define viewer: [user, team#member]
    define editor: [user, team#member] or admin from workspace
    define admin: [user] or admin from workspace

type meeting
  relations
    define workspace: [workspace]
    define project: [project]
    define viewer: viewer from project or admin from workspace
    define editor: editor from project
```

- Write tuples to OpenFGA when these domain events arrive:
  - `account.workspace.created` → add workspace admin
  - `account.member.joined` → add workspace member
  - `workspace.project.member.added` → add project viewer/editor
  - `workspace.meeting.project.assigned` → add meeting → project relation
- Expose `POST /check` (BatchCheck wrapper) for other services to call

### 2c — Postgres RLS

Every table in every service must have row-level security on `workspace_id`. Pattern:

```sql
ALTER TABLE transcript_segment ENABLE ROW LEVEL SECURITY;

CREATE POLICY workspace_isolation ON transcript_segment
  USING (workspace_id = current_setting('app.workspace_id')::uuid);
```

The `service-kit` auth middleware sets `app.workspace_id` on the DB connection after validating the JWT. **Never bypass this.** A query that does not set `app.workspace_id` will return zero rows — that is intentional.

**Tests (all required):**
- Tenant-isolation suite: seed two workspaces, make a request authenticated as workspace A and assert no rows from workspace B are returned, on every table
- RLS bypass attempt: connect directly with the DB user (no `app.workspace_id` set), assert zero rows returned
- Revocation test: revoke a session, assert the next request with that token returns 401
- Auth E2E with Playwright: sign in with Google mock via WorkOS, create workspace, invite a second user, accept invite, verify both users appear in member list

**Done when:** Two seeded workspaces are fully isolated. All tests pass. Playwright E2E green.

---

## Step 3 — Calendar integration (M3, cycles 5–6)

**Branch:** `feat/calendar-integration` → PR to `dev` (after Step 2 is merged)

**Why this is yours:** Calendar sync is a well-defined API integration. Google Calendar and Microsoft Graph both have thorough documentation, and the edge cases are handled by the B4 fixtures you already built.

**Tasks:**

### 3a — `integration` service

- Fastify + Drizzle + Postgres (logical DB)
- Tables:
  - `calendar_account { id, workspace_id, user_id, provider (google|microsoft), access_token_enc, refresh_token_enc, sync_token, expires_at }`
  - `watch_channel { id, calendar_account_id, provider_channel_id, resource_id, expires_at }`
  - `calendar_event { id, workspace_id, calendar_account_id, ical_uid, series_id, instance_id, title, start_at, end_at, organizer_email, attendee_emails[], conferencing_tool, conferencing_url, is_recurring, is_cancelled, updated_at }`
- Tokens encrypted with Key Vault before storage. Never stored in plaintext.

### 3b — OAuth flows

- `GET /auth/google/start` — redirect to Google OAuth consent, read-only scopes: `calendar.readonly`, `calendar.events.readonly`
- `GET /auth/google/callback` — exchange code, encrypt and store tokens, emit `integration.calendar.connected`
- `GET /auth/microsoft/start` — redirect to Microsoft identity, scopes: `Calendars.Read`, `offline_access`
- `GET /auth/microsoft/callback` — same pattern

### 3c — Initial sync

On `integration.calendar.connected`:
1. Fetch all events from the past 90 days and the next 30 days
2. Normalize each event into `calendar_event` using the data model above
3. Deduplicate: if two `calendar_account` rows have the same `ical_uid` + `start_at`, keep one row
4. Identify external attendee domains: any attendee email domain that is not the workspace domain is a potential customer
5. For each event, emit `calendar.event.upserted` → `workspace` subscribes and creates/updates the meeting record

### 3d — Incremental sync

- Google: use `syncToken` from the last list response; on 410 Gone, full re-sync
- Microsoft: use `deltaLink` from the last delta query
- Handle `status: cancelled` → emit `calendar.event.cancelled`

### 3e — Push notifications

- Google: `POST /google/push` — Google push channel webhook; validate the `X-Goog-Channel-Token`, trigger incremental sync for that calendar
- Microsoft: `POST /microsoft/push` — Graph subscription webhook; validate the `validationToken` on subscription creation, trigger incremental sync
- Watch channel renewal: Container Apps Job runs every 6 h, renews channels expiring in < 24 h
- Nightly reconcile: Container Apps Job runs at 02:00 UTC, full delta sync for all accounts to catch missed pushes

### 3f — Event normalization rules

| Field | Rule |
|---|---|
| `series_id` | Google: `recurringEventId`; Microsoft: series master `id` |
| `instance_id` | Google: event `id`; Microsoft: occurrence `id` |
| `conferencing_tool` | Detect from URL: `zoom.us` → Zoom, `teams.microsoft.com` → Teams, `meet.google.com` → Meet |
| `is_recurring` | True if `series_id` is set |
| `is_cancelled` | Google: `status: cancelled`; Microsoft: `isCancelled: true` |

**Tests:**
- All B4 fixture files as recorded responses — each must produce the correct normalized `calendar_event` row
- DST property test: 50 random events across DST boundaries, all `start_at` values must be correct UTC
- Watch expiry: simulate a watch channel expiring; assert the renewal job creates a new one
- Token revocation: revoke a Google token mid-sync; assert the service catches the 401, marks the account as needs-reauth, and does not crash
- Live authorized suite (separate, not in main CI): event created in a real Google Calendar, visible in the web app within 5 min

**Benchmark:**
- Sync a 2-year calendar with 5,000 events: must complete in < 60 s
- Event-to-visible p95 < 5 min (via push notification path)

---

## Step 6 — Projects backend (M6, cycles 7–8)

**Branch:** `feat/projects-backend` → PR to `dev` (after Step 4 is merged, parallel to Udula's Step 5)

**Why this is yours:** Projects is backend CRUD + a rule engine. Well-defined domain logic with clear inputs and outputs.

**Tasks:**

### 6a — `workspace` service extensions

New tables (add to the existing workspace DB):
- `project { id, workspace_id, name, description, folder_id, created_by, created_at }`
- `project_folder { id, workspace_id, name, created_at }`
- `meeting_project { meeting_id, project_id, workspace_id, added_by, added_at }` — many-to-many
- `project_rule { id, project_id, workspace_id, rule_type (domain|series_title|keyword|zx_code), value, created_at }`
- `project_suggestion { id, meeting_id, project_id, workspace_id, rule_id, status (pending|accepted|rejected), created_at }`

### 6b — APIs

- `POST /projects` — create project
- `GET /projects` — list (scoped by authz)
- `PATCH /projects/:id` — rename, change folder
- `DELETE /projects/:id` — archive
- `POST /projects/:id/meetings` — manually add a meeting
- `DELETE /projects/:id/meetings/:meetingId` — remove a meeting
- `POST /projects/:id/rules` — add a routing rule
- `DELETE /projects/:id/rules/:ruleId` — delete a rule
- `POST /project-suggestions/:id/accept` — human confirms a suggestion
- `POST /project-suggestions/:id/reject` — human dismisses a suggestion

### 6c — Rules engine

When a meeting is created or updated (from `calendar.event.upserted`), the rules engine runs:

**Precedence order (highest wins):**
1. Manual assignment (already in `meeting_project` — skip)
2. Series auto-add: if the series is linked to a project and `is_recurring`, auto-add
3. Rules:
   - `domain`: any attendee email domain matches the rule value → suggest
   - `series_title`: meeting title contains the rule value (case-insensitive) → suggest
   - `keyword`: meeting description or title contains the keyword → suggest
   - `zx_code`: meeting title or description contains `ZX-{code}` → look up code in `tracking_code` table → suggest
4. AI suggestion (Phase 1: not yet; rule creates a `pending` suggestion for human to confirm)

**Customer auto-proposal:** for any external attendee domain not already in a project, create a `pending` suggestion for a new customer project. Surface to the founder's "Unsorted" review queue.

**Unsorted inbox:** meetings with no `meeting_project` row and no pending suggestion go to "Unsorted".

### 6d — OpenFGA integration

On every `meeting_project` insert or delete, write the corresponding tuple to authz:
- `meeting:{meetingId}#project → project:{projectId}`
- `project:{projectId}#viewer → user:{userId}` (when adding a member)

**Tests:**
- Labeled set of 300+ meetings with gold project assignments: rule matching must be ≥ 95 % accurate
- Permission test: user in project A cannot see a meeting that is only in project B
- Suggestion test: rule fires, suggestion created, human accepts, meeting appears in project
- Multi-membership: one meeting in two projects, removing from one does not remove from the other

**Benchmark:** project list and board `GET /projects/:id/meetings` p95 < 300 ms with 5,000 meetings in scope.

---

## Step 7 — Agenda backend (M7, cycle 8)

**Branch:** `feat/agenda-backend` → PR to `dev` (after Step 6 is merged)

**Why this is yours:** The agenda pipeline requires Service Bus scheduled messages and a series-chain lookup. These are well-defined patterns that extend the work you already did in Steps 2 and 3.

**Tasks:**

### 7a — `workspace` service extensions

New tables:
- `agenda { id, meeting_id, workspace_id, series_id, project_id, previous_section JSONB, this_section JSONB, next_section JSONB, accepted_at, accepted_by, created_at }`
- `agenda_item { id, agenda_id, workspace_id, section (previous|this|next), text, item_type (topic|decision|question|action), owner_user_id, ticked_at, ticked_by, carry_over_to_meeting_id, created_at }`
- `tracking_code { id, workspace_id, code, project_id, created_at }` — maps `ZX-{code}` to a project

### 7b — Series chain logic

For a given meeting instance, find the "previous meeting" in this order:
1. The previous instance in the same `series_id` (by `start_at DESC` where `start_at < this_meeting.start_at` and `is_cancelled = false`)
2. If no series, the last meeting in the same project where `attendee_emails` overlaps ≥ 50 % (same customer)
3. If neither, no previous meeting (the Previous section is empty)

Expose this as `GET /meetings/:id/previous-meeting-id`.

### 7c — Service Bus scheduled message at T-24 h

When a recurring meeting's `calendar_event` is created or updated with a future `start_at`:
1. Cancel any existing scheduled message for this meeting instance
2. Schedule a new Service Bus message on the `agenda-draft` topic, delivery time = `start_at - 24h`
3. Message payload: `{ meetingId, workspaceId, seriesId, previousMeetingId }`

`intelligence` subscribes to `agenda-draft` and runs the agenda draft pipeline (Step 5e in Udula's tasks). When the draft is ready, `intelligence` publishes `intelligence.agenda.drafted` → `workspace` marks the agenda as having a pending draft.

### 7d — Post-meeting carry-over

After a meeting finishes (triggered by `ingest.meeting.finalized`):
1. Load the agenda for this meeting
2. For each `agenda_item` in `this` section:
   - If `ticked_at` is set: mark `status = closed`, store `ticked_at` and segment evidence
   - If not ticked: set `carry_over_to_meeting_id` = the next instance in the series (schedule a Service Bus message to run when the next meeting's agenda is being drafted)
3. Items in the `next` section carry over automatically to `this` in the next instance

### 7e — Ad-hoc meetings

Meetings with no series get an `on-demand` agenda endpoint:
- `POST /meetings/:id/agenda/draft` — immediately triggers `intelligence` to draft an agenda (no T-24 h delay)

**Tests:**
- 6-instance series chain including one moved instance and one cancelled instance — carry-over must be correct across all 6
- T-24 h timer: reschedule the meeting by 2 h, assert the scheduled message is cancelled and a new one is created at the new T-24 h
- Cancel test: cancel the meeting, assert the scheduled message is cancelled
- Customer fallback: meeting with no series but ≥ 50 % attendee overlap with a previous meeting → correct `previous_meeting_id`

**Benchmark:** agenda draft message present at T-24 h ± 5 min for 100 % of recurring meetings in the test set.

---

## Step 9 — Hardening (shared, cycle 9)

Work with Udula and the founder:
- Build the transcript parser for TXT, VTT, and SRT upload (see `docs/UI_PAGES.md` W-12): `POST /meetings/:id/transcript` accepts a file, parses it, and inserts rows into `ingest` as if they came from the desktop
- Parser fuzzing corpus: 20 malformed files per format; parser must not crash or produce corrupt rows
- Admin APIs: `GET /workspaces/:id/settings`, `PATCH /workspaces/:id/settings`, `GET /workspaces/:id/audit-log` (admin only)
- Consent text storage: `workspace_consent { workspace_id, consent_text, updated_at, updated_by }`
- OWASP checklist on account, authz, and integration endpoints
- Help founder record exit criteria evidence in `IMPLEMENTATION_STATUS.md`

---

## Useful references

| Document | Why you need it |
|---|---|
| [`docs/architecture/03-services-and-communication.md`](../architecture/03-services-and-communication.md) | Service Bus, outbox/inbox, domain events |
| [`docs/architecture/04-data-model.md`](../architecture/04-data-model.md) | Schema for account, workspace, ingest |
| [`docs/architecture/06-integrations.md`](../architecture/06-integrations.md) | Calendar integration full spec |
| [`docs/architecture/08-security-privacy.md`](../architecture/08-security-privacy.md) | RLS rules, OpenFGA, privacy requirements |
| [`docs/architecture/09-infrastructure-operations.md`](../architecture/09-infrastructure-operations.md) | Container Apps Jobs, Service Bus scheduled messages |
| [`docs/RESOURCES.md`](../RESOURCES.md) | Links to WorkOS AuthKit, OpenFGA, pgvector docs |
