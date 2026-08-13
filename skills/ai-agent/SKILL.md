---
name: ai-agent-builder
description: >
  AI Agent development skill for building contact center / customer service agents.
  Uses 2-service architecture: Go Gateway (Echo, Clean Arch) + Python Engine (FastAPI, LangGraph).
  Use when creating new AI agents, adding specialists/intents, adding tools, adding knowledge sources,
  configuring guardrails, managing conversations, or any AI agent development.
---

# AI Agent Builder

Kamu adalah senior AI engineer yang ahli membangun conversational AI agents untuk enterprise.
Kamu memahami LangGraph, RAG patterns, tool calling, prompt engineering, dan production-grade deployment.

Skill ini mendefinisikan pattern development AI agent berbasis 2-service architecture.

## When to use this skill

- Membuat AI agent baru dari scratch
- Menambah specialist/intent baru ke agent yang sudah ada
- Membuat atau modify tools (Python functions yang bisa dipanggil LLM)
- Menambah knowledge source baru (Qdrant sync)
- Setup guardrails (input/output filtering)
- Manage conversation lifecycle
- Configure output format per channel (WhatsApp, Webchat, etc.)
- Setup observability (tracing, costing)
- Deploy ke Docker/Kubernetes

## Architecture Overview

```
┌──────────────────┐       HTTP/internal      ┌──────────────────┐
│  Go Gateway      │ ◄─────────────────────► │  Python Engine    │
│  (Echo, Clean)   │                          │  (FastAPI, Graph) │
│  Port: 8080      │                          │  Port: 8000       │
│                  │                          │                   │
│  • Auth          │                          │  • AI Processing  │
│  • Conversation  │                          │  • RAG (Qdrant)   │
│  • User resolve  │                          │  • Tool calling   │
│  • Save message  │                          │  • Guardrails     │
│  • Cron jobs     │                          │  • Summary gen    │
│  • Analytics     │                          │  • Knowledge sync │
└────────┬─────────┘                          └────────┬──────────┘
         │                                             │
    ┌────┴────┐  ┌───────┐                    ┌────────┴────────┐
    │ MongoDB │  │ Redis │                    │     Qdrant      │
    └─────────┘  └───────┘                    └─────────────────┘
```

## Service Separation (STRICT)

| Responsibility | Go Gateway | Python Engine |
|---------------|------------|---------------|
| Auth (Basic, Internal) | ✅ | ❌ |
| Conversation lifecycle | ✅ | ❌ |
| User resolve (find/create) | ✅ | ❌ |
| Save messages to MongoDB | ✅ | ❌ |
| Update conversation stats | ✅ | ❌ |
| AI intent routing | ❌ | ✅ |
| RAG retrieval (Qdrant) | ❌ | ✅ |
| Tool execution | ❌ | ✅ |
| LLM calls | ❌ | ✅ |
| Guardrails | ❌ | ✅ |
| Summary generation | ❌ | ✅ |
| Knowledge sync | ❌ | ✅ |
| Serve external API | ✅ | ❌ |

Python engine is **STATELESS** — does NOT write to messages/conversations MongoDB.

## Conversation Lifecycle

Refer to: `references/conversation-lifecycle.md`

## Adding New Specialist

Refer to: `references/adding-specialist.md`

## Adding New Tool

Refer to: `references/adding-tool.md`

## Adding New Knowledge Source

Refer to: `references/adding-knowledge.md`

## Adding New External API Driver (Go)

Refer to: `references/adding-driver.md`

## Guardrails

Refer to: `references/guardrails.md`

## Output Formats

Refer to: `references/output-formats.md`

## Observability

Refer to: `references/observability.md`

## Critical Rules

1. **Python engine NEVER writes to MongoDB** — Go gateway handles all persistence
2. **conversation.ref_id (UUID v7)** = session_id sent to engine
3. **Client sends `identifier`** (who) — NOT session_id. Gateway resolves conversation.
4. **All tools are Python functions** — no YAML tools, registered in `tool_registry.py`
5. **Tools return plain text** — LLM formats per output_format instruction
6. **No hardcoded ref_ids** anywhere — always fetch from API
7. **Knowledge data synced daily 05:00 WIB** — schedule data fetched real-time via tools
8. **Auth**: External = Basic Auth, Internal (Python↔Go) = X-Internal-Key header
9. **Go pattern**: Clean Architecture (claudia-service), Echo v5, interface-based
10. **Python pattern**: FastAPI + LangGraph, tools via @tool decorator, configs via YAML

## Key Files

| File | Purpose |
|------|---------|
| `configs/agent.yaml` | Agent config (specialists, routing, LLM models) |
| `configs/pricing.yaml` | Model pricing (USD per 1M tokens) |
| `engine/app/tools/tool_registry.py` | All tools registered here |
| `engine/app/agents/specialist.py` | Specialist node (RAG + LLM + Tools) |
| `engine/app/agents/router.py` | Intent classification |
| `gateway/src/usecases/chat/process.go` | Full chat flow (resolve → engine → save) |
| `gateway/src/interfaces/cron/conversation_expiry.go` | Auto-close job |

## Environment Variables

| Variable | Service | Purpose |
|----------|---------|---------|
| OPENAI_API_KEY | Engine | LLM provider |
| MIKA_ACCESS_KEY_ID | Both | Partner API + Auth |
| MIKA_SECRET_ACCESS_KEY | Both | Partner API + Auth |
| INTERNAL_API_KEY | Both | Python ↔ Go secret |
| ENGINE_URL | Gateway | Where engine lives |
| GATEWAY_URL | Engine | Where gateway lives |
| CONVERSATION_TIMEOUT_MINUTES | Gateway | Auto-close threshold |
| SKIP_INITIAL_SYNC | Engine | Skip sync on startup (dev) |
