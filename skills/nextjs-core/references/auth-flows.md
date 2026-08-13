# Auth Flows — Member (Google) & Admin (Credential)

Dua model auth, kepetakan ke track (sesuai pola production):

| | Track | Metode | Session |
|---|-------|--------|---------|
| **Member** | `nextjs-customer-facing` | **Google sign-in** via NextAuth (Auth.js v5) | NextAuth (JWT) |
| **Admin** | `nextjs-dashboard` | **Username/password** + Turnstile | jose JWT (lihat `auth.md`) |

Biasanya ini **dua app terpisah** (dua Vercel project). Masing-masing punya sistem sesi sendiri; data tetap lewat `/api` + services.

---

## 1. Member — Google sign-in (NextAuth / Auth.js v5)

Install: `pnpm add next-auth@beta`

```ts
// src/auth.ts
import NextAuth from "next-auth";
import Google from "next-auth/providers/google";
import { upsertMemberFromGoogle } from "@/repositories/member"; // server (dalam scope /api NextAuth)

export const { handlers, signIn, signOut, auth } = NextAuth({
  trustHost: true,                       // wajib di Vercel
  secret: process.env.NEXTAUTH_SECRET,   // v5 juga baca AUTH_SECRET; set eksplisit biar aman
  session: { strategy: "jwt" },
  pages: { signIn: "/login" },
  providers: [
    Google({
      clientId: process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    }),
  ],
  callbacks: {
    // Simpan/mutakhirkan member di DB kita (callback jalan di /api NextAuth → boleh sentuh repo)
    async signIn({ user, account }) {
      if (account?.provider === "google" && user.email) {
        await upsertMemberFromGoogle({ email: user.email, name: user.name, image: user.image });
      }
      return true;
    },
    async jwt({ token, user }) {
      if (user) token.role = "member";
      return token;
    },
    async session({ session, token }) {
      if (session.user) session.user.role = token.role as string;
      return session;
    },
  },
});
```

```ts
// src/app/api/auth/[...nextauth]/route.ts
import { handlers } from "@/auth";
export const { GET, POST } = handlers;
```

```ts
// src/middleware.ts (member app) — proteksi via NextAuth
export { auth as middleware } from "@/auth";
export const config = { matcher: ["/((?!api|_next/static|_next/image|favicon.ico|.*\\..*).*)"] };
```

Pemakaian:
```tsx
// Server Component
import { auth } from "@/auth";
const session = await auth();       // null kalau belum login

// Client
"use client";
import { signIn, signOut } from "next-auth/react";
<button onClick={() => signIn("google")}>Masuk dengan Google</button>
```

Env: `NEXTAUTH_SECRET`, `NEXTAUTH_URL` (base URL), `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`. Callback URL Google: `https://<domain>/api/auth/callback/google`.

> Data member disimpan di DB kita via `signIn` callback → tetap satu sumber user. Panggilan data lain tetap lewat `/api` + services.

---

## 2. Admin — Credential + Turnstile

Basis session/login credential ada di **`auth.md`** (jose JWT, bcrypt, `requireAuth`). Track admin **menambah**:

### Turnstile (anti-bot) di route login

```ts
// src/lib/security/turnstile.ts
import "server-only";

export async function verifyTurnstile(token: string, ip?: string): Promise<boolean> {
  const res = await fetch("https://challenges.cloudflare.com/turnstile/v0/siteverify", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      secret: process.env.TURNSTILE_SECRET_KEY!,
      response: token,
      ...(ip ? { remoteip: ip } : {}),
    }),
  });
  const data = (await res.json()) as { success: boolean };
  return data.success === true;
}
```

Di `POST /api/auth/login` (lihat `auth.md` §3), sebelum cek password:
```ts
const { identifier, password, turnstileToken } = parsed.data;
if (!(await verifyTurnstile(turnstileToken, clientIp(request)))) {
  return fail("Verifikasi bot gagal", 400);
}
// ... lanjut verifyPassword + setSessionCookie
```

> Akun admin biasanya **di-seed** (bukan self-register). Pakai route seed terlindungi `SEED_SECRET` (bukan endpoint publik).

---

## 3. Reset password (credential) — email via Resend

Install: `pnpm add resend`

```ts
// src/lib/email.ts
import "server-only";
import { Resend } from "resend";

const resend = new Resend(process.env.RESEND_API_KEY);

export function sendEmail(opts: { to: string; subject: string; html: string }) {
  return resend.emails.send({ from: "App <noreply@example.com>", ...opts });
}
```

Token reset disimpan dengan **TTL index** (auto-expire):
```ts
// src/models/reset-token.ts — server only
resetTokenSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
// { userId, tokenHash, expiresAt }
```

Flow (dua route `/api/auth/*`):
1. **Request** `POST /api/auth/forgot-password { email }` → cari user → generate token acak (`crypto.randomBytes`) → simpan **hash**-nya + `expiresAt` (mis. 1 jam) → kirim email link `${process.env.NEXT_PUBLIC_APP_URL}/reset-password?token=...`. **Selalu** balas sukses generik (jangan bocorkan email terdaftar).
2. **Reset** `POST /api/auth/reset-password { token, password }` → hash token → cari yang valid & belum expired → `hashPassword` → update `passwordHash` → hapus token.

Verify email pola sama (token TTL + link `/verify-email?token=...` → tandai `emailVerifiedAt`).

---

## 4. authService (endpoint credential admin)

Tambahkan ke `authService` (lihat `services.md`): `forgotPassword`, `resetPassword`, `register` (kalau perlu). Member (Google) pakai `signIn("google")` dari `next-auth/react`, bukan authService.

---

## Checklist auth flows (wajib)

- [ ] Member: NextAuth v5 + Google, `trustHost: true`, secret eksplisit, callback URL Google benar
- [ ] Member di-upsert ke DB via `signIn` callback (satu sumber user)
- [ ] Admin: credential (jose, `auth.md`) + **Turnstile** diverifikasi server-side sebelum cek password
- [ ] Admin di-seed via route ber-`SEED_SECRET`, bukan self-register publik
- [ ] Reset/verify: token **di-hash** sebelum simpan + **TTL index** auto-expire
- [ ] Email enumeration dicegah (respons generik di forgot-password)
- [ ] Email dikirim server-side (Resend), API key di env (bukan `NEXT_PUBLIC_`)
- [ ] Dua app (member/admin) = dua sistem sesi; data tetap via `/api` + services
