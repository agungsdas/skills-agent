# ArgoCD Application Manifest

Setiap service punya 3 ArgoCD Application manifest (satu per environment).
File disimpan di `argocd/<app-name>/application-<env>.yaml`.

## Template

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <app-name>-<env>
  namespace: argocd
spec:
  project: <argocd-project>
  source:
    repoURL: https://github.com/agungsdas/kubernetes-manifest
    targetRevision: <env>                    # branch name = environment
    path: apps/<app-name>
    helm:
      valueFiles:
        - values.<env>.yaml
        - secrets+gpg-import:///helm-secrets-private-keys/<key-file>.asc?secrets.<env>.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: <app-name>-<env>
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## GPG Key File per Environment

| Environment | Key File | GPG Fingerprint |
|-------------|----------|-----------------|
| dev | `dev-key.asc` | `<dev-gpg-fingerprint>` |
| staging | `dev-key.asc` | `<dev-gpg-fingerprint>` |
| production | `prod-key.asc` | `<prod-gpg-fingerprint>` |

> Dev dan staging share GPG key yang sama. Production pakai key terpisah.

## Perbedaan Antar Environment

Satu-satunya yang berubah antar environment:

1. `metadata.name` — suffix environment
2. `targetRevision` — branch name
3. `valueFiles` — file values dan secrets sesuai env
4. `destination.namespace` — namespace sesuai env
5. GPG key file — `dev-key.asc` vs `prod-key.asc`

## Aturan Penting

- `project` selalu `<argocd-project>`
- `syncPolicy.automated` selalu enabled dengan `prune` dan `selfHeal`
- `CreateNamespace=true` wajib ada di `syncOptions`
- `repoURL` selalu ke repo manifest yang sama
- Secrets diakses via `helm-secrets` plugin dengan format `secrets+gpg-import://`
