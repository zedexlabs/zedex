# 11 — Quality and Testing

## Test pyramid

| Layer | Scope | Tools |
|---|---|---|
| Unit | Domain rules, state machines, parsers, prompt schema validation | Vitest, C++ unit tests (CTest) |
| Integration | Services against real PostgreSQL and the Service Bus emulator; RLS; outbox/inbox; idempotency | Vitest, Testcontainers |
| Contract | Event and HTTP schemas between producers and consumers; helper protocol; IPC | Zod schema tests, AsyncAPI/OpenAPI diff |
| Security | Tenant isolation, authorization per endpoint/event/query, prompt injection, token handling | Dedicated suite in `tests/security` |
| End-to-end | Desktop ↔ cell flows, web flows | Playwright, Electron driver |
| Resilience | Provider/model outage, broker delay, duplicate delivery, cell failover | Fault injection in `tests/resilience` |
| Performance | Sync load, finalization bursts, live-suggestion latency, cell qualification | k6 / custom in `tests/performance` |
| Evaluation | Grounding, null owners, stale sources, access leaks, live precision/recall | `tests/evaluations` |

## Hardware and capture qualification (Gate 1 and every release)

| Area | Evidence required |
|---|---|
| Four targets | macOS arm64/x64, Windows x64/arm64 real devices |
| Audio paths | Headphones, speakerphone echo, Bluetooth, device and permission changes |
| ASR | Accents, names, numbers, silence, overlap, resource use under full two-source load |
| Memory | ≤ 60 s audio per source; no audio on disk |
| Popup/overlay | Position, focus, DPI, multi-display |
| Screen-share protection | Matrix: Zoom, Meet, Teams, Slack, browser share × macOS versions × Windows 11 |
| Meeting detection | Per meeting app and browser |
| Packaging | Signing, notarization, update interruption and rollback |

Benchmark audio is licensed or consented and used only in test environments. A successful build is not hardware support.

## Required test cases (non-exhaustive)

- **Storage:** encryption, corruption, restart, identity switch.
- **Sync:** offline, duplicate batches, changed payload under a reused key, revisions, ACK-after-commit, gaps.
- **Data:** real PostgreSQL constraints, transactions, RLS, no cross-service access.
- **Access:** cross-tenant, private notes vs admin, revocation mid-run, share changes invalidating derived content.
- **AI:** fabrication, null owners/dates, stale sources, injection in transcripts and docs.
- **Calendars:** recurrence, cancel, reschedule, timezone, subscription expiry.
- **Workflows:** edited approval invalidation, rate limit, uncertain write, duplicate prevention.
- **Reports:** audience authorization, deletion, export expiry.
- **Deletion:** purge within 24 h, tombstone replay after restore.
- **Release:** signing, notarization, update.

## Release checklist (`docs/RELEASE_CHECKLIST.md`)

CI green; migrations reviewed; contracts diffed for breaking changes; security suite green; evaluation corpus has no regression; performance budgets measured; canary cell bake passed; rollback plan stated; status document updated with evidence.

## Definition of Done

See [AGENTS.md](../../AGENTS.md). Mocks, compilation, and local tests are never reported as provider, hardware, deployment, or production qualification.
