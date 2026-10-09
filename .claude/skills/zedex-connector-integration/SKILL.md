---
name: zedex-connector-integration
description: Build or change calendar sync, connectors, webhooks, token storage, and approved external writes (Linear, HubSpot, Slack, Google Docs). Use for services/integration, packages/connector-sdk, and workflow operations that write outside Zedex.
---

# Connectors and external writes

Reference: `docs/architecture/06-integrations.md`, `07-workflows-canvas.md`, `docs/architecture/03-services-and-communication.md` (external-write saga). Add a connector by implementing the `packages/connector-sdk` capability contract and passing its test harness; extend an existing adapter before creating anything new.

## Access and secrets

- Calendars are read-only by default (`calendar.readonly` scopes; Graph `Calendars.Read` + `offline_access`). Optional write only at Gate 5 with consent.
- Least-privilege scopes per capability. Tokens encrypted with Key Vault keys; never stored plaintext, logged, or sent to the client. Refresh centrally; revoke on membership change. A revoked or expired grant marks the account `needs-reauth` and does not crash the sync.
- Inbound webhooks: verify provider signature or channel token and timestamp, reject replays, dedupe by delivery ID, respond fast and process async. Treat payloads as untrusted.
- Outbound egress has per-workspace budgets and provider rate-limit handling (honor `Retry-After`, jittered backoff).

## Calendar sync

- Initial sync then incremental: Google `syncToken` (on 410, full resync), Microsoft `deltaLink`. Push channels renewed by a Container Apps Job before expiry; nightly reconcile catches missed pushes.
- Normalize series vs instance IDs, cancellations, moved instances, exceptions, time zones, DST, all-day and multi-day, private events, missing or multiple conferencing links, duplicate events across attendees (`ical_uid` + start).
- Store UTC plus original zone. Property-test DST boundaries. Build fixtures from recorded provider responses; the live provider suite runs only with explicit authorization.
- Emit `integration.calendar.event.changed.v1`; never write meeting content into the integration database.

## External writes (exact-payload approval)

1. A workflow proposes an operation; the user sees the exact payload and destination in `ApprovalPanel` and approves. Approval stores the payload hash.
2. Permission is rechecked at execution time (`integration.execute-operation`). Editing the payload after approval invalidates it.
3. The call carries an idempotency marker; each attempt is recorded in `operation_attempt` / the operation ledger with payload hash and outcome.
4. Ambiguous outcome (timeout, 5xx after send) becomes `uncertain`. Reconcile by **lookup** of the external object. Never blind-retry a non-idempotent write.
5. Duplicate prevention: check `external_ref` (internal ID <-> provider ID) before creating. Creating a task is not delivery; delivery needs external status or approved evidence.

## Tests required

Recorded-response fixtures for every edge case above, token revocation mid-sync, watch expiry and renewal, webhook forgery and replay, rate limit, edited-approval invalidation, uncertain-write reconciliation, duplicate prevention, and scope-minimality assertion. Sync of a 2-year, 5,000-event calendar completes in < 60 s; event-to-visible p95 < 5 min through push.
