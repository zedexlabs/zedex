> **Plan document — do not modify.**
> This file is the agreed plan and architecture. Treat it as source of truth.
> Changes must go through a new ADR or an explicit plan revision — do not edit in place.

---

> **Production target** — this is not a prototype or MVP. Every decision here targets a production product shipped in cycles.

---

# Zedex — UI Pages & Element Inventory

**Purpose:** Context document for designers and Claude Code. Lists every screen, the elements it contains, and the intent of each action. Does not specify color, layout, or spacing — those are implementation concerns.

**Delivery scope:** Pages are grouped by Gate. Gates 2–3 cover Phase 1. Later gates are included so the design system can be planned in full from the start.

---

## Desktop Shell (Electron — thin shell, macOS + Windows)

The desktop shell is a locked-down Electron window (`BaseWindow` + `WebContentsView`). Almost all UI is the web app loaded remotely from the Zedex domain. The shell itself contributes four native floating surfaces: a popup, a full overlay, a status strip, and an offline fallback page.

---

### DS-1 · Meeting Popup

**When:** Appears automatically when a calendar event starts (calendar-watch) or microphone activity is detected on a known meeting app (Zoom, Teams, Meet). Floats above all windows. Never starts capture on its own.

**What it shows:**
- Meeting title (from calendar)
- Start time and duration
- Attendee avatars with names (first 4, then "+ N more")
- Capture-ready status indicator

**Buttons / actions:**
- `Start Notes` — starts the capture session; only action that begins capture
- `Open Prep` — opens the meeting's agenda/prep view in the main shell window
- `Dismiss` — closes popup without capturing; can re-trigger manually from tray

**States the popup cycles through:**
- Idle (just appeared)
- Capture active (shows live timer, changes primary button to `Stop`)
- Capture stopped (shows `Open Summary` CTA)

---

### DS-2 · Full Floating Overlay

**When:** Active capture session. Floats above the meeting app window and is positioned to be outside the standard screen-share capture region. The user can drag it to reposition.

**What it shows:**
- **Header bar:** meeting title, elapsed timer, capture status icon (live / reconnecting / stopped), microphone level indicator for "You" track, audio level for "Others" track
- **Agenda section:** ordered list of agenda items with tick checkbox per item; AI-highlighted items shown with a soft indicator (Gate 3)
- **Notes section:** single-line quick-note input that appends timestamped notes; shows the last 2–3 notes inline
- **Live suggestions strip** (Gate 3): a single line at the bottom showing the current AI suggestion (e.g., "Decision detected — tick or dismiss"); never auto-ticked

**Buttons / actions:**
- `Stop` — ends capture and flushes the outbox; triggers the post-meeting summary flow
- `Pause / Resume` — pauses STT streaming (e.g., side conversation); audio is not captured during pause
- `Tick item` (per agenda item) — human marks the item as discussed
- `Add note` — submits the typed note
- `Collapse →` — collapses overlay to the DS-3 Status Strip
- `Drag handle` — reposition the overlay anywhere on screen
- `Resize handle` (corner) — resize between compact and expanded height
- Suggestion: `Tick` / `Dismiss` (per live suggestion, Gate 3)

**Overlay states:**
- Expanded (default) — shows header + agenda + notes + suggestions
- Compact — header + quick-note only
- Status strip — see DS-3

---

### DS-3 · Status Strip (Minimized Overlay)

**When:** User collapses the full overlay during a meeting. A thin floating bar stays visible.

**What it shows:**
- Capture status dot (green = live, amber = reconnecting, red = stopped)
- Elapsed time
- Meeting title (truncated)

**Buttons / actions:**
- `Expand ↑` — restores full overlay (DS-2)
- `Stop` — ends the session without needing to expand

---

### DS-4 · Post-Capture Notification

**When:** Capture session ends (user clicks Stop or session ends automatically).

**What it shows:**
- Session duration
- Segment count synced to server
- Outbox flush status (all segments acknowledged / N segments pending)

**Buttons / actions:**
- `Open Summary` — opens the meeting view in the main shell window
- `Dismiss`

---

### DS-5 · System Tray Menu

**When:** App is running in the background (no popup or overlay visible).

**What it shows:**
- App name and current capture state
- Next calendar event (title + time)

**Menu items:**
- `Open Zedex` — brings main window to front
- `Start capture` (if a meeting is in progress but popup was dismissed)
- `Upcoming: [meeting title]` (informational, click to open prep)
- `Preferences` — opens personal settings in main window
- `Quit Zedex`

---

### DS-6 · Offline / Error Page

**When:** Shell cannot reach the web app (no network, auth failure, app unreachable). This is the only locally-bundled HTML page in the installer.

**What it shows:**
- Connection status (offline / server unreachable / auth expired)
- Outbox status: "N segments saved locally, pending sync"
- Last successful sync timestamp

**Buttons / actions:**
- `Retry connection`
- `Sign out` — clears local auth state; segments in outbox survive until next sign-in
- `Report issue` — copies a diagnostic bundle to clipboard (no content, only metadata)

---

## Web App — Auth & Onboarding

---

### W-01 · Sign-in

**When:** Unauthenticated entry point for both web and the desktop shell auth handoff.

**What it shows:**
- Product name and one-line value prop
- Sign-in options

**Buttons / actions:**
- `Continue with Google` — OAuth via WorkOS (opens system browser for desktop)
- `Continue with Microsoft` — OAuth via WorkOS
- `Continue with email` — magic link / email code fallback

---

### W-02 · Workspace Setup (Onboarding Step 1)

**When:** First time a user creates a workspace.

**What it shows:**
- Workspace name field
- Workspace slug field (used in invite links)
- Team size selector (for tier guidance, not gating)

**Buttons / actions:**
- `Create Workspace` — provisions the workspace
- `Back` — returns to sign-in if applicable

---

### W-03 · Calendar Connect (Onboarding Step 2)

**When:** Immediately after workspace creation, or re-accessible from settings.

**What it shows:**
- Available calendar providers (Google Calendar, Microsoft Outlook)
- Connected state per provider
- What Zedex will read (event titles, attendees, timing — never event bodies by default)

**Buttons / actions:**
- `Connect Google Calendar` — OAuth consent flow (read-only scope)
- `Connect Microsoft Outlook` — OAuth consent flow (read-only scope)
- `Skip for now` — proceeds without a calendar; meetings can still be captured manually
- `Disconnect` (per connected provider) — revokes the calendar grant

---

### W-04 · Desktop App Download (Onboarding Step 3 — optional)

**When:** Shown to users who signed in on web but have not installed the desktop app.

**What it shows:**
- What the desktop app adds (capture, popup, overlay)
- Platform detection (macOS / Windows)

**Buttons / actions:**
- `Download for macOS`
- `Download for Windows`
- `Skip — use web only` — continues with transcript import as the capture path

---

### W-05 · Invite Teammates

**When:** Last step of onboarding or accessible from workspace settings.

**What it shows:**
- Email input (multi-entry)
- Role selector per invitee (Member / Admin)
- Pending invites list

**Buttons / actions:**
- `Send Invites`
- `Copy invite link`
- `Remove` (per pending invite)
- `Done / Skip`

---

## Web App — Core Navigation

The top-level shell wraps every authenticated page.

**Global nav elements (always present):**
- Workspace name / switcher (click to switch or create a workspace)
- `New Meeting` — quick-create a manual meeting entry
- Notifications bell — opens notification panel
- User avatar menu: `Profile`, `Workspace Settings`, `Sign out`
- Primary nav links: `Meetings`, `Projects`, `Agenda`, `Search` (Gate 3)

---

## Web App — Meetings

---

### W-10 · Meetings List

**When:** Default landing page after auth.

**What it shows:**
- Chronological list of meetings (upcoming + past)
- Per-meeting: title, date/time, attendees avatars, capture status badge (captured / not captured / transcript uploaded), AI card status (pending / ready / confirmed)
- Filter bar: date range, project, attendee, capture status

**Buttons / actions:**
- `New Meeting` — creates a blank meeting entry for manual tracking or transcript import
- `Filter` — opens filter panel
- Meeting row click — opens the Meeting View (W-11)
- `Upload Transcript` (on uncaptured meetings) — opens transcript import dialog

---

### W-11 · Meeting View

**When:** Single-meeting detail page. Central work surface.

**Tabs:**

#### Tab — Transcript
**What it shows:**
- Segmented transcript with speaker labels (You / Others or names if mapped)
- Timestamp per segment
- Segment-level evidence links from the AI card

**Buttons / actions:**
- `Map Speaker` (per speaker label) — assigns a name to an anonymous speaker track
- `Copy Segment` — copies segment text
- `Highlight` — marks a segment (anchors a note to it)

#### Tab — Notes
**What it shows:**
- Rich-text notes editor (TipTap)
- Notes taken during the meeting (from the overlay) appear here, timestamped
- Free-form area for post-meeting notes

**Buttons / actions:**
- Full rich-text toolbar: bold, italic, heading, bullet list, numbered list, link, mention
- `Export to Google Doc` (Gate 4) — user-initiated write, not auto
- `Copy all notes`

#### Tab — Meeting Card (AI Summary)
**What it shows:**
- Structured sections: Topics covered, Decisions, Open questions, Next steps
- Each item shows: AI-proposed text, evidence segment link, confirmation status
- Unconfirmed items are visually distinct from confirmed items

**Buttons / actions:**
- `Confirm` (per item) — human marks the item as accurate
- `Edit` (per item) — opens inline edit; locks out regeneration for that item
- `Reject` (per item) — removes the item from the card
- `Add item` — user manually adds a topic, decision, question, or next step
- `Regenerate card` — re-runs the AI summary (only for unedited items)
- `Export card` — copies or exports the confirmed card

#### Tab — Agenda
See W-20 (Agenda Editor) — this tab is the same surface embedded in the meeting view.

**Meeting-level actions (outside tabs):**
- `Edit Title` — inline rename
- `Assign to Project` — opens project picker
- `Share` — generates a share link (Gate 3 permissions apply)
- `Delete Meeting` — with confirmation dialog

---

### W-12 · Transcript Import Dialog

**When:** Opened from `Upload Transcript` on W-10 or W-11.

**What it shows:**
- Drop zone for TXT / VTT / SRT files
- Paste-area alternative
- Format guidance

**Buttons / actions:**
- File picker trigger
- `Import` — processes and attaches the transcript
- `Cancel`

---

## Web App — Projects

---

### W-20 · Projects List

**When:** Main Projects page.

**What it shows:**
- Grid or list of Projects and folders
- Per-project: name, member count, meeting count, last activity
- Access badges (Private / Team / Shared)

**Buttons / actions:**
- `New Project` — opens project creation dialog
- `New Folder` — groups projects into a folder
- Project card click — opens Project View (W-21)

---

### W-21 · Project View

**When:** Single-project detail page.

**What it shows:**
- Project name and description
- Meeting list for this project (with drag-and-drop reordering)
- Series auto-add rules in effect
- Open commitments summary (Gate 4)
- Reports (Gate 4)

**Tabs:**
- `Meetings` — meeting list for this project
- `Commitments` (Gate 4) — commitment board scoped to this project
- `Reports` (Gate 4) — aggregated metrics

**Buttons / actions:**
- `Add Meeting` — attaches an existing meeting to this project
- Drag meeting card — reorders or moves between projects (dnd-kit)
- `New Auto-Rule` — creates an attendee-domain or series auto-routing rule
- `Manage Access` — opens access control panel (OpenFGA)
- `Edit Project` — rename, description, icon
- `Archive Project`
- `Delete Project` (with confirmation)

---

### W-22 · Project Access Control Panel

**When:** Opened from `Manage Access` in W-21.

**What it shows:**
- Current members with role (Viewer / Editor / Admin)
- Pending invites

**Buttons / actions:**
- `Add Member` — email input + role selector
- `Change Role` (per member) — dropdown
- `Remove Member` (per member)
- `Close`

---

## Web App — Agenda

---

### W-30 · Agenda Editor

**When:** Pre-meeting prep surface. Available as a standalone page and embedded in W-11 Meeting View. 24 h before a meeting the AI drafts content; humans edit and accept.

**What it shows:**
Three sections:
1. **Previous meeting** — carry-over items, decisions and commitments from the last occurrence, AI-proposed summary of what closed and what is still open
2. **This meeting** — editable agenda items list, attachments (linked docs, context notes), attendee prep tasks
3. **Next-meeting plan** — early items for the subsequent occurrence

Per agenda item: text, owner assignment, type label (topic / decision / question / action), AI-drafted badge if AI proposed it.

**Buttons / actions:**
- `Accept AI Draft` — moves all AI-proposed items to confirmed state (one click to approve the whole draft)
- `Accept item` (per AI-proposed item) — confirms a single AI-proposed item
- `Edit item` (per item) — inline edit
- `Remove item` (per item)
- `Add item` — manual entry
- `Assign owner` (per item) — opens member picker
- `Attach doc` — links a Google Doc or text file to the agenda (Gate 3)
- `Share agenda` — generates a read-only share link
- `Export` — copies agenda as text or sends to Google Doc (Gate 4)

---

## Web App — Preference Summaries (Gate 2)

---

### W-40 · Preference Summary Builder

**When:** User-initiated. Generates a summary across a chosen scope of meetings.

**What it shows:**
- Scope selectors: date range, projects, meeting series
- Style selector: brief / detailed / executive
- Generated summary (if one exists)

**Buttons / actions:**
- `Generate Summary` — triggers AI generation from meeting cards (not raw transcripts)
- `Regenerate` — re-runs with current scope
- `Copy`
- `Export to Google Doc` (Gate 4)

---

## Web App — Search & Chat (Gate 3)

---

### W-50 · Search

**When:** Accessed from global nav `Search`.

**What it shows:**
- Search input
- Filters: date range, project, meeting, speaker
- Results list: matched transcript segments and card items, each with meeting title, date, and evidence link

**Buttons / actions:**
- Search input (submit on enter or button)
- `Filter` panel toggle
- Result click — opens the meeting at the matched segment

---

### W-51 · Chat / Ask (Gate 3)

**When:** Tab or panel alongside search; scoped to authorized meetings.

**What it shows:**
- Conversational input
- AI responses with source citations (meeting title, date, segment evidence)
- Scope indicator (which meetings are in scope for this query)

**Buttons / actions:**
- Message input (submit on enter)
- `Clear conversation`
- Citation link (per cited segment) — opens the meeting at that segment
- `Change scope` — adjusts which meetings the query covers

---

## Web App — Approval Queue & Commitments (Gate 4)

---

### W-60 · Approval Queue

**When:** Accessed from global nav or notification badge. Lists pending external writes awaiting human approval.

**What it shows:**
- Pending items: target system (Linear / HubSpot / Slack / Google Docs), exact payload preview, source meeting, proposed owner, proposed due date
- History tab: approved / rejected writes

**Buttons / actions:**
- `Approve` (per item) — executes the exact payload shown; cannot be auto-clicked
- `Edit & Approve` (per item) — opens payload editor before executing
- `Reject` (per item) — dismisses with optional reason
- Filter by: system, meeting, owner

---

### W-61 · Commitments Board

**When:** Global view of all tracked commitments across all meetings and projects.

**What it shows:**
- Board columns: Open / In progress / Done / Overdue
- Per commitment: title, owner, due date, source meeting, linked external item (Linear issue, HubSpot note, etc.), delivery evidence status

**Buttons / actions:**
- `New Commitment` — manual entry
- Drag card between columns
- `Mark delivered` (per commitment) — requires evidence or confirmation text; cannot be auto-marked
- `View source meeting` (per commitment)
- `View external item` (per commitment) — opens the linked Linear / HubSpot item
- Filter by: project, owner, due date, status

---

## Web App — Admin & Settings

---

### W-70 · Workspace Settings

**Sections:**

#### General
- Workspace name (editable)
- Workspace slug
- `Save changes`
- `Delete Workspace` (danger zone, with confirmation)

#### Members
- Members list with role (Member / Admin)
- `Invite Member`
- `Change Role` (per member)
- `Remove Member` (per member)
- Pending invites list with `Resend` and `Revoke` per invite

#### Integrations
- Connected integrations list (calendar providers, Gate 4 tools)
- `Connect` / `Disconnect` per integration
- Per integration: last synced, permission scope shown
- `Reconnect` if token has expired

#### Billing (Gate 4)
- Current plan and seat count
- Usage summary (STT minutes this period, model usage)
- `Upgrade Plan`
- `Manage Billing` — opens Stripe customer portal
- Payment method summary (last 4 digits, expiry — no full card numbers shown)

#### Security
- Session list (active sessions across devices)
- `Revoke session` (per session)
- `Revoke all other sessions`
- Audit log download (admin only)

#### Privacy & Data
- Data export request: `Request workspace export` — delivers a ZIP; human-initiated, no auto-export
- `Delete all workspace data` — danger zone, irreversible, with multi-step confirmation
- Consent record summary

---

### W-71 · Personal Profile Settings

**Sections:**

#### Profile
- Display name (editable)
- Email (read-only, managed by WorkOS)
- `Save`

#### Notifications
- Toggle per notification type: meeting reminder, AI card ready, commitment overdue, approval needed, coverage alert
- Delivery channel per type: in-app / email
- `Save preferences`

#### Connected accounts
- Calendar accounts connected to this user (separate from workspace-level)
- `Connect` / `Disconnect`

#### Appearance
- Theme selector: system / light / dark

---

## Web App — Sharing & Viral (Gate 3)

---

### W-80 · Share Link View

**When:** An external person opens a shared link (no Zedex account required).

**What it shows:**
- Meeting title and date
- Shared content only (meeting card items that were explicitly shared, or specific notes)
- No transcript unless explicitly included in the share
- Expiry notice if applicable

**Buttons / actions:**
- `Request access` — sends a notification to the sharer to grant full access
- `Sign up for Zedex` — viral CTA at the bottom; never blocks content

---

### W-81 · Share Settings Dialog

**When:** Opened from `Share` on W-11 Meeting View or W-21 Project View.

**What it shows:**
- Current share state (off / link-only / specific people)
- What is included in the share (card only / notes / transcript segments)
- Expiry selector

**Buttons / actions:**
- `Create link`
- `Copy link`
- `Revoke link`
- `Add specific person` — email input
- Content toggles: include card / include notes / include transcript
- `Close`

---

## Web App — Catch-up & Coverage (Gate 3)

---

### W-90 · Catch-up Brief

**When:** Shown to a user who missed a meeting, 10–15 min before the next occurrence.

**What it shows:**
- Since you were last here: decisions, open commitments, status changes, open questions
- Gaps section: topics where no capture exists → "Not captured"
- Coverage roster link

**Buttons / actions:**
- `Acknowledge` — marks the brief as read
- `View source meeting` (per item)
- `Open next meeting prep`

---

### W-91 · Coverage Roster

**When:** Per meeting series or team.

**What it shows:**
- Primary and backup capturers for each series
- Next uncovered occurrences
- Alert history

**Buttons / actions:**
- `Assign primary capturer` (per series)
- `Assign backup capturer` (per series)
- `Ask teammate to capture` — sends a notification to a selected teammate

---

## Web App — Reports (Gate 4)

---

### W-100 · Team Report

**When:** Scheduled digest or on-demand per team or project.

**What it shows:**
- Decisions made this period
- Commitments delivered / overdue / created
- Meeting hours
- Series health (coverage rate, agenda completion rate)
- Coverage gaps

**Buttons / actions:**
- Date range picker
- Scope selector: team / project
- `Export report` — downloads or sends to Google Doc
- `Schedule digest` — sets a recurring delivery cadence

---

## Web App — Canvas (Gate 5)

The canvas is a visual, node-graph workflow builder built on React Flow (`@xyflow/react`). Modeled after n8n: users drag nodes onto a canvas, connect them with edges, and configure each node's payload inline. Every action node that writes to an external system requires a human to approve the exact payload before it executes — no auto-execution.

---

### W-110 · Workflow Canvas (canvas view)

**When:** Gate 5. The main surface for building and managing automation workflows.

**What it shows:**
- Infinite-scroll canvas with a grid background
- Minimap (bottom-right corner) — overview of the full graph
- Zoom controls
- Node graph — nodes connected by directional edges
- Each edge shows the data type flowing through it (meeting data / commitment / text payload)
- Active / inactive indicator per workflow (top-right of canvas)

**Canvas toolbar (top bar):**
- Workflow name (editable inline)
- `Save` — saves the workflow definition
- `Enable` / `Disable` toggle — activates or pauses the workflow
- `Test run` — dry-run against a selected past meeting; shows every node's output in sequence, never executes external writes
- `Workflow history` — opens a side panel of past runs with status (succeeded / failed / pending approval)
- `Duplicate` — clones the entire workflow
- `Delete` (with confirmation)
- `Back to workflows list`

**Canvas interactions:**
- Drag node from palette onto canvas
- Click-drag node to reposition
- Drag from output port → input port to connect nodes
- Click edge to select and delete
- Right-click canvas → context menu: Add node, Add sticky note, Select all, Paste
- Cmd/Ctrl + Z — undo last canvas action
- Scroll to zoom, middle-click-drag or two-finger-pan to pan

---

### W-111 · Node Palette (slide-in panel)

**When:** Opened by clicking `Add node` or by clicking an empty area on the canvas.

**Node categories:**

#### Triggers (start nodes — each workflow has exactly one)
- `Meeting ended` — fires when a capture session ends and the meeting card is ready
- `Commitment created` — fires when a human confirms a commitment item in the meeting card
- `Approval given` — fires when a human approves an item in the approval queue
- `Schedule` — cron-style timer (e.g., every Monday 09:00)
- `Webhook` (Gate 5 public API) — fires on an inbound HTTP POST

#### Filters / Conditions
- `If / Else` — branches the flow based on a field condition (e.g., "commitment has no owner")
- `Filter` — drops items that don't match; only matching items continue downstream
- `Merge` — waits for multiple upstream branches and merges their data

#### Data transforms
- `Map fields` — renames or reshapes fields (e.g., "next_step.text → issue.title")
- `Format text` — applies a template with `{{variable}}` tokens to produce a string
- `Deduplicate` — prevents duplicate downstream writes if the trigger fires twice

#### Actions (nodes that write to external systems — every one requires human approval)
- `Create Linear issue` — payload fields: title, description, team, assignee, priority, labels, due date
- `Create HubSpot note` — payload fields: contact/company, body, associated deal
- `Send Slack message` — payload fields: channel or user, text, attachments
- `Create Google Doc` — payload fields: title, body (from template), parent folder
- `Create Google Doc row` (Sheets) — target spreadsheet, row data
- `Create Notion page` (Gate 5) — database, properties, content blocks
- `Create Jira issue` (Gate 5) — project, issue type, summary, description, assignee

#### Zedex internal actions
- `Create commitment` — creates a commitment record in Zedex from workflow data
- `Assign meeting to project` — routes a meeting to a project based on workflow logic
- `Send in-app notification` — sends a Zedex notification to a workspace member
- `Post to approval queue` — explicitly routes a payload to the W-60 approval queue (used when the workflow wants a human to review before the action node runs)

---

### W-112 · Node Config Panel (side panel, opens on node click)

**When:** User clicks any node on the canvas.

**What it shows:**
- Node name (editable)
- Node type badge
- Input / output port summary

**Sections vary by node type. Common elements:**
- Field mapping table: each output field has a value source (literal / variable token from upstream node)
- `{{variable}}` token picker — lists every field available from upstream nodes
- Test output panel: shows the output this node produced during the last test run
- Error / warning badges if the node has a configuration problem

**For action nodes (external writes):**
- Full payload preview rendered exactly as it will be sent
- `Require approval` toggle — when on, this node always posts to the approval queue (W-60) before executing; cannot be turned off for external-write nodes (enforced)
- `Notify on success` — sends an in-app notification after the write executes

**Buttons / actions:**
- `Save node`
- `Test this node` — runs only this node against the last test input
- `Duplicate node`
- `Delete node` (removes from canvas; connecting edges are removed too)

---

### W-113 · Workflows List

**When:** Entry point to the Canvas section. Lists all workflows in the workspace.

**What it shows:**
- Per workflow: name, trigger type, enabled/disabled status, last run time, last run result (succeeded / failed / pending approval)

**Buttons / actions:**
- `New Workflow` — opens blank canvas
- `New from template` — opens W-114
- Workflow row click — opens W-110 canvas
- `Enable` / `Disable` toggle (per row, without opening the canvas)
- `Duplicate` (per row)
- `Delete` (per row, with confirmation)

---

### W-114 · Workflow Templates

**When:** Opened from `New from template`.

**What it shows:**
- Template cards: pre-built workflow definitions for common patterns
  - "Meeting ended → create Linear issue for each next step"
  - "Commitment created → create HubSpot note on associated contact"
  - "Meeting ended → send Slack summary to channel"
  - "Agenda item overdue → send Slack reminder to owner"
  - "Weekly report → post digest to Slack channel"

**Buttons / actions:**
- Template card click — opens a preview of the node graph
- `Use this template` — creates a new workflow from it and opens the canvas
- `Back`

---

### W-115 · Run History Panel (slide-in)

**When:** Opened from `Workflow history` in the canvas toolbar.

**What it shows:**
- List of past runs: timestamp, trigger event (which meeting), status (succeeded / failed / pending approval / skipped by filter)
- Per run: expandable detail showing each node's input and output at that run

**Buttons / actions:**
- Run row click — expands the node-by-node trace
- `Re-run` (for failed runs) — re-triggers the workflow from the stored input data, still requires approval for action nodes
- `Close panel`

---

## Dialogs & Global UI Elements

These are not full pages but appear across multiple pages.

### D-01 · Notification Panel
- Per notification: source, type, timestamp, primary action button (e.g., `Review`, `Approve`, `View meeting`)
- `Mark all read`
- `Notification settings` link → W-71

### D-02 · Command Palette
- Keyboard-triggered (⌘K / Ctrl+K)
- Actions: jump to meeting, open project, create meeting, search
- Shortcut hints per action

### D-03 · Meeting Quick-Create Dialog
- Title input
- Date / time picker
- Attendees input
- Project assignment (optional)
- `Create` / `Cancel`

### D-04 · Confirmation Dialog (generic destructive actions)
- Action description
- Irreversibility warning if applicable
- `Confirm` (danger style)
- `Cancel`

### D-05 · Payload Approval Dialog (Gate 4 — used in W-60)
- Target system name and logo
- Full payload rendered exactly as it will be sent
- Field-level edit for each payload field
- Source evidence (which meeting, which segment)
- `Approve and send`
- `Edit, then approve`
- `Reject`

### D-06 · Speaker Mapping Dialog
- Speaker track list from the transcript
- Name input per track (autocomplete from workspace members)
- `Save mapping`
- `Cancel`

---

## Empty States

Every list page needs an empty state that makes the first action obvious. Each empty state contains:
- Illustration area (placeholder; actual illustration is a design decision)
- One-line description of what this page shows when it has data
- One primary CTA button (the most natural first action for this page)

| Page | Empty state CTA |
|---|---|
| W-10 Meetings List | `Download Desktop App` or `Import a Transcript` |
| W-20 Projects List | `New Project` |
| W-60 Approval Queue | None — "No pending approvals" is a success state |
| W-61 Commitments Board | `Add Commitment` |
| W-50 Search | Focus the input automatically |

---

## Error States

Each page must handle:
- **Loading** — skeleton placeholder, no spinner-only states
- **Failed to load** — message + `Retry` button
- **Not found** — message + link back to the parent list
- **No permission** — "You don't have access to this meeting" + `Request access` button (where applicable)

---

## Gate delivery map

| Gate | Desktop surfaces | Web pages |
|---|---|---|
| Gate 2 | DS-1, DS-2, DS-3, DS-4, DS-5, DS-6 | W-01–W-05, W-10–W-12, W-20–W-22, W-30, W-40, W-70, W-71 |
| Gate 3 | DS-2 live suggestions strip (overlay addition) | W-50, W-51, W-80, W-81, W-90, W-91 |
| Gate 4 | — | W-60, W-61, W-100, D-05 |
| Gate 5 | — | W-110–W-115 (Canvas + Workflows) |
