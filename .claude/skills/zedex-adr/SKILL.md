---
name: zedex-adr
description: Write or evaluate an Architecture Decision Record for Zedex and process plan revisions. Use when a change needs a new service, crosses a service boundary, changes the stack, touches a privacy invariant, or contradicts an existing ADR.
---

# ADRs and plan revisions

Plan documents (`ARCHITECTURE.md`, `AGENTS.md`, `docs/architecture/*`, `docs/PHASE_1_PLAN.md`, etc.) carry a "do not modify in place" banner. Changes go through a new ADR in `docs/architecture/decisions.md` or an explicit plan revision approved by the user. `docs/IMPLEMENTATION_STATUS.md` is the exception: it records delivered work and is updated with every change.

## When an ADR is required

New service; any cross-service data access or synchronous dependency; replacing a managed service or tier (including activating an ADR-029 trigger: Service Bus Premium, Redis, AI Search, elastic ingest); AI model/provider change; STT provider choice (the Phase 1 bake-off is expected to produce the next ADR); authorization model change; anything weakening a privacy invariant (not allowed without founder decision); breaking event/API version policy.

## Process

1. `grep -n "^## ADR" docs/architecture/decisions.md` and pick the next free number. Read neighboring ADRs and any this one amends or supersedes (e.g. ADR-023 supersedes ADR-012; ADR-029 amends many).
2. Match the existing format in `decisions.md`: title, status, context, decision, alternatives considered with reasons rejected, consequences (cost, risk, ops burden, migration), and which ADRs it amends or supersedes.
3. Base it on evidence: benchmark numbers, cost estimates, load results, or provider terms. Say what is unmeasured. Simplest option that meets the requirement wins; justify added moving parts.
4. List the follow-on doc updates (architecture docs, catalogue, repository tree, status) and make them in the same change, so docs never contradict the ADR.
5. Mark status honestly: proposed until the user accepts it. Do not implement against a proposed ADR beyond a spike, and never against a rejected one.

## Quality bar

A good ADR lets a new senior engineer understand why, not just what; names the trigger that would reopen the decision; and states rollback or exit cost. Avoid ADRs for reversible, local code choices.
