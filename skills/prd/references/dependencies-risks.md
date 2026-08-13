# Dependencies & Risks

## Template

```markdown
## Dependencies & Risks

### Technical Dependencies

| Dependency | Type | Owner | Status | Impact if Delayed |
|------------|------|-------|--------|-------------------|
| [API/Service X ready] | Internal | [Team] | ✅ Ready / ⏳ In Progress / ❌ Blocked | [Impact] |
| [Library/SDK update] | External | [Vendor] | [Status] | [Impact] |
| [Database migration] | Internal | [Team] | [Status] | [Impact] |

### External Dependencies

| Dependency | Provider | SLA/Timeline | Fallback Plan |
|------------|----------|--------------|---------------|
| [Third-party API] | [Provider] | [SLA] | [Apa yang dilakukan jika down] |
| [Design assets] | [Design team] | [Timeline] | [Placeholder/fallback] |

### Risks

| ID | Risk | Probability | Impact | Mitigation | Owner |
|----|------|-------------|--------|------------|-------|
| R-001 | [Risk description] | High/Med/Low | High/Med/Low | [Mitigation plan] | [Nama] |
| R-002 | [Risk description] | [Prob] | [Impact] | [Mitigation] | [Nama] |
| R-003 | [Risk description] | [Prob] | [Impact] | [Mitigation] | [Nama] |

### Risk Matrix

|  | Low Impact | Medium Impact | High Impact |
|--|-----------|---------------|-------------|
| **High Prob** | Monitor | Mitigate | Prevent |
| **Med Prob** | Accept | Monitor | Mitigate |
| **Low Prob** | Accept | Accept | Monitor |

### Assumptions

| ID | Assumption | Validated | Impact if Wrong |
|----|------------|-----------|-----------------|
| A-001 | [Assumption 1] | Yes / No | [Impact] |
| A-002 | [Assumption 2] | Yes / No | [Impact] |

### Constraints

- [Constraint 1 — technical, budget, timeline, regulatory]
- [Constraint 2]
- [Constraint 3]
```

## Common Risk Categories

### Technical Risks
- Performance degradation under load
- Third-party API breaking changes
- Data migration failures
- Security vulnerabilities

### Product Risks
- Low user adoption
- Feature doesn't solve the actual problem
- Scope creep delays delivery
- Competitor launches similar feature first

### Organizational Risks
- Key team member unavailable
- Cross-team dependency delays
- Budget constraints
- Shifting priorities mid-development

## Rules

1. Setiap risk HARUS punya mitigation plan — "accept" juga valid tapi harus explicit
2. Dependencies harus punya owner dan status yang di-update regularly
3. Assumptions yang belum validated = risk — track dan validate ASAP
4. Risk matrix membantu prioritize — focus mitigation pada High Prob × High Impact
5. External dependencies HARUS punya fallback plan
6. Review risks di setiap sprint planning — risks berubah seiring waktu
