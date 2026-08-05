### Skills Agent Agung

## How to Use

Skills ini berfungsi sebagai "memory" pattern development yang bisa dipakai di Kiro chat.

### Cara Pakai

1. Ketik `#` di chat input, lalu pilih file skill yang relevan sebagai context
2. Contoh: `#skills/golang/SKILL.md` atau `#skills/argocd/SKILL.md` atau `#skills/nextjs-core/SKILL.md`
3. Bisa juga refer ke reference spesifik, misal `#skills/argocd/references/templates.md`

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
| "Buatkan prioritization matrix dengan RICE" | `#skills/prd/SKILL.md` |
| "Buatkan ERD untuk fitur table of contents" | `#skills/erd/SKILL.md` |
| "Desain API contract untuk document export" | `#skills/erd/SKILL.md` |
| "Tulis ADR untuk pilihan search engine" | `#skills/erd/SKILL.md` |
| "Breakdown tasks untuk fitur comment system" | `#skills/erd/SKILL.md` |

### Windows

Makefile ini pakai Unix commands (`find`, `cp`, `rm`, `mkdir -p`). Di Windows, jalankan via:
- **Git Bash** (recommended) — sudah include semua Unix tools yang dibutuhkan
- **WSL** — jalankan langsung di WSL terminal

Native CMD/PowerShell tidak didukung.

### Auto-load (Opsional)

Kalau mau skill otomatis ke-load di setiap chat tanpa perlu `#` manual:
1. Copy file skill ke `.kiro/steering/`
2. Tambahkan `inclusion: auto` di frontmatter YAML

## Installed Skills

### `golang/` — Go Clean Architecture Pattern
Pattern development Go microservice dengan Clean Architecture, Echo v5, MongoDB, Redis, EventEmitter.

```
golang/
├── SKILL.md                          # Entry point — overview & critical rules
└── references/
    ├── project-structure.md          # Folder structure & naming conventions
    ├── entities.md                   # Domain objects (pure structs, json tags only)
    ├── drivers/                      # External adapters (per driver)
    │   ├── README.md                 # Index & overview semua drivers
    │   ├── mongo.md                  # MongoDB driver + BSON models
    │   ├── postgres.md               # PostgreSQL driver (GORM) + models
    │   ├── redis.md                  # Redis driver
    │   ├── nunggu.md                 # Job queue service
    │   ├── sap.md                    # SAP external service
    │   ├── service-client.md         # Microservice client pattern
    │   ├── authorizer.md             # Token verification
    │   ├── event-emitter.md          # In-process event emitter
    │   ├── cloudwatch.md             # AWS CloudWatch logging
    │   └── bootstrap.md              # Bootstrap pattern (main.go)
    ├── definitions.md                # AppContext, response, enums, workflow
    ├── repositories.md               # Data access layer (Find, FindById, Count, BulkUpsert)
    ├── usecases.md                   # Business logic layer
    ├── interfaces/                    # HTTP layer (folder, per file)
    │   ├── README.md                  # Index & overview
    │   ├── controllers.md             # HTTP controllers
    │   ├── routes.md                  # Route registration
    │   ├── middlewares.md             # Auth/RBAC/rate-limit middlewares
    │   ├── event.md                   # Event consumers
    │   └── launch.md                  # App launch/wiring
    └── helpers/                       # Shared helpers (folder, per file)
        ├── README.md                  # Index & overview
        ├── base-controller.md         # BaseController
        ├── validators.md              # Validators
        └── utils.md                   # Utils / serializers
```

### `argocd/` — ArgoCD Helm Deployment Pattern
Pattern deployment Kubernetes menggunakan ArgoCD + Helm + SOPS encrypted secrets.

```
argocd/
├── SKILL.md                          # Entry point — overview & critical rules
└── references/
    ├── repo-structure.md             # Repository structure & naming conventions
    ├── argocd-application.md         # ArgoCD Application manifest per environment
    ├── helm-chart.md                 # Chart.yaml, values per env, domain convention
    ├── templates.md                  # Deployment, Service, Ingress, HPA, Secret, ECR CronJob
    └── secrets.md                    # SOPS flow, .sops.yaml, Makefile, secrets
```

### Next.js — 3 skill (core + 2 track)
Pattern web modern Next.js 15+ App Router dengan shadcn/ui + Tailwind (single source of truth), full-stack MongoDB, dan desain production-grade anti-AI-slop. Dipisah jadi fondasi (`nextjs-core`) + track sesuai use case. `nextjs-core` selalu dipakai bersama minimal satu track.

#### `nextjs-core/` — Fondasi Bersama
```
nextjs-core/
├── SKILL.md                          # Entry point — decision guide, tech stack, critical rules
└── references/
    ├── design-principles.md          # 🔴 Hukum desain anti-AI-slop, token, tipografi, motion, a11y, DoD
    ├── setup.md                      # shadcn + Tailwind v4, globals.css token, dark mode (next-themes)
    ├── project-structure.md          # Struktur full-stack, naming, path alias, pembagian state
    ├── mongodb-mongoose.md           # Koneksi ter-cache, model, repository, Route Handler, transaksi
    ├── data-layer.md                 # TanStack Query, fetcher, response format, Redux global-only
    ├── services.md                   # Seam API transport-agnostic (client & server), portable ke Go
    ├── auth.md                       # Session jose, password bcrypt, requireAuth RBAC, middleware
    ├── security.md                   # Headers, CSP, cookie, CSRF, rate limit, XSS
    ├── middleware.md                 # Edge gate: auth redirect, defense-in-depth, CSP
    ├── environment.md                # Validasi env (Zod), server/client split, feature flags
    ├── auth-flows.md                 # Member Google (NextAuth) + admin credential/Turnstile + reset
    ├── file-upload.md                # Cloudflare R2 presigned upload
    ├── deployment.md                 # Vercel (GitHub Actions) + Docker Compose self-host
    ├── migration-guide.md            # Migrasi incremental dari Ant Design/JS ke shadcn/TS
    └── components-catalog.md         # Peta kebutuhan → komponen shadcn + ekosistem luar
```

#### `nextjs-customer-facing/` — Web Publik (landing, marketing, SEO)
```
nextjs-customer-facing/
├── SKILL.md                          # Entry point — RSC-first, kapan pakai, design mandate
└── references/
    ├── sections.md                   # Hero, Features, Testimonial, CTA, FAQ (anti-slop, token-based)
    ├── pages-seo.md                  # RSC, metadata, generateMetadata, OG, JSON-LD, sitemap/robots
    ├── animation.md                  # motion (FadeIn, Stagger, page transition), reduced-motion
    └── performance.md                # next/image, next/font, dynamic, Core Web Vitals
```

#### `nextjs-dashboard/` — Admin / Internal Tools (data-heavy)
```
nextjs-dashboard/
├── SKILL.md                          # Entry point — density kompak, RBAC, kapan pakai, design mandate
└── references/
    ├── data-table.md                 # DataTable TanStack Table, server-side pagination, states, row actions
    ├── forms.md                      # react-hook-form + Zod + shadcn Form, pola CRUD Dialog
    ├── app-shell.md                  # Layout terproteksi, Sidebar, header, RBAC nav, user menu
    └── charts.md                     # KPI StatCard, shadcn Chart (Recharts), warna token
```

### `prd/` — Product Requirement Document Pattern
Pattern penulisan PRD sebagai Senior Product Manager (10+ tahun pengalaman) dengan framework prioritisasi, user stories, dan acceptance criteria.

```
prd/
├── SKILL.md                          # Entry point — overview & critical rules
└── references/
    ├── prd-structure.md              # Template lengkap & naming convention
    ├── document-header.md            # Metadata, stakeholders, version history
    ├── problem-statement.md          # Problem definition, current/desired state
    ├── goals-metrics.md              # SMART goals, KPIs, success criteria
    ├── user-stories.md               # Personas, user stories, journey map
    ├── functional-requirements.md    # Feature breakdown, business rules, acceptance criteria
    ├── non-functional-requirements.md # Performance, security, accessibility, compliance
    ├── prioritization-scope.md       # RICE/MoSCoW framework, MVP scope, phase planning
    ├── ux-ui-guidelines.md           # Wireframes, interaction patterns, responsive
    ├── dependencies-risks.md         # Dependencies, risks, mitigations, assumptions
    └── timeline-milestones.md        # Phase overview, milestones, release plan
```

### `erd/` — Engineering Requirement Document Pattern
Pattern penulisan ERD sebagai Senior Engineering Manager / Lead Engineer (10+ tahun pengalaman) dengan system architecture, API design, database schema, dan ADR.

```
erd/
├── SKILL.md                          # Entry point — overview & critical rules
└── references/
    ├── erd-structure.md              # Template lengkap & naming convention
    ├── document-header.md            # Metadata, reviewers, revision history
    ├── technical-context.md          # Current architecture, constraints, assumptions
    ├── system-architecture.md        # Architecture diagram, component diagram, data flow
    ├── api-design.md                 # Endpoint definitions, request/response, error codes
    ├── database-design.md            # Data models, ERD diagram, indexes, migrations
    ├── technical-decisions.md        # ADR format, alternatives, consequences
    ├── security-auth.md              # Auth flow, authorization matrix, security checklist
    ├── performance-scalability.md    # Performance targets, caching, scaling plan
    ├── testing-strategy.md           # Test pyramid, test plan, coverage targets
    ├── deployment-rollout.md          # Deployment strategy, feature flags, rollback plan
    ├── task-breakdown.md              # Tasks, estimation, risk register, sprint assignment
    ├── observability-logging.md       # Structured logging, tracing, metrics, dashboards, alerting
    ├── error-handling.md              # Error classification, retry, circuit breaker, degradation
    └── async-patterns.md              # Event schema, webhook/queue contracts, SSE/WebSocket
```

## Tech Stack per Skill

### Golang Skill
- **Framework**: Echo v5
- **Database**: MongoDB, PostgreSQL (GORM)
- **Cache**: Redis
- **Events**: EventEmitter
- **External**: SAP, Nunggu (Job Queue), Microservice Clients
- **Architecture**: Clean Architecture (Entity → Repository → Usecase → Controller)

### ArgoCD Skill
- **Orchestration**: Kubernetes
- **GitOps**: ArgoCD
- **Packaging**: Helm Charts
- **Secrets**: SOPS (encrypted)
- **Registry**: AWS ECR

### Next.js Skills (`nextjs-core` + `nextjs-customer-facing` + `nextjs-dashboard`)
- **Framework**: Next.js 15+ (App Router) · React 19
- **Language**: TypeScript (strict)
- **UI**: shadcn/ui (Radix + Tailwind) — Tailwind v4 sebagai **single source of truth** (tanpa Ant Design)
- **Theme**: Light & Dark via `next-themes` + CSS variable (mandatory)
- **Database (full-stack)**: MongoDB + Mongoose
- **Auth**: jose (JWT) + bcryptjs, httpOnly cookie, RBAC
- **State**: TanStack Query (server) + Redux Toolkit (global) + react-hook-form/Zod (form)
- **Animation**: motion (Framer Motion)
- **Design**: production-grade, modern, **anti-AI-slop** (lihat `design-principles.md`)
- **Struktur**: `nextjs-core` (fondasi) + `nextjs-customer-facing` (web publik) + `nextjs-dashboard` (admin)

### PRD Skill
- **Role**: Senior Product Manager (10+ tahun)
- **Frameworks**: RICE, MoSCoW, SMART Goals, Kano Model
- **Format**: User Stories (Gherkin), Acceptance Criteria, Journey Map
- **Scope**: Problem statement, goals, requirements, prioritization, timeline

### ERD Skill
- **Role**: Senior Engineering Manager / Lead Engineer (10+ tahun)
- **Scope**: System architecture, API contracts, database schema, ADR, security & authz, performance & scalability, testing, deployment & rollout, observability & logging, error handling, async/event contracts, task breakdown
- **Format**: Architecture, sequence, dan ERD diagrams (Mermaid)
- **Methodology**: ADR, test pyramid, deployment strategy, observability-before-deploy
