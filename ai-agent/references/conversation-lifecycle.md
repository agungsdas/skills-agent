# Conversation Lifecycle

## Flow

```
Client sends: { identifier: "6281234567890", message: "halo", channel: "whatsapp" }
     │
     ▼
Go Gateway: FindActiveByIdentifierAndChannel("6281234567890", "whatsapp")
     │
     ├─ Found (status=ACTIVE) → Reuse conversation, same ref_id as session_id
     │
     └─ Not found → Create new conversation
                    → Generate UUID v7 as ref_id
                    → This ref_id = session_id to engine
     │
     ▼
Go Gateway: ResolveUser(identifier)
     │  FindUser(phone) → found? use ref_id : CreateUser(phone, name)
     │
     ▼
Go Gateway: POST engine/chat { session_id: conv.ref_id, user_ref_id, message, ... }
     │
     ▼
Engine: Process AI → Return { response, summary, trace, cost }
     │
     ▼
Go Gateway: SaveMessage(session_id, user_msg, agent_msg, trace, summary, cost)
Go Gateway: UpdateConversation(stats: message_count++, cost++, tokens++, last_message)
     │
     ▼
Return response to client
```

## Auto-Close (Cron Job)

Runs every `CONVERSATION_EXPIRY_CHECK_INTERVAL_MINUTES` (default: 1 minute).

```
For each conversation WHERE status=ACTIVE AND last_message_at < (now - CONVERSATION_TIMEOUT_MINUTES):
  1. Set status = CLOSED, close_reason = "timeout"
  2. Insert system message: "Percakapan ditutup otomatis karena tidak ada aktivitas..."
  3. Log closure
```

Next chat from same identifier → new conversation created (fresh session in engine).

## Statuses

| Status | Meaning |
|--------|---------|
| `ACTIVE` | Conversation is ongoing |
| `CLOSED` | Closed (timeout, manual, or escalation) |

## MongoDB Schema

```json
{
  "ref_id": "uuid-v7 (unique, used as session_id)",
  "identifier": "6281234567890",
  "channel": "whatsapp",
  "status": "ACTIVE",
  "user_ref_id": "mika-partner-user-id",
  "user_name": "Agung",
  "phone": "6281234567890",
  "output_format": "WHATSAPP",
  "message_count": 5,
  "total_cost_usd": 0.005,
  "total_cost_idr": 90.0,
  "total_tokens": 12000,
  "last_message_at": "2026-07-07T10:00:00Z",
  "last_summary": "User tanya cabang di Tangerang...",
  "closed_at": null,
  "close_reason": "",
  "created_at": "2026-07-07T09:50:00Z"
}
```

## Indexes

- `ref_id` (unique)
- `identifier + channel + status` (compound, for find active)
- `last_message_at` (for cron scan)
- `status` (for filtering)
