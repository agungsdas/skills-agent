# Skills & Steering — Kiro Agent

Koleksi skills (pattern development) dan steering (global rules) untuk Kiro chat.

## Repo Structure

```
.
├── README.md
├── Makefile              # Linux/macOS install
├── install.ps1           # Windows PowerShell install
├── skills/               # All skill folders
│   ├── ai-agent/         # AI Agent (Go Gateway + Python Engine)
│   ├── argocd/           # ArgoCD Helm Deployment
│   ├── erd/              # Engineering Requirement Document
│   ├── golang/           # Go Clean Architecture
│   ├── nextjs-core/      # Next.js Fondasi (wajib bareng track)
│   ├── nextjs-customer-facing/  # Web publik (landing, marketing, SEO)
│   ├── nextjs-dashboard/ # Admin / internal tools (data table, form, RBAC)
│   └── prd/              # Product Requirement Document
└── steering/             # Global rules (auto-loaded setiap session)
    ├── bahasa.md
    ├── diagram-rules.md
    ├── persona.md
    ├── production-quality.md
    └── skill-router.md
```

## Install

### Linux / macOS

```bash
make link       # Copy skills + steering ke ~/.kiro/
make unlink     # Hapus semua
make status     # Cek status
```

### Windows (PowerShell)

```powershell
.\install.ps1              # Install (default: link)
.\install.ps1 -Action link
.\install.ps1 -Action unlink
.\install.ps1 -Action status
```

> Kalau kena execution policy error:
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

Alternatif: **Git Bash** atau **WSL** — bisa jalankan `make link` langsung.

## Cara Pakai

1. Ketik `#` di chat input, pilih file skill yang relevan
2. Contoh: `#skills/golang/SKILL.md` atau `#skills/nextjs-core/SKILL.md`
3. Reference spesifik: `#skills/argocd/references/templates.md`

### Contoh Prompt

| Prompt | Skill |
|--------|-------|
| "Buatkan entity baru untuk domain Payment" | `#skills/golang/SKILL.md` |
| "Buatkan repository MongoDB untuk Invoice" | `#skills/golang/SKILL.md` |
| "Buatkan deployment config ArgoCD untuk payment-service" | `#skills/argocd/SKILL.md` |
| "Tambahkan environment staging untuk invoice-tracking" | `#skills/argocd/SKILL.md` |
| "Buatkan landing page modern + dark mode" | `#skills/nextjs-core/SKILL.md` + `#skills/nextjs-customer-facing/SKILL.md` |
| "Buatkan dashboard admin dengan data table + RBAC" | `#skills/nextjs-core/SKILL.md` + `#skills/nextjs-dashboard/SKILL.md` |
| "Setup auth + MongoDB full-stack di Next.js" | `#skills/nextjs-core/SKILL.md` |
| "Optimize Core Web Vitals halaman marketing" | `#skills/nextjs-core/SKILL.md` + `#skills/nextjs-customer-facing/SKILL.md` |
| "Buatkan PRD untuk fitur document export PDF" | `#skills/prd/SKILL.md` |
| "Tulis user stories untuk fitur bulk share" | `#skills/prd/SKILL.md` |
| "Buatkan ERD untuk fitur table of contents" | `#skills/erd/SKILL.md` |
| "Desain API contract untuk document export" | `#skills/erd/SKILL.md` |
| "Breakdown tasks untuk fitur comment system" | `#skills/erd/SKILL.md` |

### Auto-load (Opsional)

Kalau mau skill otomatis ke-load tanpa `#` manual:
1. Copy file skill ke `.kiro/steering/`
2. Tambahkan `inclusion: auto` di frontmatter YAML

---

## Skills

### `ai-agent/` — AI Agent Development

Pattern development AI agent untuk contact center / customer service. Arsitektur 2-service: Go Gateway (Echo, Clean Arch) + Python Engine (FastAPI, LangGraph).

### `golang/` — Go Clean Architecture

Pattern Go microservice dengan Clean Architecture, Echo v5, MongoDB, PostgreSQL (GORM), Redis, EventEmitter.

```
skills/golang/
├── SKILL.md
└── references/
    ├── project-structure.md
    ├── entities.md
    ├── definitions.md
    ├── repositories.md
    ├── usecases.md
    ├── drivers/
    │   ├── README.md
    │   ├── mongo.md
    │   ├── postgres.md
    │   ├── redis.md
    │   ├── nunggu.md
    │   ├── sap.md
    │   ├── service-client.md
    │   ├── authorizer.md
    │   ├── event-emitter.md
    │   ├── cloudwatch.md
    │   └── bootstrap.md
    ├── interfaces/
    │   ├── README.md
    │   ├── controllers.md
    │   ├── routes.md
    │   ├── middlewares.md
    │   ├── event.md
    │   └── launch.md
    └── helpers/
        ├── README.md
        ├── base-controller.md
        ├── validators.md
        └── utils.md
```

### `argocd/` — ArgoCD Helm Deployment

Pattern deployment Kubernetes menggunakan ArgoCD + Helm + SOPS encrypted secrets.

```
skills/argocd/
├── SKILL.md
└── references/
    ├── repo-structure.md
    ├── argocd-application.md
    ├── helm-chart.md
    ├── templates.md
    └── secrets.md
```

### Next.js — 3 skill (core + 2 track)

Pattern web modern Next.js 15+ App Router dengan shadcn/ui + Tailwind, full-stack MongoDB, desain production-grade anti-AI-slop. `nextjs-core` selalu dipakai bersama minimal satu track.

#### `nextjs-core/` — Fondasi Bersama

```
skills/nextjs-core/
├── SKILL.md
└── references/
    ├── design-principles.md
    ├── setup.md
    ├── project-structure.md
    ├── model-design.md
    ├── api-routes.md
    ├── mongodb-mongoose.md
    ├── data-layer.md
    ├── services.md
    ├── auth.md
    ├── security.md
    ├── middleware.md
    ├── environment.md
    ├── auth-flows.md
    ├── file-upload.md
    ├── deployment.md
    ├── migration-guide.md
    └── components-catalog.md
```

#### `nextjs-customer-facing/` — Web Publik

```
skills/nextjs-customer-facing/
├── SKILL.md
└── references/
    ├── sections.md
    ├── pages-seo.md
    ├── animation.md
    └── performance.md
```

#### `nextjs-dashboard/` — Admin / Internal Tools

```
skills/nextjs-dashboard/
├── SKILL.md
└── references/
    ├── data-table.md
    ├── forms.md
    ├── app-shell.md
    └── charts.md
```

### `prd/` — Product Requirement Document

Pattern PRD sebagai Senior Product Manager: RICE/MoSCoW, user stories, acceptance criteria.

```
skills/prd/
├── SKILL.md
└── references/
    ├── prd-structure.md
    ├── document-header.md
    ├── problem-statement.md
    ├── goals-metrics.md
    ├── user-stories.md
    ├── functional-requirements.md
    ├── non-functional-requirements.md
    ├── prioritization-scope.md
    ├── ux-ui-guidelines.md
    ├── dependencies-risks.md
    └── timeline-milestones.md
```

### `erd/` — Engineering Requirement Document

Pattern ERD sebagai Senior Engineering Manager: system architecture, API design, database schema, ADR.

```
skills/erd/
├── SKILL.md
└── references/
    ├── erd-structure.md
    ├── document-header.md
    ├── technical-context.md
    ├── system-architecture.md
    ├── api-design.md
    ├── database-design.md
    ├── technical-decisions.md
    ├── security-auth.md
    ├── performance-scalability.md
    ├── testing-strategy.md
    ├── deployment-rollout.md
    ├── task-breakdown.md
    ├── observability-logging.md
    ├── error-handling.md
    └── async-patterns.md
```

---

## Steering (Global Rules)

File di `steering/` otomatis di-load setiap session. Tidak perlu `#` manual.

| File | Fungsi |
|------|--------|
| `bahasa.md` | Komunikasi Bahasa Indonesia, code English |
| `diagram-rules.md` | Wajib Mermaid, dilarang ASCII art |
| `persona.md` | Senior Engineer persona — execute with confidence |
| `production-quality.md` | Zero bug, zero assumption, production-ready |
| `skill-router.md` | Auto-activate skill berdasarkan task context |

---

## Tech Stack per Skill

| Skill | Stack |
|-------|-------|
| `golang` | Echo v5, MongoDB, PostgreSQL (GORM), Redis, EventEmitter, Clean Architecture |
| `argocd` | Kubernetes, ArgoCD, Helm, SOPS, AWS ECR |
| `nextjs-core` | Next.js 15+, React 19, TypeScript, shadcn/ui, Tailwind v4, MongoDB, jose, TanStack Query |
| `nextjs-customer-facing` | RSC-first, SEO, motion, Core Web Vitals |
| `nextjs-dashboard` | TanStack Table, react-hook-form, Zod, RBAC, Charts |
| `ai-agent` | Go Gateway (Echo) + Python Engine (FastAPI, LangGraph) |
| `prd` | RICE, MoSCoW, SMART Goals, Gherkin, Journey Map |
| `erd` | Architecture (Mermaid), ADR, Test Pyramid, Deployment Strategy |
