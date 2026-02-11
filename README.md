### Skills Agent Agung

## How to Use

Skills ini berfungsi sebagai "memory" pattern development yang bisa dipakai di Kiro chat.

### Cara Pakai

1. Ketik `#` di chat input, lalu pilih file skill yang relevan sebagai context
2. Contoh: `#skills/golang/SKILL.md` atau `#skills/argocd/SKILL.md`
3. Bisa juga refer ke reference spesifik, misal `#skills/argocd/references/templates.md`

### Contoh Prompt

| Prompt | Skill |
|--------|-------|
| "Buatkan entity baru untuk domain Payment" | `#skills/golang/SKILL.md` |
| "Buatkan repository MongoDB untuk Invoice" | `#skills/golang/SKILL.md` |
| "Buatkan deployment config ArgoCD untuk payment-service" | `#skills/argocd/SKILL.md` |
| "Tambahkan environment staging untuk invoice-tracking" | `#skills/argocd/SKILL.md` |

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
