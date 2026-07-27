# Performance — Core Web Vitals

Target: **LCP < 2.5s · INP < 200ms · CLS < 0.1**. Halaman customer-facing = revenue-critical, performa wajib dijaga.

---

## 1. Image (`next/image`)

Mencegah CLS + otomatis optimize (AVIF/WebP, responsive).

```tsx
import Image from "next/image";

// Hero image (LCP) → priority
<Image src="/hero.png" alt="Dashboard produk" width={1200} height={630} priority className="rounded-xl border" />

// Fill dalam container ber-aspect-ratio → tak ada CLS
<div className="relative aspect-video overflow-hidden rounded-xl border">
  <Image src={cover} alt="" fill sizes="(max-width: 768px) 100vw, 50vw" className="object-cover" />
</div>
```

Aturan:
- **`priority`** hanya untuk gambar LCP (hero). Sisanya lazy default.
- Selalu isi `width/height` atau `fill` + container beraspek → **no layout shift**.
- `sizes` akurat supaya browser ambil resolusi tepat.
- Remote image → daftarkan `images.remotePatterns` di `next.config.ts`.

```ts
// next.config.ts
images: {
  remotePatterns: [{ protocol: "https", hostname: "cdn.example.com" }],
  formats: ["image/avif", "image/webp"],
},
```

---

## 2. Font (`next/font`)

Geist sudah self-hosted via `next/font` (lihat `nextjs-core/references/setup.md`) → no FOUT, no CLS, no request ke Google. Jangan `<link>` font eksternal manual.

---

## 3. Code splitting (`next/dynamic`)

Komponen client berat (chart, editor, modal berat) → dynamic import, jangan bebani bundle awal.

```tsx
import dynamic from "next/dynamic";

const HeavyChart = dynamic(() => import("@/components/heavy-chart"), {
  loading: () => <ChartSkeleton />,
});

// Komponen yang cuma jalan di browser (akses window) → matikan SSR
const MapWidget = dynamic(() => import("@/components/map-widget"), { ssr: false });
```

> Jangan `ssr: false` untuk konten SEO-penting. Pakai hanya untuk widget interaktif non-kritikal.

---

## 4. Prioritas RSC + payload kecil

- Server Component default → JS ke browser minimal. Dorong `"use client"` ke daun (komponen kecil), bukan di root page.
- Fetch data di server (RSC), kirim HTML jadi — bukan fetch di client setelah mount.
- Hindari import barrel besar; import per-modul supaya tree-shaking maksimal.

---

## 5. Caching & prefetch

- `<Link>` Next otomatis prefetch route di viewport → navigasi instan.
- Data fetch: pilih `revalidate` (ISR) / tag / `no-store` sesuai kebutuhan (lihat `pages-seo.md`).
- Aset statis di `public/` di-cache agresif oleh CDN.

---

## 6. Bundle analysis

```bash
pnpm add -D @next/bundle-analyzer
```

```ts
// next.config.ts
import withBundleAnalyzer from "@next/bundle-analyzer";
const analyze = withBundleAnalyzer({ enabled: process.env.ANALYZE === "true" });
export default analyze(nextConfig);
```

Jalankan: `ANALYZE=true pnpm build` → cek chunk gede yang bisa di-split/lazy.

---

## Checklist performance (wajib)

- [ ] Semua gambar via `next/image` dengan `width/height`/`fill` → no CLS
- [ ] Gambar LCP `priority`; sisanya lazy
- [ ] Font via `next/font` (self-hosted)
- [ ] Komponen client berat di-`dynamic()` dengan skeleton
- [ ] `"use client"` didorong ke daun, bukan root page
- [ ] Data fetch di server dengan strategi cache yang tepat
- [ ] `remotePatterns` + `formats` AVIF/WebP di `next.config`
- [ ] Cek bundle sebelum rilis besar (`ANALYZE=true`)
- [ ] Target LCP<2.5s / INP<200ms / CLS<0.1 terpenuhi
