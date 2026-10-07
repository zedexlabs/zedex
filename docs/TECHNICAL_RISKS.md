> **Plan document — do not modify.**
> This file is the agreed plan and architecture. Treat it as source of truth.
> Changes must go through a new ADR or an explicit plan revision — do not edit in place.

---

> **Production target** — this is not a prototype or MVP. Every decision here targets a production product shipped in cycles.


# Technical Risk Register

Every significant feature carries technical risks. This register names them, states the planned mitigation, and tracks which gate the feature belongs to. A row is added when a feature is scoped; it is updated when a mitigation is verified.

---

## Phase 1 (Gate 2) Features

### Google Calendar integration

| Risk | Mitigation |
|---|---|
| Sensitive-scope verification takes weeks; unverified apps are capped at 100 test users | Start Google Workspace API verification in Gate 1, week 1. Use read-only Calendar scope only. |
| Watch channels expire (max 7 days) | Scheduled renewal job in `integration`; renew at 6 days; fallback to polling on missed renewal |
| Recurring-event exceptions are complex (modified occurrences, cancellations, time zone overrides) | Dedupe by `iCalUID` + occurrence time; handle EXDATE and RECURRENCE-ID in the parser |
| HTTP 410 on a watch channel forces a full resync | Detect 410, drop sync token, do a full page-by-page resync, then re-register the watch |
| Time-zone handling on events (organizer TZ vs attendee TZ) | Store event in UTC; display in user's local TZ |

### Microsoft Outlook / Graph Calendar integration

| Risk | Mitigation |
|---|---|
| Tenant admin consent required for Graph access | Ship an admin-consent guide; show a clear "contact your admin" screen |
| Graph subscriptions expire in 1–3 days | Renewal scheduler at 80 % of expiry; detect 410, re-subscribe and resync |
| Delta-token edge cases (token expiry, token invalidation) | Detect delta-token errors, fall back to initial sync, log and alert |

### Duplicate meetings (same event on multiple calendars)

| Risk | Mitigation |
|---|---|
| Same meeting from Google + Outlook both sync | Dedupe by `iCalUID` + organizer email + start time; prefer the organizer's calendar source |

### Project separation

| Risk | Mitigation |
|---|---|
| Ambiguous meetings (mixed customer + internal attendees) | Rules produce a confidence score; below threshold = suggestion not silent assignment; "Unsorted" inbox |
| Renamed series break auto-rules | Rules match on attendee domain and recurring event UID, not only title |
| One meeting should be in multiple projects | Multi-membership model; access scope is the union of project rules |
| Permissions: can a project member see all meetings in the project? | Access per meeting, not per project; project is a grouping label, not a permission boundary |
| Moving a meeting between projects invalidates scoped summaries | On project reassignment, queue preference summaries for rebuild |

### Desktop capture helper

| Risk | Mitigation |
|---|---|
| macOS audio permission dialog | Permission onboarding screen before first capture attempt; detect and re-prompt if revoked |
| Windows loopback device not available on some hardware | Detect at startup; show a clear error with advice; document supported configurations |
| Echo: mic also picks up "Others" audio from speakers | Apply echo cancellation on the mic stream at the VAD stage; dedupe identical tokens in overlap |
| Lid close / sleep pauses capture | Handle `NSWorkspaceWillSleepNotification` (macOS) and `PBT_APMSUSPEND` (Windows); record gap; resume on wake |
| Audio device change mid-call (headphones plugged in) | Watch for `deviceChanged` event from the helper; reconfigure capture on device change; record brief gap |
| Capture health not visible to user | Visible indicator in overlay at all times; gap events surfaced immediately |

### Cloud STT

| Risk | Mitigation |
|---|---|
| Provider outage | Second provider benchmarked at Gate 1; switch is config-driven; fallback path tested |
| Cost growth beyond forecast | Per-workspace monthly budget enforced by `ingest`; approaching-limit and limit alerts |
| Accuracy on proper names | Keyterm prompting per project (customer names, product names, people); populated from calendar events |
| Numbers, dates, money misheard | Confidence flags + `unverified` state in the meeting card (ADR-024); human verification required before confirming |
| Consent obligations (GDPR, CCPA) | Generated consent message shown to all participants when policy requires; admin-configurable; audit log |
| Provider retains audio | Require zero-retention terms and DPA from chosen provider; verify in Gate 1 legal review |

### Transcript upload / paste (no-install users)

| Risk | Mitigation |
|---|---|
| Users paste malformed or encoding-broken files | Validate and sanitize on ingest; reject with a clear error message |
| Attribution unclear (no "You" / "Others" separation) | Fallback: single-speaker or speaker-labeled if VTT includes names |

### Agenda (previous / this meeting / next-meeting plan)

| Risk | Mitigation |
|---|---|
| Finding the right "previous" meeting for a series | Link by recurring event UID, then project, then attendee overlap; user override always available |
| First meeting in a series has no history | Draft is empty; user adds items manually; no hallucinated carry-overs |
| Stale or invented items from old carry-overs | Items carried forward more than twice trigger a "still relevant?" prompt; humans accept |
| Edit conflicts (two attendees edit simultaneously) | Optimistic versioning in `workspace`; last-write-wins with a visible conflict indicator |
| Sharing agenda leaks internal notes to customers | Internal vs shareable sections; sharing is opt-in per section |
| Drafted items not grounded in evidence | Every AI-drafted item cites its source segment or meeting card; `unverified` if no source |

### Preference summaries

| Risk | Mitigation |
|---|---|
| Cost of summarising everything automatically | Only meeting cards are generated automatically; rollups are on-request or on a user schedule |
| Long rollups fail or degrade | Layered summarisation (ADR-027): rollups built from meeting cards, not raw transcripts |
| Permission leak across meetings | Summaries scoped to meetings the requester can access; checked via OpenFGA before generation |
| Stale after transcript revision | Affected chunk and meeting card are invalidated and queued for rebuild; summaries built from cards pick up the rebuild |
| Inconsistent style across a project | Saved preference sets (style, length, focus) applied consistently per request |

### Typed notes

| Risk | Mitigation |
|---|---|
| Clock skew between note timestamp and transcript timestamp | Note timestamps use the shell or browser clock, aligned to the nearest finalized segment timestamp on sync |
| Two attendees editing the same note | Per-user note ownership; notes are not shared by default; sharing is opt-in |

### Thin desktop shell (web app loaded remotely)

| Risk | Mitigation |
|---|---|
| Security of remotely loaded content | ADR-025 hardening: sandbox, contextIsolation, origin allowlist, CSP, narrow preload API |
| Shell loads a compromised version of the web app | Certificate pinning and integrity checks on the allowed origin; alert on unexpected content changes |
| Web app is unreachable (network outage) | The helper continues capturing; segments are buffered locally in SQLite; sync resumes on reconnect |

### Tenancy and cross-workspace isolation

| Risk | Mitigation |
|---|---|
| Cross-workspace data leak | Postgres RLS on `workspace_id` in every table; OpenFGA check on every HTTP read; both verified by security tests |
| AI rollup accidentally includes meetings from another workspace | Rollup pipeline always scopes queries through OpenFGA ListObjects before fetching any meeting card |

---

## Phase 2 / Gate 3 Features

### Live tick suggestions

| Risk | Mitigation |
|---|---|
| Latency too high for real-time feel | `live` service is stateless, deployed in the same region as the cell; stream WebSocket per meeting; target p95 < 2 s |
| Too many false-positive suggestions | Confidence threshold tuned by evaluation corpus; suggestions are soft highlights, not auto-ticks |
| `live` service overloaded during peak (end of hour) | KEDA scaling on queue depth; rate limit per workspace; degrade gracefully (stop sending suggestions, capture continues) |

### Catch-up brief

| Risk | Mitigation |
|---|---|
| Brief built from meeting the recipient can't access | Source meetings checked via OpenFGA before brief is generated; "Not captured" shown if no authorized source |
| Brief scheduled too early (meeting not yet finalized) | Brief job waits for finalization event or uses meeting card if partially ready |

### AI Search

| Risk | Mitigation |
|---|---|
| Security trimming fails on vector results | Pre-filter by OpenFGA principal set; batch-recheck top-N results before returning |
| Azure AI Search cost at pilot scale | Monitor per-workspace index size; cap index growth by tier |

---

## Phase 3 / Gate 4 Features

### Commitments and exact-payload approvals

| Risk | Mitigation |
|---|---|
| Duplicate write to external system (Linear, HubSpot) | Idempotency key on every external write; operation ledger in `workflow`; dedup on external reference ID |
| User approves a payload then the integration fails | Write is retried with the same idempotency key; user sees the failure and can re-approve or cancel |
| Uncertain value in an approved commitment | Value flagged `unverified` at proposal time; user must verify before approval is possible |

### HubSpot / Linear / Slack / Google Docs connectors

| Risk | Mitigation |
|---|---|
| OAuth token expiry during a sync | Token refresh in `integration`; circuit breaker on 401; user prompted to re-authorize if refresh fails |
| Rate limits on external APIs | Per-connector rate limiter; backoff + retry; alert when sustained |

---

## Phase 4 / Gate 5 Features

### Calendar write (opt-in)

| Risk | Mitigation |
|---|---|
| Write to wrong recurring event instance | Show the exact event and time before writing; write requires separate opt-in consent from sign-in consent |
| Google write permission scope rejected by workspace admin | Document and surface clearly in the admin-consent guide; graceful fallback to read-only |

### Public API / webhooks

| Risk | Mitigation |
|---|---|
| Webhook destination is attacker-controlled | Verify destination ownership; HMAC signature on every payload |
| API key leaks | Rotate on detection; audit all uses; never log key values |

---

## Later-Phase Features

### Zoom RTMS per-participant audio

| Risk | Mitigation |
|---|---|
| RTMS partner approval process is long | Start Zoom RTMS application when Zoom is a meaningful source of revenue |
| Per-participant streams require speaker diarization | Use RTMS-provided speaker IDs; no local diarization needed |

### Local ASR enterprise privacy mode

| Risk | Mitigation |
|---|---|
| Model quality vs cloud STT on business vocabulary | Gate 1 benchmark results guide whether local is viable; document the gap |
| Model download size (80–300 MB) | Separate download flow; admin-only config; not in default install |

### Speaker naming beyond "You" / "Others"

| Risk | Mitigation |
|---|---|
| Diarization quality (who said what) | Rely on RTMS when available; otherwise use attendee name hints from calendar + VAD silence gaps as heuristic |

### Mobile app

| Risk | Mitigation |
|---|---|
| No capture on mobile (no Core Audio or WASAPI equivalent) | Mobile is viewer-only (read meeting cards, summaries, agenda); capture stays on desktop |

---

## Register maintenance

- When a risk is verified mitigated (tested in CI or by a Gate review), add a ✓ and the date.
- When a new feature is scoped (a new ADR or gate change), add its rows.
- Do not remove rows; superseded mitigations are crossed out with a note.
