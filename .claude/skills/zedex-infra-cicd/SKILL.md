---
name: zedex-infra-cicd
description: Write or review Azure Bicep, GitHub Actions, container builds, environments, rollout, cost, backups, and DR for Zedex. Use for infra/, .github/workflows/, compose.yaml, and deploy questions.
---

# Infrastructure and CI/CD

Reference: `docs/architecture/09-infrastructure-operations.md`, ADR-002, ADR-028, ADR-029. Azure only. Infrastructure is Bicep in `infra/azure/{global,cell,modules,jobs}` with `env/{dev,staging,prod}.bicepparam`.

## Topology and Phase 1 tiers

- **Global plane**: Front Door (Standard + custom WAF rules until the first external workspace, then Premium), `account` service, Key Vault, App Insights/Log Analytics, Blob for web assets and installers.
- **Cell** = one Bicep module parameterized by name, region, scale: Container Apps (consumption) + Jobs, PostgreSQL Flexible Server (one server, a DB per service; Burstable outside prod, General Purpose zone-redundant HA from the first external workspace), Service Bus **Standard** with SAS/local auth disabled, Web PubSub, OpenFGA on Container Apps, Blob, Key Vault, Azure OpenAI Data Zone deployments.
- **Deferred behind named ADR-029 triggers**: Service Bus Premium, Redis (arrives with `live`, Gate 3), Azure AI Search, `ingest` elastic cluster. Do not provision them early; price each when its trigger approaches.
- Tenancy scales by adding cells, not by growing one. First cell `us-1` (East US 2).

## Rules

- Managed identities for service-to-service and service-to-Azure access. No stored cloud credentials; GitHub Actions uses OIDC workload identity.
- Secrets only in Key Vault, referenced not copied. None in source, logs, fixtures, images, or client bundles. Run secret and dependency scanning.
- Private endpoints for PostgreSQL, Key Vault, Storage; no public database access. Least-privilege role assignments per service. Per-service DB credentials.
- Naming `zedex-{env}-{component}`; tags for env, service, owner, cost center. Environments isolated by subscription or resource group with separate identities. Only synthetic or approved data outside prod.
- Every Bicep PR shows a `what-if` result. Parameterize; no hardcoded regions, SKUs, or IDs. Idempotent, re-runnable deployments.
- Container images: multi-stage `infra/docker/service.Dockerfile`, non-root, pinned base digests, minimal runtime, SBOM per release, vulnerability scan blocks high/critical.
- Dependencies pinned (lockfile, vcpkg manifest, native engine revisions). Renovate/Dependabot PRs go through the same CI.

## Pipelines (`.github/workflows`)

`ci` (install, lint, typecheck, unit + contract + integration with Postgres and Service Bus emulator, Turborepo cache), `native` (four targets), `desktop-release` (package, sign, notarize, staged feed), `deploy-global`, `deploy-cell` (migrations under the migration role first, canary cell, bake, then the rest, automatic rollback on SLO breach), `codeql`. These workflows are currently placeholders; do not describe a pipeline as existing until it runs real steps. Pin third-party actions by SHA and use least-privilege `permissions:`.

## Rollout and reliability

Forward-only migrations (expand -> migrate -> contract). Feature flags for incomplete work; every rollout reversible (previous revision stays deployable). Backups 30 days with tested restore; RPO <= 15 min, RTO <= 4 h proven by drills (record evidence in the status doc). Pools sized below server limits. Overload degrades suggestions before capture or sync.

## Cost

Phase 1 baseline roughly $120-300/month per cell before usage. Small SKUs outside prod, scale-to-zero for non-critical workers where safe. State the cost impact of any new resource in the PR; no silent paid overages; do not invoke paid providers or deploy without authorization.
