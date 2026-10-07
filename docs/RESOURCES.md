> **Plan document — do not modify.**
> This file is the agreed plan and architecture. Treat it as source of truth.
> Changes must go through a new ADR or an explicit plan revision — do not edit in place.

---

> **Production target** — this is not a prototype or MVP. Every decision here targets a production product shipped in cycles.


# Resources

Official or primary sources by topic. Recheck each at implementation and record API versions and scopes next to the code that uses them. Research does not authorize paid calls or deployment. Links were collected from research and prior planning; they have not yet been re-verified one by one.

## Desktop and native

| Topic | Link |
|---|---|
| Electron security | https://www.electronjs.org/docs/latest/tutorial/security |
| Electron safeStorage | https://www.electronjs.org/docs/latest/api/safe-storage |
| Electron window content protection | https://www.electronjs.org/docs/latest/api/browser-window |
| Electron on Windows ARM | https://www.electronjs.org/docs/latest/tutorial/windows-arm |
| Electron code signing (incl. Azure Artifact Signing) | https://electronjs.org/docs/latest/tutorial/code-signing |
| Azure Artifact Signing | https://azure.microsoft.com/en-us/products/artifact-signing |
| Windows SetWindowDisplayAffinity | https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowdisplayaffinity |
| macOS Core Audio taps | https://developer.apple.com/documentation/coreaudio/capturing-system-audio-with-core-audio-taps |
| Windows loopback recording | https://learn.microsoft.com/en-us/windows/win32/coreaudio/loopback-recording |
| SQLite3 Multiple Ciphers | https://utelle.github.io/SQLite3MultipleCiphers/ |
| better-sqlite3-multiple-ciphers | https://github.com/m4heshd/better-sqlite3-multiple-ciphers |

## Speech-to-text (cloud providers — Gate 1 benchmark)

| Topic | Link |
|---|---|
| AssemblyAI Universal-Streaming ($0.15/h; +$0.12/h speaker separation) | https://www.assemblyai.com/docs/speech-to-text/streaming |
| AssemblyAI pricing | https://www.assemblyai.com/pricing |
| AssemblyAI keyterm prompting | https://www.assemblyai.com/docs/speech-to-text/key-phrases |
| Deepgram Nova-3 (~$0.46/h streaming) | https://developers.deepgram.com/docs/streaming |
| Deepgram pricing | https://deepgram.com/pricing |
| Deepgram keywords / keyterm prompting | https://developers.deepgram.com/docs/keywords |

## Speech recognition (local — retained for reference; enterprise privacy mode backlog)

| Topic | Link |
|---|---|
| whisper.cpp | https://github.com/ggml-org/whisper.cpp |
| sherpa-onnx | https://github.com/k2-fsa/sherpa-onnx |
| Parakeet-TDT 0.6B v3 (CC-BY-4.0) | https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3 |

## Backend and data

| Topic | Link |
|---|---|
| Fastify (TypeScript) | https://fastify.dev/docs/latest/Reference/TypeScript/ |
| PostgreSQL row-level security | https://www.postgresql.org/docs/current/ddl-rowsecurity.html |
| Azure PostgreSQL elastic clusters (Citus) | https://learn.microsoft.com/en-us/azure/postgresql/elastic-clusters/concepts-elastic-clusters |
| pgvector on Azure PostgreSQL | https://learn.microsoft.com/en-us/azure/postgresql/extensions/how-to-use-pgvector |
| OpenFGA | https://openfga.dev/ |
| SpiceDB (alternative reviewed) | https://authzed.com/docs/spicedb |
| Azure AI Search security trimming | https://learn.microsoft.com/en-us/azure/search/search-security-trimming-for-azure-search |
| Azure Service Bus | https://learn.microsoft.com/en-us/azure/service-bus-messaging/ |
| Azure Web PubSub | https://learn.microsoft.com/en-us/azure/azure-web-pubsub/ |
| Azure Managed Redis | https://learn.microsoft.com/en-us/azure/redis/ |
| AsyncAPI | https://www.asyncapi.com/docs |

## Identity and integrations

| Topic | Link |
|---|---|
| WorkOS AuthKit | https://workos.com/docs/authkit/overview |
| WorkOS authorization URL (PKCE) | https://workos.com/docs/reference/authkit/authentication/get-authorization-url |
| Google Calendar sync | https://developers.google.com/workspace/calendar/api/guides/sync |
| Google Calendar push notifications | https://developers.google.com/workspace/calendar/api/guides/push |
| Microsoft Graph delta query for events | https://learn.microsoft.com/en-us/graph/delta-query-events |
| Google Drive API scopes (`drive.file`) | https://developers.google.com/workspace/drive/api/guides/api-specific-auth |
| Google Docs API | https://developers.google.com/workspace/docs/api/how-tos/overview |
| HubSpot developers | https://developers.hubspot.com/docs |
| Linear API | https://linear.app/developers |
| Slack API | https://api.slack.com/ |
| Notion API | https://developers.notion.com/ |
| Jira Cloud REST | https://developer.atlassian.com/cloud/jira/platform/rest/v3/ |
| Stripe | https://docs.stripe.com/ |
| Granola API and help center | https://docs.granola.ai/ |
| Fathom help and API | https://help.fathom.video/ |

## Azure platform

| Topic | Link |
|---|---|
| Bicep | https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview |
| Container Apps scaling (KEDA) | https://learn.microsoft.com/en-us/azure/container-apps/scale-app |
| Container Apps managed identity | https://learn.microsoft.com/en-us/azure/container-apps/managed-identity |
| Azure OpenAI data privacy | https://learn.microsoft.com/en-us/azure/ai-foundry/responsible-ai/openai/data-privacy |
| Deployment stamps pattern | https://learn.microsoft.com/en-us/azure/architecture/patterns/deployment-stamp |
| AWS cell-based architecture whitepaper | https://docs.aws.amazon.com/wellarchitected/latest/reducing-scope-of-impact-with-cell-based-architecture/what-is-a-cell-based-architecture.html |
| Azure Pricing Calculator | https://azure.microsoft.com/en-us/pricing/calculator/ |
| OpenTelemetry | https://opentelemetry.io/docs/ |

## Front end

| Topic | Link |
|---|---|
| React Flow | https://reactflow.dev/ |
| TipTap | https://tiptap.dev/docs |
| TanStack Router / Query | https://tanstack.com/ |
| Radix UI | https://www.radix-ui.com/ |

## Security and legal

| Topic | Link |
|---|---|
| OWASP ASVS | https://owasp.org/www-project-application-security-verification-standard/ |
| OWASP Top 10 for LLM applications | https://owasp.org/www-project-top-10-for-large-language-model-applications/ |
| Otter.ai ruling summary | https://www.sheppard.com/insights/blogs/when-ai-takes-notes-court-allows-privacy-claims-against-otterai-to-proceed |

Legal advice on recording and consent must come from qualified counsel for each target jurisdiction.
