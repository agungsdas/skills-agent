---
inclusion: always
---

# Skill Router

Kamu punya akses ke skills berikut. Gunakan skill yang sesuai dengan konteks task.

## Available Skills

| Skill | Kapan Digunakan |
|-------|-----------------|
| `golang-clean-architecture` | Go backend: endpoint, usecase, repository, model, driver, middleware, migration |
| `nextjs-core` | Fondasi web Next.js (WAJIB bareng track): setup shadcn/Tailwind SSOT, design system anti-slop, MongoDB/Mongoose, auth, security, data layer |
| `nextjs-customer-facing` | Web publik: landing, marketing, pricing, blog, halaman SEO-critical |
| `nextjs-dashboard` | Admin/internal tools: data table, form CRUD, sidebar shell, chart, RBAC (di balik login) |
| `argocd` | ArgoCD: deployment, Helm chart, GitOps, Kubernetes manifest |
| `erd` | System design: ERD, architecture, database schema, technical document |
| `prd` | Product requirement: PRD, user story, acceptance criteria, scope |

## Rules

1. Kalau task melibatkan Go backend → activate `golang-clean-architecture`
2. Kalau task melibatkan web Next.js → activate `nextjs-core` (WAJIB) **plus** track yang sesuai:
   - Landing / marketing / SEO / halaman publik → `nextjs-customer-facing`
   - Admin / dashboard / CRUD / data-heavy → `nextjs-dashboard`
   - Satu produk punya keduanya → activate kedua track (dua-duanya di atas `nextjs-core`)
3. Kalau task melibatkan deployment/infra → activate `argocd`
4. Kalau task melibatkan system design/architecture → activate `erd`
5. Kalau task melibatkan product requirement → activate `prd`
6. Kalau task melibatkan lebih dari 1 domain → activate semua yang relevan
7. `nextjs-core` TIDAK berdiri sendiri — selalu diaktifkan bersama minimal satu track Next.js
8. Selalu baca SKILL.md dan references yang relevan sebelum mulai kerja
