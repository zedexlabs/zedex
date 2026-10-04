# Zedex — Planning and Implementation Status

**Updated:** 4 October 2026.

## Current scope

Planning and Markdown documentation only. Application development, package installation, native builds, and deployment are deferred until explicitly started.

## Documentation delivered

- [ARCHITECTURE.md](../ARCHITECTURE.md): product, invariants, service map, document index, requirement traceability.
- [docs/architecture/](architecture/): overview, desktop and native, services and communication, data model, intelligence, integrations, workflows and canvas, security and privacy, infrastructure and operations, repository structure, quality and testing, and the ADR log (cell-based, event-driven services).
- [DELIVERY_PLAN.md](DELIVERY_PLAN.md), [PRODUCT_WORKFLOWS.md](PRODUCT_WORKFLOWS.md) with the Gate 1 discovery kit, [MARKET_RESEARCH.md](MARKET_RESEARCH.md) with the Granola and Fathom parity matrix, [RESOURCES.md](RESOURCES.md).
- [AGENTS.md](../AGENTS.md) with the production standard and Definition of Done; [CLAUDE.md](../CLAUDE.md).

Supersedes the earlier modular-monolith plan (ADR-001).

## Planned but not yet written

`HARDWARE_SUPPORT.md`, `RELEASE_CHECKLIST.md`, `LOCAL_DEVELOPMENT.md`, `OPERATIONS.md` — created when the gate needing them starts.

## Delivery gates

| Gate | Status | Evidence still needed |
|---|---|---|
| 1 — Validate and qualify | Planned | Buyer interviews, partner journeys, four-target capture/ASR measurements, screen-share protection and detection matrices, legal/consent review, cost baseline |
| 2 — Foundation | Planned | Implementation; PostgreSQL, RLS, OpenFGA, sync, and contract tests; calendar and identity qualification |
| 3 — Meeting intelligence | Planned | Implementation; grounding, invalidation, live-precision evaluations; burst load test |
| 4 — Execution loop | Planned | Implementation; approval, retry, reconciliation tests; live connector qualification |
| 5 — Automation | Planned | Canvas, Notion/Jira/Teams, calendar write, provider transcripts, public API/MCP |
| 6 — Enterprise and expansion | Planned | Customer demand; cell migration, EU/dedicated cells, mobile, SSO/SCIM |

No gate has passed. These documents establish no runtime behavior, hardware support, customer demand, live integration, cloud resource, or production readiness.

## Known open items

- Azure baseline cost not yet priced.
- Screen-share protection on macOS is unqualified per meeting app; the plan claims best effort only.
- Resource links in [RESOURCES.md](RESOURCES.md) are collected, not yet individually re-verified.
- Legal and consent review has not started.
- Parakeet/sherpa-onnx versus whisper.cpp is undecided until Gate 1 benchmarks.

## Implementation entry point

When implementation is explicitly requested, start from ARCHITECTURE.md and recheck the workspace. Follow the gate order and preserve privacy and approval invariants. Record source work separately from local tests, provider tests, hardware testing, operational drills, and business validation.
