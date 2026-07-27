# Services Layer — API Seam (client + server, portable)

**Tujuan:** semua endpoint (path + tipe request/response) didefinisikan di **satu tempat** (`services/<domain>`).
Komponen, hook, dan RSC **tidak pernah** memanggil URL `/api` langsung — mereka lewat service.

Kenapa penting:
- **Transport-agnostic** → satu service jalan di **client maupun server** (inject `ApiClient`).
- **Portable** → pindah backend (Next `/api` → Go) = ganti **base URL (env)** + endpoint di `services/` + transport auth. **Komponen/hook/RSC tidak berubah.**
- Menegakkan aturan: **DB hanya di `/api/*`**; sisanya lewat `/api` via service.

```
Komponen / Hook / RSC
        │  (panggil service, bukan URL /api langsung)
        ▼
   services/<domain>        ← definisi endpoint + tipe (SEKALI, transport-agnostic)
        │  (pakai ApiClient yang di-inject)
        ├── clientApi  → fetcher (browser)                → /api
        └── serverApi  → fetch + forward cookie (RSC)     → /api
                                                              │
                                                     Route Handler /api/* → repository → DB
```

---

## 1. `ApiClient` — kontrak transport (tanpa runtime import → aman client & server)

```ts
// src/lib/api/types.ts
import type { ApiResponse } from "@/types/api";

export interface ApiRequestOptions {
  params?: Record<string, string | number | boolean | undefined>;
  signal?: AbortSignal;
  cache?: RequestCache;
  next?: { revalidate?: number | false; tags?: string[] };
  headers?: Record<string, string>;
}

export interface ApiClient {
  get<T>(path: string, opts?: ApiRequestOptions): Promise<ApiResponse<T>>;
  post<T>(path: string, body?: unknown, opts?: ApiRequestOptions): Promise<ApiResponse<T>>;
  patch<T>(path: string, body?: unknown, opts?: ApiRequestOptions): Promise<ApiResponse<T>>;
  delete<T>(path: string, opts?: ApiRequestOptions): Promise<ApiResponse<T>>;
}
```

---

## 2. `clientApi` — transport browser (pakai `fetcher`, lihat `data-layer.md` §2)

```ts
// src/lib/api/client.ts
import { fetcher } from "@/lib/fetcher";
import type { ApiClient } from "./types";

// Browser → same-origin /api; cookie httpOnly ikut otomatis (credentials same-origin).
export const clientApi: ApiClient = {
  get: (path, opts) => fetcher(path, { method: "GET", ...opts }),
  post: (path, body, opts) =>
    fetcher(path, { method: "POST", body: body === undefined ? undefined : JSON.stringify(body), ...opts }),
  patch: (path, body, opts) =>
    fetcher(path, { method: "PATCH", body: body === undefined ? undefined : JSON.stringify(body), ...opts }),
  delete: (path, opts) => fetcher(path, { method: "DELETE", ...opts }),
};
```

---

## 3. `serverApi` — transport server (RSC / Server Action, server-only)

Di server: butuh **absolute URL** & cookie **tidak** ikut otomatis → forward manual per request.

```ts
// src/lib/api/server.ts
import "server-only";
import { cookies } from "next/headers";
import type { ApiClient, ApiRequestOptions } from "./types";
import type { ApiResponse } from "@/types/api";

const BASE = process.env.NEXT_PUBLIC_API_URL ?? process.env.NEXT_PUBLIC_APP_URL!;

async function request<T>(
  method: string,
  path: string,
  body?: unknown,
  opts: ApiRequestOptions = {},
): Promise<ApiResponse<T>> {
  const { params, headers, ...rest } = opts;
  const url = new URL(path, BASE); // absolute URL WAJIB di server
  if (params) {
    for (const [k, v] of Object.entries(params)) {
      if (v !== undefined) url.searchParams.set(k, String(v));
    }
  }

  const res = await fetch(url, {
    method,
    body: body === undefined ? undefined : JSON.stringify(body),
    headers: {
      "Content-Type": "application/json",
      cookie: (await cookies()).toString(), // forward sesi user ke /api
      ...headers,
    },
    ...rest, // cache / next (ISR) / signal
  });

  const json = (await res.json().catch(() => null)) as ApiResponse<T> | null;
  if (!res.ok || !json?.status) throw new Error(json?.message ?? "Request gagal");
  return json;
}

export const serverApi: ApiClient = {
  get: (p, o) => request("GET", p, undefined, o),
  post: (p, b, o) => request("POST", p, b, o),
  patch: (p, b, o) => request("PATCH", p, b, o),
  delete: (p, o) => request("DELETE", p, undefined, o),
};
```

---

## 4. Service per domain (transport-agnostic — hanya import **type**)

```ts
// src/services/user.ts
import type { ApiClient, ApiRequestOptions } from "@/lib/api/types";
import type { User } from "@/types/user";
import type { CreateUserInput, UpdateUserInput } from "@/lib/validations/user";

// Endpoint terdefinisi SEKALI di sini. Pindah ke Go? Ubah path di sini + base URL (env).
export const USER_ENDPOINTS = {
  base: "/api/users",
  byRefId: (refId: string) => `/api/users/${refId}`, // refId = uuidv7, bukan _id
} as const;

export interface ListUserParams {
  page: number;
  perPage: number;
  keyword?: string;
  role?: string;
}

// Terima ApiClient → jalan di client (clientApi) MAUPUN server (serverApi).
export function userService(api: ApiClient) {
  return {
    // Read menerima opts (mis. { next: { revalidate } }) untuk caching/ISR saat dipakai di RSC
    list: (params: ListUserParams, opts?: ApiRequestOptions) =>
      api.get<User[]>(USER_ENDPOINTS.base, { params, ...opts }),
    detail: (refId: string, opts?: ApiRequestOptions) => api.get<User>(USER_ENDPOINTS.byRefId(refId), opts),
    create: (input: CreateUserInput) => api.post<User>(USER_ENDPOINTS.base, input),
    update: (refId: string, input: UpdateUserInput) => api.patch<User>(USER_ENDPOINTS.byRefId(refId), input),
    remove: (refId: string) => api.delete<null>(USER_ENDPOINTS.byRefId(refId)),
  };
}
```

> Service **tidak boleh** import `next/headers` atau akses `window` — cukup `ApiClient`. Itu yang bikin dia jalan di dua sisi.

### Contoh lain: `authService`

```ts
// src/services/auth.ts
import type { ApiClient } from "@/lib/api/types";
import type { SessionUser } from "@/lib/auth/session";
import type { LoginInput, RegisterInput } from "@/lib/validations/auth";

export const AUTH_ENDPOINTS = {
  login: "/api/auth/login",
  logout: "/api/auth/logout",
  register: "/api/auth/register",
} as const;

export function authService(api: ApiClient) {
  return {
    login: (input: LoginInput) => api.post<SessionUser>(AUTH_ENDPOINTS.login, input),
    logout: () => api.post<null>(AUTH_ENDPOINTS.logout),
    register: (input: RegisterInput) => api.post<SessionUser>(AUTH_ENDPOINTS.register, input),
  };
}
```

Pola sama untuk domain lain (`postService`, `orderService`, …): endpoint + tipe selalu di `services/<domain>`.

---

## 5. Pemakaian

### Client (hook + TanStack Query) — dominan di dashboard

```ts
// src/hooks/use-users.ts
"use client";
import { useQuery } from "@tanstack/react-query";
import { clientApi } from "@/lib/api/client";
import { userService, type ListUserParams } from "@/services/user";

const users = userService(clientApi); // transport client

export const userKeys = {
  all: ["users"] as const,
  list: (p: ListUserParams) => [...userKeys.all, "list", p] as const,
};

export function useUsers(params: ListUserParams) {
  return useQuery({ queryKey: userKeys.list(params), queryFn: () => users.list(params) });
}
```

### Server (RSC / Server Action) — dominan di customer-facing (SEO)

```tsx
// Server Component
import { serverApi } from "@/lib/api/server";
import { userService } from "@/services/user";

export default async function UsersPage() {
  const { data } = await userService(serverApi).list({ page: 1, perPage: 20 });
  // ter-render di server → SEO aman
}
```

Service-nya **sama persis** — cuma transport-nya beda (`clientApi` vs `serverApi`).

---

## 6. Migrasi Next `/api` → Go (kenapa seam ini worth)

Saat backend pindah ke Go, yang berubah **hanya**:
1. **Base URL** → set `NEXT_PUBLIC_API_URL` ke domain Go.
2. **Endpoint** (kalau path beda, mis. `/v1/users`) → edit `USER_ENDPOINTS` di `services/`.
3. **Auth transport** → Go biasanya `Authorization: Bearer`, bukan cookie → sesuaikan `clientApi`/`serverApi` (attach token; lihat `auth.md` §6).

**Yang TIDAK berubah:** hook, komponen, tabel, form, RSC page. Itulah gunanya seam.

---

## 7. Aturan (wajib)

- [ ] Komponen/hook/RSC **tidak** memanggil URL `/api` langsung — selalu via `services/<domain>`
- [ ] Endpoint path + tipe didefinisikan **sekali** di service (`*_ENDPOINTS` + factory)
- [ ] Service **transport-agnostic**: import **type** `ApiClient` saja; tak ada `next/headers`/`window`
- [ ] `clientApi` untuk client, `serverApi` untuk RSC/Server Action
- [ ] Base URL via env (`NEXT_PUBLIC_API_URL`) → portable ke backend lain
- [ ] DB tetap **hanya** di `/api/*` route handler (lihat `mongodb-mongoose.md`)
