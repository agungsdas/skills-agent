# Non-Functional Requirements

## Template

```markdown
## Non-Functional Requirements

### Performance

| Metric | Requirement | Measurement |
|--------|-------------|-------------|
| Page Load Time | < [X] seconds (first contentful paint) | Lighthouse / Web Vitals |
| API Response Time | < [X] ms (p95) | APM monitoring |
| Search Response | < [X] ms for [N] documents | Load testing |
| Concurrent Users | Support [N] concurrent users | Stress testing |
| File Upload | Max [X] MB, timeout [Y] seconds | Manual + automated |

### Security

- [ ] Authentication required for all non-public pages
- [ ] Authorization check on every API endpoint
- [ ] Input validation on all user inputs (client + server)
- [ ] XSS prevention (sanitize HTML output)
- [ ] CSRF protection on state-changing operations
- [ ] Rate limiting on authentication endpoints
- [ ] Sensitive data encrypted at rest and in transit
- [ ] Audit logging for sensitive operations

### Scalability

| Aspect | Current | Target (6 months) | Target (1 year) |
|--------|---------|--------------------|--------------------|
| Users | [N] | [N] | [N] |
| Documents | [N] | [N] | [N] |
| Storage | [N] GB | [N] GB | [N] GB |
| API Requests/day | [N] | [N] | [N] |

### Accessibility

- [ ] WCAG 2.1 Level AA compliance target
- [ ] Keyboard navigation support
- [ ] Screen reader compatible
- [ ] Color contrast ratio minimum 4.5:1
- [ ] Focus indicators visible
- [ ] Alt text for all images
- [ ] Form labels and error messages accessible

### Reliability & Availability

| Metric | Target |
|--------|--------|
| Uptime | [99.X]% |
| Recovery Time Objective (RTO) | [X] hours |
| Recovery Point Objective (RPO) | [X] hours |
| Backup Frequency | [Daily/Hourly] |

### Compatibility

| Platform | Minimum Version |
|----------|-----------------|
| Chrome | Latest 2 versions |
| Firefox | Latest 2 versions |
| Safari | Latest 2 versions |
| Edge | Latest 2 versions |
| Mobile (iOS Safari) | iOS 15+ |
| Mobile (Chrome Android) | Android 10+ |
| Screen Resolution | 320px minimum width |

### Compliance

- [ ] [Regulasi yang berlaku — GDPR, SOC2, dll]
- [ ] Data retention policy: [X] days/months
- [ ] Data deletion capability (right to be forgotten)
- [ ] Audit trail for compliance reporting
```

## Rules

1. Performance targets HARUS spesifik dan measurable — "fast" bukan requirement
2. Security requirements WAJIB ada di setiap PRD, tidak opsional
3. Accessibility bukan nice-to-have — definisikan target level (AA minimum)
4. Scalability targets based on projected growth, bukan asal tebak
5. Compatibility matrix harus realistis dengan user base
6. Compliance requirements harus di-review oleh legal/compliance team
7. Setiap NFR harus punya cara pengukuran yang jelas
