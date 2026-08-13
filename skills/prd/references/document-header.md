# Document Header & Metadata

## Template

```markdown
# [Nama Fitur] — Product Requirement Document

| Field | Value |
|-------|-------|
| **Document ID** | PRD-YYYY-NNN |
| **Title** | [Nama fitur lengkap] |
| **Author** | [Nama PM] |
| **Status** | Draft / In Review / Approved / In Progress / Completed |
| **Created** | YYYY-MM-DD |
| **Last Updated** | YYYY-MM-DD |
| **Target Release** | [Quarter / Sprint / Date] |
| **Priority** | P0 (Critical) / P1 (High) / P2 (Medium) / P3 (Low) |

### Stakeholders

| Name | Role | Approval Status |
|------|------|-----------------|
| [Nama] | Product Manager | ✅ Approved |
| [Nama] | Engineering Lead | ⏳ Pending |
| [Nama] | Design Lead | ⏳ Pending |
| [Nama] | QA Lead | — |
| [Nama] | Business Owner | ⏳ Pending |

### Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | YYYY-MM-DD | [Nama] | Initial draft |
| 1.1 | YYYY-MM-DD | [Nama] | Updated scope based on review feedback |
| 2.0 | YYYY-MM-DD | [Nama] | Major revision — MVP scope redefined |

### Related Documents

| Document | Link |
|----------|------|
| ERD / Technical Spec | [link] |
| Design Spec / Figma | [link] |
| API Documentation | [link] |
| User Research Report | [link] |
```

## Rules

1. Document ID harus unik dan mengikuti format `PRD-YYYY-NNN`
2. Status HARUS selalu up-to-date — jangan biarkan "Draft" kalau sudah approved
3. Semua stakeholders yang punya decision power HARUS tercantum
4. Approval status di-update setiap kali ada review
5. Version history WAJIB di-update setiap ada perubahan signifikan
6. Related documents di-link untuk cross-reference — jangan biarkan kosong jika ada
7. Priority menggunakan P0-P3 scale yang konsisten di seluruh organisasi
