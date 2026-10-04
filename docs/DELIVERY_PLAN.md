# Delivery Plan

Cycles are about two weeks and indicative; they depend on team size. A gate passes only with evidence recorded in [IMPLEMENTATION_STATUS](IMPLEMENTATION_STATUS.md). Source work alone cannot satisfy customer, hardware, provider, or production criteria.

## Gate 1 — Validate and qualify (cycles 1–3)

**Scope**
- 15 buyer interviews and 5 design-partner journeys using the [discovery kit](PRODUCT_WORKFLOWS.md#gate-1-discovery-kit).
- Four-target capture and ASR benchmark (whisper.cpp vs Parakeet via sherpa-onnx).
- Popup and overlay: screen-share protection matrix and meeting-detection spike.
- Consent and legal review started.
- Load model and Azure cost baseline.

**Exit:** measured hardware support, partner commitments, and an approved cost baseline.

## Gate 2 — Foundation (cycles 4–9)

**Scope**
- Repository, CI/CD, global and cell infrastructure as code, `service-kit`, contracts.
- Services: `account`, `workspace`, `ingest`, `integration` (Google/Microsoft calendars), `authz`.
- Service Bus with outbox/inbox, Web PubSub.
- Desktop shell, **meeting popup**, capture, encrypted store, durable sync.
- **Projects with drag-and-drop grouping**, series auto-add, rules and tracking-code detection.
- Manual agenda and the **live overlay**; consent basics; RLS and audit.

**Exit:** offline restart, idempotency, tenant isolation, and revocation tests pass; the first cell is live; founders dogfood their own meetings.

## Gate 3 — Meeting intelligence (cycles 10–15)

**Scope**
- Services: `intelligence`, `live`, `notification`, `reporting` (exports); AI Search.
- Notes editor and templates, summaries, scoped search and chat, briefs, catch-up, coverage honesty.
- **AI agenda with collaboration**, **live tick suggestions**, highlights, prompts, personal alerts, AI routing suggestions and AI Channels, personal export.

**Exit:** grounding, null-owner, invalidation, and live-precision evaluations pass; a burst load test passes.

## Gate 4 — Execution loop (cycles 16–21)

**Scope**
- `workflow` service with templates and exact-payload approvals; confirmed commitments.
- HubSpot, Linear, Slack, **Google Docs**.
- Analytics read models and tracking-code attribution; team alerts.
- Stripe billing; admin workspace export.

**Exit:** no duplicate writes; uncertain-write reconciliation proven; paid pilots running.

## Gate 5 — Automation (cycles 22–27)

**Scope**
- **Canvas** over the workflow engine; Notion, Jira, Teams.
- Opt-in calendar write; provider text-transcript import; consent email.
- Public API, MCP server, outbound webhooks.

**Exit:** no permission widening; every external write approved.

## Gate 6 — Enterprise and expansion (demand-led)

EU cell and dedicated cells with migration tooling, SSO/SCIM, scorecards (opt-in, visible to the scored person), mobile, languages, Salesforce, Attio, Confluence.

**Exit:** customer demand qualified for each item.

## Expansion criteria

Expand after two paying continuations, three recurring cycles, measured preparation and follow-up improvement, fewer lost commitments, and sustainable review and cost.

## Pilot and GA readiness

**Pilot** requires:
- Qualified four-target capture.
- Reliable text sync.
- Authorized continuity.
- Approved external operations without duplicates.
- Evidence and gap reports.
- Passing privacy and security tests.

**GA** additionally requires:
- Paid pilots and sustainable economics.
- Independent security and consent review.
- Tested restore and deletion.
- Incident response in place.
- Signed, qualified releases.
