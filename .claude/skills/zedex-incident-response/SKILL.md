---
name: zedex-incident-response
description: Run triage, containment, communication, and postmortem for a Zedex production incident (data exposure, silent data loss, outage, bad release). Use when something is broken in production or an alert pages.
---

# Incident response

Reference: `docs/PRODUCTION_STANDARD.md` sec. 6, `docs/architecture/09-infrastructure-operations.md`, `08-security-privacy.md`.

## Severity

| Sev | Definition | Response |
|---|---|---|
| P0 | Customer data exposed or cross-tenant leak, or a privacy invariant violated (audio stored, content in logs, unapproved external write) | Engineering stops. Founders notified immediately. Contain first |
| P1 | Meeting data silently dropped or sync/capture broken for customers | Fix within 4 h |
| P2 | Degraded feature, SLO burn, no data loss | Fix within the cycle |

## Steps

1. **Declare**: severity, incident lead, a single channel, start time. Assign a scribe.
2. **Contain** before diagnosing: disable the feature flag, roll back to the previous revision, revoke tokens/keys, block the affected workspace or route at Front Door, pause consumers. Reversible rollouts exist so this is fast.
3. **Assess scope** using IDs and metadata only (audit events, traces, queue state). Do not pull customer content into tickets, chat, or logs. Determine affected workspaces, time window, and data classes.
4. **Fix** on a `fix/` branch with a regression test; hotfix path in `zedex-git-release`. Verify in a canary cell before wide rollout.
5. **Recover**: replay from outbox/inbox, reconcile `uncertain` external operations by lookup, resync gaps from client outboxes, replay deletion tombstones after any restore.
6. **Communicate**: status page for outages; customer notification for any data exposure per the template and legal obligations; internal updates at a fixed cadence.
7. **Review**: blameless postmortem review within 48 hours, written postmortem within five working days: timeline, impact, root cause, detection gap, what worked, actions with owners and dates. Architectural findings become ADRs (`zedex-adr`). Add the missing test, alert, or runbook. Record evidence in `docs/IMPLEMENTATION_STATUS.md`.

## Do not

Do not debug by logging transcript text. Do not hot-edit production data without a recorded, reviewed script. Do not close an incident without a regression test and an alert or runbook update. Do not minimize or delay disclosure of data exposure.
