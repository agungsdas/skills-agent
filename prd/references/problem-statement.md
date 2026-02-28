# Problem Statement & Context

## Template

```markdown
## Problem Statement & Context

### Background

[Jelaskan konteks bisnis dan produk. Apa yang sedang terjadi di market/organisasi
yang membuat fitur ini relevan. Berikan data pendukung jika ada.]

### Problem Definition

**Problem:**
[Satu paragraf yang jelas mendefinisikan masalah utama. Fokus pada user pain point,
bukan solusi teknis.]

**Who is affected:**
[Siapa yang terdampak — user segment, internal team, atau stakeholder tertentu.]

**Impact:**
[Apa dampak dari masalah ini — revenue loss, user churn, productivity loss, dll.
Gunakan data kuantitatif jika tersedia.]

### Current State (As-Is)

[Jelaskan bagaimana user saat ini menyelesaikan masalah ini (workaround).
Sertakan screenshot, flow diagram, atau data usage jika relevan.]

1. User harus [langkah manual 1]
2. Kemudian [langkah manual 2]
3. Hasilnya [outcome yang tidak ideal]

**Pain Points:**
- [Pain point 1 — dengan data jika ada]
- [Pain point 2]
- [Pain point 3]

### Desired State (To-Be)

[Jelaskan state ideal setelah fitur ini diimplementasikan.
Fokus pada outcome, bukan implementation detail.]

### Urgency & Business Justification

| Factor | Detail |
|--------|--------|
| Revenue Impact | [Estimasi impact ke revenue] |
| User Impact | [Jumlah user yang terdampak] |
| Competitive Pressure | [Apakah competitor sudah punya fitur ini] |
| Strategic Alignment | [Alignment dengan company OKR/strategy] |
| Cost of Delay | [Apa yang terjadi jika tidak dikerjakan sekarang] |
```

## Rules

1. Problem statement HARUS dari perspektif user, bukan dari perspektif teknis
2. Sertakan data kuantitatif — "30% user mengeluh" lebih kuat dari "banyak user mengeluh"
3. Current state harus cukup detail agar engineering team paham konteksnya
4. Jangan langsung lompat ke solusi — section ini murni tentang masalah
5. Business justification harus menjawab "mengapa sekarang?" bukan hanya "mengapa?"
6. Jika ada user research data (interview, survey, analytics), referensikan di sini

## Anti-patterns

- ❌ "Kita butuh fitur X" — ini solusi, bukan problem statement
- ❌ "User mau bisa export PDF" — ini feature request, bukan problem
- ✅ "User kesulitan sharing dokumen ke stakeholder eksternal yang tidak punya akses ke platform. Saat ini mereka harus copy-paste manual ke Google Docs, yang menyebabkan formatting rusak dan version control hilang."

## Tips

- Gunakan "5 Whys" technique untuk menggali root cause
- Interview minimal 5 user sebelum menulis problem statement
- Validasi problem statement dengan data analytics jika tersedia
- Problem statement yang baik membuat semua orang di ruangan setuju "ya, ini memang masalah"
