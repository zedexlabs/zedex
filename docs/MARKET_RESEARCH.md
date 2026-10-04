> **Plan document — do not modify.**
> This file is the agreed plan and architecture. Treat it as source of truth.
> Changes must go through a new ADR or an explicit plan revision — do not edit in place.

---
# Market Research

Research date: 3 October 2026. This is a sample of public pages, reviews, and community threads. It informs discovery; it is not market sizing or proof of willingness to pay. Verify pricing and features before relying on them.

## 1. Problems observed

| Problem | Evidence (public sources) |
|---|---|
| Bots in calls feel intrusive; teams block them | r/sysadmin "Blocking AI notetakers"; r/projectmanagement Otter thread; r/NoteTaking bot-free requests |
| Notes and action items sit unused | r/artificial "AI meeting notes … least useful part of my week"; r/MicrosoftTeams "Do you actually read the notes?" |
| Phantom or low-quality action items | LinkedIn post describing 14 action items from one call |
| Promises lost between sales, CS, and engineering | r/CustomerSuccess "The handoff was killing us"; r/salesengineers "recall everything that was promised"; r/ProductManagement "Sales repeatedly selling non-existent features" |
| Notetaker misses meetings or mislabels speakers | r/ArtificialInteligence Granola threads; r/AI_Agents speaker identification complaint; Krisp and tl;dv reviews |
| Consent and privacy concern | r/ArtificialInteligence "Ethics of AI notetaking at work"; r/legaltech; Otter.ai class action (Brewer v. Otter.ai) allowed to proceed |
| Lock-in and weak export | meetingnotes.com Granola teardown (no export, limited sharing automation) |

## 2. Competitor snapshot

| Product | Capture | Strengths | Gaps relevant to Zedex |
|---|---|---|---|
| Granola | Bot-free desktop + mobile | Notes + transcript blend, briefs, chat, spaces/folders, MCP, API | No export; manual CRM/Slack sharing; no agenda or commitment tracking |
| Fathom | Bot and bot-free (3.0), video recording | Ask Fathom, scorecards, CRM sync, keyword alerts, clips, consent chat message | Recording-centric; follow-through left to other tools |
| Notion AI Meeting Notes | Bot-free | Native Notion pages and database | Locked to Notion |
| ChatGPT Record mode | macOS app | Summary into a canvas | Cloud audio; macOS only |
| Otter, Fireflies | Bots | Mature transcripts, integrations | Bot friction, consent exposure |
| Read AI, Circleback, Spinach | Bot and bot-free | Action items to Linear/Jira/HubSpot | Item creation without delivery tracking |
| Fellow | Agenda-centric | Collaborative agendas, rollover of open items | No live matching against the transcript |
| Gong | Sales calls | Briefs, deal intelligence | Enterprise sales focus |
| Anarlog, Meetily | Open-source local | On-device, Markdown export | Little team workflow |

## 3. Opportunity

- Notetaking and summaries are commodities. The gap is the loop: agreed agenda → live tracking → confirmed commitments → approved routing → delivery evidence → next meeting.
- Agendas that carry open commitments with live external status, with a live panel that suggests what was discussed, were not found in the surveyed products.
- Two-channel local capture separates "us" from "them", which suits customer commitments, without needing diarization.

## 4. Granola and Fathom parity matrix

| Capability | Granola | Fathom | Zedex | Gate |
|---|---|---|---|---|
| Bot-free capture | ✓ | ✓ (3.0) | ✓ | 2 |
| Mac + Windows desktop | ✓ | ✓ | ✓ | 2 |
| Mobile | ✓ | iOS | Planned | 6 |
| Calendar integration | ✓ | ✓ | ✓ read-only | 2 |
| Notes editor + templates | ✓ | templates | ✓ | 3 |
| AI-enhanced notes/summary | ✓ | ✓ | ✓ with evidence | 3 |
| Chat over meetings/folders | ✓ | Ask Fathom | ✓ scoped, cited | 3 |
| Folders, spaces, sharing | ✓ | folders | Projects + teams | 2 |
| Auto-add recurring meetings to folder | ✓ | — | ✓ | 2 |
| Briefs before meetings | ✓ | — | ✓ with agenda | 3 |
| Prompts/recipes | ✓ | templates | ✓ prompts | 3 |
| CRM association | HubSpot, Attio, Affinity | HubSpot, Salesforce | HubSpot; Salesforce later | 4 / 6 |
| Slack, Notion, Zapier | ✓ | ✓ | Slack 4; Notion, webhooks 5 | 4–5 |
| API + MCP | ✓ | ✓ | ✓ | 5 |
| Keyword/topic alerts | — | ✓ | ✓ authorized text only | 3–4 |
| Scorecards/coaching | — | ✓ | Opt-in, visible to the person | 6 |
| Video/audio recording, playback, clips | — | ✓ | **Not offered**; timestamped quote cards with deep links | — |
| Consent chat message / email | — | ✓ | Generated text; consent email | 2 / 5 |
| Enterprise SSO/SCIM, admin | Enterprise | ✓ | Demand-gated | 6 |
| Agenda built from prior context | — | — | ✓ | 2–3 |
| Live agenda and to-do tracking | — | — | ✓ human-ticked | 2–3 |
| Commitment tracking to delivery | — | partial | ✓ with approvals | 4 |
| Coverage roster for absent owners | — | — | ✓ | 3 |
| Visual workflow canvas | — | — | ✓ | 5 |
| Export and portability | limited | ✓ | Markdown/JSON personal and admin | 3–4 |

## 5. Beyond both

Agenda-to-commitment continuity, live agenda tracking, coverage roster and honest "Not captured", exact-payload approvals with uncertain-write reconciliation, tracking-code attribution by team, and data portability.

## 6. Sources

Product pages and docs: [Granola](https://www.granola.ai/), [Granola folders and spaces](https://docs.granola.ai/help-center/sharing/folders/spaces-and-folders), [Granola plans](https://www.granola.ai/blog/granola-free-vs-paid-features-each-plan), [Fathom](https://www.fathom.ai/), [Fathom release notes](https://help.fathom.video/en/articles/6220097).
Reviews and comparisons: [meetingnotes.com Granola teardown](https://meetingnotes.com/blog/granola-ai-teardown), [Krisp review](https://krisp.ai/blog/granola-ai-review-alternatives/), [tl;dv review](https://tldv.io/blog/granola-review/), [Read AI](https://www.read.ai/articles/best-ai-meeting-assistants), [Circleback](https://circleback.ai/blog/best-ai-meeting-assistants), [Fellow agendas](https://fellow.ai/blog/ai-generated-meeting-agendas/), [Anarlog and Meetily comparison](https://summitnotes.app/blog/summit-vs-meetily-hyprnote-granola-otter/).
Legal: [Sheppard on Otter.ai ruling](https://www.sheppard.com/insights/blogs/when-ai-takes-notes-court-allows-privacy-claims-against-otterai-to-proceed), [Courthouse News](https://www.courthousenews.com/otter-ai-faces-privacy-class-action/).
Community threads were found by search in r/CustomerSuccess, r/salesengineers, r/ProductManagement, r/sysadmin, r/artificial, r/ArtificialInteligence, and r/legaltech; open the linked results through a search for the titles quoted above.
