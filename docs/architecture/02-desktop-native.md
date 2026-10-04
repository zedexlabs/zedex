# 02 — Desktop App and Native Capture

## Targets

| Target | ASR backend | Qualification hardware |
|---|---|---|
| macOS 14.2+ arm64 | Metal with CPU fallback | Apple Silicon |
| macOS 14.2+ x64 | CPU | Intel Mac |
| Windows 11 x64 | CPU | Intel and AMD |
| Windows 11 arm64 | Native ARM CPU | ARM device |

There is one package per architecture, each with a matching helper build. A successful build is not proof of capture support; [11-quality-testing](11-quality-testing.md) defines qualification.

## Process model

| Process | Owns | Must not |
|---|---|---|
| Electron main | Auth, encrypted DB, sync, helper supervision, meeting detection, window manager, updates | Run model inference |
| Renderer: app window | Library, Projects, notes editor, prep, chat, settings | Access the filesystem, credentials, or shell |
| Renderer: meeting popup | Start / open prep / dismiss prompt | Start capture by itself |
| Renderer: live overlay | Agenda, to-dos, notes, ticks, capture health | Hold data beyond the current meeting view |
| Native helper (C++) | Devices, capture, resampling, VAD, ASR, health | Write audio anywhere, or send audio over IPC |

**Renderer hardening:**
- Sandbox and context isolation.
- A narrow preload bridge; every IPC message is validated against Zod schemas from `packages/contracts/ipc`.
- Sender checks.
- Navigation restricted to the app; deny-by-default permissions; strict CSP.

## Meeting popup

**Triggers:**
- A calendar event with a conferencing link starts within 2 minutes.
- The helper reports microphone activity while a known meeting app is running.

**Behaviour:**
- Compact card anchored to the top-right with title, attendees, and three actions: **Start notes**, **Open prep**, **Dismiss**.
- Shows the workspace consent reminder when policy requires it.
- Never starts capture without an explicit click.
- Dismissal is remembered per occurrence.
- Settings let users choose calendar-only, calendar + activity, or off.

## Live overlay

- A pill that expands into a side panel. It is always on top, movable, collapsible, and can be pinned to any display.
- **Sections:**
  - Accepted agenda with time boxes and status.
  - Open to-dos and commitments relevant to this meeting.
  - Quick notes.
  - Capture health: sources, levels, gaps.
- **Hotkeys:** mark moment (text highlight), add action, collapse.
- **Tick suggestions:** every 20–30 s, `live/client.ts` sends newly finalized segment text plus open item IDs to the `live` service.
  - Suggestions appear as a soft highlight with an evidence snippet; one click ticks the item.
  - Nothing ticks automatically.
  - Offline, suggestions pause with a visible state and capture continues.

## Helper protocol

- Versioned newline-delimited JSON over child-process pipes, with bounded message size. Versions are rejected before start if incompatible.
- **Commands:** `listDevices`, `configure`, `start`, `pause`, `resume`, `stop`, `health`, `shutdown`.
- **Events:** `ready`, `started`, `levels`, `partial`, `final`, `deviceChanged`, `permissionChanged`, `micActivity`, `overload`, `gap`, `stopped`, `failure`.
- Audio never crosses the protocol.

## Capture and ASR pipeline

`PCM capture → mono + resample 16 kHz → Silero VAD → bounded windows → ASR → overlap reconciliation → stable final segments`

| Concern | Rule |
|---|---|
| Sources | Microphone and meeting audio kept separate; labelled "You" and "Others" |
| macOS | Core Audio process taps for meeting audio + microphone input |
| Windows | WASAPI microphone + output loopback; per-application loopback is qualified separately |
| Memory bound | ≤ 60 s of audio per source across queues; samples released promptly |
| Persistence | No WAV, cache, diagnostic, or retry audio — ever |
| Overload | Explicit pause or drop with a reported gap |
| Failure | Finalized text is preserved and lost intervals are marked |
| Engines | whisper.cpp `small.en` / `base.en`; Parakeet-TDT via sherpa-onnx benchmarked |
| Models | Manifest with engine revision, quantization, SHA-256, size, license, platforms; verified before load |

**Speaker attribution:** "You" comes from the mic channel and "Others" from meeting audio. Remote names come from calendar attendees plus user confirmation. Owners are never inferred from uncertain labels. On-device diarization ships only if Gate 1 benchmarks pass.

## Local storage

- SQLite encrypted as a whole database (SQLite3MultipleCiphers). A random key is protected by Electron safeStorage. FTS5 provides offline search.
- **Data:** titles, transcripts, notes, agendas, ticks, highlights, outbox, and auth material.
- **Partitioning:** per identity and workspace, so a different login never reveals earlier data.
- Partial text stays in memory until finalized.

## Sync

- Stable client IDs (UUIDv7) for meeting, capture, segment, and agenda item.
- Batches carry capture ID, sequence, idempotency key, revisions, and gaps. An identical retry is safe; a changed payload under a reused key is a conflict.
- Flush about every 10 s, on stop, and on reconnect. ACK only after server commit. Finalize after the final ACK.
- A change feed pulls agendas, projects, and ticks, using optimistic versions.
- **UI states:** capturing locally, waiting to sync, synced, cloud delayed, gap, auth required.
- Revoked membership stops uploads for that workspace. Content is never rerouted silently.
- Clients may hold several workspaces in different cells. The base URL comes from the account service.

## Updates and distribution

- electron-updater uses staged rollouts from signed feeds.
- Model files download separately and are verified against the manifest.
- macOS is signed with Developer ID and notarized; Windows is signed with Azure Artifact Signing.
- Update interruption and rollback are tested before each release.

## Performance budgets (to qualify)

| Budget | Target |
|---|---|
| Idle memory (main + renderers) | ≤ 350 MB |
| Capture CPU, two sources, small.en | Keeps real time on the qualified minimum hardware |
| Popup appears after trigger | ≤ 1 s |
| Overlay render on tick suggestion | ≤ 100 ms |
