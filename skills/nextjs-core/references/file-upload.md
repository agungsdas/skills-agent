# File Upload — Cloudflare R2 (presigned URL)

Pola default: **presigned URL**. Client minta presigned ke `/api` → **upload byte langsung ke R2** (bukan lewat server kita) → simpan referensi (`key`/URL) via `/api`. Byte besar nggak numpang di server → scalable.

R2 = S3-compatible → pakai `@aws-sdk/client-s3` + `@aws-sdk/s3-request-presigner`.
Install: `pnpm add @aws-sdk/client-s3 @aws-sdk/s3-request-presigner`

> Upload langsung ke R2 itu **pengecualian sah** dari aturan "semua via `/api`": R2 = object storage eksternal, bukan DB kita. Yang lewat `/api` = **minta presigned** + **simpan referensi**. DB tetap hanya di `/api`.

---

## 1. Client R2 (server-only)

```ts
// src/lib/storage/r2.ts
import "server-only";
import { S3Client } from "@aws-sdk/client-s3";

export const r2 = new S3Client({
  region: "auto",
  endpoint: `https://${process.env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: process.env.R2_ACCESS_KEY_ID!,
    secretAccessKey: process.env.R2_SECRET_ACCESS_KEY!,
  },
});

export const R2_BUCKET = process.env.R2_BUCKET_NAME!;
export const R2_PUBLIC_DOMAIN = process.env.R2_PUBLIC_DOMAIN!; // custom domain / <bucket>.r2.dev
```

---

## 2. Route: minta presigned (validasi di server)

```ts
// src/app/api/uploads/presign/route.ts
import { type NextRequest } from "next/server";
import { z } from "zod";
import { PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { r2, R2_BUCKET, R2_PUBLIC_DOMAIN } from "@/lib/storage/r2";
import { requireAuth } from "@/lib/auth/session";
import { ok, fail } from "@/lib/api/response";

const ALLOWED = ["image/jpeg", "image/png", "image/webp"];
const MAX_SIZE = 5 * 1024 * 1024; // 5MB

const presignSchema = z.object({
  filename: z.string().min(1).max(200),
  contentType: z.enum(ALLOWED as [string, ...string[]]),
  size: z.number().int().positive().max(MAX_SIZE),
});

export async function POST(request: NextRequest) {
  const auth = await requireAuth(request);
  if (!auth.ok) return fail(auth.message, auth.status);

  const parsed = presignSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) return fail("File tidak valid (tipe/ukuran)", 422, parsed.error.flatten());

  const { filename, contentType } = parsed.data;
  const safeName = filename.replace(/[^\w.-]/g, "_");
  const key = `uploads/${auth.user.refId}/${crypto.randomUUID()}-${safeName}`; // namespaced per user (refId)

  const uploadUrl = await getSignedUrl(
    r2,
    new PutObjectCommand({ Bucket: R2_BUCKET, Key: key, ContentType: contentType }),
    { expiresIn: 60 }, // presigned singkat
  );

  return ok({ uploadUrl, key, publicUrl: `https://${R2_PUBLIC_DOMAIN}/${key}` });
}
```

---

## 3. Service + client flow

```ts
// src/services/upload.ts
import type { ApiClient } from "@/lib/api/types";

interface PresignInput { filename: string; contentType: string; size: number; }
interface PresignResult { uploadUrl: string; key: string; publicUrl: string; }

export function uploadService(api: ApiClient) {
  return {
    presign: (input: PresignInput) => api.post<PresignResult>("/api/uploads/presign", input),
  };
}
```

```ts
// src/lib/upload.ts  (fungsi biasa, bukan React hook)
"use client";
import { clientApi } from "@/lib/api/client";
import { uploadService } from "@/services/upload";

export async function uploadToR2(file: File): Promise<string> {
  const uploads = uploadService(clientApi);

  // 1) minta presigned ke /api (auth + validasi di server)
  const { data } = await uploads.presign({
    filename: file.name,
    contentType: file.type,
    size: file.size,
  });

  // 2) PUT byte LANGSUNG ke R2 (bukan /api) — Content-Type harus sama dgn saat presign
  const put = await fetch(data.uploadUrl, {
    method: "PUT",
    body: file,
    headers: { "Content-Type": file.type },
  });
  if (!put.ok) throw new Error("Upload gagal");

  // 3) simpan referensi (data.key / data.publicUrl) ke entitas via /api + service terkait
  return data.publicUrl;
}
```

Pakai di komponen: `<input type="file" onChange>` → `uploadToR2(file)` → simpan `publicUrl`/`key` ke entitas (mis. `userService(clientApi).update(id, { avatarUrl })`). Sertakan state loading/error + progress bila perlu.

---

## 4. Public vs private

- **Publik** (avatar, gambar produk) → serve via `R2_PUBLIC_DOMAIN` (custom domain / `r2.dev`).
- **Privat** (dokumen sensitif) → bucket private, generate **presigned GET** (`GetObjectCommand` + `getSignedUrl`) saat baca, expiry pendek. Jangan pakai public domain.

> File kecil & jarang? Boleh upload lewat `/api` (multipart) langsung ke R2 dari server — lebih simpel, tapi byte numpang di server. Presigned tetap default untuk skalabilitas.

---

## Checklist upload (wajib)

- [ ] Presigned URL untuk upload (byte langsung ke R2, tidak numpang server)
- [ ] Validasi **tipe + ukuran** di server (route presign), bukan cuma client
- [ ] Key di-namespace per user + nama file di-sanitasi + `crypto.randomUUID()`
- [ ] Auth dicek di route presign (`requireAuth`)
- [ ] `expiresIn` presigned pendek (mis. 60s)
- [ ] Kredensial R2 (`R2_SECRET_ACCESS_KEY`) server-only, bukan `NEXT_PUBLIC_`
- [ ] File privat → bucket private + presigned GET (jangan public domain)
- [ ] Simpan referensi (`key`/URL) ke DB **via `/api`** setelah upload sukses
