# Model Design — Mongoose Schema Patterns

Panduan lengkap untuk mendesain Mongoose schema/model di Next.js full-stack. Model = satu-satunya definisi bentuk data di DB.

Lokasi: `src/models/<domain>.ts` — **selalu `import "server-only"`**.

---

## 1. Aturan Fundamental

1. **`refId` (uuidv7) = satu-satunya ID publik.** Dipakai di URL, response, relasi antar model, dan session. `_id` (ObjectId) dibiarkan default oleh Mongo tapi **tidak pernah dipakai/diekspos**.
2. **`timestamps: true`** di semua schema — otomatis `createdAt` + `updatedAt`.
3. **Setiap query pattern → ada index pendukung.** Tidak boleh collection scan di production.
4. **Field sensitif** pakai `select: false` — tidak ikut default query.
5. **Soft delete** (`deletedAt`) untuk data yang tidak boleh hilang permanen.
6. **`models.X || model()`** — cegah `OverwriteModelError` saat hot-reload.
7. **`toJSON` transform** — strip `_id` dan `__v` otomatis.

---

## 2. Template Model Dasar

```ts
// src/models/user.ts
import "server-only";
import { Schema, model, models, type Model, type InferSchemaType } from "mongoose";
import { v7 as uuidv7 } from "uuid"; // pnpm add uuid

const userSchema = new Schema(
  {
    // ─── Identity ───────────────────────────────────────
    refId: { type: String, default: () => uuidv7(), unique: true, immutable: true, index: true },

    // ─── Domain Fields ──────────────────────────────────
    name: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    username: { type: String, unique: true, sparse: true, trim: true },
    role: { type: String, enum: ["admin", "manager", "user"], default: "user", index: true },

    // ─── Sensitive (select: false) ──────────────────────
    passwordHash: { type: String, select: false },

    // ─── Soft Delete ────────────────────────────────────
    deletedAt: { type: Date, default: null },
  },
  {
    timestamps: true,
    toJSON: { versionKey: false, transform: (_doc, ret) => { delete ret._id; return ret; } },
  },
);

// ─── Indexes (sesuai query pattern) ─────────────────────
userSchema.index({ createdAt: -1 });
userSchema.index({ role: 1, deletedAt: 1 });

// ─── Export ─────────────────────────────────────────────
export type UserDoc = InferSchemaType<typeof userSchema>;
export const User: Model<UserDoc> = models.User || model<UserDoc>("User", userSchema);
```

---

## 3. Field Patterns

### Identity

```ts
refId: { type: String, default: () => uuidv7(), unique: true, immutable: true, index: true },
```

- Generate otomatis — caller tidak perlu kirim.
- `immutable: true` — sekali set, tidak bisa diubah.
- Semua lookup, relasi, dan URL pakai `refId`, **bukan `_id`**.

### String Fields

```ts
name:     { type: String, required: true, trim: true },                    // required + trim
email:    { type: String, required: true, unique: true, lowercase: true, trim: true }, // unique + lowercase
slug:     { type: String, unique: true, sparse: true, trim: true },        // optional unique (sparse)
bio:      { type: String, maxlength: 500, default: "" },                   // optional with max
status:   { type: String, enum: ["active", "inactive", "suspended"], default: "active", index: true },
```

### Number Fields

```ts
price:    { type: Number, required: true, min: 0 },
quantity: { type: Number, default: 0, min: 0 },
order:    { type: Number, default: 0, index: true },  // sort order
```

### Boolean Fields

```ts
isActive:   { type: Boolean, default: true, index: true },
isVerified: { type: Boolean, default: false },
```

### Date Fields

```ts
publishedAt: { type: Date, default: null, index: true },  // nullable date
expiresAt:   { type: Date, index: { expireAfterSeconds: 0 } },  // TTL index
deletedAt:   { type: Date, default: null },  // soft delete
```

### Array Fields

```ts
tags:        { type: [String], default: [] },
permissions: { type: [String], enum: ["read", "write", "admin"], default: ["read"] },
```

### Nested Object (subdocument)

```ts
address: {
  type: new Schema({
    street: { type: String, required: true },
    city:   { type: String, required: true },
    zip:    { type: String },
  }, { _id: false }),  // _id: false untuk subdocument (tidak perlu ObjectId)
  required: false,
},
```

### Relasi (reference via refId, bukan ObjectId)

```ts
// Relasi pakai refId (string) — bukan ObjectId ref. Lookup manual via repository.
authorRefId:    { type: String, required: true, index: true },
workspaceRefId: { type: String, required: true, index: true },
```

> **JANGAN pakai `ref` + `populate()`** di project ini. Relasi lewat `refId` string, lookup di repository layer. Alasan: portable ke backend lain, explicit, dan tidak ada N+1 yang tersembunyi.

### Sensitive Fields

```ts
passwordHash: { type: String, select: false },   // auth only
resetToken:   { type: String, select: false },   // one-time use
apiKey:       { type: String, select: false },   // credential
```

---

## 4. Index Strategy

### Rules

1. **Setiap field yang di-`find()` atau `sort()` → harus ada index.**
2. **Compound index** kalau query sering filter gabungan.
3. **`sparse: true`** untuk unique index pada optional field (cegah duplicate null).
4. **TTL index** untuk data ephemeral (session, OTP, cache).
5. **`autoIndex: false` di production** — build index lewat `syncIndexes()` script.

### Contoh

```ts
// Single field
userSchema.index({ email: 1 });              // exact match
userSchema.index({ createdAt: -1 });         // sort descending

// Compound (filter + sort)
postSchema.index({ workspaceRefId: 1, createdAt: -1 });  // list posts per workspace
postSchema.index({ authorRefId: 1, status: 1 });          // posts by author + status

// Unique sparse (optional field)
userSchema.index({ username: 1 }, { unique: true, sparse: true });

// TTL (auto-delete setelah X detik)
otpSchema.index({ createdAt: 1 }, { expireAfterSeconds: 300 }); // 5 menit

// Text search
postSchema.index({ title: "text", content: "text" });
```

### Build Index di Production

```ts
// scripts/sync-indexes.ts — jalankan: pnpm tsx scripts/sync-indexes.ts
import "dotenv/config";
import { dbConnect } from "@/lib/db/mongoose";
import { User } from "@/models/user";
import { Post } from "@/models/post";

async function main() {
  await dbConnect();
  await User.syncIndexes();
  await Post.syncIndexes();
  // ... tambahkan model lain
  console.log("Index tersinkron");
  process.exit(0);
}

main().catch((err) => {
  console.error("Gagal sync index:", err);
  process.exit(1);
});
```

---

## 5. Soft Delete Pattern

```ts
// Di schema:
deletedAt: { type: Date, default: null },

// Di repository — SELALU filter deletedAt: null
const filter: FilterQuery<UserDoc> = { deletedAt: null, ...otherFilters };

// Soft delete operation
async softDelete(refId: string) {
  return User.findOneAndUpdate(
    { refId, deletedAt: null },
    { deletedAt: new Date() },
    { new: true, runValidators: true }
  ).select("-_id -__v").lean();
}
```

Kapan pakai soft delete:
- User accounts
- Documents / content
- Data yang butuh audit trail
- Apapun yang mungkin perlu di-restore

Kapan pakai hard delete:
- Data ephemeral (OTP, reset token — pakai TTL index)
- Cache entries
- Temporary upload records

---

## 6. Model dengan Relasi

Contoh: Post belongs to User (author) dan Workspace.

```ts
// src/models/post.ts
import "server-only";
import { Schema, model, models, type Model, type InferSchemaType } from "mongoose";
import { v7 as uuidv7 } from "uuid";

const postSchema = new Schema(
  {
    refId: { type: String, default: () => uuidv7(), unique: true, immutable: true, index: true },

    // Relasi via refId — bukan ObjectId populate
    authorRefId:    { type: String, required: true, index: true },
    workspaceRefId: { type: String, required: true, index: true },

    title:   { type: String, required: true, trim: true, maxlength: 255 },
    slug:    { type: String, required: true, trim: true },
    content: { type: String, default: "" },
    status:  { type: String, enum: ["draft", "published", "archived"], default: "draft", index: true },
    tags:    { type: [String], default: [] },

    publishedAt: { type: Date, default: null },
    deletedAt:   { type: Date, default: null },
  },
  {
    timestamps: true,
    toJSON: { versionKey: false, transform: (_doc, ret) => { delete ret._id; return ret; } },
  },
);

// Compound indexes sesuai query pattern
postSchema.index({ workspaceRefId: 1, status: 1, createdAt: -1 });
postSchema.index({ authorRefId: 1, createdAt: -1 });
postSchema.index({ workspaceRefId: 1, slug: 1 }, { unique: true }); // slug unik per workspace

export type PostDoc = InferSchemaType<typeof postSchema>;
export const Post: Model<PostDoc> = models.Post || model<PostDoc>("Post", postSchema);
```

### Lookup Relasi di Repository

```ts
// src/repositories/post.ts
async findByRefId(refId: string) {
  await dbConnect();
  const post = await Post.findOne({ refId, deletedAt: null }).select("-_id -__v").lean();
  if (!post) return null;

  // Lookup author (explicit, no hidden N+1)
  const author = await User.findOne({ refId: post.authorRefId, deletedAt: null })
    .select("refId name email -_id")
    .lean();

  return { ...post, author };
}
```

---

## 7. Domain Type (Client-Side)

Model (server) → response → Domain type (client). Type ini yang dipakai di services, hooks, tabel, form.

```ts
// src/types/post.ts — SSOT bentuk Post di client
export interface Post {
  refId: string;
  authorRefId: string;
  workspaceRefId: string;
  title: string;
  slug: string;
  content: string;
  status: "draft" | "published" | "archived";
  tags: string[];
  publishedAt: string | null;
  createdAt: string;
  updatedAt: string;
  author?: { refId: string; name: string; email: string };  // populated dari lookup
}
```

> Domain type = bentuk yang dikembalikan `/api` (tanpa `_id`, tanpa field `select: false`). Identitas selalu `refId`.

---

## 8. Checklist Model Design

Sebelum model dianggap selesai:

- [ ] `import "server-only"` di file model
- [ ] `refId` field dengan `default: () => uuidv7()`, `unique`, `immutable`, `index`
- [ ] `timestamps: true` di schema options
- [ ] `toJSON` transform yang strip `_id` dan `__v`
- [ ] `models.X || model()` pattern (cegah hot-reload error)
- [ ] `deletedAt` field untuk data yang butuh soft delete
- [ ] Field sensitif pakai `select: false`
- [ ] Index untuk setiap query pattern yang akan dipakai
- [ ] Compound index untuk filter gabungan yang sering
- [ ] `sparse: true` di unique index untuk optional fields
- [ ] Relasi pakai `refId` string (bukan ObjectId ref/populate)
- [ ] Enum values didefinisikan di schema (`enum: [...]`)
- [ ] Domain type (client-side) yang match dengan response shape
- [ ] Tidak ada `_id` atau `__v` yang terekspos ke client
