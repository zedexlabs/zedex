> **Plan document — do not modify.**
> This file is the agreed plan and architecture. Treat it as source of truth.
> Changes must go through a new ADR or an explicit plan revision — do not edit in place.

---

> **Production target** — this is not a prototype or MVP. Every decision here targets a production product shipped in cycles.


# 02 — Desktop App and Native Capture

## Targets

| Target | Qualification hardware |
|---|---|
| macOS 14.2+ arm64 | Apple Silicon |
| macOS 14.2+ x64 | Intel Mac |
| Windows 11 x64 | Intel and AMD |
| Windows 11 arm64 | ARM device |

There is one package per architecture, each with a matching helper build. A successful build is not proof of capture support; [11-quality-testing](11-quality-testing.md) defines qualification.

## Process model

| Process | Owns | Must not |
|---|---|---|
| Electron main | Sign-in and web-session handoff, STT token requests, encrypted segment outbox, sync, helper supervision, meeting detection, window manager, updates | Hold meeting content beyond the outbox |
| Web content: app window | Remote `/app` route — all product UI | Access the filesystem, credentials, or shell |
| Web content: meeting popup | Remote `/desktop/popup` route — Start / open prep / dismiss | Start capture by itself |
| Web content: live overlay | Remote `/desktop/overlay` route — agenda, to-dos, notes, ticks, capture health | Hold data beyond the current meeting view |
| Native helper (C++) | Devices, capture, resampling, VAD, echo handling, STT streaming, health | Write audio anywhere, send audio over IPC, or hold Zedex credentials |

**Shell hardening (ADR-025, ADR-029):**
- `BaseWindow` + `WebContentsView` (no `BrowserView`); each view loads one allowlisted remote route; the installer bundles only an offline/error page.
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

## Capture and STT pipeline

`PCM capture → OS echo cancellation (mic) → mono + resample 16 kHz (speexdsp) → libfvad VAD → cloud STT WebSocket stream → text segments`

| Concern | Rule |
|---|---|
| Sources | Microphone and meeting audio kept separate; labelled "You" and "Others" |
| macOS | Core Audio process taps for meeting audio + microphone input |
| Windows | WASAPI microphone + output loopback; per-application loopback is qualified separately |
| Memory bound | ≤ 30 s RAM ring buffer per source for reconnect; no disk audio, ever |
| Persistence | No WAV, cache, diagnostic, or retry audio — audio is never written to disk or uploaded to Zedex servers |
| Cloud STT | Mic and Others streams sent separately to the STT provider WebSocket. Electron main obtains a short-lived session token from `ingest` (`POST /speech-sessions`) and passes it to the helper in `configure`. Provider keys and Zedex credentials never reach the helper. |
| Networking | OS-native WebSockets behind `stream_client.h`: `URLSessionWebSocketTask` (macOS), WinHTTP WebSocket (Windows). OS trust store and system/corporate proxy settings; no bundled OpenSSL |
| Echo | OS voice processing on the mic path (macOS voice-processing I/O; Windows communications capture AEC where exposed); text-level overlap dedupe as fallback |
| Libraries | speexdsp, libfvad, nlohmann/json, pinned through a vcpkg manifest; no ONNX runtime |
| Reconnect | On a drop, helper resends from the ring buffer. Gaps longer than the buffer size are recorded and shown to the user. |
| Overload | Explicit pause or drop with a reported gap |
| Failure | Finalized text is preserved and lost intervals are marked |
| Interface | `transcriber.h` interface retained; local engine can be added later as enterprise privacy mode |

**Speaker attribution:** "You" comes from the mic channel and "Others" from meeting audio. Remote names come from calendar attendees plus user confirmation. Owners are never inferred from uncertain labels.

## Local storage (segment outbox)

- SQLite encrypted as a whole database (SQLite3MultipleCiphers). A random key is protected by Electron safeStorage.
- **Data:** finalized transcript segments and typed-note segments not yet acknowledged by `ingest`, plus auth material. Rows are purged after ACK. No meeting library, no offline search (ADR-029).
- **Partitioning:** per identity and workspace, so a different login never reveals earlier data.
- Partial text stays in memory until finalized.

## Sign-in

- Electron main signs in once through the system browser (WorkOS, authorization code + PKCE on loopback).
- `account` issues a one-time handoff code that opens the web session inside the shell, so the user signs in once.
- The main-process token is used only for `POST /speech-sessions` and segment sync.

## Sync

- Stable client IDs (UUIDv7) for meeting, capture, segment, and agenda item.
- Batches carry capture ID, sequence, idempotency key, revisions, and gaps. An identical retry is safe; a changed payload under a reused key is a conflict.
- Flush about every 10 s, on stop, and on reconnect. ACK only after server commit. Finalize after the final ACK.
- Editable records (agendas, projects, ticks) are read and written by the web content directly; the desktop has no change feed.
- **UI states:** capturing locally, waiting to sync, synced, cloud delayed, gap, auth required.
- Revoked membership stops uploads for that workspace. Content is never rerouted silently.
- Clients may hold several workspaces in different cells. The base URL comes from the account service.

## Updates and distribution

- electron-updater uses staged rollouts from signed feeds.
- No model files are bundled or downloaded (cloud STT). Installer is ~80–100 MB (down from ~300 MB with a bundled model).
- macOS is signed with Developer ID and notarized; Windows is signed with Azure Artifact Signing.
- Update interruption and rollback are tested before each release.
- UI ships through web deploys; the shell and helper update rarely.

## Performance budgets (to qualify)

| Budget | Target |
|---|---|
| Idle memory (main + web content views) | ≤ 350 MB |
| Capture CPU, two sources streaming | ≤ 5% of one core on the qualified minimum hardware |
| Popup appears after trigger | ≤ 1 s |
| Overlay render on tick suggestion | ≤ 100 ms |
