# Deployment

Dua jalur yang dipakai: **Vercel via GitHub Actions** (managed, default) dan **Docker Compose** (self-host).

---

## 1. Vercel via GitHub Actions (default)

Deploy pakai GitHub Actions + Vercel CLI action. **Env di-inject langsung ke deployment via `vercel-args`** (`-e` = runtime, `-b` = build) — bukan lewat file `.env` di runner, karena file `.env` di runner **tidak** sampai ke runtime Vercel (ini sumber bug env kosong di production).

### Secrets di GitHub (Settings → Secrets and variables → Actions)

- `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID` (per project: web/admin)
- Per environment: `MONGODB_URI_PRODUCTION` / `_STAGING`, secret auth (`NEXTAUTH_SECRET_*` untuk member NextAuth, `AUTH_SECRET_*` untuk admin jose — samakan dgn nama yang dibaca `auth.md`), `R2_SECRET_ACCESS_KEY_*`, dst.

### Production — `.github/workflows/deploy-production.yml`

Trigger: push ke `master`. Pakai `--prod` + alias domain.

```yaml
name: Deploy Production
on:
  push:
    branches: [master]

jobs:
  deploy-web:
    name: Deploy Web (Production)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: "pnpm"
      - run: pnpm install --frozen-lockfile

      # Fail fast kalau ada secret wajib yang kosong
      - name: Verify required secrets
        env:
          MONGODB_URI: ${{ secrets.MONGODB_URI_PRODUCTION }}
          NEXTAUTH_SECRET: ${{ secrets.NEXTAUTH_SECRET_PRODUCTION }}
          GOOGLE_CLIENT_SECRET: ${{ secrets.GOOGLE_CLIENT_SECRET }}
          R2_SECRET_ACCESS_KEY: ${{ secrets.R2_SECRET_ACCESS_KEY_PRODUCTION }}
        run: |
          for v in MONGODB_URI NEXTAUTH_SECRET GOOGLE_CLIENT_SECRET R2_SECRET_ACCESS_KEY; do
            if [ -z "${!v}" ]; then
              echo "::error::Secret '$v' kosong. Set di Settings > Secrets and variables > Actions."
              exit 1
            fi
          done

      - name: Deploy to Vercel
        uses: agungsdas/vercel-action@master
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_WEB_PROJECT_ID }}
          alias-domains: app.example.com
          working-directory: ./
          scope: ${{ secrets.VERCEL_ORG_ID }}
          github-comment: false
          # -e = runtime env, -b = build-time env (NEXT_PUBLIC_* butuh -b juga)
          vercel-args: >-
            --prod
            -e MONGODB_URI=${{ secrets.MONGODB_URI_PRODUCTION }}
            -e NEXTAUTH_URL=https://app.example.com
            -e NEXTAUTH_SECRET=${{ secrets.NEXTAUTH_SECRET_PRODUCTION }}
            -e GOOGLE_CLIENT_ID=${{ secrets.GOOGLE_CLIENT_ID }}
            -e GOOGLE_CLIENT_SECRET=${{ secrets.GOOGLE_CLIENT_SECRET }}
            -e R2_ACCOUNT_ID=${{ secrets.R2_ACCOUNT_ID }}
            -e R2_ACCESS_KEY_ID=${{ secrets.R2_ACCESS_KEY_ID }}
            -e R2_SECRET_ACCESS_KEY=${{ secrets.R2_SECRET_ACCESS_KEY_PRODUCTION }}
            -e R2_BUCKET_NAME=app-production
            -e NEXT_PUBLIC_APP_URL=https://app.example.com
            -b NEXT_PUBLIC_APP_URL=https://app.example.com
```

### Staging — `.github/workflows/deploy-staging.yml`

Trigger: push ke `release/**` / `hotfix/**`. **Tanpa** `--prod`, alias domain staging, secrets `_STAGING`.

```yaml
name: Deploy Staging
on:
  push:
    branches: ["release/**", "hotfix/**"]
# ... jobs sama, tapi:
#   alias-domains: staging.example.com
#   vercel-args tanpa --prod, pakai secrets *_STAGING
```

### Catatan penting

- **`NEXT_PUBLIC_*` wajib di-pass sebagai `-b` (build)** — kalau cuma `-e` (runtime), nilainya tidak ter-embed ke bundle client.
- **Multi-app** (mis. `web` + `admin` di satu repo): satu **job per project** (`deploy-web`, `deploy-admin`) dengan `vercel-project-id` masing-masing.
- **MongoDB di Vercel = MongoDB Atlas** (bukan mongo lokal); whitelist IP `0.0.0.0/0` atau Vercel egress.
- `vercel-action` = fork community vercel action; kunci polanya = inject env via `vercel-args`.

---

## 2. Docker Compose (self-host)

### `next.config.ts` — output standalone

```ts
import type { NextConfig } from "next";
const nextConfig: NextConfig = {
  output: "standalone", // bundle minimal untuk container
  poweredByHeader: false,
};
export default nextConfig;
```

### `Dockerfile` (multi-stage, standalone)

```dockerfile
# 1) deps
FROM node:22-alpine AS deps
WORKDIR /app
RUN corepack enable
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# 2) build
FROM node:22-alpine AS builder
WORKDIR /app
RUN corepack enable
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN pnpm build

# 3) runner (image kecil, non-root)
FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup -g 1001 nodejs && adduser -u 1001 -G nodejs -S nextjs
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
USER nextjs
EXPOSE 3000
CMD ["node", "server.js"]
```

### `docker-compose.yml`

```yaml
services:
  app:
    build: .
    ports: ["3000:3000"]
    environment:
      MONGODB_URI: mongodb://mongo:27017/app
      AUTH_SECRET: ${AUTH_SECRET}
      NEXT_PUBLIC_APP_URL: http://localhost:3000
    depends_on:
      mongo: { condition: service_healthy }
    restart: unless-stopped

  mongo:
    image: mongo:7
    volumes: ["mongo_data:/data/db"]
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis: # opsional (rate limit / cache)
    image: redis:7-alpine
    restart: unless-stopped

volumes:
  mongo_data:
```

> Build env `NEXT_PUBLIC_*` untuk Docker: pass sebagai build `ARG` di Dockerfile / `build.args` di compose kalau butuh ter-embed saat `pnpm build`.

---

## Checklist deployment (wajib)

- [ ] Vercel: env di-inject via `vercel-args` (`-e` runtime, `-b` build), bukan `.env` di runner
- [ ] `NEXT_PUBLIC_*` di-pass `-b` (build) agar ter-embed
- [ ] Step **verify secrets** (fail-fast) sebelum deploy
- [ ] Production (`master`, `--prod`) & staging (`release/**`) terpisah, secrets per-env
- [ ] MongoDB Atlas untuk Vercel; connection string di secret
- [ ] Docker: `output: "standalone"`, image non-root, healthcheck di compose
- [ ] Secret TIDAK pernah di-commit — hanya di GitHub Secrets / platform env
