# PRD Structure Overview

## Template Lengkap

```
# [Nama Fitur] — Product Requirement Document

## 1. Document Header
- Title, Author, Stakeholders, Status, Date, Version

## 2. Problem Statement & Context
- Background
- Problem Definition
- Current State (As-Is)
- Impact & Urgency

## 3. Goals & Success Metrics
- Objectives (SMART)
- Key Results / KPIs
- Success Criteria

## 4. User Stories & Personas
- Target Personas
- User Stories (As a... I want... So that...)
- User Journey Map

## 5. Functional Requirements
- Feature Breakdown
- Acceptance Criteria per Feature
- Business Rules
- Edge Cases & Error Handling

## 6. Non-Functional Requirements
- Performance
- Security
- Scalability
- Accessibility
- Compliance

## 7. Prioritization & Scope
- MVP Scope (Phase 1)
- Full Scope (Phase 2+)
- Out of Scope
- Prioritization Matrix (RICE / MoSCoW)

## 8. UX/UI Guidelines
- Wireframe References
- User Flow Diagrams
- Design Principles
- Interaction Patterns

## 9. Dependencies & Risks
- Technical Dependencies
- External Dependencies
- Risks & Mitigations
- Assumptions

## 10. Timeline & Milestones
- Phase Breakdown
- Milestones & Deliverables
- Release Plan
```

## Kapan Pakai Full Template vs Lite Template

| Skala Fitur | Template | Sections Wajib |
|-------------|----------|----------------|
| Large (> 2 sprint) | Full | Semua sections |
| Medium (1-2 sprint) | Standard | 1-7, 9, 10 |
| Small (< 1 sprint) | Lite | 1-5, 7 |
| Bug Fix / Improvement | Minimal | 1, 2, 5 |

## Status Dokumen

| Status | Arti |
|--------|------|
| `Draft` | Masih ditulis, belum siap review |
| `In Review` | Sudah dikirim ke stakeholders untuk review |
| `Approved` | Disetujui, siap untuk engineering |
| `In Progress` | Sedang diimplementasikan |
| `Completed` | Fitur sudah live |
| `Deprecated` | Tidak relevan lagi / dibatalkan |

## Naming Convention

```
PRD-[YYYY]-[NNN]-[nama-fitur-singkat].md

Contoh:
PRD-2026-001-workspace-bulk-share.md
PRD-2026-002-document-export-pdf.md
PRD-2026-003-table-of-contents-editor.md
```
