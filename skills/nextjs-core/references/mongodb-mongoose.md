# Full-stack: MongoDB + Mongoose — Connection & Repository

Pola full-stack Next.js dengan MongoDB (Mongoose). Backend ada **di dalam Next.js** (Route Handlers).
Semua kode DB adalah **server-only**. Layer tegas: `route.ts` → `repositories/` → `models/` → `lib/db`.

> **Batas akses (penting)**: `repositories/` & `models/` HANYA di-import oleh route handler `/api/*` — **bukan** oleh page, Server Component, Server Action, atau client. Semua konsumen ambil data lewat `/api` (RSC → `serverApi`, client → TanStack Query; lihat `data-layer.md` §0). DB tidak pernah disentuh langsung dari komponen.

**Related references:**
- **`model-design.md`** — schema patterns, field types, refId, timestamps, indexes, soft delete, relasi
- **`api-routes.md`** — Route Handler patterns, auth, Zod validation, response helpers, error handling, CRUD template

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

---

## 2. Repository Pattern

Repository = satu-satunya tempat akses data. Lokasi: `src/repositories/<domain>.ts`.

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

### Repository Rules

1. **`await dbConnect()`** di awal setiap method — jamin koneksi ada.
2. **`.select("-_id -__v")`** di semua read — jangan expose internal fields.
3. **Lookup by `refId`**, bukan `_id` — konsisten dengan URL dan response.
4. **Filter `deletedAt: null`** — soft deleted data tidak muncul di query normal.
5. **`runValidators: true`** di update operations — Mongoose skip validator di update secara default.
6. **Pagination WAJIB** di list — `.skip().limit()` + `countDocuments()`.
7. **Keyword search**: escape regex input (anti ReDoS).
8. **Duplicate key** di-handle via `isDuplicateKeyError()` — bukan pre-check `findOne`.

---

## 3. Transaksi (multi-dokumen atomik)

```ts
import mongoose from "mongoose";
import { dbConnect } from "@/lib/db/mongoose";

export async function transferSaldo(fromRefId: string, toRefId: string, amount: number) {
  await dbConnect();
  const session = await mongoose.startSession();
  try {
    await session.withTransaction(async () => {
      await Account.updateOne({ refId: fromRefId }, { $inc: { balance: -amount } }, { session });
      await Account.updateOne({ refId: toRefId }, { $inc: { balance: amount } }, { session });
    });
  } finally {
    await session.endSession(); // selalu cleanup
  }
}
```

Kapan pakai transaksi:
- Transfer saldo / operasi debit-kredit
- Multi-document update yang harus atomik (all-or-nothing)
- Operasi yang melibatkan 2+ collections dan tidak boleh partial

> MongoDB transactions butuh **replica set** (Atlas sudah default, local dev butuh `mongod --replSet`).

---

## 4. Checklist Production

- [ ] Koneksi ter-cache di `global` (bukan connect per-request)
- [ ] `autoIndex: false` di prod, build via script `syncIndexes()`
- [ ] Repository SELALU lookup by `refId` — `_id` tak pernah dipakai/diekspos
- [ ] `.select("-_id -__v")` di semua read query
- [ ] `runValidators: true` di semua update operations
- [ ] Pagination di semua list — tidak ada query unbounded
- [ ] Keyword regex di-escape (anti ReDoS)
- [ ] Duplicate key (E11000) di-catch → 409
- [ ] `import "server-only"` di db, models, repositories
- [ ] Repository/model **hanya** di-import route handler `/api/*`
- [ ] Transaksi untuk operasi multi-document atomik
- [ ] Filter `deletedAt: null` di semua query normal (soft delete)
