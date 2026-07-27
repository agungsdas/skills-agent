# Middleware — Edge Gate (peran, batas, defense-in-depth)

Middleware Next.js jalan di **edge**, sebelum request sampai ke route. Perannya: **gerbang tipis** —
bukan tempat logika berat, bukan authorization sebenarnya, bukan akses data.

---

## 1. Peran middleware

1. **Auth gate (redirect navigasi)** — baca cookie sesi, verifikasi JWT (`jose`, edge-compatible), redirect user belum-login dari route terproteksi ke `/login`, dan redirect yang sudah login dari halaman auth ke home.
2. **Security headers / CSP nonce** — inject header (detail di `security.md` §2).
3. **Redirect / rewrite / i18n / geo** — locale routing, canonical redirect, A/B, bot/geo check.

---

## 2. `middleware.ts` — auth gate

```ts
// src/middleware.ts
import { NextResponse, type NextRequest } from "next/server";
import { verifySessionToken } from "@/lib/auth/session"; // pakai jose (edge-safe)

const PUBLIC_PATHS = ["/login", "/register", "/forgot-password"];

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const isPublic = PUBLIC_PATHS.some((p) => pathname.startsWith(p));
  const token = request.cookies.get("session")?.value;

  let authenticated = false;
  if (token) {
    try {
      await verifySessionToken(token); // verifikasi tanda tangan + expiry saja
      authenticated = true;
    } catch {
      authenticated = false;
    }
  }

  // Belum login & buka halaman terproteksi → ke /login (simpan tujuan)
  if (!authenticated && !isPublic) {
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    url.searchParams.set("next", pathname);
    return NextResponse.redirect(url);
  }

  // Sudah login tapi buka halaman auth → ke home
  if (authenticated && isPublic) {
    const url = request.nextUrl.clone();
    url.pathname = "/";
    return NextResponse.redirect(url);
  }

  return NextResponse.next();
}

// Jangan intersepsi /api, asset statis, file dengan ekstensi
export const config = {
  matcher: ["/((?!api|_next/static|_next/image|favicon.ico|.*\\..*).*)"],
};
```

> `verifySessionToken` ada di `auth.md` §2. Cookie `session` yang dibaca di sini = cookie yang sama yang di-forward `serverApi` ke `/api` dan dikirim otomatis oleh browser.

---

## 3. Batasan (JANGAN)

- **No DB di middleware** — edge runtime, dan aturan kita **DB hanya di `/api/*`**. Jangan query Mongo di sini.
- **No bcrypt** — edge tidak support; hanya `jose` (verify JWT). Hashing password tetap di route (node runtime).
- **Bukan authorization granular** — middleware cuma cek "ada sesi valid?" (coarse). Cek role & kepemilikan resource ada di `/api` (`requireAuth(request, roles)`) dan RSC (`getSession` + cek role).
- **No fetch data untuk render** — jangan panggil service/api di middleware buat ngerender halaman.

---

## 4. Defense-in-depth (middleware bukan satu-satunya penjaga)

| Lapis | Di mana | Fungsi |
|-------|---------|--------|
| **Middleware** (edge) | `middleware.ts` | Gate **navigasi halaman**: ada sesi valid? redirect kalau nggak |
| **`requireAuth(roles)`** | tiap `/api/*` route handler | Gate **DATA** (wajib): `/api` bisa dihit langsung + cek role |
| **`getSession` + cek role** | RSC / layout `(app)` | Gate **render** halaman sensitif |

Kunci: **matcher sengaja exclude `/api`** → endpoint data tetap divalidasi `requireAuth` di dalam handler. Middleware nge-gate halaman; `/api` menjaga dirinya sendiri. Jangan andalkan middleware sebagai satu-satunya lapisan auth.

---

## 5. Admin (client-first) tetap butuh middleware

Meski dashboard **client-first** (CSR), middleware tetap penting: dia nge-gate di edge **sebelum React jalan**, jadi user belum-login nggak sempat lihat shell dashboard. Layout `(app)` (`getSession`) jadi backup, `/api` (`requireAuth`) jadi penjaga data.

---

## 6. Security headers / CSP di middleware (opsional, gabung)

Middleware juga tempat pas untuk inject security header + CSP nonce per-request. Bisa digabung dengan auth gate di atas (tambahkan header ke `NextResponse.next()` / redirect). Pola nonce lengkap → `security.md` §2.

---

## 7. Catatan runtime

- Middleware default **Edge Runtime** → hanya API edge-compatible (`jose` ✅, `bcrypt`/driver Mongo ❌).
- Jaga tetap ringan — dia jalan di **setiap** request yang cocok matcher. Kerja berat = latency ke semua halaman.

---

## Checklist middleware (wajib)

- [ ] Verifikasi sesi pakai `jose` (edge-safe), bukan library node-only
- [ ] Redirect belum-login dari route terproteksi + simpan `next`
- [ ] Matcher exclude `/api`, `_next/*`, asset statis
- [ ] Tidak ada DB / bcrypt / fetch data di middleware
- [ ] Authorization role tetap di `/api` (`requireAuth`) & RSC (`getSession`) — bukan cuma middleware
- [ ] Middleware ringan (no heavy work di edge)
