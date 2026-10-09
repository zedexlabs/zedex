---
name: zedex-ai-pipeline
description: Build or change Zedex AI work - chunk notes, meeting cards, agenda drafts, preference summaries, retrieval, prompts, model gateway, evaluation. Use for services/intelligence, services/live, packages/ai-kit, tests/evaluations.
---

# AI pipelines

Reference: `docs/architecture/05-intelligence.md`, ADR-018, ADR-026, ADR-027, ADR-029. Code lives in `packages/ai-kit` (gateway, prompts, structured, evidence, budgets) and `services/intelligence`.

## Rules enforced in `ai-kit` (do not bypass)

1. **Authorize before retrieval or inference.** Only sources the caller can access enter a prompt (`zedex-authz-tenant-isolation`).
2. **Structured outputs only.** Zod-validate every response; retry invalid output once, then discard.
3. **Evidence validation.** Every claim cites segment IDs; reject references that do not exist or are not accessible.
4. **Unknown stays null.** Never guess owners or dates. Never infer owners from uncertain speaker labels.
5. **Transcripts, documents, imports, webhooks are untrusted input.** Keep instructions and data separate; model output never authorizes a tool call or write.
6. **Stale-output guard.** Compare source revision before saving; discard if changed.
7. **Prompt registry.** Prompts are versioned files with owner, schema, and evaluation case set. A prompt change ships through normal review with an eval run.
8. **Budgets.** Per-workspace and per-deployment token budgets with backpressure. No silent paid overages.

## Pipeline invariants

- Raw transcripts are never sent to the model in bulk; **chunk notes** (~5 min windows with overlap) are the intermediary. Meeting card is built from chunk notes + user notes + accepted agenda.
- Do not summarize summaries recursively. Rollups are built from meeting cards only, only for meetings the requester can access (`ListObjects` first).
- Words below the STT confidence threshold are `unverified`; flagged values (numbers, dates, names, money) carry through to the card and need human verification before confirmation.
- User edits (`card_edit`) survive regeneration; user text and AI text stay visually distinct; every AI sentence links to a segment.
- Agenda drafts: nothing is auto-accepted; the organizer accepts. Draft is invalidated if attached context or access changes.
- Live ticks (Gate 3): suggestion only (`discussed | possibly_resolved | none` plus evidence). Only a human ticks. Overload pauses suggestions visibly; capture and sync are unaffected.
- Read-only prompts (follow-up email, PRD extraction) produce text only. External writes belong to workflows with approval.

## Operations

- Model calls run in `intelligence`/`live`, never in `workspace`, and never inside a DB transaction.
- Azure OpenAI Data Zone deployments (US; EU for `eu-1`). Deployments: summary, chat, live, embeddings, each with version, quota, timeouts, fallback. Models are chosen by the evaluation corpus, not by preference.
- Cache valid results, process incrementally, prefer the smallest qualified model, show usage.
- Persist `prompt_run` metadata only (prompt version, model, tokens, latency, status), never prompt or output text in logs/telemetry.

## Evaluation gate (blocks merge for any prompt, model, or pipeline change)

Corpus in `tests/evaluations`: licensed, consented, or synthetic text only. Metrics: groundedness (>= 95% of claims with a valid segment), fabrication rate, decision recall, null-owner correctness, stale-source handling, access-leak tests, flag catch rate for seeded number/date errors, live precision/recall. A drop of more than 2 points versus baseline blocks the PR. Also include OWASP LLM Top 10 cases: injection in transcripts and docs, data exfiltration through chat, tool-authorization attempts.

Report eval results as measured on the corpus, not as production quality.
