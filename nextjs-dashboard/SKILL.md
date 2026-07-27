---
name: nextjs-dashboard
description: >
  Admin dashboard & internal tools dengan Next.js App Router: data table (TanStack Table), form kompleks
  (react-hook-form + Zod), app shell/sidebar, chart, dan RBAC. Data-heavy, di balik login. shadcn/ui +
  Tailwind, full-stack MongoDB. Desain WAJIB production-grade, modern, tidak AI slop. Use SELALU bareng nextjs-core.
---

# Next.js Dashboard (Admin / Internal Tools)

Track untuk halaman **di balik login** yang **data-heavy**: admin panel, back-office, internal tools, CRUD.
Prioritas: **kepadatan informasi, kecepatan kerja, dan keterbacaan** — tanpa mengorbankan estetika.

> 🔴 WAJIB baca `nextjs-core` dulu (setup, design-principles, data layer, auth, MongoDB). Track ini menambah layer UI/UX dashboard di atas core.

## Kapan pakai track ini

- Admin panel / back-office / internal tools
- Tabel data dengan sorting, filter, pagination
- Form CRUD kompleks + validasi
- Dashboard analitik / chart / KPI
- Apa pun yang **di balik autentikasi** dengan **RBAC**

Kalau halaman publik & SEO-critical (landing/marketing) → pakai **`nextjs-customer-facing`**.

## Karakter track ini

- **Density kompak** — `text-sm`, baris tabel rapat, tapi tetap ada napas & terbaca.
- **App shell** — sidebar collapsible + header sticky (shadcn Sidebar).
- **Server-side pagination** — data besar dipaginasi di server (nyambung repository/API `{data,meta}`).
- **RBAC** — nav & aksi difilter per role; enforcement tetap di server.

## Referensi

Semua di `references/` (dibangun di atas `nextjs-core`):

1. **data-table.md** — DataTable reusable (TanStack Table), server-side pagination, toolbar search, row actions, state loading/empty/error.
2. **forms.md** — react-hook-form + Zod + shadcn Form, pola CRUD Dialog, error server per-field.
3. **app-shell.md** — layout terproteksi, Sidebar, header, RBAC nav, user menu + logout.
4. **charts.md** — KPI StatCard, shadcn Chart (Recharts), warna dari token `--chart-*`.

## Critical Rules (tambahan atas core)

1. **Pagination server-side** untuk tabel — jangan load semua data ke client.
2. **Tabel wajib** punya loading (skeleton baris), empty, dan error (retry) state.
3. **Aksi destruktif** (hapus) lewat `AlertDialog` konfirmasi.
4. **Form**: schema Zod sama dengan server; submit disabled saat pending; error per-field via `form.setError`.
5. **RBAC**: nav difilter per role (UX), tapi keamanan di-enforce di server (`requireAuth`/`getSession`).
6. **Layout `(app)` di-guard** di server (redirect kalau tak ada sesi).

## Design Mandate

Ikuti `nextjs-core/references/design-principles.md` sepenuhnya. Untuk dashboard, ekstra tegas:
- **Density kompak tapi rapi** — bukan berantakan; spacing & alignment tetap disiplin.
- Hairline border > shadow tebal; warna via token; chart pakai `--chart-*`.
- Setiap tabel/form/chart lolos **Definition of Done** (4 state, a11y, light+dark, responsive) sebelum selesai.
