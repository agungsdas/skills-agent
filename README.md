### Skills Agent Agung

## How to Use

Skills ini berfungsi sebagai "memory" pattern development yang bisa dipakai di Kiro chat.

### Cara Pakai

1. Ketik `#` di chat input, lalu pilih file skill yang relevan sebagai context
2. Contoh: `#skills/golang/SKILL.md` atau `#skills/argocd/SKILL.md` atau `#skills/nextjs/SKILL.md`
3. Bisa juga refer ke reference spesifik, misal `#skills/argocd/references/templates.md`

### Contoh Prompt

| Prompt | Skill |
|--------|-------|
| "Buatkan entity baru untuk domain Payment" | `#skills/golang/SKILL.md` |
| "Buatkan repository MongoDB untuk Invoice" | `#skills/golang/SKILL.md` |
| "Buatkan deployment config ArgoCD untuk payment-service" | `#skills/argocd/SKILL.md` |
| "Tambahkan environment staging untuk invoice-tracking" | `#skills/argocd/SKILL.md` |
| "Buatkan dashboard page dengan Ant Design dan dark mode" | `#skills/nextjs/SKILL.md` |
| "Setup authentication middleware dengan JWT" | `#skills/nextjs/SKILL.md` |
| "Optimize performance untuk image loading" | `#skills/nextjs/SKILL.md` |

### Auto-load (Opsional)

Kalau mau skill otomatis ke-load di setiap chat tanpa perlu `#` manual:
1. Copy file skill ke `.kiro/steering/`
2. Tambahkan `inclusion: auto` di frontmatter YAML

## Installed Skills

### `golang/` — Go Clean Architecture Pattern
Pattern development Go microservice dengan Clean Architecture, GoFiber, MongoDB, Redis, EventEmitter.

```
golang/
├── SKILL.md                          # Entry point — overview & critical rules
└── references/
    ├── project-structure.md          # Folder structure & naming conventions
    ├── entities.md                   # Domain objects (pure structs)
    ├── mongo-models.md               # BSON models, indexes, ToEntity()
    ├── drivers.md                    # External adapters (Mongo, Redis, Auth, CloudWatch)
    ├── definitions.md                # AppContext, response, enums, workflow
    ├── repositories.md               # Data access layer (Find, FindById, Count, BulkUpsert)
    ├── usecases.md                   # Business logic layer
    ├── interfaces.md                 # HTTP controllers, routes, middlewares, events
    └── helpers.md                    # BaseController, validators, serializers, utils
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

### `nextjs/` — Next.js 14+ Web Development Pattern
Pattern development aplikasi web modern dengan Next.js 14+ App Router, Ant Design, JavaScript, dan mandatory light/dark mode support.

```
nextjs/
├── SKILL.md                          # Entry point — overview & critical rules
└── references/
    ├── project-structure.md          # Folder structure dengan src/ (App Router, components, services)
    ├── pages.md                      # Server/Client Components, dynamic routes, data fetching
    ├── layouts.md                    # Root layout, nested layouts, route groups
    ├── components.md                 # Ant Design components, forms, custom components
    ├── api-routes.md                 # REST API endpoints, middleware, error handling
    ├── services.md                   # API service layer per backend service
    ├── theme.md                      # Light/Dark mode (mandatory), ThemeProvider, styling
    ├── hooks-utils.md                # Custom hooks, utilities, helpers
    ├── middleware.md                 # Authentication, authorization, RBAC, rate limiting
    ├── security.md                   # Security headers, CSRF, XSS, input validation
    ├── monitoring.md                 # Sentry, Winston, metrics, health checks
    ├── deployment.md                 # Vercel, Docker, CI/CD, production setup
    ├── performance.md                # Image/font optimization, caching, bundle analysis
    └── environment.md                # Environment variables, configuration, feature flags
```

## Tech Stack per Skill

### Golang Skill
- **Framework**: GoFiber
- **Database**: MongoDB
- **Cache**: Redis
- **Events**: EventEmitter
- **Architecture**: Clean Architecture (Entity → Repository → Usecase → Controller)

### ArgoCD Skill
- **Orchestration**: Kubernetes
- **GitOps**: ArgoCD
- **Packaging**: Helm Charts
- **Secrets**: SOPS (encrypted)
- **Registry**: AWS ECR

### Next.js Skill
- **Framework**: Next.js 14+ (App Router)
- **Language**: JavaScript
- **UI Library**: Ant Design
- **Theme**: Light & Dark mode (mandatory)
- **State**: React Context API / Zustand
- **Deployment**: Vercel / Docker
- **Monitoring**: Sentry, Winston
- **Security**: JWT, CSRF, XSS protection
