---
name: zedex-authz-tenant-isolation
description: Implement or verify authorization, OpenFGA tuples, sharing, roles, and tenant isolation in Zedex. Use for any endpoint, event, query, search, report, export, or cached/derived content that depends on who is allowed to see what.
---

# Authorization and tenant isolation

Reference: `docs/architecture/03-services-and-communication.md` (OpenFGA sketch), `08-security-privacy.md`, `authz/model.fga`, ADR-005.

## Principles

- **Authenticate and authorize every request, event, job, retrieval, citation, report, and export.**
- Actor comes from the verified WorkOS token. Workspace ID in a URL or payload is a scope, never authority.
- **Association is not access.** Grouping a meeting into a Project, a routing rule, a tracking code, or an AI suggestion must never widen access. Access changes only through shares and roles.
- **Admins have no implicit access to private notes.** Explicit, audited sharing only.
- Email-domain matching never grants membership; invitation or provisioning is required.
- Shared reports use sources the audience can access, not everything the creator can.

## OpenFGA usage

- Model lives in `authz/model.fga` with tests in `authz/tests`. Types: user, workspace, team, project, meeting, agenda, report.
- Owning services write tuples through their outbox (`workspace.meeting.associated.v1`, `workspace.share.changed.v1`, `account.membership.changed.v1`). Never write tuples from a request handler outside a transaction with the owning state change.
- `Check` guards single-object operations. `BatchCheck` guards search results, citations, chat sources, reports, exports. `ListObjects` powers library views.
- Retrieval order: filter by `workspace_id` and principal set, then `BatchCheck`, then show or cite. Authorize **before** retrieval or inference, so unauthorized text never enters a prompt.
- Model change = migration of tuples plus a model test. Treat `model.fga` edits like schema migrations.

## Defense in depth

OpenFGA decides who; Postgres RLS (`zedex-db-migration`) bounds what a bug can reach; composite keys prevent cross-workspace joins. All three must hold independently.

## Revocation and staleness

- Membership removal, share change, and deletion invalidate derived content (summaries, cards, proposals, search answers, chat caches) by comparing source revision and access at read time and via events.
- Revoked membership stops desktop uploads for that workspace. Content is never silently rerouted to another workspace.
- Access checks mid-long-running work (summary build, export) re-run before results are saved or delivered.

## Required security tests (`tests/security`, and per-service `test/`)

For every new endpoint, event consumer, and query:
1. Cross-tenant: seed two workspaces; a caller in A gets 403/404 and zero rows for B, on every table touched.
2. No-context connection returns zero rows (RLS bypass attempt).
3. Role matrix: owner, admin, team manager, member, viewer, non-member.
4. Private notes vs admin: admin cannot read.
5. Revocation mid-run: access removed during a job; output is discarded or filtered.
6. Share change invalidates derived content.
7. ID guessing: valid ID from another tenant returns the same response as a missing ID (no existence oracle).
8. Token handling: expired, wrong audience, replayed handoff code (single-use, short-lived).

A missing security test blocks merge. See `zedex-testing`.
