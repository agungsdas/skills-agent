# Technical Decisions (ADR)

## Template — Architecture Decision Record

```markdown
## Technical Decisions

### ADR-001: [Judul Keputusan]

**Date:** YYYY-MM-DD
**Status:** Proposed / Accepted / Deprecated / Superseded by ADR-NNN
**Deciders:** [Nama-nama yang terlibat dalam keputusan]

#### Context

[Jelaskan situasi dan masalah yang membutuhkan keputusan.
Apa yang sedang terjadi? Apa constraints-nya?]

#### Decision

[Jelaskan keputusan yang diambil. Be specific dan clear.]

**We will [keputusan].**

#### Alternatives Considered

| Alternative | Pros | Cons | Why Not |
|-------------|------|------|---------|
| [Alt 1] | [Kelebihan] | [Kekurangan] | [Alasan tidak dipilih] |
| [Alt 2] | [Kelebihan] | [Kekurangan] | [Alasan tidak dipilih] |
| [Alt 3 — chosen] | [Kelebihan] | [Kekurangan] | ✅ Dipilih |

#### Consequences

**Positive:**
- [Benefit 1]
- [Benefit 2]

**Negative:**
- [Trade-off 1]
- [Trade-off 2]

**Risks:**
- [Risk 1 — dan mitigasinya]

---

### ADR-002: [Judul Keputusan Berikutnya]
(repeat structure)
```

## Contoh ADR

```markdown
### ADR-001: Menggunakan MongoDB untuk Document Storage

**Date:** 2026-02-28
**Status:** Accepted
**Deciders:** Engineering Lead, Senior Backend Engineer

#### Context

Aplikasi WRKSPC membutuhkan storage untuk dokumen rich text (Tiptap/ProseMirror format)
yang berupa nested JSON structure. Dokumen bisa sangat bervariasi dalam structure
dan sering berubah schema-nya seiring penambahan block types baru.

#### Decision

**We will menggunakan MongoDB sebagai primary database untuk document storage.**

#### Alternatives Considered

| Alternative | Pros | Cons | Why Not |
|-------------|------|------|---------|
| PostgreSQL + JSONB | Strong consistency, mature, JSONB indexing | Schema migration overhead, less natural for nested docs | Overhead untuk flexible schema |
| MongoDB | Flexible schema, natural JSON, good for nested docs | No JOIN, eventual consistency | ✅ Dipilih |
| DynamoDB | Serverless, auto-scaling | Vendor lock-in, complex querying, expensive at scale | Vendor lock-in |

#### Consequences

**Positive:**
- Schema flexibility — bisa tambah block types tanpa migration
- Natural fit untuk JSON document storage
- Good developer experience dengan Mongoose ODM

**Negative:**
- No native JOIN — harus denormalize atau multiple queries
- Eventual consistency — harus handle di application level
- Less mature tooling dibanding PostgreSQL ecosystem
```

## Kapan Butuh ADR

| Situasi | ADR Required |
|---------|-------------|
| Pilih database / storage | ✅ Yes |
| Pilih framework / library major | ✅ Yes |
| Architecture pattern (monolith vs microservice) | ✅ Yes |
| Authentication strategy | ✅ Yes |
| Caching strategy | ✅ Yes |
| API design pattern (REST vs GraphQL) | ✅ Yes |
| Minor library choice (lodash vs ramda) | ❌ No |
| Code style / formatting | ❌ No |
| Bug fix approach | ❌ No (unless architectural) |

## Rules

1. ADR format WAJIB: Context, Decision, Alternatives, Consequences
2. Minimal 2 alternatives harus di-evaluate — jangan hanya 1 option
3. "Why not" untuk setiap alternative yang tidak dipilih harus jelas
4. Consequences harus jujur — include negative consequences dan trade-offs
5. Status harus di-update jika keputusan berubah (Deprecated / Superseded)
6. ADR adalah immutable record — jangan edit ADR lama, buat ADR baru yang supersede
7. Setiap ADR harus bisa dibaca independently tanpa context dokumen lain
