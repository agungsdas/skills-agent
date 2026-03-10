# Error Handling Strategy

## Template

```markdown
## Error Handling Strategy

### Error Classification

| Category | HTTP Status | Retry? | Alert? | Example |
|----------|-------------|--------|--------|---------|
| Client Error | 4xx | No | No (kecuali spike) | Validation error, unauthorized |
| Transient Error | 5xx / timeout | Yes (with backoff) | Yes (jika persistent) | DB timeout, external API down |
| Permanent Error | 5xx | No | Yes (immediate) | Data corruption, config error |
| Business Error | 4xx / 422 | No | No | Insufficient balance, duplicate |

### Error Response Format

```json
{
  "success": false,
  "message": "Human-readable error message",
  "error": {
    "code": "ERROR_CODE",
    "category": "VALIDATION | AUTH | BUSINESS | SYSTEM",
    "details": [
      { "field": "email", "message": "Email format invalid" }
    ],
    "traceId": "abc-123-def-456"
  }
}
```

### Error Code Registry

| Code | Category | HTTP Status | Message Template |
|------|----------|-------------|------------------|
| VALIDATION_ERROR | Validation | 400 | "Invalid input: {details}" |
| UNAUTHORIZED | Auth | 401 | "Authentication required" |
| FORBIDDEN | Auth | 403 | "Insufficient permissions" |
| NOT_FOUND | Business | 404 | "{resource} not found" |
| CONFLICT | Business | 409 | "{resource} already exists" |
| RATE_LIMITED | System | 429 | "Too many requests, retry after {seconds}s" |
| INTERNAL_ERROR | System | 500 | "Internal server error" |
| SERVICE_UNAVAILABLE | System | 503 | "Service temporarily unavailable" |

### Retry Policy

| Scenario | Strategy | Max Retries | Backoff | Timeout |
|----------|----------|-------------|---------|---------|
| Database timeout | Exponential backoff | 3 | 100ms, 200ms, 400ms | 5s per attempt |
| External API call | Exponential + jitter | 3 | 1s, 2s, 4s + random | 10s per attempt |
| Message queue publish | Fixed interval | 5 | 500ms | 3s per attempt |
| Cache operation | No retry | 0 | — | 100ms |

**Retry Rules:**
- ONLY retry transient errors (timeout, 5xx, connection refused)
- NEVER retry client errors (4xx) — kecuali 429 (rate limited)
- ALWAYS use exponential backoff + jitter untuk avoid thundering herd
- Set max retries — infinite retry = resource exhaustion

### Circuit Breaker

```
States: CLOSED → OPEN → HALF-OPEN → CLOSED

CLOSED (normal):
  - Request diteruskan ke downstream
  - Track failure count

OPEN (tripped):
  - Request langsung return fallback/error
  - Tidak call downstream sama sekali
  - Timer: tunggu [X] detik sebelum coba lagi

HALF-OPEN (testing):
  - Allow [N] request untuk test
  - Jika success → CLOSED
  - Jika fail → OPEN lagi
```

| Parameter | Value | Description |
|-----------|-------|-------------|
| Failure Threshold | [X] failures in [Y] seconds | Kapan circuit OPEN |
| Reset Timeout | [X] seconds | Berapa lama OPEN sebelum HALF-OPEN |
| Half-Open Requests | [N] requests | Berapa request di-allow saat HALF-OPEN |

### Graceful Degradation

| Dependency Down | Degradation Strategy | User Impact |
|-----------------|---------------------|-------------|
| Cache (Redis) | Bypass cache, query DB langsung | Slower response, no downtime |
| Search Engine | Disable search, show browse-only | Search unavailable, core features OK |
| External API | Return cached/stale data | Data mungkin outdated |
| Message Queue | Write to fallback (DB queue) | Async operations delayed |
| Database | Return 503, activate maintenance mode | Full downtime |

### Error Propagation

```
Controller → Usecase → Repository → Database
     ↑           ↑          ↑           ↑
  Format     Business    Data       Raw DB
  for API    context     context    error
  response   + wrap      + wrap
```

**Rules:**
- Catch di layer yang bisa handle — jangan catch-and-ignore
- Wrap error dengan context di setiap layer (add info, don't lose original)
- Transform ke user-friendly message hanya di controller/API layer
- Log original error dengan full stack trace di point of failure
- Jangan expose internal error details ke client (security risk)
```

## Rules

1. Error classification WAJIB — setiap error harus punya category yang jelas
2. Error codes harus consistent dan documented — jangan ad-hoc error messages
3. Retry hanya untuk transient errors — retry permanent error = waste resources
4. Circuit breaker WAJIB untuk external dependencies — prevent cascade failure
5. Graceful degradation plan untuk setiap critical dependency
6. Error response HARUS include traceId — untuk correlation dengan logs
7. NEVER expose stack trace atau internal details ke client
8. Log error dengan full context di point of failure — jangan hanya di top level
9. Error handling harus di-test — simulate failures di integration tests
10. Fallback strategy harus di-document dan di-test sebelum production
