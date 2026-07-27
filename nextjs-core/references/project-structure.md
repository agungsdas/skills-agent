# Project Structure — Full-stack Next.js (App Router + MongoDB)

Struktur fondasi yang dipakai **kedua track** (`nextjs-customer-facing` & `nextjs-dashboard`).
Semua file TypeScript (`.ts`/`.tsx`). Styling: Tailwind v4 + shadcn. Backend opsional: Route Handlers + MongoDB (Mongoose).

> Track menambah folder spesifik di atas fondasi ini (web: `sections/`, `banners/`; dashboard: `data-table/`, app shell). Lihat masing-masing track.

## Root

```
my-app/
├── src/
│   ├── app/                  # App Router (routes, api, layout)
│   ├── components/           # React components
│   │   ├── ui/               # shadcn/ui — OWNED (hasil `shadcn add`)
│   │   ├── commons/          # shared: mode-toggle, page-header, dll
│   │   ├── providers/        # theme-provider, query-provider
│   │   └── forms/            # form components (RHF + zod)
│   ├── lib/
│   │   ├── utils.ts          # cn() + util murni
│   │   ├── db/               # koneksi MongoDB (Mongoose) — server only
│   │   ├── api/              # ApiClient seam: types.ts, client.ts, server.ts, response.ts
│   │   ├── auth/             # helper auth (session, verify)
│   │   ├── validations/      # Zod schemas (SSOT tipe input)
│   │   └── fetcher.ts        # HTTP client (client → /api)
│   ├── models/               # Mongoose models — server only
│   ├── repositories/         # data access layer — server only
│   ├── services/             # seam API: endpoint + tipe per domain (transport-agnostic; client & server)
│   ├── hooks/                # custom hooks (termasuk TanStack Query)
│   ├── store/                # Redux Toolkit — global client state SAJA
│   ├── constants/            # enum & konstanta
│   ├── types/                # shared TypeScript types
│   └── middleware.ts         # auth/redirect edge middleware
├── public/
├── .env.local
├── components.json           # config shadcn
├── next.config.ts
├── tsconfig.json
└── package.json
```

> Catatan Tailwind v4: **tidak ada `tailwind.config.ts`** — konfigurasi via `@theme` di `src/app/globals.css`.

## App Directory

```
src/app/
├── (public)/                 # route group publik (auth, dll)
│   └── login/ page.tsx
├── (app)/                    # route group ter-proteksi
│   ├── layout.tsx            # shell (sidebar/header) + guard
│   └── .../page.tsx
├── api/                      # Route Handlers (full-stack)
│   └── <resource>/
│       ├── route.ts          # GET (list), POST (create)
│       └── [id]/route.ts     # GET, PATCH, DELETE
├── layout.tsx                # Root layout (ThemeProvider, fonts)
├── globals.css               # Tailwind v4 + token (SSOT warna)
├── loading.tsx               # skeleton global
├── error.tsx                 # error boundary ('use client')
├── not-found.tsx
├── robots.ts
└── sitemap.ts
```

## Layer Full-stack (kalau backend di Next.js)

Pemisahan tegas biar `route.ts` tipis & testable:

```
Request → app/api/*/route.ts   (validasi input Zod, auth, HTTP)
              ↓
         repositories/*         (query MongoDB via model)
              ↓
         models/*               (Mongoose schema)
              ↓
         lib/db                 (koneksi ter-cache)
```

- **`route.ts`**: parse + validasi (Zod), cek auth, panggil repository, map ke response format. TIDAK query DB langsung.
- **`repositories/`**: satu-satunya tempat akses data. Fungsi murni terhadap model.
- **`models/`**: Mongoose schema + index + timestamps.
- **`lib/db`**: koneksi global ter-cache (wajib di serverless). Lihat `mongodb-mongoose.md`.

> **Aturan akses data**: `repositories/` & `models/` HANYA di-import dari `app/api/*`. Page / Server Component / Server Action & client **tidak** import repository — mereka ambil data lewat `/api` via **services layer** (`userService(serverApi)` di server, `userService(clientApi)` + TanStack Query di client). DB tak pernah disentuh langsung dari komponen. Lihat `data-layer.md` §0 & `services.md`.

> Kalau app hanya consume backend eksternal (mis. service Go), `models/` & `repositories/` tidak dipakai — cukup `services/` + `lib/fetcher.ts` (tetap lewat HTTP, bukan DB langsung).

## Components

```
src/components/
├── ui/                       # shadcn (jangan taruh logic domain di sini)
├── commons/                  # ModeToggle, PageHeader, EmptyState, ErrorState
├── providers/                # ThemeProvider, QueryProvider
├── forms/                    # LoginForm, <Entity>Form (RHF + zod)
└── <domain>/                 # komponen spesifik domain
```

- Server Component **default**. Tambah `"use client"` hanya kalau butuh interaktivitas/hook browser.
- Komponen `ui/` = presentational primitive; jangan campur fetch/logic domain.

## Naming Conventions

| Item | Konvensi | Contoh |
|------|----------|--------|
| File komponen | kebab-case | `mode-toggle.tsx`, `user-form.tsx` |
| Nama komponen | PascalCase | `ModeToggle`, `UserForm` |
| Hook | camelCase + `use` | `use-users.ts` → `useUsers` |
| Route/segment | kebab-case | `app/user-management/` |
| Model (Mongoose) | PascalCase singular | `User`, `Invoice` |
| Zod schema | camelCase + `Schema` | `createUserSchema` |
| Konstanta | UPPER_SNAKE_CASE | `API_BASE_URL` |
| Type/Interface | PascalCase | `UserDTO`, `ApiResponse<T>` |

## Path Alias

`@/*` → `src/*`:

```ts
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { userRepository } from "@/repositories/user";
import { createUserSchema } from "@/lib/validations/user";
import type { ApiResponse } from "@/types/api";
```

## State: pembagian tegas

- **Server state** (data dari `/api`) → **TanStack Query** (client, `hooks/`) atau **`serverApi`** (RSC). Bukan Redux.
- **Global client state** (session user, tema, UI global) → **Redux Toolkit** (`store/`).
- **Form state** → **react-hook-form** (lokal ke form).
- **Local UI state** → `useState`/`useReducer`.

Jangan menyimpan server data di Redux — itu sumber stale state & boilerplate.
Server data selalu dari `/api` — DB tidak diakses langsung dari komponen (lihat `data-layer.md` §0).
