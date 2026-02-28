# Functional Requirements

## Template

```markdown
## Functional Requirements

### Feature 1: [Nama Feature]

**Description:** [Deskripsi singkat apa yang dilakukan feature ini]

**User Flow:**
1. User [action 1]
2. System [response 1]
3. User [action 2]
4. System [response 2]

**Business Rules:**
- BR-001: [Rule 1 — kondisi dan aksi yang harus terjadi]
- BR-002: [Rule 2]
- BR-003: [Rule 3]

**Acceptance Criteria:**

| ID | Criteria | Type |
|----|----------|------|
| AC-001 | [Given/When/Then] | Happy Path |
| AC-002 | [Given/When/Then] | Edge Case |
| AC-003 | [Given/When/Then] | Error Case |

**UI/Interaction Notes:**
- [Catatan untuk design/frontend — behavior, layout, feedback]

**Error Handling:**

| Error Scenario | User Message | System Action |
|----------------|--------------|---------------|
| [Scenario 1] | [Message yang ditampilkan] | [Log, retry, fallback, dll] |
| [Scenario 2] | [Message] | [Action] |

---

### Feature 2: [Nama Feature]
(repeat structure)
```

## Business Rules Format

Business rules harus spesifik dan testable:

```markdown
**BR-001: Document Permission Inheritance**
- Ketika document dibuat di workspace, author otomatis mendapat permission "owner"
- Workspace admin otomatis mendapat permission "contributor" ke semua document di workspace
- Permission TIDAK diwariskan ke sub-folder secara otomatis

**BR-002: Slug Uniqueness**
- Slug harus unik dalam scope workspace
- Jika slug sudah ada, auto-append angka increment (-1, -2, -3)
- Slug di-generate dari title, lowercase, strip special chars, replace space dengan dash
```

## Acceptance Criteria — Gherkin Format

```gherkin
AC-001: Successful document export
Given user has "owner" or "contributor" permission on the document
And the document has content
When user clicks "Export as PDF"
Then system generates a PDF file with the document content
And the PDF preserves heading hierarchy and formatting
And the file is downloaded to user's device

AC-002: Export without permission
Given user has "viewer" permission on the document
When user opens the document page
Then the "Export as PDF" button is not visible

AC-003: Export empty document
Given user has "owner" permission on the document
And the document has no content (empty)
When user clicks "Export as PDF"
Then system shows warning "Document is empty. Nothing to export."
And no file is generated
```

## Rules

1. Setiap feature HARUS punya: description, user flow, business rules, acceptance criteria, error handling
2. Business rules harus testable — jika tidak bisa di-test, terlalu vague
3. Acceptance criteria WAJIB cover: happy path, edge cases, error cases
4. Error handling harus dari perspektif user (message) DAN system (action)
5. UI notes cukup behavior/interaction, bukan pixel-perfect spec (itu di design doc)
6. Jangan campur functional requirement dengan technical implementation detail
7. Setiap requirement harus traceable ke user story (link US-ID)

## Checklist per Feature

- [ ] Description jelas dan singkat
- [ ] User flow step-by-step
- [ ] Business rules terdefinisi
- [ ] Acceptance criteria (happy + edge + error)
- [ ] Error handling scenarios
- [ ] UI/interaction notes (jika relevan)
- [ ] Linked ke user story
- [ ] Reviewed oleh QA
