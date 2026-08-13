# Observability

## Trace Structure

Every message produces a `RunTrace` with detailed per-step breakdown:

```json
{
  "trace_id": "uuid",
  "session_id": "conversation-ref-id",
  "timestamp": "2026-07-07T10:00:00Z",
  "input_message": "user message (PII masked in logs)",
  "output_message": "agent response",
  "routing": {
    "intent": "facility",
    "confidence": 0.9,
    "routed_to": "specialist_facility"
  },
  "steps": [
    {
      "step": 1,
      "type": "llm_call",
      "node": "router",
      "model": "gpt-4o-mini",
      "duration_ms": 1200,
      "input_tokens": 250,
      "output_tokens": 14,
      "cost_usd": 0.00004,
      "cost_idr": 0.72,
      "input_preview": "first 200 chars...",
      "output_preview": "{\"intent\": \"facility\"...}"
    },
    {
      "step": 2,
      "type": "tool_call",
      "node": "specialist_facility",
      "tool": "list_clinics_by_city",
      "args": {"city": "tangerang"},
      "duration_ms": 300,
      "success": true,
      "response_preview": "first 200 chars..."
    }
  ],
  "steps_full": [
    {
      "step": 1,
      "input_full": "complete system prompt + messages",
      "output_full": "complete LLM response"
    }
  ],
  "totals": {
    "llm_calls": 3,
    "tool_calls": 1,
    "total_tokens": 2500,
    "total_cost_usd": 0.001,
    "total_cost_idr": 18.0,
    "total_duration_ms": 5000,
    "usd_to_idr_rate": 18016.49,
    "models_used": ["gpt-4o-mini"]
  }
}
```

## Cost Tracking

- Model pricing in `configs/pricing.yaml` (USD per 1M tokens)
- Exchange rate fetched daily at 07:00 WIB from `open.er-api.com`
- Rate LOCKED per trace (doesn't change if rate changes later)
- Fallback rate from `USD_TO_IDR` env var

## Full LLM Input/Output Storage

`steps_full` contains complete LLM request + response for debugging:
- `input_full` — full system prompt + context injected to LLM
- `output_full` — complete LLM response text
- `response_full` — complete tool response (for tool calls)

Stored in MongoDB `messages.trace.steps_full`. Not returned in API by default (too large).

## Analytics API (via Gateway)

```
GET /v1/analytics/overview?range=7d
  → total messages, sessions, tokens, cost, avg duration

GET /v1/analytics/tokens?group_by=intent&range=7d
  → token usage breakdown by intent or channel
```

## Summary Generation

Every message gets a 1-line LLM-generated summary:
- Generated synchronously before returning response
- Stored in `messages.summary`
- Used in conversation list view (last_summary)
- Model: gpt-4o-mini, max 30 words, Bahasa Indonesia

## Monitoring Checklist

- [ ] Trace costs trending up? Check model pricing or switch to cheaper model
- [ ] High latency? Check tool call durations, consider caching
- [ ] Low confidence routing? Check router prompt, add more keywords
- [ ] Guardrail triggers? Check blocked_responses in traces
