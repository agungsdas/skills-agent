# API Route Handlers — Pattern & Rules

Panduan lengkap untuk menulis Route Handler (`/api/*`) di Next.js App Router. Route handler = satu-satunya tempat yang boleh akses DB (via repository).

Flow: **Request → Route Handler (validasi + auth) → Repository → Response**

---

## 1. Aturan Fundamental

1. **Route handler tipis** — hanya: parse input → validasi (Zod) → auth check → panggil repository → format response. Tidak ada business logic kompleks di sini.
2. **Satu file per resource segment** — `route.ts` di `app/api/<resource>/` (list + create) dan `app/api/<resource>/[refId]/` (detail + update + delete).
3. **Dynamic segment = `[refId]`** (uuidv7), **bukan `[id]`**. Folder route `[refId]` → param `refId`.
4. **Next.js 15: `params` adalah Promise** — wajib `await params`.
5. **Auth check wajib** di setiap protected route — pakai `requireAuth(request, roles?)`.
6. **Validasi input (Zod)** sebelum sentuh DB — `safeParse` + return error kalau gagal.
7. **Response format konsisten**: `{ status, message, data, meta }` via helper `ok()`, `paginated()`, `fail()`.
8. **Error handling**: `try/catch` di setiap handler, error di-log, pesan aman (tidak bocorkan internal).
9. **DB hanya di `/api/*`** — page, RSC, client **tidak boleh** import repository/model.

---

## 2. File Structure

```
src/app/api/
├── auth/
│   ├── login/route.ts
│   ├── logout/route.ts
│   └── register/route.ts
├── users/
│   ├── route.ts              ← GET (list) + POST (create)
│   └── [refId]/
│       └── route.ts          ← GET (detail) + PATCH (update) + DELETE (soft delete)
├── posts/
│   ├── route.ts
│   └── [refId]/
│       └── route.ts
└── uploads/
    └── presign/route.ts
```

---

## 3. Response Helpers

```ts
// src/lib/api/response.ts
import { NextResponse } from "next/server";
import type { ApiResponse } from "@/types/api";

export function ok<T>(data: T, message = "OK", status = 200) {
  return NextResponse.json<ApiResponse<T>>({ status: true, message, data }, { status });
}

export function paginated<T>(
  data: T,
  opts: { page: number; perPage: number; total: number },
  message = "OK",
) {
  const total_page = Math.max(1, Math.ceil(opts.total / opts.perPage));
  return NextResponse.json<ApiResponse<T>>({
    status: true,
    message,
    data,
    meta: { page: opts.page, per_page: opts.perPage, total: opts.total, total_page },
  });
}

export function fail(message: string, status = 400, errors?: unknown) {
  return NextResponse.json<ApiResponse<null>>({ status: false, message, data: null, errors }, { status });
}
```

Response type (shared client & server):

```ts
// src/types/api.ts
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

---

## 4. Validasi Input (Zod)

Lokasi: `src/lib/validations/<domain>.ts`

```ts
// src/lib/validations/user.ts
import { z } from "zod";

export const createUserSchema = z.object({
  name: z.string().trim().min(1, "Nama wajib diisi").max(120),
  email: z.string().trim().email("Email tidak valid"),
  role: z.enum(["admin", "manager", "user"]).default("user"),
  password: z.string().min(8, "Minimal 8 karakter"),
});
export type CreateUserInput = z.infer<typeof createUserSchema>;

export const updateUserSchema = createUserSchema.partial().omit({ password: true });
export type UpdateUserInput = z.infer<typeof updateUserSchema>;

export const listUserQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  perPage: z.coerce.number().int().min(1).max(100).default(20),
  keyword: z.string().trim().max(120).optional(),
  role: z.enum(["admin", "manager", "user"]).optional(),
});
```

Rules:
- `z.infer` → dipakai di client (form react-hook-form) & server (route). Satu sumber kebenaran tipe.
- Query params pakai `z.coerce.number()` karena searchParams selalu string.
- `createSchema.partial()` untuk update (semua field optional).
- `omit({ field: true })` untuk exclude field yang tidak boleh diupdate.

---

## 5. CRUD Template Lengkap

### List + Create (`route.ts`)

```ts
// src/app/api/users/route.ts
import { type NextRequest } from "next/server";
import { userRepository, isDuplicateKeyError } from "@/repositories/user";
import { createUserSchema, listUserQuerySchema } from "@/lib/validations/user";
import { ok, fail, paginated } from "@/lib/api/response";
import { requireAuth } from "@/lib/auth/session";
import { hashPassword } from "@/lib/auth/password";

// ─── LIST ───────────────────────────────────────────────
export async function GET(request: NextRequest) {
  const auth = await requireAuth(request, ["admin", "manager"]);
  if (!auth.ok) return fail(auth.message, auth.status);

  // Parse & validate query params
  const params = Object.fromEntries(new URL(request.url).searchParams);
  const parsed = listUserQuerySchema.safeParse(params);
  if (!parsed.success) return fail("Query tidak valid", 400, parsed.error.flatten());

  try {
    const { page, perPage, keyword, role } = parsed.data;
    const { data, total } = await userRepository.list({ page, perPage, keyword, role });
    return paginated(data, { page, perPage, total });
  } catch (err) {
    console.error("[GET /api/users]", err);
    return fail("Gagal mengambil data user", 500);
  }
}

// ─── CREATE ─────────────────────────────────────────────
export async function POST(request: NextRequest) {
  const auth = await requireAuth(request, ["admin"]);
  if (!auth.ok) return fail(auth.message, auth.status);

  // Parse body — handle malformed JSON
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return fail("Body JSON tidak valid", 400);
  }

  // Validate
  const parsed = createUserSchema.safeParse(body);
  if (!parsed.success) return fail("Validasi gagal", 422, parsed.error.flatten());

  try {
    const { password, ...rest } = parsed.data;
    const created = await userRepository.create({
      ...rest,
      passwordHash: await hashPassword(password),
    });
    return ok(created, "User berhasil dibuat", 201);
  } catch (err) {
    // Unique index = penjamin atomik anti-duplikat (bukan pre-check findOne — race TOCTOU)
    if (isDuplicateKeyError(err)) {
      const field = Object.keys(err.keyValue ?? {})[0] ?? "Data";
      return fail(`${field} sudah terdaftar`, 409);
    }
    console.error("[POST /api/users]", err);
    return fail("Gagal membuat user", 500);
  }
}
```

### Detail + Update + Delete (`[refId]/route.ts`)

```ts
// src/app/api/users/[refId]/route.ts
import { type NextRequest } from "next/server";
import { userRepository } from "@/repositories/user";
import { updateUserSchema } from "@/lib/validations/user";
import { ok, fail } from "@/lib/api/response";
import { requireAuth } from "@/lib/auth/session";

// ─── DETAIL ─────────────────────────────────────────────
export async function GET(request: NextRequest, { params }: { params: Promise<{ refId: string }> }) {
  const auth = await requireAuth(request);
  if (!auth.ok) return fail(auth.message, auth.status);

  const { refId } = await params; // Next.js 15: params adalah Promise
  const user = await userRepository.findByRefId(refId);
  if (!user) return fail("User tidak ditemukan", 404);
  return ok(user);
}

// ─── UPDATE ─────────────────────────────────────────────
export async function PATCH(request: NextRequest, { params }: { params: Promise<{ refId: string }> }) {
  const auth = await requireAuth(request, ["admin"]);
  if (!auth.ok) return fail(auth.message, auth.status);

  const { refId } = await params;

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return fail("Body JSON tidak valid", 400);
  }

  const parsed = updateUserSchema.safeParse(body);
  if (!parsed.success) return fail("Validasi gagal", 422, parsed.error.flatten());

  try {
    const updated = await userRepository.update(refId, parsed.data);
    if (!updated) return fail("User tidak ditemukan", 404);
    return ok(updated, "User diperbarui");
  } catch (err) {
    console.error("[PATCH /api/users]", err);
    return fail("Gagal memperbarui user", 500);
  }
}

// ─── DELETE (soft) ──────────────────────────────────────
export async function DELETE(request: NextRequest, { params }: { params: Promise<{ refId: string }> }) {
  const auth = await requireAuth(request, ["admin"]);
  if (!auth.ok) return fail(auth.message, auth.status);

  const { refId } = await params;

  try {
    const deleted = await userRepository.softDelete(refId);
    if (!deleted) return fail("User tidak ditemukan", 404);
    return ok(null, "User dihapus");
  } catch (err) {
    console.error("[DELETE /api/users]", err);
    return fail("Gagal menghapus user", 500);
  }
}
```

---

## 6. Error Handling Patterns

### HTTP Status Codes

| Status | Kapan | Contoh |
|--------|-------|--------|
| 200 | Success (read, update, delete) | `ok(data)` |
| 201 | Success (create) | `ok(data, "Created", 201)` |
| 400 | Bad request (malformed JSON, invalid query) | `fail("Body JSON tidak valid", 400)` |
| 401 | Unauthorized (no/invalid token) | dari `requireAuth` |
| 403 | Forbidden (role insufficient) | dari `requireAuth` |
| 404 | Not found | `fail("User tidak ditemukan", 404)` |
| 409 | Conflict (duplicate) | `fail("Email sudah terdaftar", 409)` |
| 422 | Validation error (business rule) | `fail("Validasi gagal", 422, errors)` |
| 500 | Internal error | `fail("Gagal...", 500)` |

### Duplicate Key (Unique Index)

```ts
import { isDuplicateKeyError } from "@/repositories/user";

// Di catch block:
if (isDuplicateKeyError(err)) {
  const field = Object.keys(err.keyValue ?? {})[0] ?? "Data";
  return fail(`${field} sudah terdaftar`, 409);
}
```

Utility function:

```ts
// Biasanya di file repository masing-masing
export function isDuplicateKeyError(
  err: unknown,
): err is { code: 11000; keyValue?: Record<string, unknown> } {
  return typeof err === "object" && err !== null && (err as { code?: number }).code === 11000;
}
```

### Error Logging

```ts
// Pattern: [METHOD /api/path] + error object
console.error("[POST /api/users]", err);
```

- Log internal error detail (untuk debugging).
- Response ke client: pesan generik aman, **tidak bocorkan** stack trace atau internal detail.

---

## 7. Auth Pattern di Route

```ts
import { requireAuth } from "@/lib/auth/session";

// Public endpoint (no auth)
export async function GET(request: NextRequest) {
  // tidak ada requireAuth — langsung handle
}

// Protected (any authenticated user)
export async function GET(request: NextRequest) {
  const auth = await requireAuth(request);
  if (!auth.ok) return fail(auth.message, auth.status);
  // auth.user tersedia
}

// Protected + role check
export async function POST(request: NextRequest) {
  const auth = await requireAuth(request, ["admin"]);
  if (!auth.ok) return fail(auth.message, auth.status);
  // hanya admin yang bisa lewat
}

// Owner check (user hanya bisa akses data sendiri)
export async function GET(request: NextRequest, { params }: { params: Promise<{ refId: string }> }) {
  const auth = await requireAuth(request);
  if (!auth.ok) return fail(auth.message, auth.status);

  const { refId } = await params;
  // Admin bisa akses semua, user biasa hanya punya sendiri
  if (auth.user.role !== "admin" && auth.user.refId !== refId) {
    return fail("Akses ditolak", 403);
  }
}
```

---

## 8. Query Params Pattern

```ts
// Parse semua searchParams jadi object
const params = Object.fromEntries(new URL(request.url).searchParams);

// Validate dengan Zod (coerce string → number/boolean)
const parsed = listQuerySchema.safeParse(params);
if (!parsed.success) return fail("Query tidak valid", 400, parsed.error.flatten());
```

Schema untuk list endpoints:

```ts
// Pattern reusable
const paginationSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  perPage: z.coerce.number().int().min(1).max(100).default(20),
});

const sortSchema = z.object({
  sort: z.enum(["createdAt", "updatedAt", "name"]).default("createdAt"),
  order: z.enum(["asc", "desc"]).default("desc"),
});

// Gabungkan per domain
export const listPostQuerySchema = paginationSchema.merge(sortSchema).extend({
  keyword: z.string().trim().max(120).optional(),
  status: z.enum(["draft", "published", "archived"]).optional(),
  authorRefId: z.string().optional(),
});
```

---

## 9. Endpoint tanpa Auth (Public API)

```ts
// src/app/api/posts/public/route.ts — public list (misal: blog posts)
import { type NextRequest } from "next/server";
import { postRepository } from "@/repositories/post";
import { publicListSchema } from "@/lib/validations/post";
import { fail, paginated } from "@/lib/api/response";

export async function GET(request: NextRequest) {
  // Tidak ada requireAuth — public endpoint
  const params = Object.fromEntries(new URL(request.url).searchParams);
  const parsed = publicListSchema.safeParse(params);
  if (!parsed.success) return fail("Query tidak valid", 400, parsed.error.flatten());

  try {
    const { page, perPage, tag } = parsed.data;
    const { data, total } = await postRepository.listPublished({ page, perPage, tag });
    return paginated(data, { page, perPage, total });
  } catch (err) {
    console.error("[GET /api/posts/public]", err);
    return fail("Gagal mengambil data", 500);
  }
}
```

---

## 10. Nested Resource

```ts
// src/app/api/workspaces/[refId]/members/route.ts
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ refId: string }> }
) {
  const auth = await requireAuth(request);
  if (!auth.ok) return fail(auth.message, auth.status);

  const { refId: workspaceRefId } = await params;

  // Verify user has access to workspace
  const hasAccess = await memberRepository.isMember(workspaceRefId, auth.user.refId);
  if (!hasAccess) return fail("Akses ditolak", 403);

  const members = await memberRepository.listByWorkspace(workspaceRefId);
  return ok(members);
}
```

---

## 11. Checklist Route Handler

Sebelum route handler dianggap selesai:

- [ ] Auth check (`requireAuth`) di setiap protected route
- [ ] Role check spesifik (jangan default "all roles can access")
- [ ] Body parsing di-wrap `try/catch` (handle malformed JSON)
- [ ] Input divalidasi Zod (`safeParse`) — jangan langsung trust
- [ ] `await params` (Next.js 15 Promise pattern)
- [ ] Dynamic segment pakai `[refId]` bukan `[id]`
- [ ] Response pakai helper (`ok`, `paginated`, `fail`) — format konsisten
- [ ] Error di-`catch`, di-log dengan context `[METHOD /api/path]`, response aman
- [ ] Duplicate key (E11000) di-handle → 409
- [ ] Not found case di-handle → 404
- [ ] Pagination di list endpoint — tidak ada query unbounded
- [ ] Tidak ada business logic kompleks di route (delegasi ke repository/service)
- [ ] File hanya import dari `@/repositories`, `@/lib/validations`, `@/lib/api/response`, `@/lib/auth`
