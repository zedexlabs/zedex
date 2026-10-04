> **Plan document — do not modify.**
> This file is the agreed plan and architecture. Treat it as source of truth.
> Changes must go through a new ADR or explicit plan revision — do not edit in place.

---

> **Production target** — this is not a prototype or MVP. Every decision here targets a production product shipped in cycles.

---

# Zedex — Production Standard

**Status:** Approved · **Applies to:** Every engineer, every PR, every line of code · **Updated:** 4 October 2026

Zedex is a **production product delivered in cycles**, not a hackathon project or an MVP.
This document states what "production" means for every person working on it.

---

## 1. What "Production" Means Here

| Dimension | Standard |
|---|---|
| **Reliability** | The app must work for paying customers every day. Capture must never silently drop data. Sync must recover from any outage without data loss. |
| **Security** | Every endpoint is authenticated and authorized. No customer data ever leaks. No credentials in code or logs. |
| **Privacy** | No raw audio ever stored or uploaded. No customer content in telemetry. Retention and deletion enforced on schedule. |
| **Human control** | AI proposes; humans decide. No external write without explicit approval. No agenda item auto-ticked. |
| **Correctness** | A commitment that was approved must be written exactly as approved. A tick that was not confirmed must not appear in history. |
| **Honesty** | Capture gaps are shown. Sync state is shown. AI claims show evidence. "Not captured" is a first-class state, not an error to hide. |

---

## 2. Engineering Rules (applies to every PR)

These rules come from [AGENTS.md](../AGENTS.md). They are not suggestions.

### Not an MVP
- Do not ship half-finished flows and call them "v1 to iterate on".
- Every feature shipped must be complete end-to-end: contract → service → UI → test → telemetry → documented invariants.
- Placeholder files (marked `Gate N — placeholder`) are intentional scaffolding. They are not "done". Do not ship them to users.

### Service boundaries are hard
- Services own their database. No service reads another service's database directly.
- No shared mutable state across services except through the event bus.
- Breaking a service boundary requires a new ADR.

### Async-first
- Domain events record facts. Commands request work. HTTP is for client-facing queries and commands only.
- Every event write uses the transactional outbox. Every event read uses the inbox dedup table.

### Contracts first
- Define the Zod schema in `@zedex/contracts` before writing the handler.
- The schema is the source of truth, not the handler. The handler must conform to the schema.

### Idempotency and authorization everywhere
- Every state-mutating operation is idempotent. Every request is authorized with an OpenFGA Check.
- "I checked in the previous step" is not authorization.

### Efficient, minimal code
- Write what the task requires. No speculative abstractions, no "we might need this later" helpers.
- Three similar lines is better than a premature abstraction.
- No half-finished implementations. No commented-out code committed.

### No content in telemetry
- OpenTelemetry spans carry IDs (meeting_id, workspace_id) and durations. Never content (transcript text, note text, commitment text).
- Log levels: ERROR for actionable failures, INFO for lifecycle events, DEBUG (dev only) for detail.

### Tests ship with the feature
- Unit tests for every domain rule.
- Contract tests for every HTTP endpoint.
- Integration tests for every connector and saga.
- Evaluations for every AI pipeline output.
- No PR merges without tests covering the changed behaviour.

---

## 3. Privacy Invariants (never negotiable)

These are product commitments to customers, not implementation details:

| Invariant | Description |
|---|---|
| No stored audio | Raw meeting audio is never written to disk beyond the capture buffer. Never uploaded. |
| No paid ASR | All speech recognition runs locally on the user's device with open-source models. |
| No meeting bot | Zedex never joins a meeting as a participant. |
| No recording | Zedex does not record audio or video. It transcribes locally in real time. |
| No training | Customer data is never used to train models. Azure OpenAI data processing terms apply. |
| Logs carry IDs, not content | No transcript text, note text, or commitment text appears in any log, trace, or metric. |
| Humans approve external writes | No data is written to an external system (Linear, HubSpot, Google Docs, Slack) without the user seeing the exact payload and clicking Approve. |

Any code that violates a privacy invariant is a P0 bug. It does not ship. It is fixed immediately in the current branch.

---

## 4. Definition of Done

A feature is **done** when all of the following are true:

- [ ] All acceptance criteria from the gate plan are met.
- [ ] Contract tests pass for every new or changed endpoint.
- [ ] Unit tests cover all new domain logic (aim: 100 % branch coverage on domain/).
- [ ] Integration tests cover the happy path and at least one error/retry path.
- [ ] Privacy invariants are not violated (checked by author + reviewer).
- [ ] No new critical or high CodeQL findings.
- [ ] Telemetry added: at least one trace span and one relevant metric for the new flow.
- [ ] IMPLEMENTATION_STATUS.md updated to reflect the delivered item.
- [ ] PR reviewed and approved by at least 1 teammate (2 for main).
- [ ] No placeholder comments (`// Gate N — placeholder`) left in shipped code.

---

## 5. Cycle Rhythm

Zedex ships in **~2-week cycles** aligned to the delivery gates in [DELIVERY_PLAN.md](DELIVERY_PLAN.md).

| Week | Activity |
|---|---|
| Week 1 | Feature development. PRs open daily. Code review same day. |
| Week 2 | Stabilisation, test coverage, and gate exit criteria. No new features after Wednesday. |
| End of cycle | Gate review: exit criteria checked against DELIVERY_PLAN.md. If criteria not met, the gate does not close. |

**Gates do not close on a schedule. They close when exit criteria are met.**
Shipping incomplete work to close a gate on time is not acceptable.

---

## 6. Incident Response Principles

- Any production incident that exposes customer data is a P0. Engineering stops, founders are notified immediately.
- Any production incident that silently drops meeting data is a P1. Fix within 4 hours.
- Every incident gets a post-incident review within 48 hours.
- Findings that change architecture become ADRs in [decisions.md](architecture/decisions.md).

---

## 7. What Not to Do

| Anti-pattern | Why |
|---|---|
| "Ship it and iterate" on broken flows | Customers lose trust the first time capture silently fails |
| Shared database between services | Destroys failure isolation and team autonomy |
| AI auto-ticking agenda items | Violates the human-control invariant; a user must see and confirm every action |
| Logging transcript text for debugging | Violates the privacy invariant; use segment IDs instead |
| Hardcoding credentials | Security violation; use Key Vault refs and managed identities |
| Bypassing approval for external writes | Violates the approval invariant; approval is non-negotiable |
| Merging placeholder files as "done" | Placeholder files have no behaviour; do not ship them to users as features |
| Adding features during stabilisation week | Scope creep delays gate exit; new work goes on a `feat/` branch for the next cycle |

---

## Related Documents

| Document | Purpose |
|---|---|
| [AGENTS.md](../AGENTS.md) | Full engineering rules and Definition of Done for AI agents and humans |
| [BRANCHING.md](BRANCHING.md) | Branch management, PR rules, release and hotfix process |
| [DELIVERY_PLAN.md](DELIVERY_PLAN.md) | Gates, cycles, and exit criteria |
| [ARCHITECTURE.md](../ARCHITECTURE.md) | Service map, invariants, and requirement traceability |
| [docs/architecture/08-security-privacy.md](architecture/08-security-privacy.md) | Full security and privacy architecture |
| [docs/architecture/11-quality-testing.md](architecture/11-quality-testing.md) | Test pyramid, hardware qualification, release checklist |
