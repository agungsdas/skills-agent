# Secrets Management (SOPS)

## Flow Secrets

```
secrets (plaintext) → sops -e → manifest repo (encrypted) → ArgoCD helm-secrets plugin → K8s Secret
```

1. Developer edit plaintext secrets di `secrets/apps/<app-name>/`
2. Jalankan `make generate-secrets-<env>` di `apps/<app-name>/` untuk encrypt
3. Push encrypted secrets ke manifest repo
4. ArgoCD decrypt otomatis via `helm-secrets` plugin saat sync

## Plaintext Secrets Format (`secrets`)

File: `.decrypted-secrets.<env>.yaml`

```yaml
env:
  CI_ENVIRONMENT: "dev"
  CI_DEBUG: "0"
  JWT_SECRET: "<secret-value>"
  POSTGRE_HOST: "<host>"
  POSTGRE_PORT: "<port>"
  POSTGRE_USERNAME: "<username>"
  POSTGRE_PASSWORD: "<password>"
  POSTGRE_DBNAME: "<dbname>"
  REDIS_HOST: "<host>"
  REDIS_PORT: "<port>"
  REDIS_PASSWORD: "<password>"
  REDIS_DATABASE: "0"
  REDIS_PREFIX: "<app-name>-<env>:"
  CLOUDWATCH_REGION: "ap-southeast-3"
  CLOUDWATCH_ACCESS_KEY_ID: "<key>"
  CLOUDWATCH_SECRET_ACCESS_KEY: "<secret>"
  CLOUDWATCH_LOG_GROUP: "<app-log-group>-<env>"
  ECR_ACCESS_KEY_ID: "<key>"
  ECR_SECRET_ACCESS_KEY: "<secret>"
  API_AUTH_USER: "<app-name>"
  API_AUTH_PASS: "<generated-hash>"
```

### Aturan Format Secrets:
- Root key selalu `env:` (flat map, tidak nested)
- Semua key pakai `SCREAMING_SNAKE_CASE`
- Semua value HARUS string (di-wrap dengan quotes)
- Prefix file dengan `.` (hidden file) dan prefix `.decrypted-`
- `REDIS_PREFIX` format: `<app-name>-<env>:`
- `CLOUDWATCH_LOG_GROUP` format: `<app-log-group>-<env>`

## SOPS Configuration (`.sops.yaml`)

File disimpan di `apps/<app-name>/.sops.yaml`:

```yaml
creation_rules:
  - path_regex: .*.dev.yaml
    encrypted_regex: ^(env)$
    pgp: <dev-gpg-fingerprint>
  - path_regex: .*.staging.yaml
    encrypted_regex: ^(env)$
    pgp: <dev-gpg-fingerprint>
  - path_regex: .*.production.yaml
    encrypted_regex: ^(env)$
    pgp: <prod-gpg-fingerprint>
```

### Penjelasan:
- `path_regex` — match file berdasarkan environment suffix
- `encrypted_regex: ^(env)$` — hanya encrypt key `env` (bukan seluruh file)
- Dev dan staging share GPG key yang sama
- Production pakai GPG key terpisah (lebih strict)

## Makefile

File disimpan di `apps/<app-name>/Makefile`:

```makefile
APP_PROJECT=<app-name>
SECRET_FOLDER=../../../secrets/apps
DEV_FILE=.decrypted-secrets.dev.yaml
STAGING_FILE=.decrypted-secrets.staging.yaml
PRODUCTION_FILE=.decrypted-secrets.production.yaml
COMMIT_MESSAGE="update env ${APP_PROJECT}"

generate-secrets-dev:
	sops -e ${SECRET_FOLDER}/${APP_PROJECT}/${DEV_FILE} > secrets.dev.yaml
generate-secrets-staging:
	sops -e ${SECRET_FOLDER}/${APP_PROJECT}/${STAGING_FILE} > secrets.staging.yaml
generate-secrets-production:
	sops -e ${SECRET_FOLDER}/${APP_PROJECT}/${PRODUCTION_FILE} > secrets.production.yaml
generate-secrets-all:
	make generate-secrets-dev && make generate-secrets-staging && make generate-secrets-production
push-secret:
	cd ${SECRET_FOLDER}/${APP_PROJECT} && git add . && git commit -m ${COMMIT_MESSAGE} -n && git push
push-manifest:
	git add . && git commit -m ${COMMIT_MESSAGE} -n && git push
process-all:
	- make generate-secrets-all
	- make push-secret
	- make push-manifest
```

### Workflow Commands:

| Command | Fungsi |
|---------|--------|
| `make generate-secrets-dev` | Encrypt secrets dev |
| `make generate-secrets-staging` | Encrypt secrets staging |
| `make generate-secrets-production` | Encrypt secrets production |
| `make generate-secrets-all` | Encrypt semua environment |
| `make push-secret` | Commit & push ke secrets repo |
| `make push-manifest` | Commit & push ke manifest repo |
| `make process-all` | Generate all + push both repos |

## Workflow Lengkap: Update Secret

```bash
# 1. Edit plaintext secret
vim secrets/apps/<app-name>/.decrypted-secrets.<env>.yaml

# 2. Generate encrypted version
cd kubernetes-manifest/apps/<app-name>
make generate-secrets-<env>

# 3. Push changes
make push-secret      # push ke secrets
make push-manifest    # push ke manifest repo

# Atau sekaligus:
make process-all
```

## Workflow Lengkap: Service Baru

```bash
# 1. Buat plaintext secrets di secrets-gwi
mkdir -p secrets/apps/<app-name>
# Buat .decrypted-secrets.dev.yaml, .staging.yaml, .production.yaml

# 2. Buat Helm chart di manifest repo
mkdir -p kubernetes-manifest/apps/<app-name>/templates
# Copy & modify Chart.yaml, .sops.yaml, Makefile, values, templates

# 3. Generate encrypted secrets
cd kubernetes-manifest/apps/<app-name>
make generate-secrets-all

# 4. Buat ArgoCD Application manifests
mkdir -p kubernetes-manifest/argocd/<app-name>
# Buat application-dev.yaml, application-staging.yaml, application-production.yaml

# 5. Push semua
make process-all
```
