> **Plan document — do not modify.**
> This file is the agreed plan and architecture. Treat it as source of truth.
> Changes must go through a new ADR or an explicit plan revision — do not edit in place.

---

> **Production target** — this is not a prototype or MVP. Every decision here targets a production product shipped in cycles.

---

# Zedex — Team, Task Assignments & Branch Management

**Phase 1 team.** Three people. Each person has a named owner for every service and every feature. Nothing is left unowned.

See individual task files:
- [UDULA_TASKS.md](tasks/UDULA_TASKS.md) — foundation, desktop, intelligence
- [SINTHUJAN_TASKS.md](tasks/SINTHUJAN_TASKS.md) — auth, calendar, projects, agenda backend
- [THANO_TASKS.md](tasks/THANO_TASKS.md) — all web UI, supervision, product decisions

---

## Team and roles

| Person | Role | What they own |
|---|---|---|
| **Udula** | Lead developer — uses Claude Code | Foundation (monorepo, IaC, CI/CD), desktop shell + C++ capture helper, intelligence service (AI pipeline), ingest service |
| **Sinthujan** | Developer | account service, authz service, calendar integration service, projects backend, agenda backend |
| **Founder** | Product + UI | All web app pages, product decisions, PR reviews, milestone sign-off, 2-week dogfood |

---

## Branch management

Three permanent branches. No exceptions.

```
main        production. Tagged releases only. v1.x.x
staging     pre-production. QA and sign-off happen here.
dev         integration. All feature work lands here first.

feat/short-name   short-lived. Cut from dev. Deleted after merge.
```

### Rules

| Branch | Push | How to merge | Required |
|---|---|---|---|
| `main` | Nobody direct | PR from `staging` only | 2 approvals + full CI green + founder sign-off |
| `staging` | Nobody direct | PR from `dev` only | 2 approvals + full CI green |
| `dev` | Nobody direct | PR from `feat/*` only | 1 approval + CI green |
| `feat/*` | Assigned developer | — | — |

### Merge style

- `feat → dev`: **squash merge** — one clean commit per feature, descriptive message
- `dev → staging`: **regular merge** — preserves full record for audit
- `staging → main`: **regular merge** + tag `v1.x.x`

### Never

- Direct push to `main`, `staging`, or `dev`
- Force push on any permanent branch
- A feature branch that lives longer than one 2-week cycle without merging — break the work into smaller pieces

### CI checks on every PR

Every pull request must pass all of these before it can merge:

| Check | What it runs |
|---|---|
| TypeScript build | `turbo run build` |
| Unit and contract tests | `turbo run test` |
| Bicep what-if | Infra change preview (infra PRs only) |
| CodeQL | Security scan |
| Eval regression gate | Grounding, recall, flag metrics must not drop > 2 pts (PRs touching `services/intelligence/`) |

---

## Dependency order

The steps must land in `dev` in this order. A step cannot start until the previous step is merged.

```
Step 1 (Udula)         monorepo + service-kit + Bicep + CI
    ↓
Step 2 (Sinthujan)     account + authz + RLS
    ↓
Step 3 (Sinthujan)     calendar integration
    ↓ (parallel)
Step 4 (Udula)         desktop shell + C++ helper + ingest
Step 2 UI (Founder)    sign-in, onboarding pages
    ↓
Step 5 (Udula)         intelligence service (AI pipeline)
Step 6 (Sinthujan)     projects backend
    ↓ (parallel)
Step 5 UI (Founder)    meeting page, card, notes tabs
Step 6 UI (Founder)    projects pages
    ↓
Step 7 (Sinthujan)     agenda backend
    ↓
Step 7 UI (Founder)    agenda editor
Step 8 (Udula)         preference summaries
    ↓
Step 9 (all)           hardening, load test, OWASP, dogfood
```

---

## Communication rules

1. **Every PR includes a one-paragraph description:** what changed, why, and what to test.
2. **Every PR links to its step number** from this document (e.g., `Step 4 — Desktop shell`).
3. **Founder reviews every PR** before it merges to `dev`. If the founder is unavailable for more than 24 h, Udula reviews instead.
4. **Milestone sign-off:** at the end of each milestone (M1–M9), the founder manually tests the feature, confirms the exit criteria in `IMPLEMENTATION_STATUS.md`, then approves the `dev → staging` PR.
5. **Blockers:** raise in under 4 h; don't stay blocked for a full day silently.

---

## Privacy invariants — must appear in every service PR

These are copied verbatim from ARCHITECTURE.md. Every PR that touches audio, transcript, or external writes must have these confirmed in the PR checklist.

| Invariant | Rule |
|---|---|
| Cloud STT, zero retention | Speech-to-text runs on a contracted streaming cloud provider with zero retention; Zedex never stores meeting audio, never uploads audio files, never records, and never joins as a bot. Uncertain values require human verification. |
| No recording | Zedex does not record audio or video |
| No meeting bot | Zedex never joins a meeting as a participant |
| No training on customer data | Customer content is never used to train models |
| Logs carry IDs not content | No transcript text, note text, or commitment text appears in any log, trace, or metric |
| Humans approve external writes | No data is written to any external system without the user seeing the exact payload and clicking Approve |

---

## Milestone sign-off checklist (founder, before `dev → staging`)

At the end of each milestone, the founder runs through this before approving the promotion PR:

- [ ] The feature works end-to-end in the staging cell
- [ ] Exit criteria from `PHASE_1_PLAN.md §5` for this milestone are met
- [ ] No critical or high CodeQL findings open
- [ ] Privacy invariants verified by author and reviewer on all PRs in this milestone
- [ ] `IMPLEMENTATION_STATUS.md` updated with evidence for each delivered item
- [ ] No cross-workspace data visible (spot check two seeded workspaces)
