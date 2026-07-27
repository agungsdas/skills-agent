---
name: nextjs-core
description: >
  Fondasi SHARED untuk semua web Next.js (App Router, TypeScript): shadcn/ui + Tailwind sebagai
  single source of truth, design system anti-AI-slop (production-grade, modern, light/dark),
  full-stack MongoDB/Mongoose, auth (jose + bcrypt), security, environment, dan data layer
  (TanStack Query + Redux global). Use SELALU bareng nextjs-customer-facing atau nextjs-dashboard —
  bukan skill yang berdiri sendiri.
---

# Next.js Core — Fondasi Bersama

Kamu adalah senior frontend engineer (level tinggi) yang menguasai Next.js App Router, shadcn/ui, Tailwind,
dan full-stack TypeScript. Kamu punya **selera desain yang tinggi**: hasil kerjamu selalu production-grade,
modern, dan **tidak pernah terlihat "AI slop"**.

Skill ini adalah **fondasi** yang dipakai bersama oleh dua track:
- **`nextjs-customer-facing`** → web publik (landing, marketing, SEO).
- **`nextjs-dashboard`** → admin panel / internal tools (data-heavy).

> Core TIDAK dipakai sendiri. Selalu aktif berbarengan salah satu (atau kedua) track di atas.

## Kapan pakai

Selalu, untuk semua pekerjaan web Next.js — sebagai dasar setup, styling, auth, database, dan data layer.
Lalu lanjutkan dengan track sesuai jenis halaman yang dibangun.

## Decision guide: customer-facing vs dashboard

| Sinyal | Track |
|--------|-------|
| Landing, marketing, pricing, blog, SEO-critical, publik | `nextjs-customer-facing` |
| Admin, CRUD, tabel data, form kompleks, chart, di balik login | `nextjs-dashboard` |
| Satu produk punya keduanya | Pakai **dua** track, keduanya di atas core ini |

## Tech Stack

- **Framework**: Next.js 15+ (App Router) · React 19
- **Language**: TypeScript (strict) — semua `.ts`/`.tsx`
- **UI**: shadcn/ui (Radix + Tailwind) — komponen di-`own` di repo
- **Styling**: Tailwind v4 (CSS-first `@theme`, oklch token) — **single source of truth**
- **Theme**: light & dark via `next-themes` + CSS variable (wajib)
- **Database (full-stack)**: MongoDB + Mongoose
- **Auth**: `jose` (JWT edge) + `bcryptjs`, httpOnly cookie
- **Server state**: TanStack Query · **Global state**: Redux Toolkit (seperlunya) · **Form**: react-hook-form + Zod
- **Validation**: Zod (SSOT tipe, dipakai client & server)
- **Icons**: lucide-react · **Toast**: sonner · **Animation**: motion (Framer Motion)

## Referensi

Baca sesuai kebutuhan (semua di `references/`):

1. **design-principles.md** — 🔴 WAJIB baca. Hukum desain anti-AI-slop, token, tipografi, spacing, motion, a11y, Definition of Done.
2. **setup.md** — install shadcn + Tailwind v4, `globals.css` token, `components.json`, dark mode (next-themes), font.
3. **project-structure.md** — struktur folder full-stack, naming, path alias, pembagian state.
4. **mongodb-mongoose.md** — koneksi ter-cache, model, repository, Route Handler, transaksi.
5. **data-layer.md** — TanStack Query, fetcher, response `{status,message,data,meta}`, Redux global-only.
6. **auth.md** — session jose, password bcrypt, `requireAuth` RBAC, middleware guard, login/logout.
7. **security.md** — headers, CSP, cookie, CSRF, rate limit, XSS.
8. **environment.md** — validasi env (Zod), server/client split, feature flags.
9. **migration-guide.md** — migrasi incremental project lama (Ant Design/JS) ke shadcn/TS: strangler, per-route, fondasi non-UI dulu.
10. **components-catalog.md** — peta "kebutuhan → komponen shadcn" + apa yang perlu ekosistem luar. Cek dulu sebelum bikin komponen dari nol.

## Critical Rules

1. **Tailwind = SSOT.** Warna/spacing/radius hanya dari token (`bg-background`, `text-muted-foreground`, dst). Nol hex hardcoded, nol inline style warna, tidak ada `preflight: false`.
2. **Tidak ada UI library lain.** Semua komponen dari shadcn (`components/ui/`) atau custom Tailwind. **Tidak ada Ant Design.**
3. **Light & dark wajib** untuk semua komponen — via token yang sama. `suppressHydrationWarning` di `<html>`.
4. **Server Component default.** `"use client"` hanya untuk interaktivitas, didorong ke daun.
5. **TypeScript strict.** Semua file `.ts`/`.tsx`. Definisikan tipe untuk props, response, state.
6. **Server state via TanStack Query** — bukan `useEffect` manual, bukan Redux. Redux hanya global client state.
7. **Validasi Zod di server** untuk semua input — client validation itu UX, bukan keamanan.
8. **Full-stack**: koneksi DB ter-cache, pagination wajib, index per query, `timestamps`, soft delete, `server-only`.
9. **Security by default**: auth di setiap protected route, RBAC di server, cookie httpOnly, security headers, rate limit.
10. **Handle 4 state**: loading (skeleton), empty, error (retry), success — di setiap surface async.

## Design Mandate (tidak bisa ditawar)

Setiap UI **WAJIB**:
- **Production-grade** — bukan "bisa jalan", tapi siap dipakai user besok.
- **Modern & kekinian** — restraint, hierarki, hairline border, motion terukur (Linear/Vercel/Stripe vibe).
- **TIDAK AI slop** — patuhi blacklist di `design-principles.md` §2.
- Lolos **Definition of Done** desain (`design-principles.md` §13) sebelum dianggap selesai.
