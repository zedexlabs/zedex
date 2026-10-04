> **Plan document — do not modify.**
> This file is the agreed plan and architecture. Treat it as source of truth.
> Changes must go through a new ADR or an explicit plan revision — do not edit in place.

---

> **Production target** — this is not a prototype or MVP. Every decision here targets a production product shipped in cycles.


# 05 — Intelligence

## Model deployments

| Deployment | Used for | Notes |
|---|---|---|
| `summary` | Summaries, proposals, briefs, catch-ups, agenda drafts | Quality-first; async |
| `chat` | Scoped chat and search answers | Streaming |
| `live` | Tick suggestions during meetings | Small and fast; separate quota; budgeted per workspace |
| `embeddings` | Index and query vectors | Batch |

Each deployment has its own version, region, quota, timeouts, and fallback. Provisioned throughput covers the baseline; pay-as-you-go absorbs spillover. A versioned evaluation corpus selects production models. Conversation and retrieval state stay in Zedex. Customer data is never used for training; review the Azure OpenAI data-privacy and abuse-monitoring settings before making stronger promises.

## Shared rules (enforced in `packages/ai-kit`)

1. **Authorize before retrieval or inference.** The caller's access decides which sources enter a prompt.
2. **Structured outputs only.** Zod schemas validate every response; invalid output is retried once, then discarded.
3. **Evidence validation.** Every claim carries segment references. References that do not exist or are not accessible are rejected.
4. **Unknown stays null.** Owners and dates are never guessed.
5. **Transcripts, documents, and imports are untrusted input.** Prompts keep instructions and data separate. Model output never authorizes a tool call or write.
6. **Stale-output guard.** Compare the source revision before saving; discard if it changed.
7. **Prompt registry.** Prompts are versioned files with an owner, schema, and evaluation case set. Changes ship through the normal review path.
8. **Budgets.** Per-workspace and per-deployment token budgets with backpressure.

## Pipelines

### Summary and proposals
`transcript.finalized` → coverage check → select authorized complete source → transcript + notes + template → structured draft (summary, decisions, commitments, questions, blockers) → evidence validation → store as proposals → `proposals.ready` → human confirmation in `workspace` → eligible for index and workflows.

Do not summarize summaries recursively. Continuity comes from confirmed decisions, commitments, open questions, external references, and verified closures.

### Agenda draft (prep)
Trigger: a calendar occurrence of a series or Project starts within the prep window (default 24 h), or the user requests a draft.

Inputs, all authorization-filtered:
- Items not covered last time (carry-over).
- Open commitments with current external status.
- Unresolved questions and blockers.
- Pending decisions.
- The latest brief.
- User context: notes, links, and picked Google Docs text.

Output: agenda items each with source, evidence link, suggested owner (null if unknown), and time box. Items arrive as `proposed`. Attendees add or edit items and context; the organizer accepts. **Nothing is auto-accepted.** Edits to attached context or access changes invalidate the draft.

### Live tick suggestions
- Desktop sends newly finalized text every 20–30 s plus the IDs and short titles of open agenda items and to-dos.
- `live` calls the `live` deployment and returns, per item: `discussed`, `possibly_resolved`, or `none`, with an evidence segment. It may also hint at new commitments.
- Debounced, budgeted, and skipped when no items are open.
- The UI shows a soft highlight; **only a human ticks**. A to-do ticked during the meeting becomes a proposed closure that needs its owner or approved evidence.
- Accepted ticks persist. Rejected suggestions are not stored.
- On overload or model failure suggestions pause visibly; capture and sync are unaffected.

### Next-meeting prep and carry-over
After finalization: covered items close with an evidence segment, uncovered items carry over, confirmed decisions and commitments feed the next agenda draft, and `agenda.drafted` is emitted.

### Catch-up brief
For a person and a series or Project: everything since their last review that they may access — decisions, their commitments, external status changes, open questions, and coverage gaps. It never claims attendance. If nobody captured or no authorized artifact exists, it says **Not captured**. Delivered 10–15 minutes before the next occurrence.

### Search and chat
- Scopes: meeting, series, project, account, team, authorized workspace.
- Retrieval combines AI Search hybrid results, confirmed records, and fresh task status. Results pass the security trim and `BatchCheck`.
- Answers cite segments and meetings and state missing or stale coverage. Corrections, access changes, and deletion invalidate cached answers.

### Alerts
Keyword/topic rules (Gate 3 personal, Gate 4 team) run on authorized final text only. A match sends a notification with an evidence link.

### Prompts (read-only outputs)
Saved prompts such as follow-up email, PRD, and feature-request extraction. They produce text only and never write externally; external writes belong to workflows.

## Evaluation and quality gates

- Corpus: licensed or consented, synthetic or approved text only.
- Metrics: groundedness, fabrication rate, null-owner correctness, stale-source handling, access-leak tests, live precision/recall for ticks.
- Release gate for each prompt or model change: no regression on the corpus.

## Cost controls

Cache valid results, process incrementally, prefer smaller qualified models, enforce per-workspace allowances, and show usage. No silent paid overages.
