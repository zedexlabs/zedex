---
name: zedex-web-ui
description: Build or review Zedex web pages and shared UI components (React, packages/ui, apps/web). Covers human-control UX rules, evidence links, approval panels, states, accessibility, and performance. Use for any file under apps/web or packages/ui.
---

# Web UI

Reference: `docs/UI_PAGES.md` (every page W-xx, dialog D-xx, desktop surface DS-x), ADR-016/025. The web app is the product; the desktop is a thin shell that loads remote routes (`/app`, `/desktop/popup`, `/desktop/overlay`).

## Stack

React 19, Vite, TanStack Router and Query v5, Tailwind v4, Radix UI primitives, TipTap, dnd-kit, react-hook-form + Zod using schemas from `packages/contracts`. `packages/ui` is presentation only: no credentials, no data fetching of its own. Do not add a library when one of these covers the need.

## Product rules the UI must enforce

- **Human control.** AI-proposed items are visibly "proposed" until a person confirms. Nothing ticks, confirms, closes, or writes externally without a click. Never pre-check a box on the user's behalf.
- **AI vs human text** is always visually distinct, and every AI sentence has an `EvidenceLink` to its transcript segment.
- **Flagged values** (numbers, dates, names, money) are highlighted and must be verified or corrected before the card is confirmed.
- **Honest states.** "Not captured", capture gaps, sync state (capturing locally, waiting, synced, delayed, auth required), and stale/invalidated outputs are first-class and visible. Never hide a failure to look polished.
- **Approvals** use `ApprovalPanel` showing the exact payload and destination that will be written; edit after approval invalidates the approval.
- Speaker labels: "You" and "Others" from channels; remote names only from calendar attendees plus user confirmation.
- Consent: show workspace consent reminders and the capture indicator; never conceal capture.

## Every page ships with

Loading skeleton (not a spinner), empty state with one primary action, error state with retry, not-found, no-permission ("Request access"), and offline/degraded behavior. Optimistic updates carry `If-Match` versions and handle conflicts. Lists are cursor-paginated and virtualized when long. Incomplete user-facing work sits behind a feature flag.

## Security and privacy

- Session via secure HTTP-only cookie with CSRF protection; no tokens in `localStorage` or URLs. Never put personal data in query strings.
- Render transcript, notes, and model output as text or sanitized rich text; never `dangerouslySetInnerHTML` on untrusted content. Strict CSP compatible code.
- No transcript, note, or commitment content in analytics, error reporters, or session replay.
- Authorization is enforced by the server; hiding a button is UX, not security.

## Quality bar

- Accessibility: WCAG 2.1 AA, full keyboard operation, visible focus, Radix semantics, labelled inputs, color contrast, `prefers-reduced-motion`, screen-reader announcements for live regions (sync state, suggestions). Run an axe check in e2e.
- Responsive to phone width; light and dark themes; no layout shift on data load.
- Performance: hashed immutable assets, route-level code splitting, no waterfalls (parallel queries), overlay renders a tick suggestion in <= 100 ms, popup in <= 1 s.
- Realtime through Web PubSub groups with reconnect and resync from the server on gap.
- Tests: component tests for state machines and states above, Playwright e2e for the flow, desktop-shell flows via the Electron driver. See `zedex-testing`.
