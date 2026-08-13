---
name: nextjs-customer-facing
description: >
  Web customer-facing dengan Next.js App Router: landing page, marketing, pricing, blog, dan halaman
  publik SEO-critical. RSC-first, shadcn/ui + Tailwind, animasi terukur (motion), performa Core Web Vitals.
  Desain WAJIB production-grade, modern, dan tidak AI slop. Use SELALU bareng nextjs-core.
---

# Next.js Customer-Facing (Web Publik)

Track untuk halaman yang **dilihat calon/pengguna publik**: landing, marketing, pricing, blog, halaman produk.
Prioritas: **SEO, performa (Core Web Vitals), dan first impression visual** yang meyakinkan.

> 🔴 WAJIB baca `nextjs-core` dulu (setup, design-principles, data layer, auth). Track ini hanya menambah layer UI/UX customer-facing di atas core.

## Kapan pakai track ini

- Landing page, homepage, halaman marketing/campaign
- Pricing, fitur, about, kontak
- Blog / konten / dokumentasi publik
- Halaman apa pun yang **SEO-critical** dan **publik**

Kalau halaman di balik login & data-heavy (tabel/CRUD/chart) → pakai **`nextjs-dashboard`**.

## Karakter track ini

- **RSC-first (server-first)** — Server Component default; data di-fetch di server via **services** (`postService(serverApi)`) → masuk HTML. SEO & performa nomor satu.
- **Density longgar** — section `py-20 md:py-28`, whitespace generous, tipografi lebih besar.
- **Hero boleh center, konten rata kiri** — hindari "semua ditengahin".
- **Motion terukur** — enhancement, bukan dekorasi; konten tetap terbaca tanpa JS.

## Referensi

Semua di `references/` (dibangun di atas `nextjs-core`):

1. **sections.md** — Section primitive, Hero, Features, LogoCloud, Testimonial, CTA, FAQ (anti-slop, token-based, dark-mode).
2. **pages-seo.md** — RSC data fetching, metadata, `generateMetadata`, OpenGraph, JSON-LD, sitemap/robots, streaming.
3. **animation.md** — `motion` (FadeIn, Stagger, page transition), `prefers-reduced-motion`.
4. **performance.md** — `next/image`, `next/font`, `next/dynamic`, caching, target Core Web Vitals.

## Critical Rules (tambahan atas core)

1. **SEO wajib**: setiap halaman publik punya `title`, `description`, `canonical`, OpenGraph + OG image.
2. **RSC-first**: jangan jadikan seluruh halaman client — membunuh SEO & LCP.
3. **Performa**: gambar via `next/image` (no CLS), LCP `priority`, komponen berat `dynamic()`.
4. **Section konsisten**: pakai `Section`/`SectionHeader` primitive — spacing & hierarki seragam.
5. **`not-found.tsx` & `error.tsx`** didesain, bukan halaman kosong.

## Design Mandate

Ikuti `nextjs-core/references/design-principles.md` sepenuhnya. Untuk customer-facing, ekstra tegas:
- **NOL gradient ungu-biru slop**, nol glassmorphism berlebihan, nol shadow-2xl di kartu.
- Hero bersih + hierarki tipografi kuat + CTA jelas (satu primary).
- Lolos **Definition of Done** desain sebelum selesai. Cek light & dark, responsive 360/768/1280.
