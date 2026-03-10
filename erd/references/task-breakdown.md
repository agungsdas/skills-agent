# Task Breakdown & Estimation

## Estimation Config

| Parameter | Value | Description |
|-----------|-------|-------------|
| FOCUSED_HOURS_PER_DAY | 5 | Jam produktif coding per hari (dari total 8 jam kerja). Sisanya untuk meeting, review, research, context switching. Adjust sesuai kondisi tim. |

> **Note:** Semua kalkulasi "Calendar Duration" di bawah dihitung berdasarkan FOCUSED_HOURS_PER_DAY.
> Jika berubah (misal jadi 6 jam), update value di atas — hour estimate tetap, calendar duration yang berubah.

## Template

```markdown
## Task Breakdown & Estimation

### Estimation Config

| Parameter | Value |
|-----------|-------|
| FOCUSED_HOURS_PER_DAY | 5 |

### Epic Overview

| Epic | Description | Total SP | Total Hours | Sprint |
|------|-------------|----------|-------------|--------|
| [Epic 1] | [Description] | [X] SP | [X] jam | Sprint [N] |
| [Epic 2] | [Description] | [X] SP | [X] jam | Sprint [N] |

### Effort Estimation

| Size | Story Points | Hour Estimate (focused) | Calendar Duration* | Description |
|------|-------------|------------------------|-------------------|-------------|
| XS | 1 | 1-2 jam | < 0.5 hari | Quick fix, config change, simple util |
| S | 2 | 2-4 jam | 0.5-1 hari | Single function, simple endpoint, minor UI |
| M | 3-5 | 4-8 jam | 1-1.5 hari | Full endpoint + validation, component + integration |
| L | 8 | 8-12 jam | 2-2.5 hari | Multi-component, complex logic, cross-service |
| XL | 13+ | 12+ jam | 3+ hari | ⚠️ HARUS dipecah jadi tasks yang lebih kecil |

*Calendar Duration = Hour Estimate ÷ FOCUSED_HOURS_PER_DAY

**Rules:**
- Hour estimate = actual focused coding time (fixed)
- Calendar duration = derived dari config (dynamic)
- XL tasks WAJIB dipecah — tidak boleh ada task > 2.5 hari calendar
- Engineer plan daily: "Gue punya [FOCUSED_HOURS_PER_DAY] jam hari ini, bisa ambil task apa?"

### Task Breakdown

#### Epic 1: [Nama Epic]

| Task ID | Task | Type | Size | SP | Hours | Dependency | Assignee | Status |
|---------|------|------|------|----|-------|------------|----------|--------|
| T-001 | [Setup database schema + indexes] | Backend | S | 2 | 2-4 | — | [Nama] | To Do |
| T-002 | [Create API endpoint POST /resource] | Backend | M | 3 | 4-6 | T-001 | [Nama] | To Do |
| T-003 | [Create API endpoint GET /resource] | Backend | M | 3 | 4-6 | T-001 | [Nama] | To Do |
| T-004 | [Create UI component — list view] | Frontend | M | 5 | 6-8 | T-003 | [Nama] | To Do |
| T-005 | [Create UI component — form] | Frontend | M | 5 | 6-8 | T-002 | [Nama] | To Do |
| T-006 | [Integration testing] | QA | S | 2 | 2-4 | T-002, T-003 | [Nama] | To Do |
| T-007 | [E2E testing] | QA | M | 3 | 4-6 | T-004, T-005 | [Nama] | To Do |

### Task Details

Setiap task HARUS punya deskripsi yang cukup jelas agar engineer bisa langsung kerja tanpa tanya-tanya.
Deskripsi bukan mini-ERD — cukup jadi "pointer" ke section ERD yang relevan.

#### T-001: Setup database schema + indexes

**Type:** Backend | **Size:** S (2-4 jam) | **SP:** 2
**Dependency:** —
**Assignee:** TBD

**What:**
Buat collection `[collection_name]` dengan schema sesuai section Database Design (ref: ERD section 5).

**Acceptance Criteria:**
- [ ] Collection created dengan semua fields sesuai schema
- [ ] Index `refId_1` (unique) created
- [ ] Index `[compound_index]` created
- [ ] Migration script ready dan tested di local

**Technical Notes:**
- Pakai UUID v7 untuk refId
- Soft delete (deletedAt) sebagai default
- Refer ke: ERD section 5 — Database Design

**Blocked By:** —
**Blocks:** T-002, T-003

---

#### T-002: Create API endpoint POST /[resource]

**Type:** Backend | **Size:** M (4-6 jam) | **SP:** 3
**Dependency:** T-001
**Assignee:** TBD

**What:**
Implementasi endpoint POST untuk create [resource] sesuai API contract di ERD section 4.

**Acceptance Criteria:**
- [ ] Endpoint accessible dan return correct response format
- [ ] Request validation sesuai schema (required fields, types, limits)
- [ ] Error responses sesuai standard error format
- [ ] Auth middleware applied
- [ ] Unit test untuk validation logic

**Technical Notes:**
- Refer ke: ERD section 4 — API Design & Contracts
- Refer ke: ERD section 7 — Security (auth requirement)

**Blocked By:** T-001
**Blocks:** T-005, T-006

---

(repeat pattern untuk setiap task)

### Task Description Format

| Komponen | Wajib? | Fungsi |
|----------|--------|--------|
| What | ✅ Ya | 1-2 kalimat, apa yang dikerjakan |
| Acceptance Criteria | ✅ Ya | Checklist kapan task dianggap "done" |
| Technical Notes | Optional | Hint teknis, referensi ke section ERD lain |
| Blocked By / Blocks | ✅ Ya | Dependency explicit |

**Prinsip:** Deskripsi = navigasi, bukan dokumentasi ulang. Detail teknis sudah ada di section ERD masing-masing.

### Dependency Graph

```
T-001 (DB Schema)
  ├── T-002 (POST API) ──── T-005 (Form UI)
  ├── T-003 (GET API) ───── T-004 (List UI)
  └── T-006 (Integration Test) ── T-007 (E2E Test)
```

### Risk Register

| Risk ID | Epic | Risk | Probability | Impact | Mitigation | Owner |
|---------|------|------|-------------|--------|------------|-------|
| R-001 | [Epic 1] | [Third-party API belum stable] | High | High | [Buat mock service, define fallback] | [Nama] |
| R-002 | [Epic 1] | [Data migration bisa lama untuk large dataset] | Medium | Medium | [Run migration off-peak, test dengan production-like data] | [Nama] |
| R-003 | [Epic 2] | [New library belum proven di production] | Low | High | [Spike task 1 hari untuk evaluate, prepare fallback library] | [Nama] |

**Risk Level Matrix:**

| | Low Impact | Medium Impact | High Impact |
|---|-----------|---------------|-------------|
| **High Probability** | Medium | High | Critical |
| **Medium Probability** | Low | Medium | High |
| **Low Probability** | Low | Low | Medium |

**Rules:**
- Critical risk = harus di-mitigate SEBELUM sprint start
- High risk = harus punya mitigation plan yang jelas
- Medium risk = monitor, mitigate jika terjadi
- Low risk = accept, no action needed

### Sprint Assignment

| Sprint | Tasks | Total SP | Total Hours | Focus |
|--------|-------|----------|-------------|-------|
| Sprint [N] | T-001, T-002, T-003 | [X] SP | [X] jam | Backend foundation |
| Sprint [N+1] | T-004, T-005, T-006 | [X] SP | [X] jam | Frontend + integration |
| Sprint [N+2] | T-007 + bug fixes | [X] SP | [X] jam | Testing + polish |

**Capacity Planning:**
- Team size: [N] engineers
- Capacity per sprint: [N] engineers × FOCUSED_HOURS_PER_DAY × [sprint days] = [total] jam
- Buffer: 20% untuk unexpected issues
- Available capacity: [total] × 0.8 = [available] jam

### Definition of Done (per Task)

- [ ] Code implemented dan self-reviewed
- [ ] Unit tests written dan passing
- [ ] Code review approved by peer
- [ ] Integration test passing (jika API)
- [ ] Documentation updated (jika applicable)
- [ ] No new lint warnings atau errors
- [ ] Tested di staging environment
```

## Task Types

| Type | Label | Description |
|------|-------|-------------|
| Backend | 🔵 | API, database, business logic |
| Frontend | 🟢 | UI components, pages, styling |
| DevOps | 🟠 | Infrastructure, CI/CD, deployment |
| QA | 🟣 | Testing, test automation |
| Documentation | ⚪ | Technical docs, API docs, runbook |

## Rules

1. Setiap task HARUS bisa diselesaikan dalam max 2.5 hari calendar — jika lebih, pecah
2. XL tasks (13+ SP / 12+ jam) WAJIB dipecah — tidak boleh ada task > 2.5 hari
3. Dependencies harus explicit — jangan assume parallel execution tanpa check
4. Setiap task HARUS punya: What, Acceptance Criteria, dan Dependencies
5. Acceptance Criteria = definition of "done" — tanpa ini, task ambigu
6. Task description = pointer ke ERD sections, bukan duplikasi detail teknis
7. QA tasks harus di-plan bersamaan dengan development tasks, bukan setelahnya
8. Buffer 20% untuk unexpected issues — jangan plan 100% capacity
9. Sprint assignment harus realistis dengan team velocity dan FOCUSED_HOURS_PER_DAY
10. Task ID harus traceable ke PRD user stories (US-001 → T-001, T-002)
11. Assignee bisa "TBD" di awal, tapi harus di-assign sebelum sprint start
12. Dependency graph membantu identify critical path — focus pada unblocking
13. Risk register per epic — identify dan mitigate sebelum sprint start
14. Hour estimate = fixed (actual effort), calendar duration = dynamic (derived dari config)
