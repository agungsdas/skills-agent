# ERD Structure Overview

## Template Lengkap

```
# [Nama Fitur] — Engineering Requirement Document

## 1. Document Header
- Title, Author, Reviewers, Status, Date, Revision History

## 2. Technical Context & Background
- Current Architecture
- Problem (Technical Perspective)
- Constraints & Limitations

## 3. System Architecture
- High-Level Architecture Diagram
- Component Diagram
- Service Boundaries
- Data Flow

## 4. API Design & Contracts
- Endpoint Definitions
- Request/Response Schemas
- Error Codes
- Authentication & Authorization
- API Versioning

## 5. Database Design & Schema
- Data Models / ERD Diagram
- Collection/Table Definitions
- Indexes
- Migrations
- Data Integrity Rules

## 6. Technical Decisions (ADR)
- Decision Records
- Alternatives Considered
- Rationale

## 7. Security & Authorization
- Authentication Flow
- Authorization Model
- Data Encryption
- Security Considerations

## 8. Performance & Scalability
- Performance Targets
- Caching Strategy
- Scaling Plan
- Load Estimation

## 9. Testing Strategy
- Test Plan
- Test Types & Coverage
- Test Environment

## 10. Deployment & Rollout Plan
- Deployment Strategy
- Feature Flags
- Rollback Plan
- Monitoring & Alerting

## 11. Task Breakdown & Estimation
- Engineering Tasks
- Dependencies
- Story Points / Effort
- Sprint Assignment
```

## Kapan Pakai Full Template vs Lite Template

| Skala Perubahan | Template | Sections Wajib |
|-----------------|----------|----------------|
| Large (new service / major feature) | Full | Semua sections |
| Medium (new domain / significant change) | Standard | 1-6, 8, 10, 11 |
| Small (API endpoint / minor feature) | Lite | 1, 2, 4, 5, 11 |
| Bug Fix / Hotfix | Minimal | 1, 2, 11 |

## Status Dokumen

| Status | Arti |
|--------|------|
| `Draft` | Masih ditulis, belum siap review |
| `In Review` | Sudah dikirim ke engineering team untuk review |
| `Approved` | Disetujui, siap untuk implementasi |
| `In Progress` | Sedang diimplementasikan |
| `Completed` | Implementasi selesai dan deployed |
| `Deprecated` | Tidak relevan lagi / superseded |

## Naming Convention

```
ERD-[YYYY]-[NNN]-[nama-fitur-singkat].md

Contoh:
ERD-2026-001-workspace-bulk-share.md
ERD-2026-002-document-export-pdf.md
ERD-2026-003-table-of-contents-editor.md
```

## Relationship dengan PRD

```
PRD (What & Why) → ERD (How)
PRD-2026-001 → ERD-2026-001
```

ERD selalu mereferensikan PRD sebagai source of truth untuk requirements.
ERD fokus pada HOW (technical implementation), bukan WHAT (product requirements).
