# Observability & Logging

## Template

```markdown
## Observability & Logging

### Observability Strategy

| Pillar | Tool | Purpose |
|--------|------|---------|
| Logging | [ELK / CloudWatch / Datadog Logs] | Structured application logs |
| Metrics | [Prometheus / CloudWatch Metrics / Datadog] | Application & infrastructure metrics |
| Tracing | [Jaeger / X-Ray / Datadog APM] | Distributed request tracing |
| Alerting | [PagerDuty / Slack / OpsGenie] | Incident notification |

### Structured Logging

**Log Format (JSON):**

```json
{
  "timestamp": "2026-01-01T00:00:00.000Z",
  "level": "info",
  "service": "api-server",
  "traceId": "abc-123-def-456",
  "spanId": "span-789",
  "userId": "user-ref-id",
  "method": "POST",
  "path": "/api/documents",
  "statusCode": 201,
  "duration": 45,
  "message": "Document created successfully",
  "metadata": {
    "documentId": "doc-ref-id",
    "workspaceId": "ws-ref-id"
  }
}
```

### Log Levels

| Level | When to Use | Example |
|-------|-------------|---------|
| `error` | Unexpected failure, butuh immediate attention | Database connection failed, unhandled exception |
| `warn` | Potential issue, tapi system masih jalan | Rate limit approaching, deprecated API called |
| `info` | Business event penting | User login, document created, payment processed |
| `debug` | Detail untuk troubleshooting | Query params, cache hit/miss, function entry/exit |

**Rules:**
- Production: `info` level minimum (no debug)
- Staging: `debug` level
- NEVER log: passwords, tokens, PII, credit card numbers
- ALWAYS log: traceId, userId, request method + path, response status, duration

### Trace Correlation

```
Request masuk → Generate traceId → Pass ke semua downstream calls → Log dengan traceId yang sama
```

**Flow:**
```
Client Request
  → API Gateway (traceId: abc-123)
    → Auth Service (traceId: abc-123, spanId: span-001)
    → Document Service (traceId: abc-123, spanId: span-002)
      → Database Query (traceId: abc-123, spanId: span-003)
    → Cache Service (traceId: abc-123, spanId: span-004)
  → Response (traceId: abc-123)
```

**Implementation:**
- Generate `traceId` di entry point (API gateway / first service)
- Propagate via header: `X-Trace-Id` atau `traceparent` (W3C standard)
- Setiap service generate `spanId` sendiri
- Log semua operations dengan `traceId` + `spanId`

### Application Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|-----------------|
| `http_request_total` | Counter | Total HTTP requests by method, path, status | — |
| `http_request_duration_ms` | Histogram | Request latency (p50, p95, p99) | p95 > [X] ms |
| `http_request_in_flight` | Gauge | Current active requests | > [X] concurrent |
| `db_query_duration_ms` | Histogram | Database query latency | p95 > [X] ms |
| `db_connection_pool_active` | Gauge | Active DB connections | > 80% pool |
| `cache_hit_ratio` | Gauge | Cache hit rate | < 70% |
| `queue_depth` | Gauge | Message queue backlog | > [X] messages |
| `error_rate` | Gauge | Error percentage (5xx / total) | > [X]% |

### Dashboard Requirements

| Dashboard | Audience | Key Panels |
|-----------|----------|------------|
| Service Overview | On-call engineer | Request rate, error rate, latency (p50/p95/p99), uptime |
| Database | Backend engineer | Query latency, connection pool, slow queries, collection size |
| Business Metrics | PM / Engineering Lead | Active users, feature usage, conversion rates |
| Infrastructure | DevOps | CPU, memory, disk, network, pod count |

### Log Retention Policy

| Environment | Retention | Storage |
|-------------|-----------|---------|
| Production | 90 days (hot) + 1 year (cold) | [Cloud storage] |
| Staging | 30 days | [Cloud storage] |
| Development | 7 days | Local / ephemeral |
```

## Rules

1. Structured logging (JSON) WAJIB — no unstructured text logs di production
2. TraceId WAJIB ada di setiap log entry — tanpa ini, debugging distributed system = nightmare
3. NEVER log sensitive data (passwords, tokens, PII) — mask atau exclude
4. Log levels harus konsisten across services — definisikan standard di awal
5. Metrics harus di-setup SEBELUM deploy — bukan setelah ada incident
6. Dashboard harus ready sebelum feature launch — bukan afterthought
7. Alert threshold harus based on baseline data, bukan asal tebak
8. Log retention policy harus comply dengan data regulation yang berlaku
9. Setiap error log HARUS punya context yang cukup untuk reproduce issue
10. Health check endpoint (`/health`, `/ready`) WAJIB ada di setiap service
