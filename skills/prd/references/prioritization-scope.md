# Prioritization & Scope

## Template

```markdown
## Prioritization & Scope

### MVP Scope (Phase 1)

**Goal:** [Apa yang ingin dicapai di MVP — minimum viable product]
**Timeline:** [Sprint/Quarter]

| Feature | Priority | Effort | Impact | RICE Score |
|---------|----------|--------|--------|------------|
| [Feature 1] | Must Have | [S/M/L] | High | [Score] |
| [Feature 2] | Must Have | [S/M/L] | High | [Score] |
| [Feature 3] | Should Have | [S/M/L] | Medium | [Score] |

### Phase 2 (Post-MVP)

| Feature | Priority | Effort | Impact | Target |
|---------|----------|--------|--------|--------|
| [Feature 4] | Should Have | [S/M/L] | Medium | [Quarter] |
| [Feature 5] | Could Have | [S/M/L] | Low | [Quarter] |

### Out of Scope

| Item | Reason | Revisit When |
|------|--------|--------------|
| [Item 1] | [Alasan tidak dikerjakan] | [Kondisi untuk revisit] |
| [Item 2] | [Alasan] | [Kondisi] |

### Prioritization Matrix

[Gunakan salah satu framework di bawah]
```

## RICE Framework

```
RICE Score = (Reach × Impact × Confidence) / Effort
```

| Factor | Scale | Penjelasan |
|--------|-------|------------|
| Reach | Jumlah user/quarter | Berapa user yang terdampak dalam 1 quarter |
| Impact | 0.25 / 0.5 / 1 / 2 / 3 | Minimal / Low / Medium / High / Massive |
| Confidence | 50% / 80% / 100% | Low / Medium / High — seberapa yakin dengan estimasi |
| Effort | Person-months | Berapa person-month effort yang dibutuhkan |

### Contoh RICE

| Feature | Reach | Impact | Confidence | Effort | RICE |
|---------|-------|--------|------------|--------|------|
| Bulk share | 500 | 2 (High) | 80% | 1 | 800 |
| PDF export | 300 | 1 (Medium) | 100% | 2 | 150 |
| TOC editor | 200 | 1 (Medium) | 80% | 0.5 | 320 |

## MoSCoW Framework

| Category | Arti | Guideline |
|----------|------|-----------|
| Must Have | Wajib | Tanpa ini, release tidak viable |
| Should Have | Penting | Significant value, tapi bisa workaround |
| Could Have | Nice to have | Hanya jika ada waktu |
| Won't Have | Excluded | Explicitly tidak dikerjakan kali ini |

### Aturan MoSCoW
- Must Have: maksimal 60% dari total effort
- Should Have: ~20% dari total effort
- Could Have: ~20% dari total effort
- Won't Have: documented tapi 0% effort

## Scope Management Rules

1. MVP harus bisa deliver value ke user dalam 1 release cycle
2. Out of scope HARUS didokumentasikan dengan alasan — bukan diabaikan
3. "Revisit when" membantu stakeholder tahu kapan item bisa diangkat lagi
4. Jika scope creep terjadi, re-evaluate dengan RICE/MoSCoW — jangan asal tambah
5. Phase 2 items harus cukup detail untuk estimasi kasar, tapi tidak perlu full spec
6. Setiap phase harus punya goal yang jelas dan independent — bisa di-release sendiri
