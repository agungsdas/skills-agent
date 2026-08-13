# Security

Baseline keamanan production: security headers, CSP, proteksi CSRF, rate limiting, XSS. Berlaku untuk kedua track.
Validasi input (Zod) & auth dibahas di `mongodb-mongoose.md` dan `auth.md`.

---

## 1. Security Headers

```ts
// next.config.ts
import type { NextConfig } from "next";

const securityHeaders = [
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "X-Frame-Options", value: "DENY" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=()" },
  {
    key: "Strict-Transport-Security",
    value: "max-age=63072000; includeSubDomains; preload",
  },
];

const nextConfig: NextConfig = {
  poweredByHeader: false, // sembunyikan X-Powered-By
  async headers() {
    return [{ source: "/:path*", headers: securityHeaders }];
  },
};

export default nextConfig;
```

---

## 2. Content Security Policy (nonce-based)

CSP paling aman pakai **nonce** per-request (bukan `unsafe-inline`). Generate di middleware, teruskan ke Next.

```ts
// potongan src/middleware.ts — bisa digabung dengan auth guard
export function middleware(request: NextRequest) {
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
  const csp = [
    `default-src 'self'`,
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
    `style-src 'self' 'unsafe-inline'`, // Tailwind inject style; ketatkan bila memungkinkan
    `img-src 'self' blob: data:`,
    `font-src 'self'`,
    `connect-src 'self'`,
    `frame-ancestors 'none'`,
    `base-uri 'self'`,
    `form-action 'self'`,
  ].join("; ");

  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);
  requestHeaders.set("content-security-policy", csp);

  const response = NextResponse.next({ request: { headers: requestHeaders } });
  response.headers.set("content-security-policy", csp);
  return response;
}
```

Baca nonce di layout untuk inline script yang perlu: `const nonce = (await headers()).get("x-nonce")`.

> Kalau CSP nonce terlalu ketat untuk fase awal, minimal set `frame-ancestors 'none'`, `base-uri 'self'`, `object-src 'none'`, dan hindari `unsafe-eval`.

---

## 3. Cookie Security

Untuk semua cookie auth/sesi (lihat `auth.md`):
- `httpOnly: true` → JS tak bisa baca (anti XSS token theft)
- `secure: true` di production → hanya HTTPS
- `sameSite: "lax"` → mitigasi CSRF untuk request cross-site
- `path: "/"`, `maxAge` eksplisit
- **Jangan** simpan token di `localStorage`/`sessionStorage`

---

## 4. CSRF

`sameSite=lax` sudah menahan mayoritas CSRF. Untuk mutasi (POST/PATCH/DELETE) berbasis cookie, tambah **origin check**:

```ts
// src/lib/security/origin.ts
import { type NextRequest } from "next/server";

export function assertSameOrigin(request: NextRequest): boolean {
  const origin = request.headers.get("origin");
  const host = request.headers.get("host");
  if (!origin) return true; // same-origin navigation biasanya tanpa Origin
  try {
    return new URL(origin).host === host;
  } catch {
    return false;
  }
}
```

Panggil di awal handler mutasi; tolak `403` kalau `false`.

---

## 5. Rate Limiting

Public/auth endpoint WAJIB dibatasi. Production pakai **Upstash Redis** (`@upstash/ratelimit`), edge-friendly & stateless-safe:

```ts
// src/lib/security/rate-limit.ts
import { Ratelimit } from "@upstash/ratelimit";
import { Redis } from "@upstash/redis";

export const authLimiter = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(5, "1 m"), // 5 request / menit / key
  prefix: "rl:auth",
});

export function clientIp(request: Request): string {
  const xff = request.headers.get("x-forwarded-for");
  return xff?.split(",")[0]?.trim() ?? "unknown";
}
```

```ts
// contoh di route login
const { success } = await authLimiter.limit(clientIp(request));
if (!success) return fail("Terlalu banyak percobaan. Coba lagi nanti.", 429);
```

> In-memory counter hanya valid untuk single-instance/dev. Serverless multi-instance WAJIB store terpusat (Redis).

---

## 6. XSS

- React **auto-escape** JSX — aman secara default.
- **Hindari `dangerouslySetInnerHTML`.** Kalau terpaksa render HTML (mis. rich text/CMS), sanitasi dulu:

```tsx
import DOMPurify from "isomorphic-dompurify";

<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(html) }} />;
```

- Jangan inject user input ke `<script>`, URL `javascript:`, atau atribut event.
- Validasi & sanitasi semua input di server (Zod).

---

## 7. Checklist Security (wajib)

- [ ] Security headers aktif (`nosniff`, `frame-ancestors/DENY`, HSTS, Referrer-Policy)
- [ ] CSP terpasang (minimal `frame-ancestors 'none'`, `object-src 'none'`, no `unsafe-eval`)
- [ ] Cookie auth: httpOnly + secure(prod) + sameSite
- [ ] Origin check di endpoint mutasi berbasis cookie
- [ ] Rate limit di endpoint auth/publik (store terpusat di prod)
- [ ] Tidak ada `dangerouslySetInnerHTML` tanpa sanitasi
- [ ] Semua input tervalidasi Zod di server
- [ ] Error ke user tidak membocorkan detail internal/stack
- [ ] `poweredByHeader: false`
