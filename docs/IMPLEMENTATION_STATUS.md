> **Plan document — do not modify.**
> This file is the agreed plan and architecture. Treat it as source of truth.
> Changes must go through a new ADR or an explicit plan revision — do not edit in place.

---

> **Production target** — this is not a prototype or MVP. Every decision here targets a production product shipped in cycles.


# Zedex — Planning and Implementation Status

**Updated:** 4 October 2026.

## Current scope

Planning and Markdown documentation only. Application development, package installation, native builds, and deployment are deferred until explicitly started.

## Documentation delivered

- [ARCHITECTURE.md](../ARCHITECTURE.md): product, invariants, service map, document index, requirement traceability.
- [docs/architecture/](architecture/): overview, desktop and native, services and communication, data model, intelligence, integrations, workflows and canvas, security and privacy, infrastructure and operations, repository structure, quality and testing, and the ADR log (ADR-001 through ADR-029).
- [DELIVERY_PLAN.md](DELIVERY_PLAN.md), [PRODUCT_WORKFLOWS.md](PRODUCT_WORKFLOWS.md), [MARKET_RESEARCH.md](MARKET_RESEARCH.md), [RESOURCES.md](RESOURCES.md).
- [PHASE_1_PLAN.md](PHASE_1_PLAN.md): Phase 1 scope, user flows, services, milestones, exit criteria.
- [TECHNICAL_RISKS.md](TECHNICAL_RISKS.md): full technical risk register for every feature, by phase.
- [AGENTS.md](../AGENTS.md) with the production standard and Definition of Done; [CLAUDE.md](../CLAUDE.md).
- [ZEDEX_BRIEFING.md](ZEDEX_BRIEFING.md): complete project briefing updated to reflect Phase 1 decisions (cloud STT, web-first, Azure, ADR-023–028).
- [UI_PAGES.md](UI_PAGES.md): full UI page and element inventory (all pages, buttons, and desktop surfaces DS-1 to DS-6).
- [TEAM_TASKS.md](TEAM_TASKS.md): team assignments, branch management (dev / staging / main), and dependency order for Phase 1.
- [tasks/UDULA_TASKS.md](tasks/UDULA_TASKS.md): Udula's full task list — benchmarks, foundation, desktop shell + C++ helper, intelligence service.
- [tasks/SINTHUJAN_TASKS.md](tasks/SINTHUJAN_TASKS.md): Sinthujan's full task list — auth, calendar integration, projects backend, agenda backend.
- [tasks/THANO_TASKS.md](tasks/THANO_TASKS.md): Thano's full task list — all web UI, supervision, milestone sign-off.

**Plan revision applied (October 2026):** ADR-023 through ADR-028 added. Cloud STT replaces local ASR as default (ADR-012 superseded). Web-first with thin desktop shell (ADR-025). Layered summarisation (ADR-027). Azure Service Bus Standard for Phase 1 (ADR-028). Phase 1 feature set confirmed: calendar integration, Projects, agenda (previous/current/next), preference summaries, typed notes.

**Stack alignment (October 2026):** ADR-029 sets one consistent stack: `intelligence` from Gate 2; PostgreSQL FTS + pgvector retrieval; Service Bus Premium, Redis, AI Search, and the `ingest` elastic cluster deferred to named triggers; Front Door Standard → Premium before external workspaces; thin shell with an encrypted segment outbox and one sign-in handoff; OS-native helper networking with speexdsp and libfvad; Data Zone model deployments.

Supersedes the earlier modular-monolith plan (ADR-001).

## Planned but not yet written

`HARDWARE_SUPPORT.md`, `RELEASE_CHECKLIST.md`, `LOCAL_DEVELOPMENT.md`, `OPERATIONS.md` — created when the gate needing them starts.

## Delivery gates

| Gate | Status | Evidence still needed |
|---|---|---|
| 1 — Validate and qualify | Planned | Buyer interviews, partner journeys, cloud STT provider benchmark (AssemblyAI vs Deepgram), screen-share protection and detection matrices, legal/consent review, Google Workspace API verification started, Azure cost baseline |
| 2 — Foundation | Planned | Implementation; PostgreSQL, RLS, OpenFGA, sync, and contract tests; calendar and identity qualification |
| 3 — Meeting intelligence | Planned | Implementation; grounding, invalidation, live-precision evaluations; burst load test |
| 4 — Execution loop | Planned | Implementation; approval, retry, reconciliation tests; live connector qualification |
| 5 — Automation | Planned | Canvas, Notion/Jira/Teams, calendar write, provider transcripts, public API/MCP |
| 6 — Enterprise and expansion | Planned | Customer demand; cell migration, EU/dedicated cells, mobile, SSO/SCIM |

No gate has passed. These documents establish no runtime behavior, hardware support, customer demand, live integration, cloud resource, or production readiness.

## Known open items

- Azure baseline estimated in ADR-029 (~$120–300/month per cell before usage); to be confirmed in the Azure Pricing Calculator.
- Screen-share protection on macOS is unqualified per meeting app; the plan claims best effort only.
- Resource links in [RESOURCES.md](RESOURCES.md) are collected, not yet individually re-verified.
- Legal and consent review has not started.
- STT provider (AssemblyAI vs Deepgram) is undecided until the Gate 1 benchmark.

## Implementation entry point

When implementation is explicitly requested, start from ARCHITECTURE.md and recheck the workspace. Follow the gate order and preserve privacy and approval invariants. Record source work separately from local tests, provider tests, hardware testing, operational drills, and business validation.
