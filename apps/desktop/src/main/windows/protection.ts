// Screen-share content protection.
// Windows: SetWindowDisplayAffinity(WDA_EXCLUDEFROMCAPTURE) — fully excluded.
// macOS: setContentProtection(true) — best effort; newer ScreenCaptureKit apps may bypass.
// Exposes protection level and a collapse hotkey to renderer via IPC.
// Gate 2 — placeholder
export {}
