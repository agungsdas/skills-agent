---
inclusion: auto
---

# Skill Router

Kamu punya akses ke skills berikut. Gunakan skill yang sesuai dengan konteks task.

## Available Skills

| Skill | Kapan Digunakan |
|-------|-----------------|
| `golang-clean-architecture` | Go backend: endpoint, usecase, repository, model, driver, middleware, migration |
| `nextjs` | Next.js frontend: page, component, API route, hook, layout, middleware |
| `argocd` | ArgoCD: deployment, Helm chart, GitOps, Kubernetes manifest |
| `erd` | System design: ERD, architecture, database schema, technical document |
| `prd` | Product requirement: PRD, user story, acceptance criteria, scope |

## Rules

1. Kalau task melibatkan Go backend → activate `golang-clean-architecture`
2. Kalau task melibatkan Next.js frontend → activate `nextjs`
3. Kalau task melibatkan deployment/infra → activate `argocd`
4. Kalau task melibatkan system design/architecture → activate `erd`
5. Kalau task melibatkan product requirement → activate `prd`
6. Kalau task melibatkan lebih dari 1 domain → activate semua yang relevan
7. Selalu baca SKILL.md dan references yang relevan sebelum mulai kerja
