> **Plan document — do not modify.**
> This file is the agreed plan and architecture. Treat it as source of truth.
> Changes must go through a new ADR or an explicit plan revision — do not edit in place.

---

> **Production target** — this is not a prototype or MVP. Every decision here targets a production product shipped in cycles.


# Phase 1 Plan (Gate 2)

Phase 1 is the **first shippable product**. Its goal: founders dogfood their own meetings across Zoom, Teams, and Meet on macOS and Windows, and the core experience — capturing a meeting, reading a structured summary, grouping by project, seeing the agenda — is reliable, fast, and trustworthy.

**Phase 1 does not include:** live tick suggestions, commitments routing, external integrations (Linear, HubSpot, Slack), workflows, canvas, chat, AI Search, or mobile.

---

## 1. What Ships in Phase 1

### Web app — all features

| Surface | What it includes |
|---|---|
| Sign-in / onboarding | WorkOS AuthKit, Google and Microsoft sign-in, workspace creation, calendar connect |
| Meetings list | Chronological feed; filter by project, date, meeting tool; "Not captured" state shown |
| Meeting page | Transcript with speaker labels and confidence flags; typed notes; meeting card (topics, decisions, open questions, next steps); agenda panel |
| Projects | Drag-and-drop grouping; auto-rules (attendee domain, series title, keywords); "Unsorted" inbox; multi-membership; access control per project |
| Agenda editor | Three sections: Previous meeting (summary + open items), This meeting (confirmed agenda), Next-meeting plan. Drafted by AI 24 h before; human edits and accepts. |
| Preference summaries | Request a summary for chosen meetings, date range, project, or style. Built from meeting cards. Saved preferences. |
| Transcript fallback | Upload or paste TXT / VTT / SRT for meetings captured without the desktop app |
| Admin | Workspace settings, member management, consent configuration |

### Desktop shell — macOS and Windows

| Component | What it does |
|---|---|
| Thin shell | Loads the web app in a hardened window (sandbox, contextIsolation, origin allowlist, CSP). All UI other than popup/overlay is web. |
| Meeting popup | Triggered by calendar event or mic activity. Three actions: Start notes, Open prep, Dismiss. Consent reminder when policy requires. |
| Compact overlay | Agenda and notes panel, hidden from screen share by default. |
| Native capture helper | Streams mic and system audio over WebSocket to cloud STT. Gets a short-lived session token from `ingest`. Audio never passes through Zedex servers. RAM ring buffer ≤ 30 s for reconnect. Gap reporting. |
| Encrypted segment outbox | SQLite with SQLite3MultipleCiphers, key via Electron safeStorage. Holds finalized segments until `ingest` acknowledges them, then purges (ADR-029). |
| Sync | Batches transcript segments to `ingest` every ~10 s, on stop, and on reconnect. ACK after server commit. |

---

## 2. Services in Phase 1

A strict subset of the 9 services. Later services are not introduced until their gate.

| Service | Phase 1 responsibility |
|---|---|
| `account` (global) | Users, sessions, workspaces, teams, roles, entitlements, cell directory, WorkOS integration |
| `workspace` | Projects (rules, membership, access), meetings (metadata, status), notes, agendas, meeting cards, summary preferences |
| `ingest` | Transcript segment sync, STT session tokens (`POST /speech-sessions`), finalization, segment revisions, sharded by workspace_id |
| `integration` | Google Calendar and Microsoft Outlook sync — events, attendees, conferencing links, watch channels, delta tokens |
| `authz` | OpenFGA relationship tuples for workspace membership, team, project access, meeting access |
| `intelligence` | Chunk notes, meeting cards, agenda drafts, preference summaries, embeddings and Postgres retrieval index, using Azure OpenAI (ADR-029) |

**Not in Phase 1 (Gate 3+):** `live`, `notification`, `reporting`, `workflow`. Model calls never run inside `workspace`; `intelligence` owns them from Phase 1 (ADR-029).

**Team assignments:** see [TEAM_TASKS.md](TEAM_TASKS.md) for branch management, ownership per service, and the full dependency order. Individual task files: [Udula](tasks/UDULA_TASKS.md) · [Sinthujan](tasks/SINTHUJAN_TASKS.md) · [Thano](tasks/THANO_TASKS.md).

**Infrastructure:**
- Azure Front Door Standard + WAF custom rules; web app as static assets in Blob Storage
- Azure Container Apps (consumption) and Container Apps Jobs for calendar renewal and reconcile
- Azure Service Bus Standard (one topic per producing service; managed-identity access only)
- One PostgreSQL Flexible Server per cell, logical database per service
- Postgres full-text search + pgvector for search (no Azure AI Search until Phase 2)
- No Redis (budgets are PostgreSQL counters; rate limits at Front Door)

---

## 3. User Flows

### 3.1 First use (desktop install)

1. User downloads and installs the desktop app (~80–100 MB).
2. App opens the web sign-in in the shell window. User signs in with Google or Microsoft.
3. Onboarding: workspace name → connect calendar → consent acknowledgement.
4. Meeting popup appears automatically when the next calendar event starts.

### 3.2 Capturing a meeting

1. A calendar event with a conferencing link starts within 2 minutes. The meeting popup appears.
2. User clicks **Start notes**. The popup shows consent reminder if policy requires it.
3. The native helper begins streaming mic and system audio to the cloud STT provider.
4. The capture health indicator shows sources and levels in the overlay.
5. The compact overlay shows the accepted agenda and a notes field.
6. User types notes during the meeting. Notes are timestamped and merged into the meeting card.
7. User ends the meeting (or helper detects silence for 5 min). Capture stops. Final segments are synced.
8. A meeting card is generated (chunk notes → meeting card pipeline). User sees the meeting page.

### 3.3 Using the meeting page

1. Transcript is shown with speaker labels ("You" / "Others") and confidence flags on uncertain values.
2. The meeting card shows structured summary, with each AI sentence linking to a transcript segment.
3. User edits the card directly. User text and AI text are visually distinct.
4. Flagged values (numbers, dates, names) are highlighted. User verifies or corrects each.

### 3.4 Organizing by Project

1. User creates a Project ("Acme Corp", "Q4 Planning", "Internal").
2. User adds rules: attendee domain, series title contains, keywords.
3. New meetings matching the rules are auto-suggested to the project (one-click confirm, never silent).
4. Meetings with no project go to the "Unsorted" inbox.
5. A meeting can be in multiple projects. Moving a meeting re-scopes its summaries.

### 3.5 Agenda

1. 24 h before a recurring meeting, the AI drafts the agenda from:
   - Open items from the previous meeting in the series.
   - Items added manually by attendees.
   - Any open commitments from this project (later phase).
2. The organizer reviews, edits, and accepts. Nothing is auto-accepted.
3. During the meeting, the overlay shows the accepted agenda.
4. After the meeting, the "Previous meeting" section carries forward to the next agenda draft.

### 3.6 Preference summaries

1. User opens "Summaries" on a project or meeting.
2. User sets preferences: style (executive / detailed / bullet), focus (decisions / commitments / blockers), date range, specific meetings.
3. System generates a summary from meeting cards (not raw transcripts).
4. User can save the preference set and re-run it later.

---

## 4. Milestones

| Milestone | Cycle | Done when |
|---|---|---|
| M1: Infrastructure up | 4 | Azure cell running; `account` service deployable; CI green |
| M2: Auth and workspace | 4–5 | Sign-in, workspace create, member invite, OpenFGA tuples, RLS verified |
| M3: Calendar sync | 5–6 | Google and Microsoft events syncing; watch channels renewing; dedup working |
| M4: Capture + sync | 6–7 | Helper streaming to STT; segments arriving in `ingest`; transcript visible in web |
| M5: Meeting card | 7–8 | Chunk notes and meeting card generated; confidence flags visible; typed notes merged |
| M6: Projects | 7–8 | Create/edit projects; auto-rules; suggestions (not silent); Unsorted inbox; access control |
| M7: Agenda | 8–9 | Draft generated 24 h before; human accepts; Previous/This/Next sections working |
| M8: Preference summaries | 8–9 | On-request summaries from meeting cards; saved preferences; correct scoping |
| M9: Dogfood | 9 | Founders capture their own meetings on macOS + Windows across Zoom, Teams, Meet |

---

## 5. Exit Criteria

Gate 2 closes when **all** of the following are verified with evidence recorded in IMPLEMENTATION_STATUS.md:

- [ ] Founders have used Phase 1 for their own meetings for at least 2 weeks.
- [ ] Capture works on macOS 14.2+ arm64, macOS 14.2+ x64, Windows 11 x64 with Zoom, Teams, and Google Meet.
- [ ] Transcript accuracy benchmark: < 5 % WER on a reference set of 10 hours of English business meetings.
- [ ] Confidence flags correctly mark ≥ 90 % of numbers and dates that differ from the transcript in test cases.
- [ ] Meeting card generated within 60 s of meeting end for a 1-hour meeting.
- [ ] Preference summaries generated on request within 30 s.
- [ ] Google and Microsoft calendar sync: events appear within 5 min of creation.
- [ ] Project auto-rules: correct match rate ≥ 95 % on a labeled test set.
- [ ] Agenda draft available 24 h before a meeting in a recurring series.
- [ ] Tenant isolation: cross-workspace data access blocked in all security tests.
- [ ] Idempotency: duplicate segment push does not create duplicate records.
- [ ] Desktop shell: no navigation outside the allowlist; CSP violations logged.
- [ ] All privacy invariants verified by author + reviewer on every PR.
- [ ] No critical or high CodeQL findings.
- [ ] IMPLEMENTATION_STATUS.md reflects each delivered item.

---

## 6. Out of Scope for Phase 1

The following features are in the plan but are explicitly **not** in Phase 1:

| Feature | Gate |
|---|---|
| Live tick suggestions | 3 |
| AI catch-up brief | 3 |
| Scoped search and chat | 3 |
| Notes editor templates | 3 |
| Commitments and approvals | 4 |
| External integrations (Linear, HubSpot, Slack, Google Docs) | 4 |
| Stripe billing | 4 |
| Workflow canvas | 5 |
| Zoom RTMS per-participant audio | Later ADR |
| Speaker naming beyond "You" / "Others" | Later |
| Local ASR enterprise privacy mode | Later ADR |
| Browser tab capture (no-install) | Later |
| Mobile app | 6 |

See [TECHNICAL_RISKS.md](TECHNICAL_RISKS.md) for the risk register covering every feature.
