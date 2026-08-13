# Async Patterns & Event Contracts

## Template

```markdown
## Async Patterns & Event Contracts

### Pattern Selection

| Pattern | Use Case | Latency | Complexity |
|---------|----------|---------|------------|
| REST (sync) | CRUD operations, simple queries | Low | Low |
| Webhook | External service notifications | Medium | Medium |
| Message Queue | Background jobs, decoupled processing | High (async) | Medium |
| SSE (Server-Sent Events) | Real-time updates (one-way) | Low | Low |
| WebSocket | Real-time bidirectional communication | Low | High |
| Polling | Fallback when SSE/WS not available | Medium | Low |

### Event Schema Standard

**Event Envelope:**

```json
{
  "eventId": "evt-uuid-v7",
  "eventType": "document.created",
  "version": "1.0",
  "timestamp": "2026-01-01T00:00:00.000Z",
  "source": "api-server",
  "traceId": "abc-123-def-456",
  "data": {
    "documentId": "doc-ref-id",
    "workspaceId": "ws-ref-id",
    "createdBy": "user-ref-id",
    "title": "Document Title"
  },
  "metadata": {
    "correlationId": "req-uuid",
    "causedBy": "user.action"
  }
}
```

### Event Naming Convention

```
{domain}.{entity}.{action}

Contoh:
- document.created
- document.updated
- document.deleted
- workspace.member.invited
- workspace.member.removed
- auth.user.login
- auth.user.logout
```

### Webhook Contract

```markdown
#### Webhook: [event_name]

**URL:** Configured by receiver (callback URL)
**Method:** POST
**Content-Type:** application/json
**Auth:** HMAC-SHA256 signature in `X-Webhook-Signature` header

**Payload:**
```json
{
  "eventId": "evt-uuid-v7",
  "eventType": "document.created",
  "timestamp": "2026-01-01T00:00:00.000Z",
  "data": { ... }
}
```

**Signature Verification:**
```
signature = HMAC-SHA256(webhook_secret, raw_body)
X-Webhook-Signature: sha256={signature}
```

**Delivery Policy:**

| Parameter | Value |
|-----------|-------|
| Timeout | 10 seconds |
| Max Retries | 5 |
| Retry Backoff | 1m, 5m, 30m, 2h, 24h |
| Success Status | 2xx |
| Failure Action | Retry → after max retries, disable webhook + notify |
```

### Message Queue Contract

```markdown
#### Queue: [queue_name]

**Broker:** [RabbitMQ / SQS / Kafka]
**Topic/Exchange:** [nama topic]
**Consumer Group:** [nama consumer group]

**Message Schema:**
```json
{
  "eventId": "evt-uuid-v7",
  "eventType": "document.created",
  "version": "1.0",
  "timestamp": "2026-01-01T00:00:00.000Z",
  "data": { ... }
}
```

**Consumer Config:**

| Parameter | Value |
|-----------|-------|
| Concurrency | [N] consumers |
| Prefetch | [N] messages |
| Ack Mode | Manual (after processing) |
| Dead Letter Queue | [queue_name].dlq |
| Max Retries | 3 |
| Retry Delay | Exponential (1s, 5s, 30s) |

**Idempotency:**
- Consumer HARUS idempotent — same message processed 2x = same result
- Use `eventId` sebagai idempotency key
- Store processed eventIds di cache/DB dengan TTL
```

### SSE (Server-Sent Events)

```markdown
#### SSE Endpoint: GET /api/[resource]/stream

**Auth:** Bearer token via query param (SSE limitation)
**Content-Type:** text/event-stream

**Event Format:**
```
event: document.updated
id: evt-uuid-v7
data: {"documentId": "doc-123", "title": "Updated Title"}

event: heartbeat
id: hb-001
data: {"timestamp": "2026-01-01T00:00:00.000Z"}
```

**Connection Config:**

| Parameter | Value |
|-----------|-------|
| Heartbeat Interval | 30 seconds |
| Reconnect Delay | 3 seconds (client-side) |
| Max Connection Duration | 1 hour (then reconnect) |
| Auth Refresh | Via reconnect with new token |
```

### WebSocket Contract

```markdown
#### WebSocket: ws://[host]/ws/[resource]

**Auth:** Token via first message atau query param
**Protocol:** JSON messages

**Message Format:**
```json
{
  "type": "subscribe | unsubscribe | event | ack | error",
  "channel": "document:doc-123",
  "data": { ... },
  "messageId": "msg-uuid"
}
```

**Channels:**
| Channel Pattern | Description | Auth Required |
|----------------|-------------|---------------|
| `document:{id}` | Document real-time updates | Document read permission |
| `workspace:{id}` | Workspace activity feed | Workspace membership |
| `user:{id}` | Personal notifications | Owner only |

**Connection Lifecycle:**
```
Connect → Authenticate → Subscribe to channels → Receive events → Unsubscribe → Disconnect
```

**Heartbeat:**
- Server sends `ping` every 30s
- Client must respond `pong` within 10s
- No pong → server closes connection
```

## Event Versioning

| Version Change | Strategy | Example |
|---------------|----------|---------|
| Add optional field | Backward compatible, same version | Add `metadata.source` |
| Change field type | New version, support both | v1: string → v2: object |
| Remove field | Deprecate in v1, remove in v2 | Remove `legacyField` |
| Rename field | New version | v1: `name` → v2: `title` |

**Rules:**
- Consumer HARUS handle unknown fields gracefully (ignore, don't fail)
- Producer HARUS support N-1 version selama transition period
- Version di-include dalam event envelope

## Rules

1. Event schema HARUS se-strict REST API contract — documented, versioned, validated
2. Setiap event HARUS punya `eventId` (UUID v7) untuk idempotency dan tracing
3. Consumer HARUS idempotent — assume at-least-once delivery
4. Dead Letter Queue WAJIB — failed messages harus bisa di-inspect dan di-replay
5. Webhook signature verification WAJIB — prevent spoofing
6. Event naming convention harus konsisten: `{domain}.{entity}.{action}`
7. Heartbeat mechanism untuk long-lived connections (SSE, WebSocket)
8. Connection lifecycle harus documented — termasuk reconnect strategy
9. Event versioning strategy harus defined di awal — breaking change = new version
10. Monitor queue depth dan consumer lag — alert jika backlog growing
