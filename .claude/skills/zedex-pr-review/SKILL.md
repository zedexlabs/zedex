---
name: zedex-pr-review
description: Senior-level review of a Zedex diff or pull request against the production standard. Use before opening a PR, when asked to review code, or when checking a teammate's branch. Produces severity-ranked findings, not a rewrite.
---

# PR review

Review the diff the way a senior engineer who owns production would. Read the PR description, linked step in `docs/TEAM_TASKS.md`, and the owning architecture doc first. Then review in this order and stop at the first P0 class that is unresolved.

## 1. P0 - must not merge

- Privacy: audio persisted or uploaded; content (transcript/note/commitment/prompt/output) in a log, span, metric, error, analytics, fixture, or URL; credential in source or client bundle; training use of customer data.
- Authorization: endpoint, event handler, query, search, cache, export, or report without an authz check; trust of a URL workspace ID; association granting access; admin reading private notes; missing RLS on a tenant table.
- Human control: anything auto-ticks, auto-confirms, auto-closes, or writes externally without exact-payload approval.
- Data loss: capture/sync path that can silently drop segments, ACK before commit, or lose data on restart.
- Boundary break: cross-service DB access or code import; shared mutable state outside the bus.

## 2. P1 - fix before merge

- Contract not defined first, or handler diverges from Zod schema; breaking change without new version.
- Missing idempotency, outbox, or inbox; DB transaction held across a network/model call; unbounded retry; no timeout.
- Migration not forward-only/expand-contract; missing index for a query path; N+1; unbounded memory or list.
- Missing tests per `zedex-testing` (especially security and failure paths); tests that assert implementation, sleep, or mock the DB for integration claims.
- AI: unvalidated output, guessed owners/dates, no evidence validation, no eval run for a prompt/model change.
- No telemetry for a new failure mode; no feature flag for incomplete user-facing work.

## 3. P2 - should fix

- Duplicated logic, speculative abstraction, dead code, commented-out code, TODOs, placeholder text left in shipped code, comments that restate code.
- Naming, module placement against `docs/architecture/10-repository-structure.md`, inconsistent error shapes, accessibility gaps, missing empty/error states.
- Docs and `docs/IMPLEMENTATION_STATUS.md` not updated; PR description missing what/why/how to test.

## Output format

List findings ranked P0 -> P2. Each: `file:line`, the defect in one sentence, the concrete failure scenario (inputs/state -> wrong result), and the smallest fix. Mark each CONFIRMED (traced in code) or PLAUSIBLE. End with a verdict: approve, approve with follow-ups, or request changes, and list what was verified versus not run. Do not pad with praise or style nits when a P0/P1 exists. Do not rewrite the PR; suggest changes.

Run `lint`, `typecheck`, and affected tests rather than assuming. Report exactly what ran.
