---
name: zedex-engineering-standard
description: Entry point for any code, schema, infra, or design change in Zedex. Load first when starting or reviewing implementation work. Sets the senior-engineer production bar, the phase/gate check, and routes to the other zedex-* skills.
---

# Zedex engineering standard

Zedex is a production product shipped in ~2-week cycles. It is not an MVP. Every increment ships production-grade or does not ship. Sources of truth: `AGENTS.md`, `docs/PRODUCTION_STANDARD.md`, `ARCHITECTURE.md`, `docs/architecture/`. Those files are plan documents: never edit them in place. Changes go through a new ADR (see `zedex-adr`) or an explicit plan revision.

## Before writing any code

1. Read `docs/IMPLEMENTATION_STATUS.md`. It says what is delivered, verified, blocked, deferred. `AGENTS.md` says application code starts only when the user explicitly starts implementation. If the status file still says planning-only, ask before writing code.
2. Find the gate and milestone in `docs/DELIVERY_PLAN.md` and `docs/PHASE_1_PLAN.md`. Do not build Gate 3+ services (`live`, `notification`, `reporting`, `workflow`) during Phase 1.
3. Open the owning architecture doc for the area (service map in `03`, data in `04`, AI in `05`, desktop in `02`, security in `08`, infra in `09`).
4. Scaffold files marked `Gate N — placeholder` have no behaviour. Replace them with real implementations at their gate. Never ship a placeholder as "done". Never scaffold empty future modules.

## Non-negotiables (violating any is a P0, fix in the current branch)

- No audio stored, uploaded, or recorded. No video. No meeting bot. No training on customer data.
- Logs, traces, metrics carry IDs and durations, never transcript, note, or commitment text.
- AI proposes, humans decide: no auto-ticking, no auto-confirming commitments, no external write without exact-payload approval.
- Every request authenticated and authorized (OpenFGA + workspace RLS). Association never grants access.
- Services own their data. No cross-service DB access, no importing another service's code.
- Contracts first: Zod schema in `packages/contracts` before routes, events, IPC, helper messages.
- Idempotency key on every write; transactional outbox for events; inbox dedupe for consumers; never hold a DB transaction across a network or model call.

## Code bar

- Focused functions, typed interfaces, no duplicated logic, no speculative abstractions, no stubs/TODOs, no commented-out code, no comments that restate code.
- Bounded memory, streaming for large payloads, batched I/O, no N+1, an index for every query path.
- Extend an existing service, connector adapter, workflow node, or prompt-registry entry before creating anything new. A new service needs an accepted ADR.
- Timeouts + jittered retries + circuit breakers on every remote call.
- Provider credentials never in source, logs, fixtures, or client bundles.

## Reporting rules

- Report unverified behavior plainly. Mocks, compilation, and local tests are never provider, hardware, deployment, or production qualification.
- Do not commit, publish, deploy, or call paid providers without authorization for that action.
- `scripts/verify.ps1` and `.github/workflows/ci.yml` are currently placeholders. Do not claim "verify passed" or "CI green" on the strength of them; run lint, typecheck, and tests directly (`pnpm lint`, `pnpm typecheck`, `pnpm test`) and say exactly what ran.

## Routing

| Task | Skill |
|---|---|
| New or changed HTTP endpoint / use case | `zedex-service-endpoint` |
| New or changed event or command | `zedex-event-contract` |
| Schema change, migration, RLS | `zedex-db-migration` |
| Permissions, tenant isolation, sharing | `zedex-authz-tenant-isolation` |
| Model call, prompt, retrieval, evaluation | `zedex-ai-pipeline` |
| Electron shell, C++ helper, outbox, sync | `zedex-desktop-capture` |
| Web pages, `packages/ui` | `zedex-web-ui` |
| Calendar/connector, external writes | `zedex-connector-integration` |
| Which tests to write | `zedex-testing` |
| Logs, traces, metrics, SLOs | `zedex-observability` |
| Bicep, CI/CD, deploys, cost | `zedex-infra-cicd` |
| Reviewing a diff or PR | `zedex-pr-review` |
| Declaring work finished | `zedex-definition-of-done` |
| Branching, commits, releases, hotfixes | `zedex-git-release` |
| Production incident | `zedex-incident-response` |
| Architectural decision | `zedex-adr` |
