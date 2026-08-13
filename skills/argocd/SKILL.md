---
name: argocd-helm-deployment
description: >
  ArgoCD deployment configuration skill menggunakan Helm chart dengan SOPS encrypted secrets.
  Use when membuat deployment config baru untuk service, menambah environment baru,
  mengkonfigurasi ingress/HPA/secrets, atau setup ECR credential rotation.
---

# ArgoCD Helm Deployment Pattern

Kamu adalah senior DevOps engineer dengan pengalaman bertahun-tahun di Kubernetes, CI/CD pipelines, infrastructure as code, dan cloud-native deployment.
Kamu memahami best practices GitOps, secrets management, observability, dan production-grade infrastructure.

Skill ini mendefinisikan pattern deployment Kubernetes menggunakan ArgoCD + Helm + SOPS secrets
yang digunakan di seluruh infrastructure.

## When to use this skill

- Membuat deployment config baru untuk service baru
- Menambah environment baru (dev/staging/production) untuk service yang sudah ada
- Mengkonfigurasi ingress, HPA, secrets, atau ECR credential rotation
- Review atau troubleshoot deployment config
- Memahami flow secrets dari plaintext sampai encrypted di cluster

## Repository Structure

Refer to: `references/repo-structure.md`

## Component Guide

### 1. ArgoCD Application (Per Environment)

Manifest ArgoCD Application yang mendefinisikan source, destination, dan sync policy per environment.

Refer to: `references/argocd-application.md`

### 2. Helm Chart & Values

Chart.yaml, values per environment, dan konfigurasi Helm.

Refer to: `references/helm-chart.md`

### 3. Helm Templates

Semua Kubernetes resource templates: Deployment, Service, Ingress, HPA, Secret, ECR CronJob.

Refer to: `references/templates.md`

### 4. Secrets Management (SOPS)

Flow enkripsi secrets, .sops.yaml config, Makefile commands, dan secrets structure.

Refer to: `references/secrets.md`

## Critical Rules

1. Namespace convention: `<app-name>-<env>` (e.g. `invoice-tracking-dev`)
2. Branch = environment: `targetRevision` harus match branch name (`dev`, `staging`, `production`)
3. ArgoCD project selalu `<argocd-project>`
4. Sync policy: `automated` dengan `prune: true`, `selfHeal: true`, `CreateNamespace=true`
5. Secrets WAJIB dienkripsi pakai SOPS sebelum push ke manifest repo
6. GPG keys: dev/staging share satu key, production pakai key terpisah
7. Container port default: `33200` dengan health check di `/health`
8. Service type selalu `ClusterIP` dengan port `80` → targetPort `33200`
9. TLS secret selalu `<tls-secret-name>`
10. ECR CronJob wajib ada jika pakai private ECR registry (schedule: setiap 12 jam)
11. Secret values di `secrets` HARUS format flat `env:` map dengan SCREAMING_SNAKE_CASE keys, semua string values
12. Jangan pernah commit plaintext secrets ke manifest repo
