---
name: zedex-definition-of-done
description: Verify a Zedex change or milestone is actually done and record it honestly in IMPLEMENTATION_STATUS.md. Use before saying work is complete, opening a PR, promoting dev to staging, or closing a gate.
---

# Definition of Done

Source: `AGENTS.md`, `docs/PRODUCTION_STANDARD.md` sec. 4, `docs/DELIVERY_PLAN.md`, `docs/TEAM_TASKS.md` milestone checklist.

## Checklist (all must be true, with evidence)

- [ ] Acceptance criteria / gate exit criteria from the plan are met.
- [ ] Contracts, migrations, and affected docs updated together.
- [ ] Unit tests cover domain rules; integration tests (real Postgres, Service Bus emulator where touched); contract tests for each endpoint/event; security tests for tenant isolation and authorization on every new endpoint, event, and query.
- [ ] Lint, typecheck, and tests pass. Run them: `pnpm lint`, `pnpm typecheck`, `pnpm test`. `scripts/verify.ps1` is a placeholder today; do not cite it.
- [ ] Privacy invariants verified by author and reviewer (no content in telemetry, no audio persisted, human approval on external writes).
- [ ] Traces, metrics, and alerts exist for new failure modes.
- [ ] Performance budget of the touched path stated and measured where relevant.
- [ ] No new critical/high CodeQL findings; no secrets; no placeholder comments (`Gate N - placeholder`) in shipped code.
- [ ] Feature flag in place if user-facing work is incomplete; rollout is reversible.
- [ ] PR reviewed (1 approval to `dev`, 2 to `staging`/`main`).
- [ ] `docs/IMPLEMENTATION_STATUS.md` updated.

## Updating the status document

Record, per item: **Delivered** (what exists), **Verified** (which suites/measurements, on what environment, date), **Not verified** (what was not run and why), **Blocked / Deferred** (with reason and trigger). Keep entries factual and short. Rules:

- Compilation, mocks, and local runs are not provider, hardware, deployment, or production qualification. Say "implemented, unit-tested locally" rather than "works".
- Hardware/capture support requires device evidence. STT quality requires corpus numbers. Deployment claims require a deploy record.
- Never mark a gate closed on schedule. Gates close when exit criteria are met.
- If something regressed or a check was skipped, say so with the output.

## Milestone sign-off (before `dev` -> `staging`)

End-to-end test in the staging cell by a human; exit criteria from `docs/PHASE_1_PLAN.md` met; status doc has evidence; two-workspace isolation spot check passes; no open critical/high security findings.

## Final report to the user

State what changed, what was verified (exact commands and results), what was not, and any risk or follow-up. No hedging on things that were verified; no claims about things that were not.
