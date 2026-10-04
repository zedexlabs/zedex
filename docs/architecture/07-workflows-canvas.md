# 07 — Workflows and Canvas

## Concepts

| Concept | Meaning | Gate |
|---|---|---|
| Prompt | Read-only AI output (follow-up draft, PRD, extraction). No external effect | 3 |
| Workflow | Versioned typed DAG that can organize content and propose external writes | 4 |
| Canvas | Visual editor over the same DAGs | 5 |

There is one engine. The canvas never gets private capabilities.

## DAG schema (`packages/contracts/workflow`)

```text
Workflow { id, workspaceId, name, version, enabled, trigger, nodes[], edges[] }
Node     { id, type, config, position? }
Edge     { from, to, condition? }
```

Definitions are validated at save and again at run. Published versions are immutable; edits create a new version and invalidate pending approvals from older ones.

## Node catalog

| Category | Nodes |
|---|---|
| Triggers | meeting finalized, meeting in Project/series, tracking code detected, commitment confirmed, external status changed, schedule |
| Conditions | team, account, meeting type, keyword, owner present, status |
| AI steps | extract, summarize, draft (from the prompt registry) |
| Organize (internal, no approval) | add to Project, assign team, tag, add to agenda |
| External actions | create/update Linear or Jira issue, HubSpot update, Slack post, Google Doc create, email draft |
| **Approval** | Inserted automatically before every external action |
| Control | wait/delay, fan-out, join |

No arbitrary code nodes. New nodes are added to the catalog through the registry with schema, permissions, and tests.

## Engine

- Trigger events create a `run` and enqueue its first steps on a Service Bus session keyed by `runId`.
- Each step is idempotent, records its input hash and output, and is retried with backoff.
- Timers use scheduled messages.
- **Approval step:** renders the exact payload (destination, fields, text) for a reviewer who has access to the sources. Any edit to the workflow or payload invalidates the approval.
- **External write:** `workflow` sends `integration.execute-operation` with the approved payload hash. `integration` rechecks permission and connection, executes, and returns `succeeded`, `failed`, or `uncertain`.
- **Uncertain** results block dependent steps until reconciled by lookup.
- Ledger states: `pending → approved → executing → succeeded | failed | uncertain`.
- Closure of a commitment requires its owner or approved evidence; creating a ticket is not delivery.

## Permissions

A run executes with the initiating actor's authority (or a named service authority for scheduled maintenance, scoped and audited). A workflow can organize only content the actor may access, and cannot widen access.

## Canvas (Gate 5)

- React Flow editor in `apps/web/src/features/canvas`, with a node palette, typed ports, inline validation, a test-run on sample data that cannot write externally, and version history with diff.
- Drag meetings onto Projects or teams to create organize rules.
- Template gallery from Gate 4 (customer promise loop, handoff to CS, weekly team digest, feature-request capture).
- Run history shows each step, approval, and external reference.

## Observability

Per-run traces, step latency, approval wait time, uncertain-operation count, dead-letter alerts, and per-workspace usage.
