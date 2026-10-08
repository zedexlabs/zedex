> **Plan document — do not modify.**
> This file is the agreed plan and architecture. Treat it as source of truth.
> Changes must go through a new ADR or an explicit plan revision — do not edit in place.

---

> **Production target** — this is not a prototype or MVP. Every decision here targets a production product shipped in cycles.


# 04 — Data Model

Each service owns one logical database. No cross-service joins; services hold foreign IDs only and learn about changes through events. Every tenant row carries `workspace_id`, with composite foreign keys inside a database and RLS as defense in depth. The runtime role is neither table owner nor `BYPASSRLS`; the actor and workspace are set transaction-locally; migrations use a separate role.

## account (global)

`user`, `identity`, `session`, `workspace` (cell_id, region, plan), `membership` (role), `team`, `team_member`, `invitation`, `entitlement`, `feature_flag`, `subscription`, `usage_meter`, `cell`.

## workspace (cell)

| Group | Tables |
|---|---|
| Organization | `project` (parent_id, one nested level), `account_company`, `person`, `series`, `context_association` (meeting ↔ project/account/team/series; source: manual, series, rule, code, ai), `routing_rule`, `tracking_code`, `saved_view` (AI Channels) |
| Meetings | `meeting` (occurrence), `capture_ref`, `coverage_assignment`, `consent_notice`, `note` (+ revisions), `highlight`, `import_ref` |
| Prep | `agenda`, `agenda_item` (source ref, evidence ref, proposer, owner, time box, status), `agenda_contribution`, `context_attachment` (text, links, picked docs) |
| Outcomes | `decision` (+ supersession), `commitment` (owner, date, state, evidence), `commitment_event` |
| Sharing | `share` (user/group/team/project/workspace) |
| Governance | `audit_event` (minimal metadata), `deletion_tombstone` |
| Messaging | `outbox`, `inbox` |

**Agenda item states:** `proposed → accepted → discussed → covered | deferred`.

**Commitment states:** `proposed → confirmed → in_delivery → delivered → closed`, plus `declined`. Closure needs an owner or approved evidence. Creating a task is not delivery.

**Association sources and precedence:** manual > series auto-add > rule/code > AI (only after confirmation). Association never changes access; access comes from authz tuples.

## ingest (cell, distribution-ready by workspace_id)

`workspace_id` leads every primary key and index; no cross-workspace joins, foreign keys, or global sequences. Starts as a logical database; moves to an elastic cluster on the ADR-029 trigger.


`capture` (meeting, device owner, sources), `source` (microphone | meeting_audio), `segment` (client ID, sequence, start/end, text, source, **kind** [transcript | user_note], **word_confidence** [JSON word-level scores from STT provider]), `segment_revision` (append-only; reason), `sync_batch` (idempotency key, request hash, ack state), `gap` (interval, reason), `finalization`, `speech_session` (short-lived STT provider token; workspace policy and consent checked before issue), `outbox`, `inbox`.

**Segment kinds:**
- `transcript` — finalized STT output. Word-level confidence scores stored; words below threshold are flagged `unverified`.
- `user_note` — typed by the user during the meeting; always considered authoritative.

Retention follows workspace policy (default 12 months). Several captures for one meeting stay separate. A complete authorized source is selected for downstream use; duplicates are never auto-concatenated, and private content never merges into shared material.

## integration (cell)

`connection` (provider, scopes, health, owner), `token` (encrypted, Key Vault key reference), `calendar_account`, `calendar_subscription` (cursor, expiry), `calendar_event` (provider ID, recurrence, conferencing link, attendees), `external_ref` (internal ID ↔ provider ID), `operation_attempt` (payload hash, outcome), `webhook_event` (signature verified), `provider_transcript_import`, `outbox`, `inbox`.

## workspace additions for Phase 1

Added to `workspace` (user-owned records, ADR-029):
- `card_edit` (meeting_card_id, item_id, edit JSON, verified_values JSON, editor_id, version) — user edits and value verifications, preserved when the card is regenerated.
- `summary_preference` (owner_id, name, style, length, focus, date_range?, project_id?, meeting_ids?, created_at) — saved summary preferences.
- `agenda_item` gains columns: `previous_meeting_ref` (link to the previous meeting's item), `section` (previous | current | next).

**Agenda item sections:**
- `previous` — carried from the prior meeting in the series; read-only in the current meeting.
- `current` — items for this meeting; editable before and during.
- `next` — planned items for the next meeting; editable at any time.

## intelligence (cell)

Generated artefacts (Gate 2):
- `chunk_note` (capture_id, window_start, window_end, content JSON, flagged_values JSON, source_segment_ids, created_at) — built during the meeting every ~5 min.
- `meeting_card` (meeting_id, source_revision, chunk_note_ids, content JSON, flagged_values JSON, model/prompt version, created_at, invalidated_at) — built from chunk notes after finalization.
- `summary_run` (requester, preference snapshot, source card IDs, output JSON, created_at, invalidated_at) — preference summaries built from meeting cards.
- `retrieval_chunk` (workspace_id, meeting_id, segment_range, principal_set, text, tsvector, embedding vector, source_revision).

Later gates: `summary` (source revision, template version, model/prompt version), `proposal` (decision | commitment | question | blocker, evidence refs, confidence), `brief`, `catch_up`, `agenda_draft`, `alert_rule`, `alert_match`, `chat_thread`, `chat_message` (citations), `index_state`, `prompt_run` (metadata only), `outbox`, `inbox`.

Summaries and proposals store the **source revision** they were built from. If the source changes or access is revoked, the output is invalidated and rebuilt. Unknown owners and dates stay null.

## notification, reporting, workflow

| Service | Tables |
|---|---|
| notification | `preference`, `delivery`, `digest`, `template`, `scheduled_brief` |
| reporting | `report_definition`, `report_run`, `export` (expires in 7 days), `rollup_team_period`, `rollup_series_health`, `rollup_commitment_cycle` |
| workflow | `workflow`, `workflow_version` (typed DAG JSON), `trigger`, `run`, `step`, `approval` (exact payload hash, reviewer, destination), `operation` (ledger), `schedule`, `template` |

## Indexing and search

- PostgreSQL: B-tree on `(workspace_id, …)` access paths; GIN for FTS; HNSW (pgvector) on `retrieval_chunk.embedding` in `intelligence`; cursor pagination keys. Queries filter by workspace and principal set, then `BatchCheck` before results are shown or cited.
- If the ADR-029 retrieval trigger fires, Azure AI Search becomes a derived index with fields: `workspaceId`, `principalSet`, `meetingId`, `segmentRange`, `text`, `vector`, `sourceRevision`. Queries filter by workspace and principal set, then `BatchCheck` before results are shown or cited.

## Retention and deletion

| Data | Default |
|---|---|
| Raw audio, partial text | Memory only / until final |
| Transcripts and notes | 12 months, configurable shorter |
| Derived content | Source policy |
| Exports | 7 days |
| Operational logs | 30 days, metadata only |
| Audit | 12 months |
| Backups | 30 days |

Deletion immediately blocks retrieval and operations, purges active content and indexes within 24 h, and invalidates derived outputs. Tombstones outside the restore boundary are replayed before access reopens. Content already exported to external tools cannot be recalled automatically.
