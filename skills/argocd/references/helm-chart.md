# Helm Chart & Values

## Chart.yaml

```yaml
apiVersion: v2
name: <app-name>
description: A Helm chart for <app-name>
type: application
version: 0.1.0
appVersion: "1.16.0"
```

Tidak ada dependencies. Chart sederhana, semua template di-manage langsung.

## Values Structure

Setiap environment punya file `values.<env>.yaml` dengan struktur yang sama:

```yaml
replicaCountHttpPrivate: 1                    # jumlah replica (dev: 1, prod: 3+)
environment: dev                               # dev | staging | production
image: <account-id>.dkr.ecr.ap-southeast-3.amazonaws.com/<app-name>:latest

ingressHttpPrivate:
    domain: <subdomain>.<app-name>.mitrakeluarga.com
    path: /
    tlsSecret: <tls-secret-name>

autoscalingHttpPrivate:
    enabled: false                             # true jika mau pakai HPA
    minReplicas: 1
    maxReplicas: 5
    targetCPUUtilizationPercentage: 75
    targetMemoryUtilizationPercentage: 75

requests:
    cpu: "100m"
    memory: "100Mi"
limits:
    cpu: "400m"
    memory: "400Mi"

registryECR:
    enabled: true
    secretName: ecr-creds
    region: "ap-southeast-3"
    accountId: "<aws-account-id>"
```

## Perbedaan Values Antar Environment

| Field | Dev | Production |
|-------|-----|------------|
| `replicaCountHttpPrivate` | `1` | `3` atau lebih |
| `environment` | `dev` | `production` |
| `image` | ECR dev account | ECR prod account |
| `ingressHttpPrivate.domain` | `dev-<app>.mitrakeluarga.com` | `<app>.mitrakeluarga.com` |
| `requests/limits` | Lebih kecil | Lebih besar |
| `registryECR.accountId` | Dev AWS account ID | Prod AWS account ID |

## Domain Convention

| Environment | Pattern |
|-------------|---------|
| dev | `dev-<app-name>.mitrakeluarga.com` |
| staging | `staging-<app-name>.mitrakeluarga.com` |
| production | `<app-name>.mitrakeluarga.com` |

## Aturan Penting

- `tlsSecret` selalu `<tls-secret-name>`
- ECR region selalu `ap-southeast-3` (Jakarta)
- `autoscalingHttpPrivate.enabled` default `false`, enable manual jika perlu
- Image tag default `latest` (CI/CD yang handle tag update)
