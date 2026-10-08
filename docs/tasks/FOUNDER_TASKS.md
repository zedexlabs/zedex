> **Plan document — do not modify.**
> This file is the agreed plan and architecture. Treat it as source of truth.
> Changes must go through a new ADR or an explicit plan revision — do not edit in place.

---

> **Production target** — this is not a prototype or MVP. Every decision here targets a production product shipped in cycles.

---

# Founder — Phase 1 Task Assignment

Your role in Phase 1: build all web UI, own all product decisions, review every PR, and sign off at each milestone before it promotes to staging. You supervise but you also ship — the web app is yours.

Read these documents before starting UI work:
- [`docs/UI_PAGES.md`](../UI_PAGES.md) — every page, every button, every element. This is your spec.
- [`docs/PHASE_1_PLAN.md`](../PHASE_1_PLAN.md) — what ships in Phase 1 and why
- [`docs/TEAM_TASKS.md`](../TEAM_TASKS.md) — branch management, dependency order, how to sign off
- [`docs/architecture/08-security-privacy.md`](../architecture/08-security-privacy.md) — privacy invariants your UI must enforce

---

## Tech stack for the web app

| Concern | Library |
|---|---|
| Framework | React 19 |
| Build | Vite |
| Server state | TanStack Query v5 |
| Styling | Tailwind v4 |
| Component primitives | Radix UI |
| Rich text editor | TipTap |
| Drag and drop | dnd-kit |
| Forms | react-hook-form + Zod (shared schemas from `packages/contracts`) |
| Routing | TanStack Router |

The web app lives in `packages/ui`. It loads inside the Electron shell as a remote URL and runs standalone in the browser.

---

## Dependency map — which pages unlock when

You can start building UI scaffolding and static pages immediately. Pages that call backend APIs unlock as each backend step merges to `dev`.

| Pages | Unlocks after |
|---|---|
| Static pages: sign-in, workspace setup, download, invite (W-01–W-05) | Sinthujan Step 2 merged |
| Meetings list, meeting view shell (W-10, W-11) | Udula Step 4 merged |
| Transcript tab, card tab, notes tab | Udula Step 5 merged |
| Projects list and view (W-20, W-21, W-22) | Sinthujan Step 6 merged |
| Agenda editor (W-30) | Sinthujan Step 7 merged |
| Preference summary builder (W-40) | Udula Step 8 merged |
| Workspace settings, profile (W-70, W-71) | Sinthujan Step 2 merged |

---

## Web pages to build

All page and element specs are in [`docs/UI_PAGES.md`](../UI_PAGES.md). This list maps each page to its step and gives the build priority.

### Auth and onboarding (W-01 to W-05) — Step 2 dependency

- **W-01 Sign-in:** Google and Microsoft buttons (WorkOS AuthKit UI), email fallback. This is the first thing every user sees.
- **W-02 Workspace setup:** workspace name + slug inputs, Create button. Show the slug preview as the user types the name.
- **W-03 Calendar connect:** Google Calendar and Microsoft Outlook connect buttons, read-only scope summary, Skip option.
- **W-04 Desktop app download:** platform detection, download buttons, Skip option.
- **W-05 Invite teammates:** multi-email input, role selector, Send Invites, Copy link.

### Meetings (W-10, W-11, W-12) — Step 4 + 5 dependency

- **W-10 Meetings list:** chronological feed, filter bar (date, project, meeting tool, capture status). Capture status badge per row (captured / not captured / transcript uploaded / card ready). Empty state: "Download the desktop app or import a transcript" with two CTA buttons.
- **W-11 Meeting view:** four tabs — Transcript, Notes, Meeting Card, Agenda.
  - **Transcript tab:** segmented by speaker ("You" / "Others"), timestamps, confidence flag highlights on uncertain values. Speaker mapping button per unknown speaker. Copy segment.
  - **Notes tab:** TipTap editor. Notes from the overlay appear here timestamped. Standard rich-text toolbar (bold, italic, heading, bullets, numbered list, link). Copy all notes.
  - **Meeting Card tab:** four sections (Topics, Decisions, Open questions, Next steps). Each item: AI-proposed text + evidence link + Confirm / Edit / Reject buttons. AI text and user-edited text visually distinct. Add item button. Regenerate card button (only for items with no user edit).
  - **Agenda tab:** same surface as W-30 (Agenda editor), embedded.
- **W-12 Transcript import dialog:** file drop zone (TXT / VTT / SRT), paste area, Import + Cancel.

### Projects (W-20, W-21, W-22) — Step 6 dependency

- **W-20 Projects list:** grid of project cards + folders. Per card: name, member count, meeting count, access badge (Private/Team/Shared). New Project + New Folder buttons. Empty state: New Project CTA.
- **W-21 Project view:** meeting list with dnd-kit drag-and-drop reordering. Tabs: Meetings, (Commitments — Gate 4), (Reports — Gate 4). Add Meeting button. New Auto-Rule button. Manage Access button.
- **W-22 Access control panel:** member list with role dropdowns. Add Member (email + role). Remove Member. Close.

### Agenda editor (W-30) — Step 7 dependency

Three sections: Previous meeting, This meeting, Next-meeting plan.

**Previous section:** read-only summary from the last instance. Each item has an icon showing whether it was ticked or carried over. Unresolved items are highlighted.

**This meeting section:** editable agenda items. Per item: text input, type selector (topic / decision / question / action), owner picker, tick checkbox, AI-drafted badge if proposed by AI. Accept AI Draft button (accepts all AI items at once). Add item button.

**Next-meeting plan section:** items the team is deferring. Editable. Same per-item controls.

Global: Share agenda link, Export button.

### Preference summaries (W-40) — Step 8 dependency

- Date range picker + project multi-select + meeting multi-select
- Style selector: executive / detailed / bullet
- Focus selector: decisions / next steps / blockers
- Generate Summary button. Regenerate. Copy. Save preferences. Load saved preference set.

### Admin and settings (W-70, W-71) — Step 2 dependency

- **W-70 Workspace settings:** General (name, slug, Save, Delete workspace). Members (list, Invite Member, Change Role, Remove, Resend/Revoke invites). Integrations (connected list, Connect/Disconnect per provider). Security (session list, Revoke session, Revoke all others). Privacy (Request export, Delete all data).
- **W-71 Personal profile:** display name, email (read-only), notification toggles (per type: in-app/email), connected accounts, theme (system/light/dark).

### Shared dialogs (D-01 to D-06)

- **D-01 Notification panel:** slide-in panel, per-notification action button, Mark all read, Settings link.
- **D-02 Command palette:** ⌘K / Ctrl+K, actions: jump to meeting, open project, create meeting, search. Keyboard shortcut hints.
- **D-03 Meeting quick-create:** title, date/time, attendees, project, Create/Cancel.
- **D-04 Confirmation dialog:** destructive action warning, Confirm (danger style), Cancel.
- **D-05 Speaker mapping dialog:** speaker track list, name input with autocomplete from workspace members, Save mapping, Cancel.

### Empty states and error states

Every list page needs:
- Empty state: illustration placeholder, one-line description, one primary CTA button
- Loading state: skeleton placeholders (not spinners)
- Error state: "Failed to load" message + Retry button
- Not found: message + back link
- No permission: "You don't have access" + Request access button

---

## Supervision responsibilities

### PR reviews

You review every PR before it merges to `dev`. Check:
- Does the API match what the UI expects? (schemas in `packages/contracts`)
- Do the privacy invariants hold? (no transcript text in logs, no auto-ticking, no auto-external-write)
- Does the feature do what the product plan says?
- Are there obvious missing error states or edge cases?

You have 24 h to review. If you are unavailable, Udula reviews instead.

### Milestone sign-offs (M1–M9)

At the end of each milestone, before approving the `dev → staging` PR:

1. Test the feature end-to-end in the staging cell yourself — not just CI passing.
2. Confirm the exit criteria from `PHASE_1_PLAN.md §5` are met for this milestone.
3. Check `IMPLEMENTATION_STATUS.md` is updated with evidence.
4. Run the privacy spot-check: log into a second test workspace, confirm you cannot see any data from the first.
5. Approve the `dev → staging` PR.

### Product decisions

Any question about what a feature should do — edge cases, wording, whether something is in scope — comes to you, not to Udula or Sinthujan. The developers build what is decided; they do not decide.

### 2-week dogfood (M9)

At milestone 9, the founders run 2 weeks of real meeting capture on the staging cell:
- Use Zedex for your own internal meetings every day
- Record issues in the repo as bugs
- Confirm exit criteria evidence in `IMPLEMENTATION_STATUS.md`:
  - Capture works on macOS and Windows with Zoom, Teams, and Meet
  - WER < 5 % on your own meetings
  - Meeting card generated in < 60 s
  - Agenda draft appears 24 h before recurring meetings
  - No data loss on network drop and app restart

---

## Useful references

| Document | Why you need it |
|---|---|
| [`docs/UI_PAGES.md`](../UI_PAGES.md) | Your full spec — every page and element |
| [`docs/PHASE_1_PLAN.md`](../PHASE_1_PLAN.md) | What ships, user flows, exit criteria |
| [`docs/architecture/08-security-privacy.md`](../architecture/08-security-privacy.md) | What the UI must never do (no auto-tick, no auto-write) |
| [`docs/TEAM_TASKS.md`](../TEAM_TASKS.md) | Branch rules, dependency order, how to sign off |
| [`AGENTS.md`](../../AGENTS.md) | Definition of Done — applies to UI PRs too |
