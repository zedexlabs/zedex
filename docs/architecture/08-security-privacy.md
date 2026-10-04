# 08 — Security and Privacy

## Trust boundaries

| Boundary | Controls |
|---|---|
| Device | Sandboxed renderers, validated IPC, whole-database encryption, key in OS-protected storage, signed app/helper/updates, no audio persistence |
| Client → cell | TLS, WorkOS tokens, Front Door WAF, rate limits |
| Service → service | Managed identity, private networking, per-service database credentials |
| Cell → providers | Minimal OAuth scopes, encrypted tokens, signature-checked webhooks, egress budgets |
| Cell → models | Text only, authorized sources only, no training on customer data |

## Threat model highlights

| Threat | Mitigation |
|---|---|
| Cross-tenant data access | Workspace RLS + OpenFGA + composite keys; automated tenant-isolation tests on every endpoint, event, and query |
| Privilege widening by grouping, rules, codes, or AI routing | Association never grants access; access changes only through shares and roles |
| Admin reading private notes | No implicit admin access; explicit audited sharing only |
| Prompt injection via transcript, doc, or webhook | Instruction/data separation, schema-validated outputs, model output never authorizes tools, evidence validation, OWASP LLM Top 10 test cases |
| Data exfiltration through chat or reports | Retrieval authorized per caller; audience-based report sources; citations re-checked |
| Stale or revoked access in derived content | Source revision comparison, invalidation on access/deletion events |
| Duplicate or unapproved external writes | Exact-payload approval, idempotency markers, operation ledger, uncertain-state reconciliation |
| Token theft | Key Vault encryption, short-lived access tokens, central refresh, revoke on membership change |
| Compromised update channel | Signed builds, signed feeds, staged rollout, rollback |
| Local data theft | Encrypted DB, per-identity partitions, OS-protected key |

## Consent and disclosure

Recording-consent law varies by jurisdiction, and AI note-taking has already drawn litigation (for example, the Otter.ai class action). Consent is a product feature, and a legal review is part of Gate 1.

- Workspace consent policy, defaulting to **notify all participants**.
- Generated disclosure text for invites or meeting chat.
- A visible capture indicator on the user's screen, and a reminder on the popup when policy requires it.
- "Participant objected" stops the meeting-audio source immediately; microphone-only or notes-only continues at the user's choice.
- Each notice is recorded as metadata-only audit.
- Gate 5: consent emails to external attendees from the connected mailbox.
- The live overlay and popup are excluded from screen capture only so participants do not see the user's private notes. They never hide that capture is happening.

### Screen-share protection

- Applied to the popup and overlay through the OS content-protection flag.
- Windows 10 2004+: excluded from capture. macOS: best effort, because newer capture frameworks can ignore the flag.
- Qualified per meeting app and OS version before any claim is made to users. The settings screen states the platform guarantee honestly and offers a collapse hotkey and second-display pinning.

## Identity and sessions

WorkOS AuthKit (Google/Microsoft). Desktop uses the system browser with authorization code + PKCE on loopback and no client secret. Web uses secure HTTP-only sessions with CSRF protection. Invitations and provisioning are required; email-domain matching alone never grants membership. SSO and SCIM arrive when customer demand qualifies them (Gate 6).

## Roles

| Role | Capability |
|---|---|
| Owner | Billing, policy, admins |
| Administrator | Membership, integrations, governance |
| Team manager | Authorized team content, coverage roster |
| Member | Owned and authorized collaboration content |
| Viewer | Explicitly shared content |

Sharing levels: personal, explicit users/groups, team/Project, workspace. Shared reports use sources accessible to the audience, not everything the creator can see.

## Data protection

- TLS in transit; encryption at rest on databases, Blob, and local store; connector tokens encrypted with Key Vault keys.
- Secrets only in Key Vault; none in source, logs, fixtures, or client bundles.
- Logs and telemetry carry IDs and metrics, never transcript or note content. No session replay on transcripts.
- Retention, deletion, and tombstones as in [04-data-model](04-data-model.md).

## Secure development

Dependency, secret, and container scanning in CI; CodeQL; pinned dependencies and native engine revisions; SBOM per release; security tests per feature (see [11-quality-testing](11-quality-testing.md)). Independent security and consent review before GA.

## Incident response

Severity levels, an on-call rotation, runbooks, a customer notification procedure, and blameless postmortems are defined in [09-infrastructure-operations](09-infrastructure-operations.md) and rehearsed before the first paid pilot.
