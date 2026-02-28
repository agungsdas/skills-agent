# Technical Context & Background

## Template

```markdown
## Technical Context & Background

### Current Architecture

[Jelaskan arsitektur saat ini yang relevan dengan fitur ini.
Sertakan diagram jika membantu. Fokus pada komponen yang akan berubah.]

```
[Diagram arsitektur current state — ASCII, Mermaid, atau link ke diagram tool]
```

### Technical Problem

[Jelaskan masalah dari perspektif teknis. Berbeda dengan PRD yang fokus pada user problem,
di sini fokus pada technical limitations, bottlenecks, atau gaps.]

**Current Limitations:**
- [Limitation 1 — technical detail]
- [Limitation 2]
- [Limitation 3]

**Technical Debt (jika relevan):**
- [Tech debt yang harus di-address sebagai bagian dari fitur ini]

### Constraints

| Constraint | Detail | Impact |
|------------|--------|--------|
| [Backward Compatibility] | [Harus compatible dengan API v1] | [Tidak bisa breaking change] |
| [Database] | [MongoDB — no JOIN, eventual consistency] | [Denormalize data] |
| [Performance] | [Response time < 200ms p95] | [Caching required] |
| [Infrastructure] | [Single region deployment] | [No geo-replication] |
| [Timeline] | [Harus selesai dalam 2 sprint] | [Scope terbatas] |

### Assumptions

| Assumption | Validated | Impact if Wrong |
|------------|-----------|-----------------|
| [Assumption 1] | Yes / No | [Impact] |
| [Assumption 2] | Yes / No | [Impact] |

### Scope (Technical)

**In Scope:**
- [Technical change 1]
- [Technical change 2]

**Out of Scope:**
- [Technical change yang TIDAK dikerjakan — dan alasannya]
```

## Rules

1. Current architecture harus cukup detail agar engineer baru bisa paham konteksnya
2. Technical problem berbeda dari user problem — fokus pada WHY secara teknis
3. Constraints harus explicit — jangan assume semua orang tahu limitasi system
4. Assumptions yang belum validated = risk — flag dan validate sebelum implementasi
5. Technical scope harus align dengan PRD scope — jika berbeda, dokumentasikan alasannya
6. Sertakan diagram — "a picture is worth a thousand words" berlaku di engineering docs

## Diagram Tools yang Direkomendasikan

- Mermaid (inline di markdown)
- draw.io / diagrams.net
- Excalidraw
- PlantUML
- ASCII art (untuk yang simple)
