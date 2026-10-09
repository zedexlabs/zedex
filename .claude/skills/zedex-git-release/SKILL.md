---
name: zedex-git-release
description: Zedex branching, commit, pull request, release, and hotfix workflow (dev/staging/main, feat branches, squash vs merge, tags, rollback). Use when creating branches, commits, PRs, releases, or hotfixes.
---

# Git and release workflow

Authoritative text: `docs/TEAM_TASKS.md` (branch rules). `docs/BRANCHING.md` is currently an empty file; if asked to write it, base it on this skill and TEAM_TASKS.md, via the plan-revision path.

## Branches

| Branch | Rule |
|---|---|
| `main` | Production. Tagged releases `v1.x.x`. PR from `staging` only; 2 approvals + CI green + founder sign-off |
| `staging` | Pre-production QA. PR from `dev` only; 2 approvals + CI green |
| `dev` | Integration. PR from `feat/*`; 1 approval + CI green |
| `feat/<short-name>` | Cut from `dev`, short-lived, deleted after merge. Break work up rather than exceed one cycle |

Never push directly to `main`, `staging`, or `dev`. Never force-push a permanent branch. Merges: `feat -> dev` squash; `dev -> staging` and `staging -> main` merge commit (keeps audit trail); tag on `main`.

## Commits and PRs

- Imperative, scoped subject: `service-kit: add inbox dedupe`, `docs: ...`, `fix(ingest): ...`. Body explains why. One logical change per commit; migration + code + tests + docs that belong together travel together.
- Do not commit generated secrets, `.env`, local settings, large binaries, or audio. Check `git status` and staged diff before committing.
- PR description: what changed, why, how to test, link to the step in `docs/TEAM_TASKS.md`, privacy-invariant confirmation for anything touching audio, transcript, or external writes, and the evidence for the Definition of Done (`zedex-definition-of-done`).
- CI must pass: build, unit and contract tests, CodeQL; Bicep what-if for infra; eval regression gate for `services/intelligence`.
- Commit, push, open PRs, deploy, or invoke paid providers only when the user has authorized that action.

## Releases

Follow `docs/RELEASE_CHECKLIST.md` once written; until then: CI green, migrations reviewed, contracts diffed for breaking changes, security suite green, evaluation corpus has no regression, performance budgets measured, canary cell bake passed, rollback plan stated, status doc updated with evidence. Desktop releases: sign, notarize, staged feed; test update interruption and rollback. Roll out cell by cell with automatic rollback on SLO breach.

## Hotfix

Branch `fix/<name>` from `main`; minimal change plus a regression test; PR to `main` with 2 approvals; tag a patch release; merge back into `staging` and `dev` immediately. Data-exposure or silent-data-loss hotfixes follow `zedex-incident-response` first.

## Cycle rhythm

Week 1 feature work with daily PRs and same-day review. Week 2 stabilization, tests, and gate exit criteria; no new features after Wednesday (new work goes on a `feat/` branch for the next cycle).
