# Product Workflows and Discovery Kit

## 1. Customer promise loop (first paid workflow)

1. A founder or salesperson meets a customer. The desktop popup offers notes; capture starts.
2. After the call, Zedex proposes decisions and commitments with evidence. The user confirms.
3. A workflow proposes a Linear issue (and a HubSpot note) with the exact payload. A teammate approves.
4. The integration creates the issue and stores the external reference. Status changes flow back.
5. Before the next customer meeting, the agenda and brief show current status per promise.
6. Delivery needs the owner's confirmation or approved evidence; a ticket alone is not delivery.

## 2. Prep → live → wrap agenda loop

1. 24 h before a recurring meeting, `intelligence` drafts an agenda: carry-over, open commitments with status, blockers, pending decisions, plus any context users added (notes, links, picked Google Docs).
2. Attendees add or edit items and context; the AI keeps proposing alongside them. The organizer accepts; nothing is auto-accepted.
3. During the meeting the overlay shows the accepted agenda and open to-dos. When text suggests an item was discussed, it highlights with evidence. A person ticks.
4. After the meeting, covered items close with evidence, uncovered ones carry over, and decisions and commitments go to confirmation. Next prep is drafted.

## 3. Grouping, routing, and tracking codes

- Users create Projects and folders, drag meetings in, multi-select, and assign one meeting to several Projects. Recurring meetings can auto-add to a chosen Project. Board views group by Project or team.
- Precedence: manual > series auto-add > rule/code > AI suggestion with confirmation.
- Rules: attendee domain → account, series → Project, organizer's team → team space.
- A `ZX-` code typed in a calendar title or description routes a meeting to a context. Unknown or inaccessible codes are ignored.
- Reports aggregate by team, Project, and code: meeting hours, commitments created/delivered/overdue, request-to-delivery cycle time, meetings with no outcome, series health. No per-person scoring.

## 4. Missed-meeting catch-up

10–15 minutes before the next occurrence, a person who missed the last one receives "since you were last here": decisions, their commitments, external status changes, open questions, and gaps. If nobody captured it, the brief says **Not captured** and links to the coverage roster.

## 5. Coverage roster and handoff

- Each team or series has primary and backup capturers.
- Managers get an alert 24 h and 1 h before an uncovered meeting, with one-click "ask a teammate to capture".
- A teammate's capture lands in the team space per policy.
- Gate 5: an admin may opt in to import the meeting platform's own text transcript after the fact, labelled "provider transcript".

## 6. Document export and import

- Export notes, an agenda, a report, or a brief into a new Google Doc (user-initiated write; `drive.file` scope).
- Pick an existing Doc to attach as agenda or Project context. Its text is treated as untrusted input.
- Notion follows at Gate 5.

## 7. Weekly team and executive reports

Scheduled digests per team or Project: decisions made, commitments delivered and overdue, blockers, series health, and coverage gaps. Audience-aware: each recipient sees only sources they can access. Exports expire after seven days.

## Gate 1 discovery kit

### Interview guide (15 interviews)

- Walk me through the last customer call that produced a request.
- Where did that request go afterward? Who knew, and when?
- Last time something promised on a call was missed, what happened?
- How do you prepare for a recurring meeting today? How long does it take?
- Which tools hold the truth for requests and delivery (CRM, tracker, chat)?
- What stops you from using a notetaker today (bots, privacy, trust, cost)?
- Who must approve what is written to those tools?
- Do not pitch Zedex in the first 20 minutes.

### End-to-end journey map

`call → request → owner → ticket → delivery → customer told → next meeting`

For each step record: actor, tool, time lost, failure modes, and evidence of lost work.

### Baseline metrics (before and after pilot)

| Metric | How measured |
|---|---|
| Preparation minutes per recurring meeting | Self-report plus observation |
| Follow-up minutes per customer call | Same |
| % commitments with owner and date | Audit of last 20 |
| Lost or late commitments per month | Audit and customer feedback |
| Request-to-delivery days | Tracker timestamps |
| Meetings with no outcome | Review |

### Design-partner criteria

20–100 employees, B2B SaaS, founders or sales on customer calls, Google or Microsoft calendar, HubSpot/Linear/Slack in use, willing to dogfood weekly and share baseline numbers.

### Pricing hypothesis (to test, not a claim)

Price as a workflow tool above notetakers. Reference points seen in public pricing: Granola Business about $14–15 per user/month, Fathom Team $15 and Business $25 (annual), Notion Business about $20 per seat. Willingness to pay is validated in pilots, not assumed.
