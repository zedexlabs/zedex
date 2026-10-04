# 10 — Repository Structure

pnpm workspace with Turborepo. Files are created at the gate that needs them; this tree is the target, not scaffolding. Each TypeScript package has `package.json` and `tsconfig.json`.

```text
Zedex/
  AGENTS.md  CLAUDE.md  ARCHITECTURE.md  README.md
  package.json  pnpm-workspace.yaml  pnpm-lock.yaml  turbo.json
  tsconfig.base.json  eslint.config.mjs  vitest.workspace.ts  compose.yaml  .env.example  .gitignore

  apps/
    desktop/                                  # Gate 2+
      electron.vite.config.ts  electron-builder.yml
      resources/  models.manifest.json  entitlements.mac.plist  THIRD_PARTY_NOTICES.md
      src/main/
        index.ts                              # lifecycle
        windows/  main.ts  meeting-popup.ts  live-overlay.ts  protection.ts
        ipc/                                  # validated handlers
        auth/                                 # PKCE loopback, session
        capture/                              # helper supervision, protocol, gaps
        detection/                            # calendar + mic-activity triggers
        storage/  database.ts  key-provider.ts  migrations.ts  repositories.ts
        sync/  queue.ts  engine.ts  changefeed.ts
        live/  client.ts                      # tick suggestions (Gate 3)
        realtime/  pubsub.ts
        updates/  models.ts  app.ts
        telemetry.ts
      src/preload/  index.ts
      src/renderer/  app/  popup/  overlay/  prep/  editor/

    web/                                      # Gate 2+
      vite.config.ts  index.html
      src/  main.tsx  router.tsx  api/  realtime.ts  session.ts
      src/routes/  workspace/  teams/  projects/  meetings/  prep/  chat/
                   commitments/  reports/  workflows/  settings/  admin/
      src/features/  agenda/  projects/  search/  canvas/        # canvas: Gate 5

  services/                                   # layout per 03-services-and-communication
    account/       # Gate 2
    workspace/     # Gate 2
    ingest/        # Gate 2
    integration/   # Gate 2
    intelligence/  # Gate 3
    live/          # Gate 3
    notification/  # Gate 3
    reporting/     # Gate 3 (exports), Gate 4 (analytics)
    workflow/      # Gate 4

  packages/
    contracts/     # Zod: http/, events/, commands/, ipc/, helper/, workflow/; generated OpenAPI + AsyncAPI
    domain/        # pure rules: permissions helpers, routing precedence, agenda/commitment state machines, revisions
    service-kit/   # bootstrap, config, auth, authz client, errors, idempotency, pagination, outbox, inbox, bus, telemetry, health, shutdown
    ai-kit/        # model gateway, prompt registry, structured output, evidence validation, budgets
    connector-sdk/ # capability contract, test harness
    ui/            # design system, WorkspaceShell, MeetingEditor, EvidenceLink, ApprovalPanel, CoverageStatus, AgendaList

  authz/           model.fga  tests/
  native/capture-asr/
    CMakeLists.txt  CMakePresets.json  cmake/dependencies.cmake
    include/zedex/  capture.h  audio_pipeline.h  transcriber.h  protocol.h
    src/core/  main.cpp  protocol.cpp  audio_pipeline.cpp  transcriber.cpp  health.cpp
    src/platform/mac/  system_capture.mm  microphone_capture.mm  permissions.mm  mic_activity.mm
    src/platform/win/  system_capture.cpp  microphone_capture.cpp  devices.cpp  mic_activity.cpp
    tests/  pipeline_test.cpp  protocol_test.cpp
    bench/  asr_benchmark.cpp

  infra/
    azure/  global/  cell/  modules/  env/{dev,staging,prod}.bicepparam
    docker/  service.Dockerfile

  tests/
    contract/  e2e/  security/  performance/  resilience/  evaluations/  desktop/
  tooling/  eslint/  tsconfig/
  scripts/  verify.ps1  migrate.ts  benchmark-asr.ps1  benchmark-asr.sh
  .github/workflows/  ci.yml  native.yml  desktop-release.yml  deploy-global.yml  deploy-cell.yml  codeql.yml

  docs/
    IMPLEMENTATION_STATUS.md  DELIVERY_PLAN.md  PRODUCT_WORKFLOWS.md  MARKET_RESEARCH.md  RESOURCES.md
    HARDWARE_SUPPORT.md  RELEASE_CHECKLIST.md  LOCAL_DEVELOPMENT.md  OPERATIONS.md
    architecture/  01-overview.md … 11-quality-testing.md  decisions.md
```

## Dependency rules

- `contracts` depends on nothing from apps or services.
- `domain` is pure: no database, HTTP, Electron, or cloud SDKs.
- `service-kit`, `ai-kit`, and `connector-sdk` depend on `contracts` and `domain` only.
- `ui` is presentation only and holds no credentials.
- Services import `packages/*` but never other services.
- The renderer never imports from `main`; the desktop talks to services only through contracts.
- Infrastructure owns resources; tests hold evidence; status records delivered/verified/blocked/deferred.

## Ownership

| Path | Owner squad (proposed) |
|---|---|
| `apps/desktop`, `native/` | Desktop & capture |
| `apps/web`, `packages/ui` | Web |
| `services/account`, `services/workspace`, `authz/` | Core platform |
| `services/ingest`, `services/integration` | Sync & integrations |
| `services/intelligence`, `services/live`, `packages/ai-kit` | Intelligence |
| `services/workflow`, `services/reporting`, `services/notification` | Automation & insights |
| `infra/`, `.github/` | Platform & SRE |
