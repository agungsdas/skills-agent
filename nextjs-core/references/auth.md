# Authentication & Authorization

Auth self-hosted untuk full-stack Next.js: **session JWT (jose) di httpOnly cookie + password hash (bcrypt) + middleware guard + RBAC**.
`jose` dipakai karena **edge-compatible** (jalan di middleware). `bcryptjs` untuk hashing (node runtime).

> Butuh OAuth/social login? Pakai **Auth.js (NextAuth v5)** + MongoDB adapter. Pola di bawah untuk credential-based yang kamu kontrol penuh & konsisten dengan layer MongoDB.

Install: `pnpm add jose bcryptjs && pnpm add -D @types/bcryptjs`

---

## 1. Password hashing

```ts
// src/lib/auth/password.ts
import "server-only";
import bcrypt from "bcryptjs";

const ROUNDS = 12;

export function hashPassword(plain: string): Promise<string> {
  return bcrypt.hash(plain, ROUNDS);
}

export function verifyPassword(plain: string, hash: string): Promise<boolean> {
  return bcrypt.compare(plain, hash);
}
```

> `bcryptjs` butuh **node runtime** — route auth otomatis node runtime (default). Jangan panggil di edge/middleware.

---

## 2. Session (jose JWT)

```ts
// src/lib/auth/session.ts
import { SignJWT, jwtVerify, type JWTPayload } from "jose";
import { cookies } from "next/headers";
import type { NextRequest } from "next/server";

const secret = new TextEncoder().encode(process.env.AUTH_SECRET);
const COOKIE = "session";
const MAX_AGE = 60 * 60 * 24 * 7; // 7 hari

export type Role = "admin" | "manager" | "user";
export interface SessionUser {
  id: string;
  email: string;
  role: Role;
}

export async function createSessionToken(user: SessionUser): Promise<string> {
  return new SignJWT({ email: user.email, role: user.role })
    .setProtectedHeader({ alg: "HS256" })
    .setSubject(user.id)
    .setIssuedAt()
    .setExpirationTime("7d")
    .sign(secret);
}

export async function verifySessionToken(token: string): Promise<SessionUser> {
  const { payload } = await jwtVerify<JWTPayload & { email: string; role: Role }>(token, secret);
  return { id: String(payload.sub), email: payload.email, role: payload.role };
}

/** Set cookie sesi (dipanggil di route login). */
export async function setSessionCookie(user: SessionUser): Promise<void> {
  const token = await createSessionToken(user);
  (await cookies()).set(COOKIE, token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    maxAge: MAX_AGE,
  });
}

export async function clearSessionCookie(): Promise<void> {
  (await cookies()).delete(COOKIE);
}

/** Baca sesi di Server Component / Route Handler. */
export async function getSession(): Promise<SessionUser | null> {
  const token = (await cookies()).get(COOKIE)?.value;
  if (!token) return null;
  try {
    return await verifySessionToken(token);
  } catch {
    return null;
  }
}

type AuthResult =
  | { ok: true; user: SessionUser }
  | { ok: false; status: 401 | 403; message: string };

/** Guard untuk Route Handler. Optional role check (RBAC). */
export async function requireAuth(request: NextRequest, roles?: Role[]): Promise<AuthResult> {
  const token = request.cookies.get(COOKIE)?.value;
  if (!token) return { ok: false, status: 401, message: "Unauthorized" };

  try {
    const user = await verifySessionToken(token);
    if (roles && !roles.includes(user.role)) {
      return { ok: false, status: 403, message: "Forbidden: role tidak diizinkan" };
    }
    return { ok: true, user };
  } catch {
    return { ok: false, status: 401, message: "Sesi tidak valid atau kedaluwarsa" };
  }
}
```

---

## 3. Route: login & logout

```ts
// src/app/api/auth/login/route.ts
import { type NextRequest } from "next/server";
import { z } from "zod";
import { userRepository } from "@/repositories/user";
import { verifyPassword } from "@/lib/auth/password";
import { setSessionCookie } from "@/lib/auth/session";
import { ok, fail } from "@/lib/api/response";

const loginSchema = z.object({
  identifier: z.string().trim().min(1), // username (admin) atau email
  password: z.string().min(1),
});

export async function POST(request: NextRequest) {
  const parsed = loginSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return fail("Input tidak valid", 422, parsed.error.flatten());

  const { identifier, password } = parsed.data;

  // Pesan generik — jangan bocorkan apakah akun ada atau password salah
  const user = await userRepository.findByIdentifier(identifier, { withPassword: true });
  if (!user || !user.passwordHash || !(await verifyPassword(password, user.passwordHash))) {
    return fail("Username/email atau password salah", 401);
  }

  await setSessionCookie({ id: String(user._id), email: user.email, role: user.role });
  return ok({ id: String(user._id), email: user.email, role: user.role }, "Login berhasil");
}
```

```ts
// src/app/api/auth/logout/route.ts
import { clearSessionCookie } from "@/lib/auth/session";
import { ok } from "@/lib/api/response";

export async function POST() {
  await clearSessionCookie();
  return ok(null, "Logout berhasil");
}
```

---

## 4. Middleware guard (edge)

Middleware = **gerbang tipis di edge**: verifikasi sesi (`verifySessionToken`, jose edge-compatible) lalu redirect user belum-login dari route terproteksi. **Bukan** authorization sebenarnya — cek role & data tetap di `requireAuth` (route) dan `getSession` (RSC).

Kode lengkap `middleware.ts`, batasan (no DB/bcrypt), matcher, dan pola **defense-in-depth** → lihat **`middleware.md`**.

---

## 5. RBAC di Server Component / page

```tsx
// src/app/(app)/admin/page.tsx
import { redirect } from "next/navigation";
import { getSession } from "@/lib/auth/session";

export default async function AdminPage() {
  const session = await getSession();
  if (!session) redirect("/login");
  if (session.role !== "admin") redirect("/403");

  return <AdminDashboard />;
}
```

Pola RBAC:
- **Route Handler** → `requireAuth(request, ["admin"])`.
- **Server Component/page** → `getSession()` + cek `role`, `redirect()` kalau tidak berhak.
- **UI** (sembunyikan tombol) → cek role, tapi **jangan andalkan UI untuk keamanan** — enforcement tetap di server.

---

## 6. Varian: consume backend eksternal (mis. service Go)

Kalau token diterbitkan backend lain (bukan MongoDB lokal):

- Login route jadi **proxy**: forward kredensial ke backend, ambil `access_token` + `refresh_token`, simpan di **httpOnly cookie** (jangan di localStorage — rawan XSS).
- Middleware cek keberadaan + expiry access token; kalau expired, refresh via refresh token (server-side).
- `fetcher` (lihat data-layer) menyisipkan token dari cookie ke header `Authorization`.

Prinsip yang sama berlaku: token di httpOnly cookie, enforcement di server, pesan error generik.

---

## 7. Checklist auth (wajib)

- [ ] Password di-hash (bcrypt rounds ≥ 12), `passwordHash` `select:false`
- [ ] Token sesi di **httpOnly + secure (prod) + sameSite=lax** cookie — bukan localStorage
- [ ] `AUTH_SECRET` ≥ 32 char, dari environment (tervalidasi)
- [ ] Pesan login **generik** (tidak bocorkan email terdaftar / password salah)
- [ ] Middleware verifikasi sesi untuk semua route terproteksi
- [ ] RBAC di-enforce di server (route + page), bukan cuma UI
- [ ] Logout menghapus cookie
- [ ] `jose` di edge (middleware), `bcryptjs` di node (route) — tidak tertukar
