---
name: zedex-service-endpoint
description: Build or change a Zedex backend endpoint or use case end to end (contract, domain, application, route, authz, idempotency, outbox, tests). Use when adding or editing anything under services/*/src or packages/service-kit.
---

# Service endpoint, contracts-first

Layout of every service (`docs/architecture/03-services-and-communication.md`):

```text
services/<name>/src/
  main.ts        entry: config, telemetry, server/consumers, graceful shutdown
  app.ts         composition root, no listener (testable)
  config.ts      typed env (Zod), Key Vault refs
  http/          Fastify routes: validate -> call application -> map errors
  application/   use cases; transactions; authz calls; emit events via outbox
  domain/        pure rules and state machines, NO I/O
  infrastructure/{db,repositories,adapters,messaging}
  consumers/     event/command handlers -> application
migrations/  test/
```

Dependency rules: `domain` imports nothing from infrastructure. `http` and `consumers` call only `application`. Services never import each other; they share only `packages/*`. `contracts` and `domain` import nothing from apps or services.

## Workflow (do in this order)

1. **Confirm scope**: gate, owning service, and that the service is allowed in the current phase. Check the service owns the data the endpoint touches. If it needs another service's data, use an event-fed replica or an allowed synchronous read (internal ingress, managed identity, 2 s timeout, jittered retries on idempotent reads, circuit breaker). Never read another service's database.
2. **Contract**: add Zod request/response/error schemas in `packages/contracts/src/http`. Changes are additive; deprecate before removing. Regenerate `packages/contracts/openapi.json`. Path is `/v1/<service>/...`.
3. **Domain**: put the rule or state machine in `domain/` as pure functions. Agenda items: `proposed -> accepted -> discussed -> covered | deferred`. Commitments: `proposed -> confirmed -> in_delivery -> delivered -> closed` (+ `declined`). Closure needs an owner or approved evidence. Creating a task is not delivery. Unknown owners/dates stay null.
4. **Application use case**:
   - Actor comes from the verified token. A workspace ID in the URL is scope, not authority.
   - Run an OpenFGA `Check` in this request. "Checked in a previous step" is not authorization.
   - Mutations require `Idempotency-Key`; store with request hash. Same key + different body returns conflict.
   - Editable records use optimistic versions (`If-Match`).
   - Write state and the outbox row in one transaction. Publish events through `service-kit` outbox only.
   - Never hold the transaction across a network or model call. Do the call first or after, and make it idempotent.
5. **HTTP route**: validate input with the contract schema, call application, map errors to the structured non-sensitive error with a correlation ID. List endpoints use cursor pagination. Treat all request bodies, imports, and webhooks as untrusted input.
6. **Persistence**: Drizzle repository per aggregate, every query scoped by `workspace_id`, an index for each access path. For schema work load `zedex-db-migration`.
7. **Events**: load `zedex-event-contract` if the change emits or consumes anything.
8. **Telemetry**: at least one span and one metric for the new flow, IDs only (`zedex-observability`).
9. **Tests**: `zedex-testing` lists the required set. Security tests (tenant isolation, authorization) are mandatory for every new endpoint, event, and query.
10. **Docs**: update the affected architecture doc through the ADR/plan-revision path, and record delivered/verified in `docs/IMPLEMENTATION_STATUS.md`.

## Rejection checklist

- Handler logic that is not behind a Zod schema.
- Authorization done only in the route or only in the UI.
- Missing idempotency on a write; non-idempotent retry on a remote call.
- Event payload containing content (text) rather than IDs, revision, and `workspaceId`.
- A query without `workspace_id`, or a list without a page limit.
- Catch-and-swallow error handling; error bodies that echo content or internal details.
- New service or cross-service call without an accepted ADR.
