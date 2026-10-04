# 06 — Integrations

All integrations live in the `integration` service behind adapters in `packages/connector-sdk`. External tools stay authoritative for their records. Recheck each provider's documentation at implementation and record API versions and scopes next to the adapter.

## Calendars (Gate 2)

| Provider | Mechanism | Scope |
|---|---|---|
| Google Calendar | Incremental sync with sync tokens + push channels | Read-only |
| Microsoft 365 | Graph delta query + change notifications | Read-only |

- Multiple calendars per user, recurrence and exceptions, reschedule/cancel/timezone, duplicate reconciliation, subscription renewal, refresh and revoke.
- Notifications only trigger reconciliation; the provider is the source of truth for events.
- Extracted per event: title, time, attendees, conferencing link, series ID, and any `ZX-` code.
- Calendar consent is separate from sign-in.

## Tracking codes (Gate 2 detect, Gate 5 write)

- Format `ZX-<CONTEXT>[-<SERIES>]`, workspace-scoped. A code is a routing hint and never grants access.
- Detection is read-only in calendar title, description, and location. Unknown codes, or codes pointing at contexts the organizer cannot access, are ignored.
- Routing precedence: manual > series auto-add > rules (attendee domain → account, series → project, organizer's team → team space) / code > AI suggestion with confirmation.
- Gate 5 (opt-in, separate consent): calendar write scope to stamp codes and agenda links into invites.
- Attribution chain: meeting → confirmed commitments → external references → outcome. Reporting aggregates by team, project, and code only. There is no per-person scoring.

## Connector capability contract

Every adapter implements: `health`, `lookup`, `draft`, `executeApproved(payload)`, `status`, `validateWebhook`, `revoke`, `reconcile`.

- Writes happen only through `executeApproved` with an approved payload hash.
- Permission and connection are rechecked immediately before the write.
- Outcomes: `succeeded`, `failed`, or `uncertain`. An uncertain outcome is reconciled by lookup using an idempotency marker, never blindly retried.
- Rate limits are honored with bounded retries and per-provider egress budgets.

## Connector order

| Gate | Connector | Use |
|---|---|---|
| 2 | Google Calendar, Microsoft calendar | Read-only events |
| 4 | HubSpot | Contact/deal association, notes, tasks, field updates |
| 4 | Linear | Create and track issues; status back to commitments |
| 4 | Slack | Post summaries, send briefs, approval prompts |
| 4 | Google Docs | Export notes, agendas, reports; import user-picked docs as context |
| 5 | Notion | Same document contract |
| 5 | Jira, Microsoft Teams | Issues; notifications |
| 5 | Webhooks, public API, MCP server | Outbound events; programmatic access |
| 5 | Zoom/Meet/Teams provider transcripts | Admin opt-in text import |
| 6 | Salesforce, Attio, Confluence | Demand-gated |

## Google Docs

- Scope `drive.file` only: files Zedex creates or the user picks (Google Picker). No broad Drive access.
- Export is a user-initiated write: notes, agenda, report, or brief into a new Doc.
- Import: a user-picked Doc becomes text context for agendas and Projects. Imported documents are untrusted input and follow their source's retention and deletion.

## Text imports (Gate 3)

TXT, MD, VTT, SRT with bounded type and size. Imports normalize to segments without claiming verified speakers or coverage. No audio import.

## Provider transcripts (Gate 5, admin opt-in)

Read-only text APIs after the meeting. Items are labelled "provider transcript" with no coverage or speaker guarantees. Zedex never requests audio or video.

## Webhooks

Inbound webhooks verify signatures, are deduplicated, and publish events. Outbound webhooks (Gate 5) are signed, retried with backoff, and carry identifiers only.

## Credentials

OAuth tokens are encrypted with Key Vault-managed keys, scoped minimally, refreshed centrally, and revocable. Provider secrets never appear in source, logs, fixtures, or client bundles.
