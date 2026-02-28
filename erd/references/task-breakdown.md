# Task Breakdown & Estimation

## Template

```markdown
## Task Breakdown & Estimation

### Epic Overview

| Epic | Description | Total Effort | Sprint |
|------|-------------|-------------|--------|
| [Epic 1] | [Description] | [X] story points | Sprint [N] |
| [Epic 2] | [Description] | [X] story points | Sprint [N] |

### Task Breakdown

#### Epic 1: [Nama Epic]

| Task ID | Task | Type | Effort | Dependency | Assignee | Status |
|---------|------|------|--------|------------|----------|--------|
| T-001 | [Setup database schema + indexes] | Backend | [S/M/L] | — | [Nama] | To Do |
| T-002 | [Create API endpoint POST /resource] | Backend | [S/M/L] | T-001 | [Nama] | To Do |
| T-003 | [Create API endpoint GET /resource] | Backend | [S/M/L] | T-001 | [Nama] | To Do |
| T-004 | [Create UI component — list view] | Frontend | [S/M/L] | T-003 | [Nama] | To Do |
| T-005 | [Create UI component — form] | Frontend | [S/M/L] | T-002 | [Nama] | To Do |
| T-006 | [Integration testing] | QA | [S/M/L] | T-002, T-003 | [Nama] | To Do |
| T-007 | [E2E testing] | QA | [S/M/L] | T-004, T-005 | [Nama] | To Do |

### Dependency Graph

```
T-001 (DB Schema)
  ├── T-002 (POST API) ──── T-005 (Form UI)
  ├── T-003 (GET API) ───── T-004 (List UI)
  └── T-006 (Integration Test) ── T-007 (E2E Test)
```

### Effort Estimation

| Size | Story Points | Duration | Description |
|------|-------------|----------|-------------|
| S (Small) | 1-2 | < 1 day | Simple, well-understood, no unknowns |
| M (Medium) | 3-5 | 1-2 days | Some complexity, minor unknowns |
| L (Large) | 8-13 | 3-5 days | Complex, multiple components, some unknowns |
| XL (Extra Large) | 13+ | > 5 days | ⚠️ HARUS dipecah jadi tasks yang lebih kecil |

### Sprint Assignment

| Sprint | Tasks | Total Points | Focus |
|--------|-------|-------------|-------|
| Sprint [N] | T-001, T-002, T-003 | [X] pts | Backend foundation |
| Sprint [N+1] | T-004, T-005, T-006 | [X] pts | Frontend + integration |
| Sprint [N+2] | T-007 + bug fixes | [X] pts | Testing + polish |

### Definition of Done (per Task)

- [ ] Code implemented and self-reviewed
- [ ] Unit tests written and passing
- [ ] Code review approved by peer
- [ ] Integration test passing (if API)
- [ ] Documentation updated (if applicable)
- [ ] No new lint warnings or errors
- [ ] Tested on staging environment
```

## Task Types

| Type | Color/Label | Description |
|------|-------------|-------------|
| Backend | 🔵 | API, database, business logic |
| Frontend | 🟢 | UI components, pages, styling |
| DevOps | 🟠 | Infrastructure, CI/CD, deployment |
| QA | 🟣 | Testing, test automation |
| Documentation | ⚪ | Technical docs, API docs, runbook |

## Rules

1. Setiap task HARUS bisa diselesaikan dalam 1-2 hari kerja — jika lebih, pecah
2. XL tasks (13+ points) WAJIB dipecah — tidak boleh ada task > 5 hari
3. Dependencies harus explicit — jangan assume parallel execution tanpa check
4. Setiap task harus punya Definition of Done yang jelas
5. QA tasks harus di-plan bersamaan dengan development tasks, bukan setelahnya
6. Buffer 20% untuk unexpected issues — jangan plan 100% capacity
7. Sprint assignment harus realistis dengan team velocity
8. Task ID harus traceable ke PRD user stories (US-001 → T-001, T-002)
9. Assignee bisa "TBD" di awal, tapi harus di-assign sebelum sprint start
10. Dependency graph membantu identify critical path — focus pada unblocking
