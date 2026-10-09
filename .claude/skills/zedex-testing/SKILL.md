---
name: zedex-testing
description: Decide and write the tests a Zedex change requires (unit, contract, integration, security, e2e, resilience, performance, evaluation, STT, native). Use when adding code, reviewing coverage, or answering "what tests do I need".
---

# Testing

Reference: `docs/architecture/11-quality-testing.md`, `docs/PRODUCTION_STANDARD.md` sec. 2 and 4. Tests ship in the same PR as the behavior. No PR merges without tests covering the changed behavior. Tests are deterministic: fake the clock, seed randomness, no sleeps, no network to real providers in CI.

## Required tests by change type

| Change | Minimum set |
|---|---|
| Domain rule / state machine (`packages/domain`, `services/*/domain`) | Unit, every branch (target 100% branch coverage on `domain/`), property tests for routing precedence, recurrence, revisions |
| HTTP endpoint | Contract test (schema in/out, error shape), integration test on real Postgres, security tests (tenant isolation, role matrix), idempotent replay, conflicting reused key |
| Event / command | Contract (AsyncAPI diff), duplicate delivery, out-of-order, crash/redelivery, outbox rollback, dead-letter |
| Migration | Applies on populated DB, RLS isolation, old revision compatible, deletion purge |
| Consumer / saga | Integration with Service Bus emulator, compensation / retry-until-ack, uncertain-state reconcile |
| AI pipeline / prompt | Evaluation corpus run (groundedness, fabrication, null owners, stale source, access leak), injection cases, schema-invalid retry-then-discard |
| Connector | Recorded-response fixtures, token revocation, webhook forgery/replay, rate limit |
| Web feature | Component tests for all states, Playwright e2e for the flow, axe accessibility check |
| Desktop shell | Origin allowlist, CSP, preload surface, IPC schema rejection, single-use handoff code, outbox encryption/corruption/restart/purge-after-ACK/identity switch |
| Native helper | CTest unit tests, protocol fuzzing (malformed JSON, oversize), pipeline test with synthetic PCM, reconnect from ring buffer, no-audio-on-disk assertion |
| Infra | Bicep `what-if` in PR, policy checks, restore drill evidence |

## Where tests live

Per-service `test/` (unit, integration), `packages/*/test`, and cross-cutting suites in `tests/contract`, `tests/security`, `tests/e2e`, `tests/desktop`, `tests/resilience`, `tests/performance`, `tests/evaluations`. Stack: Vitest, Testcontainers (real PostgreSQL), Service Bus emulator, Playwright, Electron driver, k6, CTest.

## Rules

- Integration tests use real PostgreSQL with RLS enabled and the non-owner runtime role, so isolation bugs surface. Never replace the database with a fake for these.
- Assert behavior and invariants, not implementation details. One reason to fail per test; name tests by the rule they protect.
- Every bug fix lands with a test that fails before the fix.
- Privacy tests: assert logs, spans, and metrics from a flow contain IDs and no seeded content strings; assert no audio file is created.
- Performance budgets are measured with k6/benchmarks and the numbers are recorded; "should be fast" is not evidence. Cell qualification target: 100 workspaces, 1,000 concurrent capturing clients, 1M segments.
- Flaky tests are fixed or deleted within the cycle, never retried into green.
- Test fixtures use synthetic or consented data only. No customer data, no real credentials.
- Report exactly which suites ran. Mocked-provider and local runs are never reported as provider, hardware, or production qualification.
