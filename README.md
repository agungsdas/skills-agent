### Skills Agent Agung

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
