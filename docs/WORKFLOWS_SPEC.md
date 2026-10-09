> **Plan document — do not modify.**
> This file is the agreed plan and architecture. Treat it as source of truth.
> Changes must go through a new ADR or an explicit plan revision — do not edit in place.

---

> **Production target** — this is not a prototype or MVP. Every decision here targets a production product shipped in cycles.

---

# Zedex — Workflows, Explained Clearly

**Purpose:** one place that explains what a Zedex workflow is, how it runs, what the user sees, and the order we build it in. Written for designers, Claude Design, and engineers. Page-by-page element lists are in [UI_PAGES.md](UI_PAGES.md) (W-40, W-60, W-110 to W-115). Every example value is in [UI_SAMPLE_DATA.md](UI_SAMPLE_DATA.md). Engine and DAG schema are in [07-workflows-canvas](architecture/07-workflows-canvas.md).

---

## 1. What a workflow is (plain language)

A **workflow** is a saved recipe: *"when this happens, take this information, shape it like this, and then do this."*

Every workflow is made of four kinds of building blocks, always in this order:

| Block | Plain meaning | Example |
|---|---|---|
| **Source / Trigger** | What starts it, or what information it works on | "Meeting ended", or "these 6 meetings from Sep 14 to Oct 9" |
| **Filter / Condition** | Keep only what matters | "Only if the meeting has next steps" |
| **Transform** | Reshape or combine information | "Combine the meeting cards", "Turn next step into an issue title" |
| **Output / Action** | The result | "Show me a final summary", or "Create a Linear issue" |

Three rules never change, in any phase:

1. **AI proposes, a human decides.** Nothing is written to another system until a person has seen the exact payload and approved it.
2. **A workflow only uses what the person running it is allowed to see.** It can never widen access. Meetings the user cannot open are left out, quietly, and the result says how many meetings it was based on.
3. **Everything is traceable.** Every sentence in a result links back to the meeting (title and date) and the evidence segment it came from.

There is one workflow engine. The form editor (earlier phases) and the visual canvas (later) are two views over the same saved definition, so nothing built early is thrown away.

---

## 2. The build order (three phases)

We deliver workflows in phases. Each phase is usable on its own.

| Phase | Name | What the user can do | External writes? | Gate |
|---|---|---|---|---|
| **W1** | **Combine and Summarize** | Pick meetings and projects (with dates), join them, and get one final summary. Save the recipe and re-run it. | **None.** Result stays inside Zedex (view, copy, save) | Phase 1 (rides on Gate 2 preference summaries, screen W-40) |
| **W2** | **Triggers and Approved Actions** | Start automatically from "Meeting ended" or "Commitment created"; create Linear issues, HubSpot notes, Slack messages, Google Docs, each after approval | Yes, always through the Approval Queue | Gate 4 |
| **W3** | **Canvas and more triggers** | Drag-and-drop canvas, Schedule and Webhook triggers, Notion and Jira, template gallery, version diff | Yes, same approval rule | Gate 5 |

**Plan note (needs an explicit plan revision before build):** the current delivery plan places workflows at Gate 4 and the canvas at Gate 5. W1 is pulled forward only as an extension of the Gate 2 preference summaries (it adds a saved "recipe" and a meeting/project/date picker; it needs no new service and no external write). The `workflow` service still arrives at Gate 4. The W1 recipe is stored in the same typed shape as a workflow definition so W2 can adopt it without migration.

---

## 3. Phase W1 — Combine and Summarize (build first)

### 3.1 The user story

> "I had six Lumen meetings over four weeks plus one SSO design review. I want one final summary of everything, grouped by the date each meeting happened, so I can send an update upward."

### 3.2 The steps the user takes (screen W-40, "Summary Builder")

1. **Choose what to include.** Three ways, combinable:
   - **Projects** — add one or more projects; every meeting in them is included.
   - **Individual meetings** — search and tick specific meetings; each row shows its **date**, title, project(s), capture status.
   - **Date range** — a from/to range that filters the chosen projects (e.g. Sep 14 – Oct 9). Applied to projects, not to hand-picked meetings (a meeting you tick by hand is always included).
2. **Review the list.** A "Meetings included" table shows each meeting with its date and a checkbox to exclude it. Counts are live: "7 meetings, 5 h 22 m".
3. **Choose the output.** Style (Brief / Detailed / Executive), focus (Everything / Decisions / Next steps / Risks and blockers), length, and how to group (By date, oldest first / By date, newest first / By project / By theme).
4. **Generate.** Zedex builds one final summary. The page shows progress per meeting.
5. **Review the result.** Sections grouped as chosen. Each statement carries a chip like `Sep 28 · Lumen weekly sync` that opens the meeting at the evidence segment. Flagged values (money, dates, counts) show "verify".
6. **Act on it.** `Copy`, `Save as recipe` (keeps the scope rules, so it can re-run later), `Regenerate`. Export to Google Doc arrives at Gate 4 as a user-initiated write.

### 3.3 Rules for combining

| Rule | Behavior |
|---|---|
| Source of truth | Built from **meeting cards**, never from raw transcripts. |
| Confirmed vs proposed | Default uses **confirmed** items. A toggle "Include unconfirmed items" adds proposed items, shown with an "unconfirmed" tag. |
| Duplicates | A meeting that is in two selected projects is counted **once**. |
| Dates | Every meeting keeps its own date in the result. Decisions that were later changed show the newest decision and "changed from Sep 21". |
| Access | Only meetings the requester can open are used. Others are skipped without an error; the footer says "Based on 6 meetings you can access." |
| Meeting without a card | Skipped and listed under "Not included: no confirmed card" with a link to open the meeting. |
| Stale result | If any source card changes or access is revoked after generation, the summary shows "Out of date — regenerate". |
| Large scopes | Uses layered summarization (ADR-027): meetings are condensed per project or per week first, then combined. Recommended per-run limit is 50 meetings, to be confirmed by benchmark. |
| Unknowns | Owners and dates that were never stated stay empty ("Owner not stated"). Never guessed. |
| Privacy | Private notes and private-only meetings are never included for other people. Result text is never written to logs. |

### 3.4 What a saved recipe looks like

A recipe is a small saved definition. Same shape as a later workflow, with a manual trigger.

```json
{
  "id": "rcp_lumen_monthly",
  "name": "Lumen monthly rollup",
  "version": 1,
  "trigger": { "type": "manual" },
  "scope": {
    "projects": ["prj_lumen"],
    "meetings": ["mtg_2026-10-07_saml_design"],
    "dateRange": { "from": "2026-09-14", "to": "2026-10-09" },
    "excludedMeetings": []
  },
  "combine": { "source": "confirmed_cards", "dedupe": true },
  "summarize": { "style": "detailed", "focus": "everything", "groupBy": "date_asc", "length": "medium" },
  "output": { "type": "summary", "actions": ["view", "copy", "save"] }
}
```

### 3.5 Where W1 sits in the node view (for later reuse)

```text
[Projects + Meetings + Date range] -> [Combine cards] -> [Summarize] -> [Output: Summary]
```

W1 shows this as a simple form, not a canvas. In W3 the same recipe opens on the canvas as these four nodes.

---

## 4. Phase W2 — Triggers and Approved Actions

After W1, workflows can start by themselves and send results to other tools. Every external write goes through approval.

### 4.1 Triggers (start nodes, exactly one per workflow)

| Trigger | Fires when | Data it hands on |
|---|---|---|
| **Meeting ended** | A capture ends and the meeting card is ready | meeting, card, next steps, decisions |
| **Commitment created** | A human confirms a commitment in a card | commitment (text, owner, due date, evidence) |
| **Approval given** | A person approves an item in the Approval Queue | the approved item and its result |

(Schedule and Webhook come in W3.)

### 4.2 Filters, transforms, Zedex actions

| Type | Nodes |
|---|---|
| Conditions | If / Else, Filter, Merge |
| Transforms | Map fields, Format text, Deduplicate |
| Zedex actions (no approval needed, internal only) | Create commitment, Assign meeting to project, Send in-app notification, Post to approval queue |

### 4.3 External actions (always need approval)

| Action | Writes to | Main payload fields |
|---|---|---|
| Create Linear issue | Linear | title, description, team, assignee, priority, labels, due date |
| Create HubSpot note | HubSpot | contact or company, body, deal |
| Send Slack message | Slack | channel or person, text |
| Create Google Doc | Google Drive | title, body, folder |

Jira, Notion, Google Sheets rows arrive in W3.

### 4.4 The approval rule, step by step

1. The workflow reaches an action node. It does **not** send anything. It prepares the exact payload.
2. The payload appears in the **Approval Queue** (W-60) as a card: destination, every field, source meeting and evidence, suggested owner and due date.
3. A person with access to the source reviews it. They can **Approve**, **Edit then approve**, or **Reject** (with optional reason).
4. Only then Zedex sends it. If the workflow or payload is edited after approval, the approval is cancelled and must be given again.
5. The result is recorded: sent, failed, or **uncertain** (sent but no confirmation). Uncertain items are checked by looking up the external item, never by blindly sending again.
6. Creating a ticket is not the same as delivering the promise. The commitment closes only when its owner confirms or approved evidence is attached.

The "Require approval" switch on external action nodes is always on and cannot be turned off.

### 4.5 Run states

`Queued -> Running -> Waiting for approval -> Sending -> Succeeded`  
Other endings: `Skipped by filter`, `Rejected`, `Failed`, `Uncertain`, `Cancelled (edited after approval)`.

### 4.6 Test run

"Test run" picks a past meeting and runs the whole workflow on it. It shows what every node would output. It **never** sends anything outside Zedex; action nodes only show the payload they would create.

### 4.7 A complete W2 example (the workflow in the canvas screenshot)

Name: **Meeting ended — Linear issue and Slack summary**

```text
Trigger: Meeting ended
   -> Filter: Has next steps            (label on edge: meeting)
        -> Transform: Map fields        (label: meeting)
             -> Action: Create Linear issue   [Approval required]   (label: next step)
        -> Transform: Format summary    (label: meeting)
             -> Action: Send Slack message    [Approval required]   (label: text)
```

Explained as a sentence: *When a meeting ends, if it has next steps, turn each next step into a Linear issue and post a short summary to Slack — but wait for a person to approve each one first.*

Create Linear issue field mapping and payload preview (from the example):

| Field | Mapping | Result for the Lumen meeting |
|---|---|---|
| Title | `{{next_step.text}}` | Scope SAML SSO for the Lumen tenant |
| Description | `{{evidence.quote}}` | "Then I'll scope SAML SSO for the Lumen tenant by Friday, October sixteenth." |
| Assignee | `{{next_step.owner}}` | Priya Nair |
| Team | literal | Platform |
| Due | `{{next_step.due}}` | 2026-10-16 |

The canvas also carries a yellow note: "Every action waits in Approvals. Nothing is sent until a person approves the exact payload."

---

## 5. Phase W3 — Canvas and more triggers

- Visual canvas (React Flow): palette on the left, canvas in the middle, node settings on the right, minimap bottom right, zoom and fit controls bottom left.
- Triggers added: **Schedule** (for example every Monday 09:00) and **Webhook**.
- Actions added: Notion page, Jira issue, Google Sheets row.
- Template gallery, version history with diff, sticky notes, undo and redo.
- Draft versions and published versions: a published version is frozen; editing creates a new version and cancels waiting approvals from the old one.

The canvas screen elements are listed in [UI_PAGES.md](UI_PAGES.md) W-110 to W-115. A full description of the screenshot layout is in section 7 below.

---

## 6. Plain-language glossary

| Term | Meaning |
|---|---|
| Workflow / Recipe | A saved set of steps. In W1 it is called a recipe |
| Node | One block in the workflow (trigger, filter, transform, action) |
| Edge | The arrow between two blocks; its label says what kind of data flows (meeting, next step, text) |
| Run | One execution of a workflow, with a start time, a trigger (which meeting), and a status |
| Payload | The exact content that would be sent to another system |
| Approval | A person confirming the exact payload |
| Version | Edits create a new version; old runs keep the version they used |
| Scope | Which meetings and projects a summary covers |
| Evidence | The transcript segment behind a statement |

---

## 7. The canvas screen, described (from the reference screenshot)

Everything below is content and function. Colors, spacing, and exact layout are the designer's decision.

- **Top bar:** back arrow; breadcrumb "Workflows"; workflow name "Meeting ended — Linear issue and Slack summary"; status badge "Enabled"; buttons `Test run`, `History`, `Duplicate`, `Save`.
- **Left panel "Add a node":** search box "Search nodes"; group **Triggers** (Meeting ended, Commitment created, Approval given, Schedule, Webhook); group **Actions — need approval** with a lock on each (Create Linear issue, Create HubSpot note, Send Slack message, Create Google Doc); collapsed groups with counts: Conditions 3, Data transforms 3, Zedex actions 4.
- **Canvas:** five-step graph described in 4.7. Each node card shows a small category label (TRIGGER, FILTER, TRANSFORM, ACTION), its name, and for external actions a badge "Approval required". The selected node is highlighted. Edge labels read: meeting, meeting, next step, meeting, text. A sticky note explains the approval rule. Bottom left: zoom out, "100%", zoom in, `Fit`. Bottom right: minimap.
- **Right panel (node selected):** header "Action · writes to Linear" and title "Create Linear issue" with close; **Field mapping** (Title, Description, Assignee as variable fields shown in `{{...}}` form; Team as plain value); **Payload preview** in a code-style block showing the exact text that would be sent; **Require approval** switch, on and locked, with the line "Always on for nodes that write to another system. This can't be turned off."; **Notify me after it sends** switch, on; buttons `Test this node` and `Save node`.

---

## 8. Acceptance checklist for each phase

**W1 done when:** a user can pick projects, individual meetings and a date range; see the included meetings with dates; exclude any; generate a summary grouped by date; every statement links to its meeting and date; inaccessible meetings are left out with an honest count; changed sources mark the result out of date; the recipe saves and re-runs; privacy test shows no content in logs; generation time target is measured and recorded (target: 20 meetings in under 30 s).

**W2 done when:** the Meeting ended and Commitment created triggers run; all four external actions go only through the Approval Queue with exact payloads; edited-after-approval is cancelled; duplicate sends are impossible after retries; uncertain results reconcile by lookup; run history shows each node's input and output.

**W3 done when:** the canvas edits the same saved definition the form editor does; test run cannot write externally; Schedule and Webhook triggers work with authorization; templates install and run.
