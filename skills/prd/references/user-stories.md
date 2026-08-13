# User Stories & Personas

## Template — Persona

```markdown
### Persona: [Nama Persona]

| Attribute | Detail |
|-----------|--------|
| Role | [Job title / role] |
| Goals | [Apa yang ingin dicapai] |
| Pain Points | [Frustrasi utama] |
| Tech Savviness | Low / Medium / High |
| Usage Frequency | Daily / Weekly / Monthly |

**Bio:**
[1-2 kalimat deskripsi persona — background, motivasi, dan konteks penggunaan produk.]
```

## Template — User Story

```markdown
### User Stories

| ID | Persona | User Story | Priority | Acceptance Criteria |
|----|---------|------------|----------|---------------------|
| US-001 | [Persona] | As a [persona], I want [action], so that [benefit] | Must Have | AC-001 |
| US-002 | [Persona] | As a [persona], I want [action], so that [benefit] | Should Have | AC-002 |
| US-003 | [Persona] | As a [persona], I want [action], so that [benefit] | Could Have | AC-003 |

---

#### US-001: [Judul singkat]

**Story:** As a [persona], I want [action], so that [benefit].

**Acceptance Criteria:**

```gherkin
AC-001-1:
Given [precondition]
When [action]
Then [expected result]

AC-001-2:
Given [precondition]
When [action]
Then [expected result]
```

**Edge Cases:**
- [Edge case 1 — apa yang terjadi jika...]
- [Edge case 2]

**Notes:**
- [Catatan tambahan untuk engineering/design]
```

## Template — User Journey Map

```markdown
### User Journey: [Nama Journey]

| Step | Action | Touchpoint | Emotion | Pain Point | Opportunity |
|------|--------|------------|---------|------------|-------------|
| 1 | [Apa yang user lakukan] | [Di mana] | 😊/😐/😤 | [Jika ada] | [Improvement] |
| 2 | [Action] | [Touchpoint] | [Emotion] | [Pain] | [Opportunity] |
| 3 | [Action] | [Touchpoint] | [Emotion] | [Pain] | [Opportunity] |
```

## User Story Format Rules

1. Format WAJIB: "As a [persona], I want [action], so that [benefit]"
2. [persona] = role spesifik, bukan "user" generik
3. [action] = satu aksi spesifik, bukan multiple actions
4. [benefit] = business/user value, bukan technical outcome
5. Setiap story HARUS punya minimal 1 acceptance criteria
6. Acceptance criteria pakai Gherkin format (Given/When/Then)
7. Edge cases didokumentasikan terpisah dari happy path

## Priority Labels (MoSCoW)

| Label | Arti | Guideline |
|-------|------|-----------|
| Must Have | Wajib ada di release ini | Tanpa ini, fitur tidak bisa dipakai |
| Should Have | Penting tapi bisa ditunda | Fitur tetap usable tanpa ini |
| Could Have | Nice to have | Hanya jika ada waktu/resource |
| Won't Have | Tidak dikerjakan di release ini | Explicitly excluded |

## Contoh User Story yang Baik vs Buruk

### ❌ Buruk
- "As a user, I want to export" — terlalu vague, benefit tidak ada
- "As a user, I want the system to be fast" — bukan actionable story
- "As a developer, I want to refactor the code" — ini technical task, bukan user story

### ✅ Baik
- "As a workspace admin, I want to bulk share documents to all workspace members, so that I don't have to share one by one when onboarding new team members"
- "As a document author, I want to export my document as PDF, so that I can share it with external stakeholders who don't have platform access"
- "As a team member, I want to see a table of contents in long documents, so that I can quickly navigate to the section I need"

## Tips

- Satu user story = satu testable increment
- Jika story terlalu besar, pecah jadi sub-stories
- Acceptance criteria harus bisa di-automate sebagai test case
- Libatkan QA saat menulis acceptance criteria
- User journey map membantu menemukan gap yang terlewat di individual stories
