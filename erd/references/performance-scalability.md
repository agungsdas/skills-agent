# Performance & Scalability

## Template

```markdown
## Performance & Scalability

### Performance Targets

| Metric | Target | Measurement | Current Baseline |
|--------|--------|-------------|------------------|
| API Response Time (p50) | < [X] ms | APM monitoring | [Current] |
| API Response Time (p95) | < [X] ms | APM monitoring | [Current] |
| API Response Time (p99) | < [X] ms | APM monitoring | [Current] |
| Page Load (FCP) | < [X] s | Lighthouse | [Current] |
| Page Load (LCP) | < [X] s | Web Vitals | [Current] |
| Database Query Time | < [X] ms | Query profiler | [Current] |
| Throughput | [X] req/s | Load testing | [Current] |
| Error Rate | < [X]% | Monitoring | [Current] |

### Load Estimation

| Metric | Current | 6 Months | 1 Year |
|--------|---------|----------|--------|
| Daily Active Users | [N] | [N] | [N] |
| Peak Concurrent Users | [N] | [N] | [N] |
| API Requests/day | [N] | [N] | [N] |
| Database Size | [N] GB | [N] GB | [N] GB |
| File Storage | [N] GB | [N] GB | [N] GB |

### Caching Strategy

| Data | Cache Layer | TTL | Invalidation Strategy |
|------|-------------|-----|----------------------|
| [User session] | [Redis] | [7d] | [On logout / password change] |
| [Document list] | [Redis] | [5m] | [On create/update/delete] |
| [Static assets] | [CDN] | [1y] | [Cache busting via hash] |
| [API response] | [In-memory] | [1m] | [Time-based] |

**Cache Invalidation Rules:**
- [Rule 1 — kapan cache di-invalidate]
- [Rule 2]

### Database Optimization

**Query Optimization:**
- [Query 1] — index yang digunakan, expected performance
- [Query 2] — aggregation pipeline optimization

**Connection Pooling:**
- Min connections: [N]
- Max connections: [N]
- Idle timeout: [N] seconds

### Scaling Plan

| Load Level | Strategy | Trigger | Action |
|------------|----------|---------|--------|
| Normal | Single instance | — | — |
| High | Horizontal scale | CPU > 70% | Add instances |
| Peak | Auto-scale | Request queue > [N] | Scale to max [N] instances |
| Emergency | Circuit breaker | Error rate > [X]% | Degrade gracefully |

### Performance Budget

| Resource | Budget | Current |
|----------|--------|---------|
| JavaScript bundle | < [X] KB (gzipped) | [Current] |
| CSS bundle | < [X] KB (gzipped) | [Current] |
| Image per page | < [X] KB total | [Current] |
| API payload | < [X] KB per response | [Current] |
| Third-party scripts | < [X] KB total | [Current] |
```

## Rules

1. Performance targets HARUS spesifik — percentile-based (p50, p95, p99)
2. Baseline measurement WAJIB ada sebelum optimization — tanpa baseline, tidak bisa measure improvement
3. Caching strategy harus include invalidation — cache tanpa invalidation = stale data
4. Load estimation based on data, bukan feeling — gunakan analytics
5. Database queries harus di-profile — EXPLAIN sebelum deploy
6. Scaling plan harus include trigger conditions dan actions
7. Performance budget membantu prevent regression — enforce di CI/CD
8. Monitor setelah deploy — performance di staging ≠ performance di production
