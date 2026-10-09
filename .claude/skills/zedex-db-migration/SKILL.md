---
name: zedex-db-migration
description: Design or change PostgreSQL schema, migrations, RLS policies, indexes, or retention/deletion handling in a Zedex service. Use when touching services/*/migrations, infrastructure/db, repositories, or scripts/migrate.ts.
---

# Database and migrations

Reference: `docs/architecture/04-data-model.md`, `08-security-privacy.md`. One PostgreSQL Flexible Server per cell, one logical database per service. No cross-service joins, FKs, or reads; hold foreign IDs only and learn of changes through events.

## Schema rules

- Every tenant row has `workspace_id`. Composite foreign keys inside a database include `workspace_id`.
- `ingest` is distribution-ready: `workspace_id` leads every primary key and index; no cross-workspace joins, FKs, or global sequences.
- IDs are client-stable where sync needs it (UUIDv7 for meeting, capture, segment, agenda item).
- Each service has `outbox` and `inbox` tables (see `zedex-event-contract`).
- Append-only where history matters (`segment_revision`, `commitment_event`, `audit_event`). Derived outputs store the **source revision** they were built from.
- Audit and logs hold minimal metadata, never content.
- Index every query path: B-tree on `(workspace_id, ...)`, GIN for FTS, HNSW for `retrieval_chunk.embedding`, cursor-pagination keys. State the expected query plan for any new hot query and check it with `EXPLAIN` on realistic row counts.

## RLS (defense in depth, required on every tenant table)

- Enable and **force** RLS; policy `workspace_id = current_setting('app.workspace_id')::uuid`.
- Runtime role is neither table owner nor `BYPASSRLS`. Migrations run under a separate role.
- Actor and workspace are set **transaction-locally** (`SET LOCAL`) by `service-kit` after the token is verified. A connection with no context returns zero rows by design. Never use a pooled connection state that outlives the transaction.
- Test with two seeded workspaces on every table (`zedex-authz-tenant-isolation`).

## Migration discipline

- SQL files in `services/<name>/migrations`, reviewed, **forward-only**. No down migrations in production; fix forward.
- Expand -> migrate -> contract across releases: add nullable/new structures, dual-write and backfill, switch reads, then drop in a later release. Old and new app revisions must both run against the schema during rollout.
- No destructive change (drop, rename, type narrowing, NOT NULL on populated column) in the same release as the code that stops using it.
- Backfills run batched and resumable, off the request path, with a rate limit. Avoid long locks: `CREATE INDEX CONCURRENTLY`, `NOT VALID` constraints then `VALIDATE`.
- Migrations run before the new revision receives traffic, under the migration role, from the deploy pipeline (`scripts/migrate.ts`).
- Never hold a transaction across a network or model call.

## Retention and deletion

Default retention: transcripts and notes 12 months (configurable shorter), exports 7 days, operational logs 30 days (metadata only), audit 12 months, backups 30 days. Every table holding customer content must participate in the deletion saga: block access immediately, purge within 24 h, record a tombstone, acknowledge to `workspace`. Tombstones are replayed after any restore before access reopens.

## Tests required

Real PostgreSQL via Testcontainers (never SQLite or in-memory fakes): constraints, RLS isolation, bypass attempt without context, migration applies on a populated database, old app revision still works after expand step, deletion purge. See `zedex-testing`.
