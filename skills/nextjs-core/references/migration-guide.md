# Migration Guide — dari Ant Design/JS ke shadcn/TS

Panduan migrasi project lama (Next.js + Ant Design + JavaScript) ke stack baru (shadcn/ui + Tailwind SSOT + TypeScript + full-stack).

**Prinsip utama: JANGAN big-bang rewrite.** Pakai pendekatan **strangler** — adopsi fondasi non-UI dulu (murah, aman), migrasi UI paling akhir per-fitur. Project yang sudah stabil & jarang disentuh → **biarkan**; skill baru untuk yang greenfield & yang aktif dikembangkan.

---

## 1. Assessment dulu: perlu migrasi atau tidak?

Migrasi **worth** hanya kalau ada minimal satu:

- [ ] Project **masih aktif dikembangkan** (bukan maintenance-only)
- [ ] Ada **pain nyata**: maintain antd + Tailwind barengan, `preflight:false`, bundle besar, theming ribet
- [ ] Sudah ada rencana **redesign / rewrite besar** → sekalian
- [ ] Kebutuhan bisnis: **konsistensi lintas produk**
- [ ] Dependency **kejebak** (nggak kompatibel React 19, isu security)

Kalau **tidak ada** satupun → jangan migrasi UI. Maksimal adopsi fondasi non-UI (Fase 1) sebagai standar ke depan.

---

## 2. Peta fase (urutan low-risk → high-risk)

| Fase | Isi | Sentuh antd? | Risiko |
|------|-----|--------------|--------|
| 0 | Audit & baseline | Tidak | — |
| 1 | Fondasi non-UI (data layer, Zod, auth, security, env) | Tidak | Rendah |
| 2 | Upgrade versi + setup Tailwind v4/shadcn (koeksistensi) | Sedikit | Sedang |
| 3 | Migrasi UI per-fitur (antd → shadcn) | Ya | Tinggi |
| 4 | Buang antd + cleanup | Ya | Sedang |

Kerjakan berurutan. Tiap fase bisa di-ship terpisah (PR kecil, mudah rollback).

---

## 3. Fase 0 — Audit & baseline

- Catat versi: Next (14?), React (18?), Tailwind (v3?), TS coverage (banyak `.js`?).
- Inventaris komponen antd yang dipakai (`Table`, `Form`, `Modal`, `DatePicker`, dll) + frekuensinya.
- Inventaris pola data fetching (`useEffect` manual? Redux nyimpen server data?).
- **Baseline test**: minimal smoke test / QA checklist per halaman kritikal → jadi jaring pengaman sebelum ngoprek.

---

## 4. Fase 1 — Fondasi non-UI (quick win, TANPA sentuh antd)

Ini bisa diadopsi sambil UI antd tetap jalan. High value, low risk.

**a. Data fetching: `useEffect` manual → TanStack Query** (lihat `data-layer.md`)

```tsx
// ❌ SEBELUM (rawan race condition, no cancel)
const [data, setData] = useState([]);
const [loading, setLoading] = useState(true);
useEffect(() => {
  setLoading(true);
  fetch("/api/users").then(r => r.json()).then(d => { setData(d.data); setLoading(false); });
}, [keyword]);

// ✅ SESUDAH — cache, dedupe, cancel, retry otomatis
const { data, isLoading } = useUsers({ page, perPage: 20, keyword });
```

**b. Response format `{status,message,data,meta}` + `fetcher`** — standarkan (lihat `data-layer.md`).
**c. Validasi Zod** — schema jadi SSOT tipe, dipakai client & server (lihat `mongodb-mongoose.md`).
**d. Auth/session pattern, security headers, env validation** — adopsi dari `auth.md`, `security.md`, `environment.md`.

> Fase 1 tidak mengubah tampilan sama sekali — cuma benerin arsitektur data & keamanan. Aman di-ship duluan.

---

## 5. Fase 2 — Upgrade versi + setup shadcn (koeksistensi)

**a. Upgrade versi** (pakai codemod resmi):
- Next 14 → 15: `params`/`searchParams` jadi **Promise** (wajib `await`); `cookies()`/`headers()` async.
- React 18 → 19: hapus `forwardRef` (ref jadi prop biasa).
- Tailwind v3 → v4: CSS-first `@theme`, oklch, `tw-animate-css` (`npx @tailwindcss/upgrade`).

**b. Setup shadcn** mengikuti `setup.md` (components.json, globals.css token, `next-themes`).

**c. ⚠️ Masalah koeksistensi antd + Tailwind (preflight).**
shadcn butuh **preflight (base reset) ON**; antd butuh **OFF** (biar reset-nya nggak nabrak style antd). Dua-duanya di satu app itu konflik nyata.

Solusi selama transisi (Tailwind v4) — import layer **tanpa preflight** dulu:

```css
/* globals.css — SELAMA antd masih ada: skip preflight */
@layer theme, base, components, utilities;
@import "tailwindcss/theme.css" layer(theme);
/* @import "tailwindcss/preflight.css" layer(base);  <- SENGAJA dimatikan dulu */
@import "tailwindcss/utilities.css" layer(utilities);
@import "tw-animate-css";
```

Konsekuensi: sebagian komponen shadcn mungkin butuh penyesuaian kecil karena base reset belum aktif. Ini **kompromi sementara** — bukan kondisi akhir.

> **Rekomendasi kuat**: jangan campur antd + shadcn **dalam satu halaman**. Migrasi **per-route / per-route-group** utuh. Satu halaman = satu design system.

---

## 6. Fase 3 — Migrasi UI per-fitur

Urutan: **leaf component dulu** (Button, Input, Badge) → **composite** (Form, Table) → **halaman utuh** → **route group**.

Peta komponen lengkap ada di `setup.md` §9. Gotcha penting per komponen:

**Form: antd `Form` → react-hook-form + shadcn (lihat dashboard track `forms.md`)**
```tsx
// ❌ antd
<Form onFinish={onFinish}>
  <Form.Item name="email" rules={[{ required: true, type: "email" }]}>
    <Input />
  </Form.Item>
</Form>

// ✅ RHF + Zod — validasi jadi schema (SSOT client+server)
const form = useForm({ resolver: zodResolver(userFormSchema) });
<Form {...form}><form onSubmit={form.handleSubmit(onSubmit)}>
  <FormField name="email" control={form.control} render={({ field }) => (
    <FormItem><FormLabel>Email</FormLabel><FormControl><Input {...field} /></FormControl><FormMessage /></FormItem>
  )} />
</form></Form>
```

**Table: antd `Table` (`dataSource`/`columns`) → TanStack Table** (lihat dashboard track `data-table.md`). Sorting/filter/pagination antd yang built-in → jadi eksplisit (server-side pagination direkomendasikan).

**Feedback & overlay:**
- `message.success()` / `notification` → `toast()` dari **sonner**.
- `Modal` (imperatif `Modal.confirm`) → `Dialog` (controlled `open` state) / `AlertDialog` untuk konfirmasi destruktif.
- `Drawer` → `Sheet`. `Popconfirm` → `AlertDialog`.
- `Select` (`<Option>` children) → shadcn `Select` (`<SelectItem>`), `onChange` → `onValueChange`.
- `DatePicker` → `Calendar` + `Popover`.

**Gotcha umum**: antd komponen sering **uncontrolled + imperatif**; shadcn cenderung **controlled + eksplisit**. Siapkan state (`open`, `value`) yang tadinya di-handle antd internal.

---

## 7. State & Theming

- **Server data di Redux → TanStack Query.** Redux disisakan cuma untuk global client state (lihat `data-layer.md`).
- **antd Form state → react-hook-form.**
- **Theming**: `ConfigProvider` token + `darkAlgorithm` → **CSS variables oklch + `next-themes`** (`.dark`). Warna primary yang tadinya `colorPrimary` → `--primary` di `globals.css`.
- **Dark mode**: buang mekanisme antd, pakai `next-themes` (satu sumber).

---

## 8. JavaScript → TypeScript (incremental)

- Aktifkan `allowJs: true` + `strict: true` di `tsconfig` → `.js` lama tetap jalan.
- Rename per-file `.js` → `.tsx`/`.ts` saat file itu disentuh (jangan sekaligus).
- Tambah tipe props, response (`ApiResponse<T>`), dan state. Prioritaskan file yang lagi dimigrasikan UI-nya.

---

## 9. Fase 4 — Buang antd + cleanup

Setelah semua route migrasi:
- Hapus dependency: `antd`, `@ant-design/icons`, `@ant-design/nextjs-registry`, `AntdRegistry` di layout.
- **Aktifkan kembali preflight**: kembalikan `globals.css` ke `@import "tailwindcss";` penuh (lihat `setup.md` §4).
- Hapus CSS/override khusus antd, `corePlugins.preflight:false` (kalau masih ada dari v3).
- Verifikasi: `grep -ri "antd\|ant-design"` → harus nol.

---

## 10. Checklist per fitur yang dimigrasi (Definition of Done)

Sebuah fitur/halaman dianggap selesai migrasi kalau:
- [ ] Fungsionalitas **paritas** dengan versi antd (nggak ada fitur hilang)
- [ ] 4 state: loading (skeleton), empty, error (retry), success
- [ ] Light **dan** dark mode rapi (token, bukan style antd)
- [ ] Responsive 360/768/1280
- [ ] Keyboard + focus ring; kontras AA
- [ ] Lolos `design-principles.md` (nol AI slop)
- [ ] Test / QA baseline dari Fase 0 masih hijau
- [ ] Tidak ada import antd tersisa di route ini

---

## 11. Anti-pattern saat migrasi

- ❌ **Big-bang rewrite** semua sekaligus → risiko regresi masif, susah rollback.
- ❌ Campur **antd + shadcn dalam satu halaman** (permanen) → dua design system, konflik preflight.
- ❌ Migrasi UI **sebelum** ada baseline test/QA → nggak ketahuan kalau ada yang rusak.
- ❌ Migrasi tapi **server data tetap di Redux + useEffect** → setengah jalan, tetap warisin masalah lama.
- ❌ Rewrite project **stabil yang jarang disentuh** tanpa alasan bisnis → buang waktu.

> Aturan emas: **PR kecil, per-route, reversible.** Kalau satu route bermasalah, gampang di-rollback tanpa nyeret yang lain.
