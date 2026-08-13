# Document Header & Metadata

## Template

```markdown
# [Nama Fitur] — Engineering Requirement Document

| Field | Value |
|-------|-------|
| **Document ID** | ERD-YYYY-NNN |
| **Title** | [Nama fitur — technical title] |
| **Author** | [Nama Engineer Lead] |
| **Status** | Draft / In Review / Approved / In Progress / Completed |
| **Created** | YYYY-MM-DD |
| **Last Updated** | YYYY-MM-DD |
| **PRD Reference** | PRD-YYYY-NNN |
| **Target Sprint** | Sprint [N] / [Quarter] |

### Reviewers

| Name | Role | Review Status |
|------|------|---------------|
| [Nama] | Engineering Manager | ✅ Approved / ⏳ Pending |
| [Nama] | Senior Engineer | ⏳ Pending |
| [Nama] | DevOps/Infra | ⏳ Pending |
| [Nama] | Security Engineer | — (optional) |
| [Nama] | QA Lead | ⏳ Pending |

### Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | YYYY-MM-DD | [Nama] | Initial draft |
| 1.1 | YYYY-MM-DD | [Nama] | Updated API contracts after review |
| 2.0 | YYYY-MM-DD | [Nama] | Major revision — architecture change |

### Related Documents

| Document | Link |
|----------|------|
| PRD | [link ke PRD] |
| API Documentation | [link] |
| Architecture Diagram | [link] |
| Database Schema | [link] |
| Runbook | [link] |

### Glossary

| Term | Definition |
|------|------------|
| [Term 1] | [Definisi teknis] |
| [Term 2] | [Definisi teknis] |
```

## Rules

1. Document ID format: `ERD-YYYY-NNN` — harus unik dan sequential
2. PRD Reference WAJIB ada — ERD tanpa PRD = implementasi tanpa requirement
3. Reviewers minimal: 1 senior engineer + 1 peer engineer
4. Revision history WAJIB di-update setiap ada perubahan signifikan
5. Glossary untuk istilah domain-specific yang mungkin tidak familiar bagi semua engineer
6. Status harus selalu up-to-date
7. Target sprint harus realistis dan sudah di-align dengan PM
