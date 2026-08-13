# Environment Variables & Configuration

Env WAJIB divalidasi saat startup — fail fast kalau ada yang hilang/salah. Pakai **`@t3-oss/env-nextjs` + Zod**:
type-safe, dan **memisahkan server vs client** agar secret tidak pernah bocor ke browser.

Install: `pnpm add @t3-oss/env-nextjs zod`

---

## 1. Validasi env (server/client split)

```ts
// src/lib/env.ts
import { createEnv } from "@t3-oss/env-nextjs";
import { z } from "zod";

export const env = createEnv({
  // Server-only: TIDAK PERNAH masuk bundle browser.
  // Var app-specific ditandai .optional() — aktif sesuai app (member vs admin).
  server: {
    NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
    MONGODB_URI: z.string().url(),

    // Admin (dashboard) — sesi jose + extras
    AUTH_SECRET: z.string().min(32, "AUTH_SECRET (sesi admin/jose) minimal 32 karakter"),
    TURNSTILE_SECRET_KEY: z.string().optional(),
    SEED_SECRET: z.string().optional(),

    // Member (customer-facing) — NextAuth + Google
    NEXTAUTH_SECRET: z.string().min(32).optional(),
    NEXTAUTH_URL: z.string().url().optional(),
    GOOGLE_CLIENT_ID: z.string().optional(),
    GOOGLE_CLIENT_SECRET: z.string().optional(),

    // Email (Resend)
    RESEND_API_KEY: z.string().optional(),

    // Storage (Cloudflare R2)
    R2_ACCOUNT_ID: z.string().optional(),
    R2_ACCESS_KEY_ID: z.string().optional(),
    R2_SECRET_ACCESS_KEY: z.string().optional(),
    R2_BUCKET_NAME: z.string().optional(),
    R2_PUBLIC_DOMAIN: z.string().optional(),

    // Rate limit (opsional)
    UPSTASH_REDIS_REST_URL: z.string().url().optional(),
    UPSTASH_REDIS_REST_TOKEN: z.string().optional(),
  },
  // Client: HARUS berprefix NEXT_PUBLIC_ (terekspos ke browser)
  client: {
    NEXT_PUBLIC_APP_URL: z.string().url(),
    NEXT_PUBLIC_API_URL: z.string().url().optional(), // base API; isi kalau backend pindah (mis. Go)
  },
  runtimeEnv: {
    NODE_ENV: process.env.NODE_ENV,
    MONGODB_URI: process.env.MONGODB_URI,
    AUTH_SECRET: process.env.AUTH_SECRET,
    TURNSTILE_SECRET_KEY: process.env.TURNSTILE_SECRET_KEY,
    SEED_SECRET: process.env.SEED_SECRET,
    NEXTAUTH_SECRET: process.env.NEXTAUTH_SECRET,
    NEXTAUTH_URL: process.env.NEXTAUTH_URL,
    GOOGLE_CLIENT_ID: process.env.GOOGLE_CLIENT_ID,
    GOOGLE_CLIENT_SECRET: process.env.GOOGLE_CLIENT_SECRET,
    RESEND_API_KEY: process.env.RESEND_API_KEY,
    R2_ACCOUNT_ID: process.env.R2_ACCOUNT_ID,
    R2_ACCESS_KEY_ID: process.env.R2_ACCESS_KEY_ID,
    R2_SECRET_ACCESS_KEY: process.env.R2_SECRET_ACCESS_KEY,
    R2_BUCKET_NAME: process.env.R2_BUCKET_NAME,
    R2_PUBLIC_DOMAIN: process.env.R2_PUBLIC_DOMAIN,
    UPSTASH_REDIS_REST_URL: process.env.UPSTASH_REDIS_REST_URL,
    UPSTASH_REDIS_REST_TOKEN: process.env.UPSTASH_REDIS_REST_TOKEN,
    NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL,
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL,
  },
  emptyStringAsUndefined: true,
});
```

Idealnya akses via `env.*` (type-safe & tervalidasi). Di modul **server-only** sederhana, `process.env.*` masih boleh — yang **wajib**: semua var didaftarkan & divalidasi di `env.ts` ini (fail-fast saat startup). `NEXT_PUBLIC_*` aman dipakai di client.

---

## 2. Aturan NEXT_PUBLIC_

- Hanya var berprefix `NEXT_PUBLIC_` yang terekspos ke browser.
- **JANGAN** pernah taruh secret (DB URI, AUTH_SECRET, API key privat) di `NEXT_PUBLIC_*` — itu bocor ke bundle client.
- Server secret = tanpa prefix, hanya diakses dari kode server (route, RSC, repository).

---

## 3. `.env.example` (commit ini, jangan commit `.env.local`)

```bash
# App
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_API_URL=              # opsional; default = /api app ini. Isi kalau backend pindah (mis. Go)

# Database
MONGODB_URI=mongodb://localhost:27017/myapp

# Admin auth — sesi jose (generate: openssl rand -base64 32)
AUTH_SECRET=
TURNSTILE_SECRET_KEY=             # Cloudflare Turnstile (login admin)
SEED_SECRET=                      # seed akun admin

# Member auth — NextAuth + Google (app customer-facing)
NEXTAUTH_SECRET=
NEXTAUTH_URL=http://localhost:3000
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=

# Email (Resend)
RESEND_API_KEY=

# Storage (Cloudflare R2)
R2_ACCOUNT_ID=
R2_ACCESS_KEY_ID=
R2_SECRET_ACCESS_KEY=
R2_BUCKET_NAME=
R2_PUBLIC_DOMAIN=

# Rate limit (opsional, prod)
UPSTASH_REDIS_REST_URL=
UPSTASH_REDIS_REST_TOKEN=
```

Pastikan `.env.local`, `.env*.local` ada di `.gitignore` (default Next.js sudah).

---

## 4. Multi-environment

- `.env.local` → dev lokal (git-ignored)
- `.env.development` / `.env.production` → default per mode (boleh commit kalau tanpa secret)
- Secret production → inject via platform (Vercel env, K8s secret, dsb), **bukan** file di repo.

---

## 5. Feature Flags (sederhana, type-safe)

```ts
// src/lib/flags.ts
import { env } from "@/lib/env";

export const flags = {
  newDashboard: env.NODE_ENV !== "production", // contoh: aktif di non-prod
} as const;

export type FeatureFlag = keyof typeof flags;
export const isEnabled = (f: FeatureFlag): boolean => flags[f];
```

Untuk flag dinamis per-user/gradual rollout, gunakan layanan flag (mis. Vercel Flags / Unleash) — jangan hardcode kondisi tersebar di banyak tempat.

---

## 6. Checklist (wajib)

- [ ] Semua env divalidasi via `@t3-oss/env-nextjs` + Zod (fail fast)
- [ ] Server secret TIDAK berprefix `NEXT_PUBLIC_`
- [ ] `AUTH_SECRET` ≥ 32 char, di-generate acak
- [ ] `.env.example` di-commit; `.env.local` di-gitignore
- [ ] Secret production via platform, bukan file repo
- [ ] Semua env didaftarkan & divalidasi di `env.ts`; akses via `env.*` (disarankan), `process.env.*` boleh di modul server-only
- [ ] Var app-specific (`NEXTAUTH_*`, `GOOGLE_*`, `TURNSTILE_*`, `R2_*`, `RESEND_*`) diisi sesuai app (member vs admin)
