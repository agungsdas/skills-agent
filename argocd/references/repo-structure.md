# Repository Structure

## Manifest Repo (`kubernetes-manifest`)

```
kubernetes-manifest/
├── argocd/<app-name>/                    # ArgoCD Application manifests
│   ├── application-dev.yaml
│   ├── application-staging.yaml
│   └── application-production.yaml
├── apps/<app-name>/                      # Helm charts per app
│   ├── Chart.yaml                        # Helm chart metadata
│   ├── .sops.yaml                        # SOPS encryption rules (GPG keys per env)
│   ├── .helmignore
│   ├── Makefile                          # Secret generation & push commands
│   ├── values.dev.yaml                   # Helm values — dev
│   ├── values.staging.yaml               # Helm values — staging
│   ├── values.production.yaml            # Helm values — production
│   ├── secrets.dev.yaml                  # SOPS-encrypted secrets — dev
│   ├── secrets.staging.yaml              # SOPS-encrypted secrets — staging
│   ├── secrets.production.yaml           # SOPS-encrypted secrets — production
│   └── templates/
│       ├── deployment-http-private.yaml  # Deployment resource
│       ├── service-http-private.yaml     # Service resource (ClusterIP)
│       ├── ingress-http-private.yaml     # Ingress resource (nginx)
│       ├── hpa-http-private.yaml         # HorizontalPodAutoscaler
│       ├── secret.yaml                   # K8s Secret dari .Values.env
│       └── ecr-cron.yaml                # ECR credential rotation CronJob + RBAC
├── core/                                 # Cluster-wide resources
└── tools/                                # SSL, kubernetes install scripts
```

## Secrets Repo (`secrets`)

```
secrets/
└── apps/<app-name>/
    ├── .decrypted-secrets.dev.yaml        # Plaintext secrets — dev
    ├── .decrypted-secrets.staging.yaml    # Plaintext secrets — staging
    └── .decrypted-secrets.production.yaml # Plaintext secrets — production
```

## Konvensi Penamaan

| Item | Pattern | Contoh |
|------|---------|--------|
| ArgoCD app name | `<app-name>-<env>` | `invoice-tracking-dev` |
| Namespace | `<app-name>-<env>` | `invoice-tracking-production` |
| Helm chart name | `<app-name>` | `invoice-tracking` |
| Values file | `values.<env>.yaml` | `values.dev.yaml` |
| Secrets file (encrypted) | `secrets.<env>.yaml` | `secrets.production.yaml` |
| Secrets file (plaintext) | `.decrypted-secrets.<env>.yaml` | `.decrypted-secrets.dev.yaml` |
| Branch per env | `dev`, `staging`, `production` | — |

## Membuat App Baru

Ketika membuat deployment untuk service baru, buat folder di kedua repo:

1. `kubernetes-manifest/argocd/<app-name>/` — 3 application YAML files
2. `kubernetes-manifest/apps/<app-name>/` — Helm chart + templates + values + secrets
3. `secrets/apps/<app-name>/` — 3 plaintext secret files
