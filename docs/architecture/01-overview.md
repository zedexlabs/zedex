> **Plan document — do not modify.**
> This file is the agreed plan and architecture. Treat it as source of truth.
> Changes must go through a new ADR or an explicit plan revision — do not edit in place.

---
# 01 — System Overview

## Context

| Actor / system | Interaction |
|---|---|
| Meeting participant using the desktop app | Captures meetings locally, writes notes, sees agenda and to-dos live, confirms suggestions |
| Team member using the web app | Browses projects, prepares agendas, chats over history, reviews commitments, approves workflows |
| Workspace admin | Manages teams, policies, integrations, retention, billing |
| Google / Microsoft | Identity (via WorkOS) and read-only calendars |
| HubSpot, Linear, Slack, Google Docs, Notion, Jira, Teams | Connector targets; remain authoritative for their records |
| Azure OpenAI | Text-only model inference (no training on customer data) |

## Containers

| Container | Tech | Notes |
|---|---|---|
| Desktop app | Electron + React; C++ capture helper; encrypted SQLite | Local-first; works offline |
| Web app | React SPA on Azure Static hosting via Front Door | Same design system as desktop |
| Edge | Azure Front Door Premium + WAF | TLS, routing, rate limits |
| Control plane | `account` service + PostgreSQL | Global: identity, workspaces, teams, billing, cell directory |
| Cell | 9 services + OpenFGA + Service Bus + PostgreSQL + AI Search + Redis + Web PubSub | Complete stack per cell |

## Key flows

**Capture and memory**
1. The popup offers to start notes. The user starts capture.
2. The helper transcribes locally. The desktop app stores encrypted text and syncs batches to `ingest`.
3. `ingest` commits and acknowledges, then emits `transcript.finalized` when the user stops.
4. `intelligence` generates a summary and decision/commitment proposals with evidence, then indexes into AI Search.
5. `workspace` presents the proposals for confirmation. `notification` tells participants.

**Prep → live → wrap**
1. Before the next occurrence, `intelligence` drafts an agenda from carry-over items, open commitments, external status from `integration`, and user-added context.
2. Attendees edit and contribute through `workspace`, with realtime updates through Web PubSub. The organizer accepts.
3. During the meeting, the overlay shows the accepted agenda and to-dos. The desktop sends new finalized text to `live`, which returns "discussed" suggestions with evidence. The user ticks.
4. After the meeting, covered items close with evidence and the rest carry over. The next prep is drafted.

**Commitment to delivery**
1. A confirmed commitment triggers a workflow in the `workflow` service.
2. The workflow proposes an exact payload (for example, a Linear issue). A human approves it.
3. `integration` executes the write, records the external reference, and reconciles uncertain outcomes.
4. External status changes flow back. The next brief and agenda show current status.

**Missed meeting**

`notification` sends a "since you were last here" brief 10–15 minutes before the next occurrence. It is built only from sources the person can access.

## Quality targets (to be measured, not yet achieved)

| Target | Value |
|---|---|
| Final text after window closes | ≤ 15 s |
| Sync acknowledgement p95 | < 1 s |
| Live suggestion latency p95 | ≤ 10 s |
| Summary ready p95 | < 2 min (subject to model quota) |
| Availability (GA) | 99.9% per cell |
| Recovery | RPO ≤ 15 min, RTO ≤ 4 h |
| Cell qualification | 100 workspaces, 1,000 concurrent capturing clients, 1M segments |
