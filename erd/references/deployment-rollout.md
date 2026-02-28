# Deployment & Rollout Plan

## Template

```markdown
## Deployment & Rollout Plan

### Deployment Strategy

| Aspect | Detail |
|--------|--------|
| Strategy | [Rolling update / Blue-green / Canary] |
| Downtime | [Zero downtime / Maintenance window] |
| Rollback Time | < [X] minutes |
| Feature Flags | [Yes/No — list flags] |
| Database Migration | [Before/During/After deploy] |

### Pre-Deployment Checklist

- [ ] All tests passing (unit, integration, E2E)
- [ ] Code review approved
- [ ] Database migration tested on staging
- [ ] Performance test passed
- [ ] Security review completed
- [ ] Documentation updated
- [ ] Monitoring & alerting configured
- [ ] Rollback plan tested
- [ ] Stakeholders notified

### Rollout Phases

| Phase | Audience | Duration | Success Criteria | Rollback Trigger |
|-------|----------|----------|------------------|------------------|
| Phase 1 | Internal team only | [X] days | [Criteria] | [Trigger] |
| Phase 2 | [X]% of users | [X] days | [Criteria] | [Trigger] |
| Phase 3 | 100% of users | — | [Criteria] | [Trigger] |

### Feature Flags

| Flag Name | Description | Default | Rollout |
|-----------|-------------|---------|---------|
| [flag_name] | [Apa yang di-toggle] | false | Phase 1: internal, Phase 2: 10%, Phase 3: 100% |

### Database Migration Plan

| Step | Action | Reversible | Duration | Risk |
|------|--------|------------|----------|------|
| 1 | [Add new field with default] | Yes | < 1 min | Low |
| 2 | [Deploy new code] | Yes (rollback) | < 5 min | Low |
| 3 | [Backfill data] | Yes (unset) | [Duration] | Medium |
| 4 | [Remove old field] | No | < 1 min | Low — only after validation |

**Migration Order:** Schema change FIRST → Deploy code → Backfill → Cleanup

### Rollback Plan

| Scenario | Action | Time | Owner |
|----------|--------|------|-------|
| Code bug (non-data) | Revert deployment | < 5 min | [DevOps] |
| Data corruption | Restore from backup + revert | < 30 min | [DBA + DevOps] |
| Performance degradation | Disable feature flag | < 1 min | [On-call engineer] |
| Security vulnerability | Emergency patch + revert | < 15 min | [Security + DevOps] |

### Monitoring & Alerting

| Metric | Threshold | Alert Channel | Action |
|--------|-----------|---------------|--------|
| Error rate (5xx) | > [X]% | [Slack/PagerDuty] | Investigate, consider rollback |
| Response time (p95) | > [X] ms | [Slack] | Investigate |
| CPU usage | > [X]% | [Monitoring] | Scale up |
| Memory usage | > [X]% | [Monitoring] | Investigate leak |
| Database connections | > [X]% pool | [Slack] | Scale / optimize |

### Post-Deployment Validation

- [ ] Health check endpoints responding
- [ ] Key user flows working (smoke test)
- [ ] Error rate within normal range
- [ ] Response times within SLA
- [ ] Database metrics stable
- [ ] No increase in support tickets
- [ ] Feature flag working as expected
```

## Rules

1. Rollback plan WAJIB ada — dan harus tested sebelum deploy
2. Database migration harus backward compatible — deploy code yang handle both old & new schema
3. Feature flags untuk fitur besar — enable gradual rollout dan instant rollback
4. Monitoring harus ready SEBELUM deploy, bukan setelah
5. Post-deployment validation checklist harus dijalankan setiap deploy
6. Zero downtime sebagai default — maintenance window hanya jika absolutely necessary
7. Migration order: schema first → code → backfill → cleanup (never reverse)
8. Rollback time target: < 5 minutes untuk code, < 30 minutes untuk data issues
