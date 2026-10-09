> **Plan document — do not modify.**
> This file is the agreed plan and architecture. Treat it as source of truth.
> Changes must go through a new ADR or an explicit plan revision — do not edit in place.

---

> **Production target** — this is not a prototype or MVP. Every decision here targets a production product shipped in cycles.

---

# Zedex — UI Sample Data (for realistic screens)

**Purpose:** one complete, consistent set of fictional data so every page in [UI_PAGES.md](UI_PAGES.md) can be drawn and built with real content instead of placeholder text. Workflow behavior is explained in [WORKFLOWS_SPEC.md](WORKFLOWS_SPEC.md).

**How to use this file (designers, Claude Design, engineers):**
- Use these exact values on screens. Do not invent lorem ipsum.
- Colors, spacing, layout, icons, illustration style, and typography are **your decision**. This file only supplies content and states.
- All people, companies, and numbers are **fictional**. Email domains use `.example`.
- "Today" in this dataset is **Friday, 9 October 2026**, 14:20, time zone America/New_York (EDT, UTC-4). Dates are written ISO (2026-10-09) with a display form.
- Items marked **[state]** are there to show a specific UI state (empty, error, flagged, overdue, and so on).
- The same entities repeat across pages on purpose: the Lumen meeting on 2026-10-05 appears in the list, the meeting view, the card, the summary, the workflow, the approval queue, and the commitments board.

---

## 0. Index

| Section | Pages covered |
|---|---|
| 1 Workspace, people, teams | W-02, W-05, W-70, W-71, nav |
| 2 Calendar and integrations | W-03, W-70 |
| 3 Projects and folders | W-20, W-21, W-22 |
| 4 Meetings list | W-10, D-03 |
| 5 Meeting 2026-10-05 in full (transcript, notes, card, agenda) | W-11, W-12, D-06, W-30 |
| 6 Other meeting cards (inputs for summaries) | W-11, W-40 |
| 7 Agenda for the next meeting | W-30 |
| 8 Combine and Summarize (Phase W1) | W-40 |
| 9 Workflows (W2/W3), approvals, runs, templates | W-60, W-110 to W-115, D-05 |
| 10 Commitments and reports | W-61, W-100 |
| 11 Search, chat, sharing | W-50, W-51, W-80, W-81 |
| 12 Catch-up and coverage | W-90, W-91 |
| 13 Desktop surfaces | DS-1 to DS-6 |
| 14 Settings, profile, security, billing | W-70, W-71 |
| 15 Notifications, command palette, dialogs | D-01 to D-06 |
| 16 Empty, loading, error, no-permission copy | all pages |
| 17 Onboarding | W-01 to W-05 |

---

## 1. Workspace, people, teams

### 1.1 Workspace

| Field | Value |
|---|---|
| Name | Northwind Software |
| Slug | `northwind` |
| Industry | B2B SaaS |
| Team size selector | 11–50 |
| Cell / region | us-1, East US 2 |
| Plan | Team, 12 seats |
| Created | 2026-08-24 |
| Recording-consent policy | Notify all participants (default) |
| Retention | 12 months |
| Product tagline (sign-in) | "Know what your team promised, and make sure it happens." |

### 1.2 Current user (signed in)

**Maya Chen**, Owner, `maya.chen@northwind.example`, Founders team, initials MC.

### 1.3 Members

| Name | Email | Workspace role | Team | Title | Last active |
|---|---|---|---|---|---|
| Maya Chen (you) | maya.chen@northwind.example | Owner | Founders | CEO | now |
| Daniel Okafor | daniel.okafor@northwind.example | Admin | Engineering | CTO | 2026-10-09 13:52 |
| Priya Nair | priya.nair@northwind.example | Member | Platform | Engineering Manager | 2026-10-09 14:05 |
| Sofia Marino | sofia.marino@northwind.example | Member | Platform | Senior Engineer | 2026-10-09 11:30 |
| Tomás Rivera | tomas.rivera@northwind.example | Member | Sales | Account Executive | 2026-10-09 14:11 |
| Hannah Weiss | hannah.weiss@northwind.example | Member | Customer Success | CS Lead | 2026-10-08 18:40 |
| Ravi Patel | ravi.patel@northwind.example | Member | Product | Product Manager | 2026-10-09 09:15 |
| Ben Carter | ben.carter@northwind.example | Member | Design | Product Designer | 2026-10-07 16:02 |

### 1.4 Pending invitations

| Email | Role | Invited | Expires | Actions |
|---|---|---|---|---|
| leo.park@northwind.example | Member | 2026-10-07 | 2026-10-14 | Resend, Revoke |
| amara.diaz@northwind.example | Admin | 2026-10-08 | 2026-10-15 | Resend, Revoke |

### 1.5 Teams

Founders (1), Engineering (1), Platform (2), Sales (1), Customer Success (1), Product (1), Design (1).

### 1.6 External people (appear as attendees)

| Name | Email | Company | Role |
|---|---|---|---|
| Elena Brandt | elena.brandt@lumen.example | Lumen Analytics | VP Engineering |
| Marcus Hale | marcus.hale@lumen.example | Lumen Analytics | IT Security Lead |
| Dr. Nora Whitfield | nora.whitfield@pinecrest.example | Pinecrest Health | Director of Operations |
| Samir Joshi | samir.joshi@pinecrest.example | Pinecrest Health | Compliance Officer |
| Chloe Dubois | chloe.dubois@orbit.example | Orbit Retail | Head of Product |

---

## 2. Calendar and integrations

### 2.1 Calendar connect page (W-03)

| Provider | State | Detail |
|---|---|---|
| Google Calendar | **Connected** as maya.chen@gmail.example · last synced 2026-10-09 14:18 · "Read-only: event titles, attendees, times, meeting links" | Buttons: Disconnect |
| Microsoft Outlook | Not connected | Button: Connect Microsoft Outlook |

Footer: "Zedex never reads event descriptions by default and never changes your calendar."

### 2.2 Integrations list (W-70 Integrations)

| Integration | State | Last synced / used | Scope shown |
|---|---|---|---|
| Google Calendar | Connected | 2026-10-09 14:18 | Read events (read-only) |
| Microsoft Outlook | Not connected | — | — |
| Linear | **Not connected** (available at Gate 4) | — | Create and update issues |
| Slack | Not connected (Gate 4) | — | Post messages to chosen channels |
| HubSpot | Not connected (Gate 4) | — | Create notes on contacts and companies |
| Google Docs | Not connected (Gate 4) | — | Create documents you pick |
| Google Calendar (Sofia) **[state]** | **Needs reconnect**, token expired 2026-10-06 | — | Button: Reconnect |

---

## 3. Projects and folders

### 3.1 Folders

Customers, Internal, Product.

### 3.2 Projects (W-20 cards)

| Project | Folder | Description | Members | Meetings | Last activity | Access |
|---|---|---|---|---|---|---|
| Lumen Analytics | Customers | Enterprise pilot: SSO, audit log, security review | 5 | 5 | 2026-10-09 13:40 | Team |
| Pinecrest Health onboarding | Customers | Rollout plan and compliance review | 4 | 2 | 2026-10-06 12:10 | Team |
| SAML SSO Launch | Product | Cross-team launch of SAML SSO | 6 | 2 | 2026-10-08 10:22 | Shared |
| Q4 Planning | Internal | Roadmap and capacity for Q4 | 7 | 3 | 2026-10-08 17:30 | Team |
| Founders Private | — | Private notes and 1:1s | 1 | 1 | 2026-10-08 17:50 | Private |

Project icons are the designer's choice. Empty-folder example **[state]**: folder "Archive 2025" with 0 projects.

### 3.3 Project view: Lumen Analytics (W-21)

- Description: "Enterprise pilot: SSO, audit log, security review."
- Tabs: Meetings (5), Commitments (Gate 4, shown disabled "Coming with approvals"), Reports (Gate 4).
- Auto-rules in effect:

| Rule | Type | Value | Effect |
|---|---|---|---|
| Lumen attendees | Attendee domain | `lumen.example` | Suggest this project |
| Weekly sync series | Series | "Lumen Analytics — Weekly sync" | Auto-add every occurrence |
| Tracking code | Code in title or description | `ZX-LUMEN` | Route here |

- Meeting list (newest first):

| Date | Title | Capture | Card |
|---|---|---|---|
| Mon 2026-10-12 10:00 | Lumen Analytics — Weekly sync | Upcoming | Agenda drafted |
| Mon 2026-10-05 10:00 | Lumen Analytics — Weekly sync | Captured | Ready, 4 of 12 confirmed |
| Mon 2026-09-28 10:00 | Lumen Analytics — Weekly sync | Captured | Confirmed |
| Mon 2026-09-21 10:00 | Lumen Analytics — Weekly sync | Captured | Confirmed |
| Mon 2026-09-14 10:00 | Lumen Analytics — Weekly sync | Captured | Confirmed |

- Pending suggestion **[state]** banner: "Suggested: add 'Intro call — Orbit Retail' (attendee domain orbit.example) to a new project 'Orbit Retail'." Buttons: Accept, Dismiss.

### 3.4 Access panel (W-22) for Lumen Analytics

| Member | Role |
|---|---|
| Maya Chen | Admin |
| Tomás Rivera | Editor |
| Priya Nair | Editor |
| Hannah Weiss | Viewer |
| Daniel Okafor | Viewer |

Pending invite: ravi.patel@northwind.example, Viewer. Note under the panel: "Adding a meeting to a project never gives anyone access to it. Access comes from sharing and roles."

---

## 4. Meetings list (W-10)

Filters shown: Date range "Last 30 days", Project "All", Capture status "All".

| # | Title | Date and time | Duration | Tool | Attendees (shown) | Capture | Card status | Projects |
|---|---|---|---|---|---|---|---|---|
| 1 | Product weekly sync | Fri 2026-10-09 15:00 | 30 m | Google Meet | RP, MC, BC +2 | **Upcoming, starts in 40 min** | — | Q4 Planning |
| 2 | Customer success weekly | Thu 2026-10-08 11:00 | 45 m | Zoom | HW, MC, TR | Captured | **Failed to generate, Retry** [state] | — |
| 3 | Founders 1:1 | Thu 2026-10-08 17:00 | 25 m | In person | MC, DO | Captured | Ready, private | Founders Private |
| 4 | SAML SSO design review | Wed 2026-10-07 15:00 | 60 m | Google Meet | PN, SM, DO, BC, RP | Captured | Confirmed | SAML SSO Launch |
| 5 | Intro call — Orbit Retail | Wed 2026-10-07 09:00 | 30 m | Zoom | MC, TR, Chloe Dubois | Captured | Ready | **Unsorted** [state] |
| 6 | Platform weekly planning | Tue 2026-10-06 14:00 | 50 m | Microsoft Teams | PN, SM, DO | Captured | Ready, 6 of 8 confirmed | SAML SSO Launch, Q4 Planning |
| 7 | Pinecrest — Security questionnaire walkthrough | Tue 2026-10-06 11:00 | 40 m | Zoom | HW, TR, Samir Joshi | **Not captured** [state] · button Upload Transcript | — | Pinecrest Health onboarding |
| 8 | Lumen Analytics — Weekly sync | Mon 2026-10-05 10:00 | 50 m | Zoom | MC, PN, TR +2 | Captured | Ready, 4 of 12 confirmed | Lumen Analytics |
| 9 | Q4 Planning — Roadmap review | Fri 2026-10-02 09:30 | 60 m | Google Meet | MC, DO, RP, BC | **Transcript uploaded (VTT)** | **Generating…** [state] | Q4 Planning |
| 10 | Pinecrest — Kickoff | Thu 2026-10-01 13:00 | 55 m | Zoom | HW, TR, Nora Whitfield +1 | Captured | Confirmed | Pinecrest Health onboarding |
| 11 | Lumen Analytics — Weekly sync | Mon 2026-09-28 10:00 | 45 m | Zoom | MC, PN, TR +2 | Captured | Confirmed | Lumen Analytics |
| 12 | Lumen Analytics — Weekly sync | Mon 2026-09-21 10:00 | 40 m | Zoom | MC, TR, Elena Brandt | Captured | Confirmed | Lumen Analytics |
| 13 | Lumen Analytics — Weekly sync | Mon 2026-09-14 10:00 | 45 m | Zoom | MC, TR, Elena Brandt +1 | Captured | Confirmed | Lumen Analytics |
| 14 | A very long meeting title to test truncation: Quarterly cross-functional alignment on enterprise security, compliance evidence, and customer rollout sequencing | Mon 2026-09-07 16:00 | 90 m | Microsoft Teams | 12 attendees | Captured | Confirmed | — |

Row status badges: Captured, Not captured, Transcript uploaded, Upcoming. Card badges: Pending, Generating, Ready, Confirmed, Failed.

### 4.1 Quick-create dialog (D-03) sample entry

Title "Lumen Analytics — Security review", date 2026-10-14, time 13:00–13:45, attendees `elena.brandt@lumen.example, marcus.hale@lumen.example`, project "Lumen Analytics".

---

## 5. Meeting in full: Lumen Analytics — Weekly sync, Mon 2026-10-05

**Header:** title, "Mon 5 Oct 2026, 10:00–10:50 (50 min)", Zoom, organizer Maya Chen, attendees Maya Chen, Priya Nair, Tomás Rivera, Elena Brandt, Marcus Hale. Projects: Lumen Analytics. Capture: captured by Maya Chen, 16 segments, no gaps. Series: "Lumen Analytics — Weekly sync" (occurrence 4 of 4 so far).

### 5.1 Transcript tab (W-11)

Speakers before mapping: **You** (Maya's microphone) and **Others** (meeting audio, speaker names mapped by the user in D-06, see 5.1.2). Words below the confidence threshold are marked **[flag]**.

| # | Time | Speaker | Text | Flag |
|---|---|---|---|---|
| 1 | 00:08 | You (Maya Chen) | Thanks for joining. Let's start with where we are on the SSO scope for your tenant. | |
| 2 | 00:21 | Elena Brandt | We need SAML in place before our November audit. Marcus can walk through what the auditors asked for. | |
| 3 | 00:40 | Marcus Hale | Mainly single sign-on with our Okta tenant, and an export of the audit log. Provisioning is nice to have. | |
| 4 | 01:12 | Priya Nair | SAML we can scope this week. The audit log export is a separate piece, I'd estimate two sprints. | |
| 5 | 01:45 | Tomás Rivera | On pricing, SSO is an add-on at **twelve hundred dollars** a month for the workspace. | **[flag] $1,200, confidence 0.62** |
| 6 | 02:10 | Elena Brandt | Twelve hundred is fine if it includes up to **two hundred fifty** seats. | **[flag] 250, confidence 0.58** |
| 7 | 02:33 | Tomás Rivera | It does. I'll send the updated order form. | |
| 8 | 03:05 | You (Maya Chen) | So we agree: SAML first, SCIM later. | |
| 9 | 03:12 | Elena Brandt | Agreed. SCIM can wait until next quarter. | |
| 10 | 04:20 | Marcus Hale | One question is whether the audit log export needs to include admin actions or just sign-ins. | |
| 11 | 04:48 | Priya Nair | Both are possible. I need to check with Daniel on the retention window. | |
| 12 | 06:02 | You (Maya Chen) | Let's park that as an open question. | |
| 13 | 08:15 | Elena Brandt | Go-live target is **November third** for our pilot team. | **[flag] Nov 3, confidence 0.55** |
| 14 | 08:40 | Priya Nair | Then I'll scope SAML SSO for the Lumen tenant by Friday, **October sixteenth**. | **[flag] Oct 16, confidence 0.71** |
| 15 | 09:10 | Marcus Hale | I'll share our security questionnaire answers when I can. | (no date stated) |
| 16 | 09:35 | You (Maya Chen) | Great, let's wrap there. Thanks everyone. | |

Segment actions: Copy, Highlight. Highlighted example: segment 14. Footer: "16 segments · no capture gaps · last synced 2026-10-05 10:52".

#### 5.1.1 Capture gap **[state]** (shown on a different meeting, the Product weekly sync of 2026-10-02)

"Gap 14:32–15:10 (38 s): connection lost, text before and after is preserved."

#### 5.1.2 Speaker mapping dialog (D-06)

| Track | Default label | Suggested names (from attendees) | Saved |
|---|---|---|---|
| Mic | You | Maya Chen | Maya Chen |
| Others A | Others | Elena Brandt, Marcus Hale, Priya Nair, Tomás Rivera | Elena Brandt |
| Others B | Others | same list | Marcus Hale |
| Others C | Others | same list | Priya Nair |
| Others D | Others | same list | Tomás Rivera |

Note under the dialog: "Names are never guessed. Unmapped speakers stay as 'Others'."

### 5.2 Notes tab

Typed during the meeting (timestamped):

| Time | Note |
|---|---|
| 02:12 | Lumen audit in November is a hard deadline |
| 05:30 | Ask Daniel about audit log retention |
| 09:20 | Marcus owes security questionnaire, no date given |

Post-meeting free text: "Send Elena a recap today. Check if Okta supports SCIM later. Draft the SSO order form before Wednesday."

### 5.3 Meeting Card tab (AI summary, unconfirmed vs confirmed)

Header: "Generated 2026-10-05 10:54 · 4 of 12 items confirmed · 4 values to verify". Legend: AI-proposed, Confirmed, Edited by you.

**Topics covered**

| Item | Text | Evidence | Status |
|---|---|---|---|
| T1 | SAML SSO scope for the Lumen tenant | #2, #3, #4 | Confirmed |
| T2 | SSO pricing and seat count | #5, #6, #7 | Proposed |
| T3 | Audit log export and retention window | #4, #10, #11 | Proposed |
| T4 | Pilot go-live timing | #13 | Proposed |

**Decisions**

| Item | Text | Evidence | Status |
|---|---|---|---|
| D1 | Ship SAML SSO first and defer SCIM to next quarter | #8, #9 | Confirmed |
| D2 | SSO is sold as an add-on at **$1,200 per month** for up to **250 seats** | #5, #6 | Proposed, **verify** (flags: $1,200, 250) |

**Open questions**

| Item | Text | Evidence | Status |
|---|---|---|---|
| Q1 | Should the audit log export include admin actions or only sign-ins? | #10, #11 | Proposed |
| Q2 | What retention window can Engineering support for audit logs? | #11 | Edited by you ("What audit-log retention window can Platform support?") |

**Next steps**

| Item | Text | Owner | Due | Evidence | Status |
|---|---|---|---|---|---|
| N1 | Scope SAML SSO for the Lumen tenant | Priya Nair | 2026-10-16 | #14 | Confirmed (date to verify) |
| N2 | Send the updated SSO order form | Tomás Rivera | *not stated* | #7 | Confirmed |
| N3 | Share security questionnaire answers | Marcus Hale (external) | *not stated* | #15 | Proposed |
| N4 | Target pilot go-live | Elena Brandt (external) | 2026-11-03, **verify** | #13 | Proposed |
| N5 **[state: rejected]** | Hire a security consultant | — | — | — | Rejected by Maya Chen, hidden from the card; shown under "Rejected (1)" |

Buttons per item: Confirm, Edit, Reject. Card buttons: Add item, Regenerate card (disabled note: "2 edited items will be kept"), Export card.

Evidence popover example (for N1): "Segment #14 · 08:40 · Priya Nair: 'Then I'll scope SAML SSO for the Lumen tenant by Friday, October sixteenth.'"

Verify popover (for flag on Oct 16): "Heard as 'October sixteenth' (confidence 0.71). Mark as correct, or enter the right value." Inputs: Correct / Edit value.

### 5.4 Meeting-level actions and share

Edit Title, Assign to Project (current: Lumen Analytics), Share (see 11.4), Delete Meeting (confirm: "Delete this meeting and its transcript, notes, and card? This cannot be undone.").

### 5.5 Transcript import dialog (W-12) sample

File: `orbit-intro-call.vtt` (42 KB). Detected format: WebVTT, 212 cues, 28 minutes. Button Import. Error variant **[state]**: "This file isn't a supported transcript. Use TXT, VTT, or SRT."

---

## 6. Other meeting cards (inputs for summaries)

Only the confirmed items are used by default in summaries. Each meeting shows date, title, and items. These feed section 8.

### 6.1 Mon 2026-09-14 · Lumen Analytics — Weekly sync (45 min) · Confirmed

- Topics: pilot kickoff goals; data residency; success criteria.
- Decision: Pilot runs 8 weeks starting 2026-09-21 with the Platform team of 40 users.
- Decision: Data stays in the US region.
- Next steps: Tomás Rivera sends pilot agreement by 2026-09-16; Elena Brandt names two pilot admins by 2026-09-18.

### 6.2 Mon 2026-09-21 · Lumen Analytics — Weekly sync (40 min) · Confirmed

- Topics: pilot admins named; first-week usage; SSO request.
- Decision: Lumen will require SSO before expanding beyond the pilot team.
- Open question: Which identity provider does Lumen use? (answered later: Okta, 2026-10-05)
- Next steps: Priya Nair to share SSO options by 2026-09-25; Hannah Weiss to run a training session for pilot admins by 2026-09-24.

### 6.3 Mon 2026-09-28 · Lumen Analytics — Weekly sync (45 min) · Confirmed

- Topics: training session feedback; SSO options; November audit mentioned.
- Decision: Move forward with SAML as the SSO method.
- Open question: Does Lumen need provisioning (SCIM) at launch?
- Next steps: Marcus Hale to confirm identity provider details by 2026-10-02; Tomás Rivera to draft an SSO price proposal by 2026-10-02.

### 6.4 Mon 2026-10-05 · Lumen Analytics — Weekly sync · see section 5.3

Confirmed items used by default: T1, D1, N1, N2. With "Include unconfirmed items" on, the others join, tagged "unconfirmed".

### 6.5 Wed 2026-10-07 · SAML SSO design review (60 min) · Confirmed

- Topics: SP-initiated vs IdP-initiated flows; certificate rotation; error handling.
- Decision: Support both SP-initiated and IdP-initiated sign-in at launch.
- Decision: Certificate rotation notices go out 30 days before expiry.
- Open question: Do we support multiple identity providers per workspace at launch?
- Next steps: Sofia Marino builds the metadata import by 2026-10-14; Ben Carter drafts the SSO admin screens by 2026-10-13; Ravi Patel writes the customer-facing SSO doc by 2026-10-15.

### 6.6 Tue 2026-10-06 · Platform weekly planning (50 min) · Ready, 6 of 8 confirmed

- Topics: SAML scope vs audit-log export; sprint capacity.
- Decision: Audit-log export moves to the sprint after SAML.
- Next steps: Priya Nair to confirm retention window with Daniel Okafor by 2026-10-09 (**overdue today**, see 10.1).

### 6.7 Private meeting **[state]**: Founders 1:1 (Thu 2026-10-08)

Visible only to Maya Chen and Daniel Okafor. It is **excluded** from any summary built by someone else, with no error shown.

---

## 7. Agenda (W-30) for Mon 2026-10-12 · Lumen Analytics — Weekly sync

Status: "AI draft ready". The draft is created 24 h before the meeting; show this screen as it looks once the draft exists (Sun 2026-10-11, 10:00). Nothing is accepted until a person accepts it.

**Section 1 — Previous meeting (2026-10-05), read-only**

| Item | State |
|---|---|
| Scope SAML SSO for the Lumen tenant (Priya Nair, due 2026-10-16) | Open, carried over |
| Send the updated SSO order form (Tomás Rivera) | Open, carried over, **overdue** |
| Audit log: admin actions or sign-ins only? | Unresolved question, carried over |
| SAML first, SCIM later | Decision made, closed |
| Pilot go-live target 2026-11-03 | To verify |

**Section 2 — This meeting (editable)**

| # | Item | Type | Owner | Time box | Source | State |
|---|---|---|---|---|---|---|
| 1 | Review SAML SSO scope | Topic | Priya Nair | 10 min | Carry-over | AI-drafted |
| 2 | Confirm SSO order form and pricing | Decision | Tomás Rivera | 5 min | Carry-over, overdue | AI-drafted |
| 3 | Decide audit-log export contents | Question | Priya Nair | 10 min | Open question | AI-drafted |
| 4 | Security questionnaire status | Action | Marcus Hale | 5 min | Open commitment | AI-drafted |
| 5 | Confirm pilot go-live date | Decision | Elena Brandt | 5 min | To verify | Added by Maya Chen |

Attachments: "Lumen SSO requirements (Google Doc)" linked (Gate 3). Attendee prep tasks: "Marcus: bring auditor checklist."

**Section 3 — Next-meeting plan (2026-10-19)**

| Item | Type |
|---|---|
| Go-live readiness check | Topic |
| SCIM timing next quarter | Question |

Buttons: Accept AI Draft (accepts items 1–4), Accept item, Edit, Remove, Add item, Assign owner, Attach doc, Share agenda, Export.

---

## 8. Combine and Summarize (Phase W1, screen W-40)

The first workflow. Behavior is explained in [WORKFLOWS_SPEC.md](WORKFLOWS_SPEC.md) section 3.

### 8.1 Builder screen state

**Name:** Lumen monthly rollup · **Recipe saved:** yes

**1 · What to include**

| Source | Detail |
|---|---|
| Project | Lumen Analytics (5 meetings) |
| Individual meeting | SAML SSO design review · Wed 2026-10-07 (picked by hand) |
| Date range | 2026-09-14 → 2026-10-09 (applies to the project) |
| Include unconfirmed items | Off |

**2 · Meetings included (7 found, 6 used)**

| ✓ | Date | Title | Project | Card | Used |
|---|---|---|---|---|---|
| ☑ | Mon 2026-09-14 | Lumen Analytics — Weekly sync | Lumen Analytics | Confirmed | Yes |
| ☑ | Mon 2026-09-21 | Lumen Analytics — Weekly sync | Lumen Analytics | Confirmed | Yes |
| ☑ | Mon 2026-09-28 | Lumen Analytics — Weekly sync | Lumen Analytics | Confirmed | Yes |
| ☑ | Mon 2026-10-05 | Lumen Analytics — Weekly sync | Lumen Analytics | 4 of 12 confirmed | Yes (confirmed items only) |
| ☑ | Wed 2026-10-07 | SAML SSO design review | SAML SSO Launch | Confirmed | Yes (hand-picked) |
| ☐ | Mon 2026-10-12 | Lumen Analytics — Weekly sync | Lumen Analytics | Upcoming | Outside date range |
| ☑ | Tue 2026-10-06 | Platform weekly planning | SAML SSO Launch, Q4 Planning | 6 of 8 confirmed | Yes (hand-picked) |

Counts line: "7 listed · 6 used · 1 outside range · 4 h 50 m of meetings". Note: meeting listed in two projects is counted once.

**3 · Output options**

| Option | Selected |
|---|---|
| Style | Detailed (alternatives: Brief, Executive) |
| Focus | Everything (alternatives: Decisions, Next steps, Risks and blockers) |
| Group by | Date, oldest first (alternatives: Date newest first, Project, Theme) |
| Length | Medium |

Buttons: Generate Summary, Save as recipe, Cancel.

### 8.2 Progress state **[state]**

"Reading meeting cards… 4 of 6 done" with per-meeting ticks. Estimated time: "about 20 seconds".

### 8.3 Result: Detailed, grouped by date

**Title:** Lumen Analytics and SSO: 14 Sep – 9 Oct 2026  
**Footer:** "Based on 6 meetings you can access · Generated 2026-10-09 14:26 · Confirmed items only · 2 values to verify"

**Overview.** Over four weeks the Lumen pilot moved from kickoff to an SSO commitment. Lumen made SSO a condition for expanding past the pilot team. Northwind decided on SAML first, with SCIM deferred to next quarter, and design review settled sign-in flows. Open items are the audit-log export scope and the exact go-live date.

**Mon 14 Sep — Pilot kickoff** `Sep 14 · Lumen weekly sync`
- Decided an 8-week pilot starting 21 Sep with the Platform team of 40 users.
- Decided data stays in the US region.
- Next steps: pilot agreement from Tomás Rivera (due 16 Sep); two pilot admins from Elena Brandt (due 18 Sep).

**Mon 21 Sep — Pilot admins and SSO request** `Sep 21 · Lumen weekly sync`
- Lumen requires SSO before expanding beyond the pilot team.
- Next steps: SSO options from Priya Nair (due 25 Sep); admin training from Hannah Weiss (due 24 Sep).

**Mon 28 Sep — SAML chosen** `Sep 28 · Lumen weekly sync`
- Decided to move forward with SAML as the SSO method.
- Next steps: identity provider details from Marcus Hale (due 2 Oct); SSO price proposal from Tomás Rivera (due 2 Oct).

**Mon 5 Oct — Scope and sequencing** `Oct 5 · Lumen weekly sync`
- Decided SAML first, SCIM next quarter.
- Next steps: Priya Nair scopes SAML SSO for the Lumen tenant by 16 Oct **(verify date)**; Tomás Rivera sends the updated SSO order form (no date stated).

**Tue 6 Oct — Platform planning** `Oct 6 · Platform weekly planning`
- Audit-log export moves to the sprint after SAML.

**Wed 7 Oct — SAML SSO design review** `Oct 7 · SAML SSO design review`
- Decided to support both SP-initiated and IdP-initiated sign-in.
- Decided certificate rotation notices go out 30 days before expiry.
- Open question: multiple identity providers per workspace at launch?
- Next steps: metadata import by Sofia Marino (14 Oct); SSO admin screens by Ben Carter (13 Oct); customer SSO doc by Ravi Patel (15 Oct).

**Decisions that changed.** None in this period.

**Open questions.** Audit-log export contents · multiple identity providers at launch · pilot go-live date (Elena said 3 Nov, unverified).

**Not included:** Mon 12 Oct (upcoming, no card yet).

Result actions: Copy, Regenerate, Save as recipe, Export to Google Doc (disabled, "Available with Gate 4 integrations").

### 8.4 Same data, other styles

**Executive (5 lines):**
1. Lumen pilot is on track; SSO is the gate to expansion.
2. SAML first, SCIM next quarter; both sign-in flows supported.
3. SSO add-on priced at a monthly fee, details pending verification.
4. Key dates: scope due 16 Oct, target go-live 3 Nov (unverified).
5. Open: audit-log export scope, multiple identity providers.

**Brief (3 bullets):** Pilot running since 21 Sep · SAML SSO scoped by 16 Oct · audit-log export and go-live date still open.

### 8.5 States **[state]**

| State | Copy |
|---|---|
| Out of date | "A source meeting card changed after this summary was made. Regenerate to include it." |
| Nothing selected | "Pick a project or meetings to summarize." |
| No cards | "None of the selected meetings have a confirmed card yet. Open a meeting and confirm its items first." |
| Too many | "You picked 64 meetings. Choose up to 50, or narrow the date range." |
| Access | "Based on 5 meetings you can access." (1 private meeting left out, no names shown) |

### 8.6 Saved recipes list

| Name | Scope | Style | Last run |
|---|---|---|---|
| Lumen monthly rollup | Project Lumen Analytics + 2 meetings, 14 Sep–9 Oct | Detailed | 2026-10-09 14:26 |
| Weekly platform digest | Project SAML SSO Launch, last 7 days | Brief | 2026-10-05 08:00 |
| Q4 planning executive | Project Q4 Planning, all dates | Executive | 2026-10-03 17:12 |

---

## 9. Workflows (Phase W2 / W3), approvals, runs, templates

### 9.1 Workflows list (W-113)

| Name | Trigger | Status | Last run | Last result |
|---|---|---|---|---|
| Meeting ended — Linear issue and Slack summary | Meeting ended | Enabled | 2026-10-05 10:56 | Waiting for approval (3) |
| Commitment created — HubSpot note | Commitment created | Enabled | 2026-10-05 11:02 | Waiting for approval (1) |
| Weekly Lumen digest to Slack | Schedule · Mondays 09:00 | Enabled | 2026-10-05 09:00 | Succeeded |
| Agenda item overdue — Slack reminder | Schedule · daily 08:30 | **Disabled** | 2026-09-30 08:30 | Failed (Slack channel not found) |
| Approval given — Google Doc recap | Approval given | Enabled | never | — |

### 9.2 Canvas content for "Meeting ended — Linear issue and Slack summary" (W-110)

Taken from the reference screenshot. Content only:

- Toolbar: name, Enabled, Test run, History, Duplicate, Save. Zoom 100%, Fit, minimap.
- Palette: search "Search nodes"; Triggers: Meeting ended, Commitment created, Approval given, Schedule, Webhook; Actions need approval (lock icons): Create Linear issue, Create HubSpot note, Send Slack message, Create Google Doc; Conditions 3, Data transforms 3, Zedex actions 4.
- Nodes:

| Node | Category | Name | Badge |
|---|---|---|---|
| n1 | Trigger | Meeting ended | |
| n2 | Filter | Has next steps | |
| n3 | Transform | Map fields | |
| n4 | Transform | Format summary | |
| n5 | Action | Create Linear issue | Approval required |
| n6 | Action | Send Slack message | Approval required |

- Edges: n1→n2 "meeting", n2→n3 "meeting", n2→n4 "meeting", n3→n5 "next step", n4→n6 "text".
- Sticky note: "Every action waits in Approvals. Nothing is sent until a person approves the exact payload."

### 9.3 Node config panel (W-112) for n5, Create Linear issue

| Field | Value |
|---|---|
| Header | Action · writes to Linear / Create Linear issue |
| Title | `{{next_step.text}}` |
| Description | `{{evidence.quote}}` |
| Assignee | `{{next_step.owner}}` |
| Team | Platform |
| Payload preview (exact text) | title: Scope SAML SSO for the Lumen tenant · assignee: Priya Nair · team: Platform · due: 2026-10-16 |
| Require approval | On, locked. "Always on for nodes that write to another system. This can't be turned off." |
| Notify me after it sends | On |
| Buttons | Test this node, Save node |

Config for n6, Send Slack message: Channel `#lumen-pilot`, text = formatted summary:
"Lumen weekly sync (Mon 5 Oct): SAML first, SCIM next quarter. Priya scopes SAML SSO by 16 Oct. Tomás sends the order form. Open: audit-log export contents."

Config for n2, Filter: condition `meeting.next_steps.confirmed.count > 0`. Test output: "Passed: 2 confirmed next steps."

### 9.4 Approval Queue (W-60 and D-05)

Tabs: Pending (4), History.

| # | Destination | Payload (exact) | Source | Proposed owner | Due | Created |
|---|---|---|---|---|---|---|
| 1 | Linear | Title: Scope SAML SSO for the Lumen tenant · Description: "Then I'll scope SAML SSO for the Lumen tenant by Friday, October sixteenth." · Team: Platform · Assignee: Priya Nair · Priority: High · Due: 2026-10-16 | Lumen weekly sync, 2026-10-05, segment #14 | Priya Nair | 2026-10-16 | 2026-10-05 10:56 |
| 2 | Linear | Title: Send the updated SSO order form · Description: "It does. I'll send the updated order form." · Team: Sales · Assignee: Tomás Rivera · Priority: Medium · Due: not set | Lumen weekly sync, 2026-10-05, segment #7 | Tomás Rivera | — | 2026-10-05 10:56 |
| 3 | Slack | Channel #lumen-pilot · Text: "Lumen weekly sync (Mon 5 Oct): SAML first, SCIM next quarter. Priya scopes SAML SSO by 16 Oct. Tomás sends the order form. Open: audit-log export contents." | Lumen weekly sync, 2026-10-05 | — | — | 2026-10-05 10:56 |
| 4 | HubSpot | Note on company Lumen Analytics: "Customer requires SAML SSO before expanding past pilot. Add-on pricing under discussion. Go-live target 2026-11-03 (unverified)." | Lumen weekly sync, 2026-10-05, segment #13 | Tomás Rivera | — | 2026-10-05 11:02 |

Dialog buttons: Approve and send, Edit then approve, Reject (reason box). Note: "The sent content will match this preview exactly."

History rows: "Linear issue ZED-214 'Draft SSO price proposal' · Approved by Maya Chen · Sent 2026-09-30 11:14 · Succeeded"; "Slack message #lumen-pilot · Rejected by Maya Chen · Reason: 'Too much detail for the channel'"; "HubSpot note · Approved · **Uncertain** (no confirmation received), checking by lookup".

### 9.5 Run history (W-115)

| Run | Trigger | Started | Status |
|---|---|---|---|
| #41 | Lumen weekly sync, 2026-10-05 | 2026-10-05 10:56 | Waiting for approval (3 actions) |
| #40 | SAML SSO design review, 2026-10-07 | 2026-10-07 16:05 | Succeeded |
| #39 | Customer success weekly, 2026-10-08 | 2026-10-08 11:52 | **Skipped by filter** (no next steps) |
| #38 | Platform weekly planning, 2026-10-06 | 2026-10-06 14:55 | Failed: Slack channel not found. Button: Re-run |

Expanded run #41: trigger output (meeting id, title, 4 next steps of which 2 confirmed) → Filter passed (2 confirmed next steps) → Map fields output (2 issue drafts) → Create Linear issue: 2 payloads waiting in approval; Format summary → Send Slack message: 1 payload waiting.

### 9.6 Templates (W-114)

1. Meeting ended → create a Linear issue for each next step
2. Commitment created → create a HubSpot note on the associated contact
3. Meeting ended → send a Slack summary to a channel
4. Agenda item overdue → send a Slack reminder to the owner
5. Weekly report → post a digest to a Slack channel

---

## 10. Commitments and reports

### 10.1 Commitments board (W-61)

| Commitment | Owner | Due | Column | Source meeting | External item |
|---|---|---|---|---|---|
| Scope SAML SSO for the Lumen tenant | Priya Nair | 2026-10-16 | In progress | Lumen weekly sync, 2026-10-05 | Linear ZED-231 (pending approval) |
| Send the updated SSO order form | Tomás Rivera | 2026-10-07 | **Overdue** | Lumen weekly sync, 2026-10-05 | — |
| Confirm retention window with Daniel | Priya Nair | 2026-10-09 | **Overdue** (today) | Platform weekly planning, 2026-10-06 | — |
| Build SAML metadata import | Sofia Marino | 2026-10-14 | In progress | SAML SSO design review, 2026-10-07 | Linear ZED-232 |
| Draft SSO admin screens | Ben Carter | 2026-10-13 | Open | SAML SSO design review, 2026-10-07 | — |
| Write customer SSO doc | Ravi Patel | 2026-10-15 | Open | SAML SSO design review, 2026-10-07 | — |
| Draft SSO price proposal | Tomás Rivera | 2026-10-02 | Done | Lumen weekly sync, 2026-09-28 | Linear ZED-214 (delivered, owner confirmed) |
| Run admin training for pilot | Hannah Weiss | 2026-09-24 | Done | Lumen weekly sync, 2026-09-21 | — |

Note: the order form had no due date in the card; Maya Chen added 2026-10-07 on 2026-10-06, which is why it is overdue. Delivery note shown on Done cards: "Delivered · confirmed by Hannah Weiss 2026-09-24". A ticket alone shows "Ticket created, not yet delivered".

### 10.2 Team report (W-100)

Scope: Team Platform + project SAML SSO Launch · 2026-10-01 → 2026-10-09.

| Metric | Value |
|---|---|
| Meetings | 6 |
| Meeting hours | 5.4 h |
| Decisions made | 7 |
| Commitments created | 11 |
| Commitments delivered | 3 |
| Commitments overdue | 2 |
| Meetings with no outcome | 1 |
| Agenda completion rate | 78% |
| Series health: Lumen weekly sync | 100% captured, agenda used 3 of 4 weeks |
| Coverage gaps | 1: Pinecrest security walkthrough (2026-10-06) not captured |

Digest schedule dialog: "Every Monday 08:00 to #leadership" (Gate 4 delivery).

---

## 11. Search, chat, sharing

### 11.1 Search (W-50)

Query: **"SCIM"** · filters: last 60 days, all projects.

| Result | Meeting and date | Snippet | Link |
|---|---|---|---|
| Transcript | Lumen weekly sync · Mon 2026-10-05, 03:05 | "So we agree: SAML first, SCIM later." | Open at segment #8 |
| Transcript | Lumen weekly sync · Mon 2026-10-05, 03:12 | "Agreed. SCIM can wait until next quarter." | #9 |
| Card decision | Lumen weekly sync · Mon 2026-10-05 | "Ship SAML SSO first and defer SCIM to next quarter" | Card D1 |
| Card question | Lumen weekly sync · Mon 2026-09-28 | "Does Lumen need provisioning (SCIM) at launch?" | Card |
| Card question | SAML SSO design review · Wed 2026-10-07 | "Do we support multiple identity providers per workspace at launch?" | Card |

Results the user cannot access are not shown. **[state]** empty: "No results for 'zebra'. Try fewer words."

### 11.2 Chat (W-51)

Scope: "Project: Lumen Analytics · 5 meetings".

**You:** What did Lumen decide about SCIM and when is go-live?  
**Zedex:** Lumen agreed on SAML first with SCIM deferred to next quarter (Mon 5 Oct, Lumen weekly sync). Elena Brandt gave a go-live target of 3 November for the pilot team, but that date is unverified. Citations: [Oct 5 · #9] [Oct 5 · #13].  
**You:** Who owns the order form?  
**Zedex:** Tomás Rivera, no due date was stated, and it is currently overdue against the 7 Oct date on the commitments board. Citations: [Oct 5 · #7].  
**[state]** coverage note: "Mon 12 Oct is upcoming and has no notes yet."

### 11.3 Share link view (W-80, external person)

Title: "Lumen Analytics — Weekly sync · Mon 5 Oct 2026". Shared content: confirmed card items only (T1, D1, N1, N2). Banner: "Shared by Maya Chen · expires 2026-10-23". Footer buttons: Request access, "Sign up for Zedex". No transcript shown.

### 11.4 Share settings (W-81)

State: Link-only · Includes: Card (on), Notes (off), Transcript (off) · Expiry: 14 days · People: elena.brandt@lumen.example. Buttons: Create link, Copy link `https://app.zedex.example/s/9fK2-QmL7`, Revoke link, Add specific person, Close.

---

## 12. Catch-up and coverage

### 12.1 Catch-up brief (W-90), for Hannah Weiss, before Mon 2026-10-12 10:00

Header: "Since you were last here (Mon 2026-09-28)". Sections:

| Section | Items |
|---|---|
| Decisions | SAML first, SCIM next quarter (Oct 5) · Support both sign-in flows (Oct 7, SAML design review) |
| Your commitments | Run admin training for pilot, delivered |
| External status changes | Linear ZED-232 moved to In progress (Oct 8) |
| Open questions | Audit-log export contents · Multiple identity providers at launch |
| Not captured **[state]** | "Pinecrest security walkthrough (Oct 6): no notes were captured." Link: coverage roster |

Buttons: Acknowledge, View source meeting, Open next meeting prep.

### 12.2 Coverage roster (W-91)

| Series | Primary | Backup | Next uncovered |
|---|---|---|---|
| Lumen Analytics — Weekly sync | Maya Chen | Tomás Rivera | None |
| Pinecrest — Weekly check-in | Hannah Weiss | *Not assigned* **[state]** | Tue 2026-10-13 11:00 |
| Platform weekly planning | Priya Nair | Sofia Marino | None |
| Customer success weekly | Hannah Weiss | Maya Chen | None |

Alert history: "2026-10-05: Pinecrest check-in had no capturer 24 h before. Hannah Weiss asked Tomás Rivera, who declined." Button: Ask teammate to capture.

---

## 13. Desktop surfaces

### 13.1 DS-1 Meeting popup (Product weekly sync, today)

"Product weekly sync · Today 15:00–15:30 · Google Meet" · attendees Ravi Patel, Maya Chen, Ben Carter, Sofia Marino, + 1 more · status "Ready to capture" · consent reminder line: "Participants will be notified that notes are being taken." Buttons: Start Notes, Open Prep, Dismiss. States: capture active "00:12:48" with Stop; stopped with Open Summary.

### 13.2 DS-2 Overlay (Lumen weekly sync, 2026-10-05, at 06:02)

Header: "Lumen Analytics — Weekly sync · 06:02 · Live" · mic level "You" medium, "Others" high.

Agenda: ☑ Review SAML SSO scope (ticked 03:12) · ☑ Pricing and seats · ☐ Audit log export · ☐ Go-live timing.  
Notes: "02:12 Lumen audit in November is a hard deadline" · "05:30 Ask Daniel about audit log retention".  
Live suggestion strip (Gate 3): "Possibly resolved: 'Audit log export' — evidence at 04:48. Tick or dismiss." Buttons Tick, Dismiss, Pause, Stop, Collapse.

### 13.3 DS-3 Status strip

"● Live · 06:02 · Lumen Analytics — Weekly sync" · Expand, Stop. Variants: amber "Reconnecting…", red "Stopped".

### 13.4 DS-4 Post-capture notification

"Capture ended · 49 min 52 s · 16 segments synced · all acknowledged" · Open Summary, Dismiss. Variant **[state]**: "3 segments saved on this device, waiting to sync."

### 13.5 DS-5 Tray menu

"Zedex · Not capturing" · "Next: Product weekly sync, 15:00" · Open Zedex · Upcoming: Product weekly sync · Preferences · Quit Zedex.

### 13.6 DS-6 Offline page

"You're offline" · "3 segments saved on this device, pending sync" · "Last successful sync: Fri 9 Oct 2026, 14:18" · Retry connection, Sign out, Report issue.

---

## 14. Settings, profile, security, billing

### 14.1 Workspace settings (W-70)

**General:** Name Northwind Software · Slug northwind.  
**Members:** list from 1.3 with roles; pending from 1.4.  
**Security — sessions:**

| Device | Location | Last active | Current |
|---|---|---|---|
| MacBook Pro · Zedex desktop 1.0.3 | Brooklyn, US | now | Yes |
| Chrome on Windows 11 | Brooklyn, US | 2026-10-08 18:02 | No · Revoke |
| iPhone Safari | New Jersey, US | 2026-10-05 07:41 | No · Revoke |

Buttons: Revoke all other sessions, Download audit log.

**Audit log (sample rows, metadata only):**

| Time | Actor | Event |
|---|---|---|
| 2026-10-09 13:40 | Maya Chen | Added meeting to project Lumen Analytics |
| 2026-10-08 17:50 | Maya Chen | Created share link for a meeting |
| 2026-10-07 10:12 | Daniel Okafor | Changed role of Priya Nair to Editor on Lumen Analytics |
| 2026-10-06 09:30 | Maya Chen | Invited leo.park@northwind.example as Member |

**Privacy and data:** Request workspace export (button) · Delete all workspace data (danger, multi-step) · Consent record: "Policy: notify all participants. Notices recorded this month: 14. Participant objections: 0."

**Billing (Gate 4):** Plan Team · 12 seats ($0 pilot) · usage this period: speech-to-text 18.4 h of 240 h included; model usage 1,240 of 8,000 requests · Payment method "Visa ending 4242, expires 08/28" (fictional) · Upgrade Plan, Manage Billing.

### 14.2 Personal profile (W-71)

Display name Maya Chen · Email maya.chen@northwind.example (read-only).

| Notification | In-app | Email |
|---|---|---|
| Meeting reminder | On | Off |
| AI card ready | On | On |
| Commitment overdue | On | On |
| Approval needed | On | On |
| Coverage alert | On | Off |

Connected accounts: Google Calendar (maya.chen@gmail.example) · Disconnect. Theme: System.

---

## 15. Notifications, command palette, dialogs

### 15.1 Notification panel (D-01)

| Time | Notification | Action |
|---|---|---|
| 14:05 | Approval needed: Create Linear issue "Scope SAML SSO for the Lumen tenant" | Review |
| 13:40 | Meeting card ready: Customer success weekly failed. Try again | Retry |
| 11:20 | Commitment overdue: Send the updated SSO order form (Tomás Rivera) | View |
| Yesterday 18:40 | Meeting card ready: Founders 1:1 | View meeting |
| Yesterday 09:10 | Coverage alert: Pinecrest check-in has no backup capturer | Open roster |

Buttons: Mark all read, Notification settings.

### 15.2 Command palette (D-02)

Typed "lumen": results — Meetings: "Lumen Analytics — Weekly sync (Mon 5 Oct)" ⏎ · Projects: "Lumen Analytics" · Actions: "Create meeting", "New summary". Hints: ⌘K open, ↑↓ move, ⏎ select, Esc close.

### 15.3 Confirmation dialog (D-04) samples

"Delete this project? Its 5 meetings stay in your library. This can't be undone." Confirm (danger) · Cancel.  
"Remove Priya Nair from Lumen Analytics? She will lose access to meetings shared only through this project."

---

## 16. Empty, loading, error, no-permission copy

| Page | Empty | Primary button |
|---|---|---|
| Meetings list | "No meetings yet. Install the desktop app to capture, or import a transcript." | Download Desktop App / Import a Transcript |
| Projects | "Group meetings by customer, product, or team." | New Project |
| Approval queue | "No pending approvals. Nothing is waiting to be sent." (success state) | — |
| Commitments | "Commitments you confirm in meeting cards appear here." | Add Commitment |
| Search | "Search every meeting you can access." | (focus input) |
| Workflows | "Automate what happens after meetings." | New Workflow |
| Summary builder | "Pick projects or meetings to combine into one summary." | Choose meetings |
| Notifications | "You're all caught up." | — |

| State | Copy |
|---|---|
| Loading | Skeleton rows matching the layout |
| Failed to load | "We couldn't load this page." · Retry |
| Not found | "This meeting doesn't exist or was deleted." · Back to meetings |
| No permission | "You don't have access to this meeting." · Request access |
| Card generation failed | "We couldn't generate the card. Your transcript is safe." · Retry |
| Offline | "You're offline. Changes will sync when you reconnect." |
| Sync delayed | "Waiting to sync · 3 segments saved on this device" |

---

## 17. Onboarding (W-01 to W-05)

- **W-01 Sign-in:** product name "Zedex", line "Know what your team promised, and make sure it happens."; Continue with Google, Continue with Microsoft, Continue with email.
- **W-02 Workspace:** Name "Northwind Software", slug "northwind" (shows `zedex.example/northwind`), team size "11–50", Create Workspace.
- **W-03 Calendar:** see 2.1.
- **W-04 Desktop app:** "Capture meetings with a floating notes panel. Windows and macOS." Detected: macOS 14 (Apple Silicon). Buttons: Download for macOS, Download for Windows, "Skip — use web only".
- **W-05 Invite:** emails `leo.park@northwind.example, amara.diaz@northwind.example`, role per person, Send Invites, Copy invite link `https://app.zedex.example/join/nw-7Q2x`, Done.

---

## 18. Data consistency notes for builders

- The tracked meeting of record is **Mon 2026-10-05, Lumen Analytics — Weekly sync**. Quote text in cards, approvals, workflow payloads, and chat must match section 5.1 segments exactly.
- The summary in section 8 uses only confirmed items from section 6. If the card status changes, the summary must show "Out of date".
- The Linear issue payload is the same everywhere: title "Scope SAML SSO for the Lumen tenant", assignee Priya Nair, team Platform, due 2026-10-16.
- Flagged values are exactly: $1,200 (0.62), 250 seats (0.58), Nov 3 (0.55), Oct 16 (0.71).
- Private meeting (Founders 1:1) must never appear in any list, search, summary, or chat for anyone but its two attendees.
- Every number here is fictional and not a pricing statement.
