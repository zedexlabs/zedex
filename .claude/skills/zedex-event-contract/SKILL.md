---
name: zedex-event-contract
description: Add, change, or consume a domain event, command, or Service Bus message in Zedex (naming, payload rules, versioning, outbox/inbox, ordering, dead-letter, AsyncAPI). Use for anything under packages/contracts events/commands or services/*/consumers and infrastructure/messaging.
---

# Events and commands

Events record facts. Commands request work. HTTP is for client-facing queries and commands only. Reference: `docs/architecture/03-services-and-communication.md` (event catalogue, commands, sagas).

## Define (contracts first)

- Zod schema in `packages/contracts/src/events` or `.../commands`; update `packages/contracts/asyncapi.yaml`.
- Event type name: `domain.entity.verb.v{n}`, e.g. `workspace.commitment.confirmed.v1`. One topic per producing service.
- Payload carries identifiers, revision numbers, and `workspaceId` only. **Never content** (no transcript, note, or commitment text). Consumers fetch content with their own authorization.
- Envelope: event id (used as inbox key), type, `workspaceId`, occurred-at, trace context, payload.
- Commands go to queues owned by the receiver and carry the initiating actor; the receiver rechecks permission before acting.

## Evolve

- Additive changes only. A breaking change publishes a new `v{n+1}` alongside the old one until every consumer migrates, then retire the old one via a plan revision.
- Adding an event to the catalogue in doc 03 is a plan revision; record it with the ADR or revision, not an in-place edit.

## Produce

- Domain change and outbox row commit in one transaction (`service-kit` outbox). A relay publishes at-least-once. Never publish directly from a handler, and never publish before commit.
- Realtime fan-out (Web PubSub groups `ws:{id}`, `meeting:{id}`, `agenda:{id}`) happens after commit.

## Consume

- Insert the message ID into the inbox first; a duplicate is skipped. Handlers must be idempotent anyway.
- Handlers call the application layer only. Recheck authorization where the effect is user-visible.
- Ordering: Service Bus sessions keyed by `meetingId` (ingest, intelligence) or `runId` (workflow). Do not assume global order; handle out-of-order and replays (compare source revision).
- Retries: exponential backoff with jitter, bounded attempts, then dead-letter with an alert. A poison message must never block the queue.
- Timers: Service Bus scheduled messages for per-entity timers (agenda draft at T-24 h; cancel and reschedule when the meeting moves or is cancelled). Cron work uses Container Apps Jobs.
- Local dev and CI use the Service Bus emulator. Cell Service Bus is Standard in Phase 1 with SAS disabled and managed identity only.

## Deletion and revocation

Events that affect access or deletion (`workspace.share.changed.v1`, `workspace.content.deleted.v1`, `account.membership.changed.v1`) must invalidate derived content and caches. A consumer that holds copies must implement purge and acknowledgement for the deletion saga (purge within 24 h; tombstones replayed after restore).

## Tests required

Contract test (schema valid and diffed for breaking changes via AsyncAPI), duplicate delivery, out-of-order delivery, consumer crash mid-handle then redelivery, outbox rollback when the transaction fails, dead-letter path. See `zedex-testing`.
