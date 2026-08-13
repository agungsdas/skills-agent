# Data Layer — TanStack Query + Fetcher + Redux Toolkit

Pembagian state **tegas**:
- **Server state** (data dari `/api`) → **TanStack Query** (client). Bukan Redux, bukan `useEffect` manual.
- **Global client state** (UI global, preferensi) → **Redux Toolkit** (diciutkan, seperlunya).
- **Form state** → react-hook-form (lihat dashboard track).
- **Local UI state** → `useState`/`useReducer`.

Ini menghapus pola lama `useEffect` + `setLoading` manual (rawan race condition, boilerplate).

Install: `pnpm add @tanstack/react-query @reduxjs/toolkit react-redux`

---

## 0. Aturan akses data — `/api` via services layer

Dua aturan wajib:
1. **DB (Mongoose/repository) HANYA diakses di dalam Route Handler `/api/*`.** Tidak ada page/RSC/Server Action/komponen client yang query DB langsung.
2. **Komponen & hook tidak memanggil URL `/api` langsung** — semua lewat **services layer** (transport-agnostic). Ini yang bikin backend bisa dipindah (Next `/api` → Go) tanpa nyentuh komponen.

| Konteks | Cara ambil data |
|---------|-----------------|
| **Client** (filter tabel, mutation) | `userService(clientApi)` + TanStack Query |
| **RSC / Server Action** (initial, SEO) | `await userService(serverApi).list()` |
| **DB** | hanya di `/api/*` route handler → repository |

Seam-nya — `ApiClient`, `clientApi`, `serverApi`, service factory, endpoints, + cerita migrasi ke Go — ada di **`services.md`**. `fetcher` (§2) = transport HTTP low-level yang dipakai `clientApi`.

> `/api` = satu-satunya backend → logika & auth terpusat. RSC menembak `/api`-nya sendiri = 1 hop server-to-server (diterima). Base URL via env → pindah ke Go = ganti env + endpoint di `services/`, komponen tetap.

**Server Actions? Tidak dipakai sebagai default.** Mutasi lewat Route Handler `/api` + `services` + `useMutation` (client), supaya `/api` tetap satu-satunya gerbang & portable. Server Actions cuma boleh untuk form progressive-enhancement, dan **tetap** lewat service — **jangan** colok DB langsung dari action (itu langgar "DB only in `/api`").

---

## 1. Tipe response (SSOT tipe)

```ts
// src/types/api.ts  — satu definisi, dipakai client & server
export interface Meta {
  page: number;
  per_page: number;
  total: number;
  total_page: number;
}

export interface ApiResponse<T> {
  status: boolean;
  message: string;
  data: T;
  meta?: Meta;
  errors?: unknown;
}
```

> `lib/api/response.ts` (server) meng-import tipe ini juga — jangan duplikasi definisi.

Tipe domain = bentuk yang dikembalikan `/api` (tanpa `_id`/field sensitif). Identitas selalu `refId`:

```ts
// src/types/user.ts — dipakai service, hook, tabel, form (SSOT bentuk User di client)
export interface User {
  refId: string; // uuidv7 — identitas publik; _id tak pernah diekspos
  name: string;
  email: string;
  role: "admin" | "manager" | "user";
  createdAt: string; // ISO string (Date ter-serialisasi JSON)
  updatedAt: string;
}
```

---

## 2. Fetcher (client HTTP)

```ts
// src/lib/fetcher.ts
import type { ApiResponse } from "@/types/api";

export class ApiError extends Error {
  constructor(
    public status: number,
    message: string,
    public errors?: unknown,
  ) {
    super(message);
    this.name = "ApiError";
  }
}

interface FetcherOptions extends RequestInit {
  params?: Record<string, string | number | boolean | undefined>;
}

export async function fetcher<T>(path: string, options: FetcherOptions = {}): Promise<ApiResponse<T>> {
  const { params, headers, ...rest } = options;

  // Base sama dgn serverApi → portable (pindah ke Go = cukup ganti NEXT_PUBLIC_API_URL)
  const base =
    process.env.NEXT_PUBLIC_API_URL ??
    (typeof window === "undefined" ? process.env.NEXT_PUBLIC_APP_URL! : window.location.origin);
  const url = new URL(path, base);
  if (params) {
    for (const [k, v] of Object.entries(params)) {
      if (v !== undefined) url.searchParams.set(k, String(v));
    }
  }

  const res = await fetch(url, {
    ...rest,
    credentials: "same-origin", // cookie sesi httpOnly ikut otomatis
    headers: { "Content-Type": "application/json", ...headers },
  });

  const json = (await res.json().catch(() => null)) as ApiResponse<T> | null;

  if (!res.ok || !json?.status) {
    throw new ApiError(res.status, json?.message ?? "Permintaan gagal", json?.errors);
  }
  return json;
}
```

> API route sendiri (same-origin) → cookie httpOnly terkirim otomatis, tak perlu attach token manual. Untuk **backend eksternal**, tambahkan header `Authorization` dari cookie server-side (lihat `auth.md` §6).

---

## 3. QueryProvider

```tsx
// src/components/providers/query-provider.tsx
"use client";

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { useState, type ReactNode } from "react";

export function QueryProvider({ children }: { children: ReactNode }) {
  const [client] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 60_000, // 1 menit — kurangi refetch berlebihan
            retry: 1,
            refetchOnWindowFocus: false,
          },
        },
      }),
  );

  return <QueryClientProvider client={client}>{children}</QueryClientProvider>;
}
```

Komposisi provider di root layout:

```tsx
// src/app/layout.tsx (bagian provider)
<ThemeProvider attribute="class" defaultTheme="system" enableSystem disableTransitionOnChange>
  <StoreProvider>
    <QueryProvider>
      {children}
      <Toaster richColors position="top-right" />
    </QueryProvider>
  </StoreProvider>
</ThemeProvider>
```

---

## 4. Query hooks (server state)

Query key factory biar invalidation konsisten & bebas typo.

```ts
// src/hooks/use-users.ts
"use client";

import { useQuery, useMutation, useQueryClient, keepPreviousData } from "@tanstack/react-query";
import { toast } from "sonner";
import { clientApi } from "@/lib/api/client";
import { userService, type ListUserParams } from "@/services/user";
import { ApiError } from "@/lib/fetcher";
import type { CreateUserInput } from "@/lib/validations/user";

const users = userService(clientApi); // transport client; endpoint & tipe dari services/user.ts

export const userKeys = {
  all: ["users"] as const,
  list: (params: ListUserParams) => [...userKeys.all, "list", params] as const,
  detail: (refId: string) => [...userKeys.all, "detail", refId] as const,
};

export function useUsers(params: ListUserParams) {
  return useQuery({
    queryKey: userKeys.list(params),
    queryFn: () => users.list(params),
    placeholderData: keepPreviousData, // pagination tanpa flicker
  });
}

export function useUser(refId: string) {
  return useQuery({
    queryKey: userKeys.detail(refId),
    queryFn: () => users.detail(refId),
    enabled: Boolean(refId),
  });
}

export function useCreateUser() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: CreateUserInput) => users.create(input),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: userKeys.all });
      toast.success("User berhasil dibuat");
    },
    onError: (err) => toast.error(err instanceof ApiError ? err.message : "Gagal membuat user"),
  });
}

export function useDeleteUser() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (refId: string) => users.remove(refId),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: userKeys.all });
      toast.success("User dihapus");
    },
    onError: (err) => toast.error(err instanceof ApiError ? err.message : "Gagal menghapus"),
  });
}
```

Komponen tinggal konsumsi — loading/error/data sudah dikelola:

```tsx
const { data, isLoading, isError, refetch } = useUsers({ page, perPage: 20, keyword });
if (isLoading) return <TableSkeleton />;
if (isError) return <ErrorState onRetry={refetch} />;
if (!data?.data.length) return <EmptyState />;
// render data.data + data.meta untuk pagination
```

> Handle 4 state (loading/error/empty/success) sesuai `design-principles.md`.

---

## 5. Redux Toolkit (global client state SAJA)

Hanya untuk state UI global yang lintas komponen. **Bukan** untuk server data. Tema pakai `next-themes` (jangan simpan di Redux).

```ts
// src/store/slices/ui-slice.ts
import { createSlice, type PayloadAction } from "@reduxjs/toolkit";

interface UiState {
  sidebarCollapsed: boolean;
}

const initialState: UiState = { sidebarCollapsed: false };

const uiSlice = createSlice({
  name: "ui",
  initialState,
  reducers: {
    toggleSidebar: (s) => {
      s.sidebarCollapsed = !s.sidebarCollapsed;
    },
    setSidebar: (s, action: PayloadAction<boolean>) => {
      s.sidebarCollapsed = action.payload;
    },
  },
});

export const { toggleSidebar, setSidebar } = uiSlice.actions;
export default uiSlice.reducer;
```

```ts
// src/store/index.ts
import { configureStore } from "@reduxjs/toolkit";
import uiReducer from "./slices/ui-slice";

export const makeStore = () =>
  configureStore({
    reducer: { ui: uiReducer },
  });

export type AppStore = ReturnType<typeof makeStore>;
export type RootState = ReturnType<AppStore["getState"]>;
export type AppDispatch = AppStore["dispatch"];
```

```ts
// src/store/hooks.ts
import { useDispatch, useSelector, useStore } from "react-redux";
import type { AppDispatch, AppStore, RootState } from "@/store";

export const useAppDispatch = useDispatch.withTypes<AppDispatch>();
export const useAppSelector = useSelector.withTypes<RootState>();
export const useAppStore = useStore.withTypes<AppStore>();
```

```tsx
// src/store/store-provider.tsx  — store per-request (pola App Router)
"use client";

import { useRef, type ReactNode } from "react";
import { Provider } from "react-redux";
import { makeStore, type AppStore } from "@/store";

export function StoreProvider({ children }: { children: ReactNode }) {
  const storeRef = useRef<AppStore | null>(null);
  if (!storeRef.current) storeRef.current = makeStore();
  return <Provider store={storeRef.current}>{children}</Provider>;
}
```

> Butuh persist preferensi UI (mis. sidebar)? Tambah `redux-persist` **hanya untuk slice UI**. Jangan persist server data atau tema.

---

## 6. Aturan (wajib)

- [ ] **DB hanya di `/api/*`**; akses data via **services layer** (`userService(clientApi)` di client, `userService(serverApi)` di RSC) — bukan URL `/api` langsung, bukan query DB
- [ ] Server data via TanStack Query (client) / `serverApi` (RSC) — bukan `useEffect` manual, bukan Redux
- [ ] Query key pakai factory (konsisten, invalidation aman)
- [ ] Mutation → `invalidateQueries` + feedback `sonner`
- [ ] Pagination pakai `placeholderData: keepPreviousData`
- [ ] Error di-handle via `ApiError`; komponen render 4 state
- [ ] Redux hanya global client state; tema di `next-themes`
- [ ] Tipe `ApiResponse<T>` satu sumber di `types/api.ts`
