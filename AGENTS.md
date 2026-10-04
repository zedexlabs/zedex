> **Plan document — do not modify.**
> This file is the agreed plan and architecture. Treat it as source of truth.
> Changes must go through a new ADR or an explicit plan revision — do not edit in place.

---
# Zedex engineering instructions

Shared by Codex, Claude, and human engineers. [ARCHITECTURE.md](ARCHITECTURE.md) and [docs/architecture/](docs/architecture/) are the source of truth. [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md) records delivered and verified work.

## Current phase

Planning and Markdown documentation only. Do not create application code, manifests, infrastructure definitions, or install dependencies until the user explicitly starts implementation. Preserve the approved architecture while refining documentation.

## Production standard

Zedex is a production product delivered in feature cycles, not an MVP. Every increment ships production-grade or does not ship.

- **Architecture:** think as a senior architect. Respect the service boundaries in [03-services-and-communication.md](docs/architecture/03-services-and-communication.md). A service owns its data; no cross-service database access. Integrate only through versioned contracts, events, and commands. A new service requires an accepted ADR in [decisions.md](docs/architecture/decisions.md).
- **Contracts first:** define Zod schemas in `packages/contracts` before routes, events, commands, IPC, or helper messages. Changes are additive; deprecate before removing.
- **Efficient, compact code:** focused functions, typed interfaces, no duplicated logic, no speculative abstractions, no stubs or TODO placeholders, no comments that restate code. Bounded memory, streaming for large payloads, batched I/O, no N+1 queries, an index for every query path.
- **Correct under failure:** idempotency keys on every write, transactional outbox for events, inbox dedupe for consumers, timeouts plus jittered retries plus circuit breakers on remote calls. Never hold a database transaction across a network or model call.
- **Secure by default:** authenticate every request; authorize through OpenFGA plus workspace RLS; validate all input; least-privilege scopes and identities; secrets only in Key Vault. Transcripts, imports, webhooks, and model output are untrusted input.
- **Privacy invariants:**
  - Never persist or upload raw meeting audio.
  - Never record video.
  - Never invoke paid ASR.
  - No meeting bot.
  - No training on customer data.
  - Logs and telemetry carry identifiers, never content.
- **Human control:** AI suggests. Humans tick agenda items, confirm commitments, close items, and approve every external write with its exact payload.
- **Operability:** structured logs, OpenTelemetry traces and metrics, health and readiness endpoints, graceful shutdown, feature flags for incomplete user-facing work, reversible rollouts.
- **Growth:** add features by extending an existing service, connector adapter, workflow node, or prompt registry entry before creating anything new.

## Definition of Done

A change is done only when:

1. Contracts, migrations, and affected docs are updated together.
2. Unit tests cover domain rules. Integration tests run against real PostgreSQL and the Service Bus emulator where touched. Security tests cover tenant isolation and authorization for every new endpoint, event, and query.
3. Lint, type-check, and tests pass through the repository verify script.
4. Traces, metrics, and alerts exist for new failure modes.
5. The performance budget of the touched path is stated, and measured where relevant.
6. [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md) records what is delivered, what is verified, and what is not.

## Reporting and authority

- Report unverified behavior plainly.
- Never present mocks, compilation, or local tests as provider, hardware, deployment, or production qualification.
- Do not commit, publish, deploy, or invoke paid providers without authorization for that action.
- Keep provider credentials out of source, logs, fixtures, and client bundles.
- Create files at the gate that needs them. Never scaffold empty future modules.
