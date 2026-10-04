> **Plan document — do not modify.**
> This file is the agreed plan and architecture. Treat it as source of truth.
> Changes must go through a new ADR or an explicit plan revision — do not edit in place.

---

> **Production target** — this is not a prototype or MVP. Every decision here targets a production product shipped in cycles.


# Zedex

Meeting memory, live agendas, commitment tracking, and approved workflow automation for growing B2B SaaS teams. macOS and Windows desktop app plus a web app. Text only: no meeting bot, no recording.

**Current phase: planning and Markdown documentation only.** No application, native helper, dependency installation, cloud deployment, or production integration has been completed.

## Documents

| Document | Purpose |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Product, invariants, service map, requirement traceability, document index |
| [docs/architecture/](docs/architecture/) | Detailed architecture: overview, desktop/native, services, data, AI, integrations, workflows/canvas, security, infrastructure, repository, testing, decisions |
| [docs/DELIVERY_PLAN.md](docs/DELIVERY_PLAN.md) | Gates 1–6, cycles, exit criteria |
| [docs/PRODUCT_WORKFLOWS.md](docs/PRODUCT_WORKFLOWS.md) | End-to-end workflows and the Gate 1 discovery kit |
| [docs/MARKET_RESEARCH.md](docs/MARKET_RESEARCH.md) | Problems, competitors, Granola/Fathom parity |
| [docs/RESOURCES.md](docs/RESOURCES.md) | Official links by topic |
| [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md) | What is delivered, verified, and open |
| [AGENTS.md](AGENTS.md) / [CLAUDE.md](CLAUDE.md) | Engineering rules for Codex, Claude, and humans |

The architecture describes intended future files. Files are created only when their gate needs them; the plan is not a request to generate empty scaffolding.

Free open-source ASR runs locally. Raw meeting audio is never intentionally persisted or uploaded. Azure receives text and metadata. Paid cloud text models are allowed; paid ASR is prohibited.
