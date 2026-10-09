---
name: zedex-desktop-capture
description: Work on the Electron thin shell, the C++ capture helper, cloud STT streaming, the encrypted segment outbox, sync, popup/overlay, signing, or updates. Use for apps/desktop, native/capture-asr, and anything touching audio, IPC, or helper protocol.
---

# Desktop shell and native capture

Reference: `docs/architecture/02-desktop-native.md`, ADR-010/011/013/014/023/025/029, `docs/UI_PAGES.md` (DS-1..DS-6).

## Hard rules (P0 if violated)

- Audio is **never** written to disk, never uploaded to Zedex servers, never crosses the helper IPC. RAM ring buffer <= 30 s per source. No WAV, cache, diagnostic, or retry audio files.
- Audio goes only from helper to the contracted STT provider WebSocket using a short-lived token from `ingest` `POST /speech-sessions`. Provider keys and Zedex credentials never reach the helper or device.
- Capture never starts without an explicit user click. Popup is never auto-start. Overlay never auto-ticks.
- The overlay and popup are hidden from screen share only to protect private notes. Never hide that capture is happening; keep the visible capture indicator and consent reminder. State the platform guarantee honestly (Windows 10 2004+ excluded; macOS best effort).

## Electron main

- `BaseWindow` + `WebContentsView` (never `BrowserView`). Each view loads one allowlisted remote route; the installer bundles only the offline/error page.
- Sandbox on, context isolation on, node integration off, deny-by-default permissions, strict CSP, navigation restricted to the origin allowlist, sender checks on every IPC handler.
- Preload exposes a narrow API. Every IPC message is validated with Zod from `packages/contracts/src/ipc`. Define the schema before the handler.
- Sign-in: system browser, authorization code + PKCE on loopback, no client secret. `account` issues a one-time, short-lived, single-use handoff code for the web session. The main-process token is used only for speech sessions and segment sync.
- Main must not hold meeting content beyond the outbox; web content gets no filesystem, credentials, or shell.

## Native helper (C++)

- Versioned newline-delimited JSON over child-process pipes, bounded message size, version check before start. Commands: `listDevices`, `configure`, `start`, `pause`, `resume`, `stop`, `health`, `shutdown`. Events: `ready`, `started`, `levels`, `partial`, `final`, `deviceChanged`, `permissionChanged`, `micActivity`, `overload`, `gap`, `stopped`, `failure`. Change the schema in `packages/contracts/src/helper` and the C++ `protocol.h` together; fuzz malformed input.
- Pipeline: PCM capture -> OS echo cancellation (mic) -> mono 16 kHz (speexdsp) -> libfvad -> cloud STT stream. Mic ("You") and meeting audio ("Others") stay separate.
- macOS: Core Audio process taps + voice-processing I/O; `URLSessionWebSocketTask`. Windows: WASAPI mic + loopback, communications AEC; WinHTTP WebSocket. OS trust store and system proxy; no bundled OpenSSL. Libraries pinned by `vcpkg.json`; no ONNX runtime.
- Reconnect resends from the ring buffer; gaps beyond the buffer are recorded and shown. Overload pauses or drops with a reported gap. Finalized text is preserved, lost intervals marked.
- RAII, no raw owning pointers, bounded queues, no allocation in the audio callback, no blocking calls on the capture thread. Build with CMake presets; CI builds all four targets.

## Outbox and sync

- SQLite3MultipleCiphers whole-database encryption; key protected by Electron `safeStorage`; partitioned per identity and workspace so another login never sees earlier data.
- Stores unacknowledged finalized segments and typed notes only; purge after ACK. No library, no offline search.
- Stable UUIDv7 client IDs. Batches carry capture ID, sequence, idempotency key, revisions, gaps. Identical retry is safe; changed payload under a reused key is a conflict. Flush ~10 s, on stop, on reconnect. ACK only after server commit; finalize after the final ACK.
- UI states: capturing locally, waiting to sync, synced, cloud delayed, gap, auth required. A cloud or model outage never stops local capture.

## Qualification

A successful build is not hardware support. Qualification evidence (macOS arm64/x64, Windows x64/arm64; headphones, speakerphone echo, Bluetooth; Zoom, Meet, Teams, Slack, browser share; WER; reconnect; proxy; CPU/RAM) goes in `docs/CAPTURE_MATRIX.md` / status doc with device and date. Budgets: idle <= 350 MB, capture CPU <= 5% of one core on minimum hardware, popup <= 1 s, overlay render <= 100 ms. Unmeasured budgets are reported as unmeasured.

Releases: macOS Developer ID + notarization, Windows Azure Artifact Signing, signed feeds, staged rollout; test update interruption and rollback.
