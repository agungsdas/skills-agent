# Full-stack: MongoDB + Mongoose + API Routes

Pola full-stack Next.js dengan MongoDB (Mongoose). Dipakai kalau backend ada **di dalam Next.js** (Route Handlers).
Semua kode DB adalah **server-only**. Layer tegas: `route.ts` → `repositories/` → `models/` → `lib/db`.

> **Batas akses (penting)**: `repositories/` & `models/` HANYA di-import oleh route handler `/api/*` — **bukan** oleh page, Server Component, Server Action, atau client. Semua konsumen ambil data lewat `/api` (RSC → `serverApi`, client → TanStack Query; lihat `data-layer.md` §0). DB tidak pernah disentuh langsung dari komponen.

Prinsip wajib: connection caching, validasi input (Zod), pagination, index, timestamps, no injection, error handling proper.

---

## 1. Koneksi ter-cache (WAJIB di serverless)

Di serverless/hot-reload, tanpa caching setiap invocation bikin koneksi baru → connection pool exhaust. Cache di `global`.

```ts
// src/lib/db/mongoose.ts
import "server-only";
import mongoose from "mongoose";

const MONGODB_URI = process.env.MONGODB_URI;
if (!MONGODB_URI) throw new Error("MONGODB_URI belum di-set di environment");

interface MongooseCache {
  conn: typeof mongoose | null;
  promise: Promise<typeof mongoose> | null;
}

// Reuse koneksi antar invocation & antar hot-reload di dev
declare global {
  // eslint-disable-next-line no-var
  var _mongooseCache: MongooseCache | undefined;
}

const cached: MongooseCache = global._mongooseCache ?? { conn: null, promise: null };
global._mongooseCache = cached;

export async function dbConnect(): Promise<typeof mongoose> {
  if (cached.conn) return cached.conn;

  if (!cached.promise) {
    cached.promise = mongoose.connect(MONGODB_URI, {
      bufferCommands: false,   // fail fast kalau belum connect
      maxPoolSize: 10,         // tune sesuai beban
      serverSelectionTimeoutMS: 8000,
      autoIndex: process.env.NODE_ENV !== "production", // di prod, build index terpisah
    });
  }

  try {
    cached.conn = await cached.promise;
  } catch (err) {
    cached.promise = null; // reset supaya percobaan berikut bisa reconnect
    throw err;
  }

  return cached.conn;
}
```

> `autoIndex: false` di production: build index lewat script/migration sekali, jangan tiap boot (mahal). Di dev boleh auto.

Script build index (jalankan **sekali** saat deploy — step CI/CD atau `predeploy`, bukan tiap boot):

```ts
// scripts/sync-indexes.ts — jalankan: pnpm tsx scripts/sync-indexes.ts
import "dotenv/config";
import { dbConnect } from "@/lib/db/mongoose";
import { User } from "@/models/user";

async function main() {
  await dbConnect();
  // syncIndexes: buat index yang belum ada + drop index yang sudah tak ada di schema
  await User.syncIndexes();
  // daftarkan model lain: await Post.syncIndexes(); await Order.syncIndexes(); ...
  console.log("Index tersinkron");
  process.exit(0);
}

main().catch((err) => {
  console.error("Gagal sync index:", err);
  process.exit(1);
});
```

> Di collection besar `syncIndexes()` bisa nge-lock saat build — jadwalkan lewat ops (rolling/background), hindari jam sibuk.

---

## 2. Model (schema + index + timestamps)

```ts
// src/models/user.ts
import "server-only";
import { Schema, model, models, type Model, type InferSchemaType } from "mongoose";
import { v7 as uuidv7 } from "uuid"; // pnpm add uuid

const userSchema = new Schema(
  {
    // refId = SATU-SATUNYA ID aplikasi: lookup, relasi, URL /api, response, session.
    // _id (ObjectId) dibiarkan default oleh Mongo TAPI tidak pernah dipakai/diekspos.
    refId: { type: String, default: () => uuidv7(), unique: true, immutable: true, index: true },

    name: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    username: { type: String, unique: true, sparse: true, trim: true }, // admin login (member Google tak punya)
    role: { type: String, enum: ["admin", "manager", "user"], default: "user", index: true },
    passwordHash: { type: String, select: false }, // hanya akun credential (admin); member Google tak punya
    deletedAt: { type: Date, default: null }, // soft delete
  },
  {
    timestamps: true, // createdAt + updatedAt otomatis
    // Jangan bocorkan _id/__v kalau dokumen di-serialize (non-lean)
    toJSON: { versionKey: false, transform: (_doc, ret) => { delete ret._id; return ret; } },
  },
);

// Index sesuai query pattern nyata
userSchema.index({ createdAt: -1 });
userSchema.index({ role: 1, deletedAt: 1 });

// UserDoc pakai refId sebagai identitas; _id tidak dipakai
export type UserDoc = InferSchemaType<typeof userSchema>;

// `models.User ||` mencegah OverwriteModelError saat hot-reload
export const User: Model<UserDoc> = models.User || model<UserDoc>("User", userSchema);
```

Aturan model:
- **`timestamps: true`** di semua schema (`createdAt`/`updatedAt`).
- **Setiap query pattern baru → ada index pendukung.** Jangan biarkan collection scan.
- Field sensitif (`passwordHash`, token) pakai `select: false`.
- **Soft delete** (`deletedAt`) untuk data yang tak boleh hilang permanen.

---

## 3. Repository (satu-satunya tempat akses data)

```ts
// src/repositories/user.ts
import "server-only";
import type { FilterQuery } from "mongoose";
import { dbConnect } from "@/lib/db/mongoose";
import { User, type UserDoc } from "@/models/user";

// Escape input sebelum masuk RegExp — cegah ReDoS / regex injection
function escapeRegExp(input: string): string {
  return input.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

// Duplicate key dari unique index (code 11000). Index unik = penjamin ATOMIK;
// pre-check findOne punya race TOCTOU, jadi INI sumber kebenaran anti-duplikat.
export function isDuplicateKeyError(
  err: unknown,
): err is { code: 11000; keyValue?: Record<string, unknown> } {
  return typeof err === "object" && err !== null && (err as { code?: number }).code === 11000;
}

interface ListParams {
  page: number;
  perPage: number;
  keyword?: string;
  role?: UserDoc["role"];
}

// Lookup & mutasi eksternal SELALU by refId. `_id` di-exclude dari read (tidak diekspos).
export const userRepository = {
  async list({ page, perPage, keyword, role }: ListParams) {
    await dbConnect();

    const filter: FilterQuery<UserDoc> = { deletedAt: null };
    if (role) filter.role = role;
    if (keyword) {
      const safe = new RegExp(escapeRegExp(keyword), "i");
      filter.$or = [{ name: safe }, { email: safe }];
    }

    // Pagination WAJIB — jangan pernah query unbounded
    const [data, total] = await Promise.all([
      User.find(filter)
        .select("-_id -__v") // jangan expose _id
        .sort({ createdAt: -1 })
        .skip((page - 1) * perPage)
        .limit(perPage)
        .lean(),
      User.countDocuments(filter),
    ]);

    return { data, total };
  },

  async findByRefId(refId: string) {
    await dbConnect();
    return User.findOne({ refId, deletedAt: null }).select("-_id -__v").lean();
  },

  // Untuk auth (internal): boleh sertakan passwordHash; hasil tidak diekspos langsung ke client
  async findByIdentifier(identifier: string, opts?: { withPassword?: boolean }) {
    await dbConnect();
    const value = identifier.trim();
    const q = User.findOne({ $or: [{ email: value.toLowerCase() }, { username: value }], deletedAt: null });
    if (opts?.withPassword) q.select("+passwordHash");
    return q.lean();
  },

  async findByEmail(email: string) {
    await dbConnect();
    return User.findOne({ email: email.toLowerCase(), deletedAt: null }).lean();
  },

  async create(input: Pick<UserDoc, "name" | "email" | "role"> & { passwordHash?: string }) {
    await dbConnect();
    const doc = await User.create(input); // refId di-generate otomatis (uuidv7 default)
    const obj = doc.toObject() as Record<string, unknown>;
    delete obj._id;
    delete obj.__v;
    delete obj.passwordHash;
    return obj;
  },

  async update(refId: string, patch: Partial<Pick<UserDoc, "name" | "role">>) {
    await dbConnect();
    // runValidators: true — Mongoose TIDAK jalanin schema validator di findOneAndUpdate secara default
    return User.findOneAndUpdate({ refId, deletedAt: null }, patch, { new: true, runValidators: true })
      .select("-_id -__v")
      .lean();
  },

  async softDelete(refId: string) {
    await dbConnect();
    return User.findOneAndUpdate({ refId, deletedAt: null }, { deletedAt: new Date() }, { new: true, runValidators: true })
      .select("-_id -__v")
      .lean();
  },
};
```

---

## 4. Validasi input (Zod = SSOT tipe)

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

export const listUserQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  perPage: z.coerce.number().int().min(1).max(100).default(20),
  keyword: z.string().trim().max(120).optional(),
  role: z.enum(["admin", "manager", "user"]).optional(),
});
```

> `z.infer` dipakai di client (form RHF) & server (route) → satu sumber kebenaran tipe input.

---

## 5. Response contract + helper

Format konsisten `{ status, message, data, meta }` (selaras dengan backend service lain).

```ts
// src/lib/api/response.ts — helper server. Tipe di-import dari types/api.ts (JANGAN duplikasi)
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

---

## 6. Route Handler (tipis: validasi → auth → repository → response)

```ts
// src/app/api/users/route.ts
import { type NextRequest } from "next/server";
import { userRepository, isDuplicateKeyError } from "@/repositories/user";
import { createUserSchema, listUserQuerySchema } from "@/lib/validations/user";
import { ok, fail, paginated } from "@/lib/api/response";
import { requireAuth } from "@/lib/auth/session";
import { hashPassword } from "@/lib/auth/password";

export async function GET(request: NextRequest) {
  const auth = await requireAuth(request, ["admin", "manager"]);
  if (!auth.ok) return fail(auth.message, auth.status);

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

export async function POST(request: NextRequest) {
  const auth = await requireAuth(request, ["admin"]);
  if (!auth.ok) return fail(auth.message, auth.status);

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return fail("Body JSON tidak valid", 400);
  }

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
    // Unique index = penjamin atomik anti-duplikat (bukan pre-check findOne yang punya race TOCTOU)
    if (isDuplicateKeyError(err)) {
      const field = Object.keys(err.keyValue ?? {})[0] ?? "Data";
      return fail(`${field} sudah terdaftar`, 409);
    }
    console.error("[POST /api/users]", err);
    return fail("Gagal membuat user", 500);
  }
}
```

```ts
// src/app/api/users/[refId]/route.ts  — segmen dinamis = refId (uuidv7), bukan _id
import { type NextRequest } from "next/server";
import { userRepository } from "@/repositories/user";
import { updateUserSchema } from "@/lib/validations/user";
import { ok, fail } from "@/lib/api/response";
import { requireAuth } from "@/lib/auth/session";

export async function GET(request: NextRequest, { params }: { params: Promise<{ refId: string }> }) {
  const auth = await requireAuth(request);
  if (!auth.ok) return fail(auth.message, auth.status);

  const { refId } = await params; // Next.js 15: params adalah Promise
  const user = await userRepository.findByRefId(refId);
  if (!user) return fail("User tidak ditemukan", 404);
  return ok(user);
}

export async function PATCH(request: NextRequest, { params }: { params: Promise<{ refId: string }> }) {
  const auth = await requireAuth(request, ["admin"]);
  if (!auth.ok) return fail(auth.message, auth.status);

  const { refId } = await params;
  const parsed = updateUserSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return fail("Validasi gagal", 422, parsed.error.flatten());

  const updated = await userRepository.update(refId, parsed.data);
  if (!updated) return fail("User tidak ditemukan", 404);
  return ok(updated, "User diperbarui");
}

export async function DELETE(request: NextRequest, { params }: { params: Promise<{ refId: string }> }) {
  const auth = await requireAuth(request, ["admin"]);
  if (!auth.ok) return fail(auth.message, auth.status);

  const { refId } = await params;
  const deleted = await userRepository.softDelete(refId);
  if (!deleted) return fail("User tidak ditemukan", 404);
  return ok(null, "User dihapus");
}
```

> **Next.js 15**: `params` di dynamic route adalah **Promise** — wajib `await`.
> **Identitas di URL = `refId` (uuidv7), bukan `_id`.** Folder route `[refId]` → param `refId`; lookup lewat `findByRefId`.

---

## 7. Transaksi (multi-dokumen atomik)

```ts
import mongoose from "mongoose";
import { dbConnect } from "@/lib/db/mongoose";

export async function transferSaldo(fromRefId: string, toRefId: string, amount: number) {
  await dbConnect();
  const session = await mongoose.startSession();
  try {
    await session.withTransaction(async () => {
      // Filter pakai refId (konvensi app) — konsisten, _id tak pernah dipakai
      await Account.updateOne({ refId: fromRefId }, { $inc: { balance: -amount } }, { session });
      await Account.updateOne({ refId: toRefId }, { $inc: { balance: amount } }, { session });
    });
  } finally {
    await session.endSession(); // selalu cleanup
  }
}
```

---

## 8. Checklist production (wajib)

- [ ] Koneksi ter-cache di `global` (bukan connect per-request)
- [ ] **`refId` (uuidv7) = satu-satunya ID publik** (URL `[refId]`, lookup, response, relasi); `_id` tak pernah dipakai/diekspos
- [ ] `timestamps: true` di semua schema
- [ ] Setiap query pattern punya index pendukung; `autoIndex: false` di prod, build via script `syncIndexes()`
- [ ] Pagination di semua list endpoint — tidak ada query unbounded
- [ ] Input divalidasi Zod sebelum sentuh DB
- [ ] Keyword regex di-escape (anti ReDoS)
- [ ] Field sensitif `select: false`
- [ ] `runValidators: true` di `findOneAndUpdate`/`findOneAndDelete` (Mongoose skip validator di update secara default)
- [ ] Duplicate key (E11000) di-catch → 409; unique index = penjamin atomik (bukan pre-check `findOne` yang punya race TOCTOU)
- [ ] Auth + otorisasi role dicek di setiap protected route
- [ ] Semua handler `try/catch`, error di-log, pesan aman (tak bocorkan internal)
- [ ] Response pakai format konsisten `{ status, message, data, meta }`
- [ ] Soft delete untuk data penting
- [ ] `import "server-only"` di db/models/repositories
- [ ] Repository/model **hanya** di-import route handler `/api/*` — RSC & client ambil data lewat `/api`
