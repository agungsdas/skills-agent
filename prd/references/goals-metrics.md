# Goals & Success Metrics

## Template

```markdown
## Goals & Success Metrics

### Objectives

| # | Objective | Type | Target |
|---|-----------|------|--------|
| O1 | [Objective 1 — SMART format] | Primary | [Target kuantitatif] |
| O2 | [Objective 2] | Primary | [Target kuantitatif] |
| O3 | [Objective 3] | Secondary | [Target kuantitatif] |

### Key Results / KPIs

| KPI | Baseline (Current) | Target | Measurement Method | Timeline |
|-----|---------------------|--------|--------------------|----------|
| [Metric 1] | [Current value] | [Target value] | [Bagaimana diukur] | [Kapan diukur] |
| [Metric 2] | [Current value] | [Target value] | [Bagaimana diukur] | [Kapan diukur] |
| [Metric 3] | [Current value] | [Target value] | [Bagaimana diukur] | [Kapan diukur] |

### Success Criteria

Fitur dianggap sukses jika dalam [timeframe] setelah launch:

1. ✅ [Criteria 1 — measurable]
2. ✅ [Criteria 2 — measurable]
3. ✅ [Criteria 3 — measurable]

### Non-Goals (Explicitly Out of Scope)

- ❌ [Hal yang BUKAN tujuan fitur ini]
- ❌ [Hal yang sering diasumsikan tapi bukan scope]
```

## SMART Goals Framework

Setiap objective HARUS memenuhi kriteria SMART:

| Criteria | Penjelasan | Contoh Baik | Contoh Buruk |
|----------|------------|-------------|--------------|
| Specific | Jelas dan spesifik | "Reduce document creation time" | "Improve UX" |
| Measurable | Bisa diukur dengan angka | "dari 5 menit ke 2 menit" | "lebih cepat" |
| Achievable | Realistis dengan resource yang ada | "20% improvement" | "1000% improvement" |
| Relevant | Sesuai dengan business goal | "Increase user retention" | "Add cool animation" |
| Time-bound | Ada deadline yang jelas | "dalam 3 bulan setelah launch" | "someday" |

## Contoh KPI per Kategori

### Engagement Metrics
- DAU/MAU ratio
- Feature adoption rate (% user yang pakai fitur baru)
- Session duration
- Actions per session

### Efficiency Metrics
- Task completion time
- Error rate
- Number of steps to complete task
- Support ticket reduction

### Business Metrics
- Conversion rate
- Revenue per user
- Churn rate reduction
- NPS score improvement

### Technical Metrics
- Page load time
- API response time
- Error rate (5xx)
- Uptime percentage

## Rules

1. Minimal 2 KPIs per fitur — 1 engagement + 1 business/efficiency
2. Setiap KPI HARUS punya baseline (current state) — tanpa baseline, target tidak bermakna
3. Target harus realistis — based on benchmark atau historical data
4. Measurement method harus jelas — tool apa yang dipakai, query apa yang dijalankan
5. Timeline pengukuran: minimal 2 checkpoint (1 week, 1 month post-launch)
6. Non-goals sama pentingnya dengan goals — prevent scope creep
