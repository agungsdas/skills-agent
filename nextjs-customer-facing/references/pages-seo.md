# Pages & SEO (RSC-first)

Halaman customer-facing = **SEO-critical**. Prinsip: **Server Component default**, data di-fetch di server, metadata lengkap, structured data, streaming untuk bagian lambat.

---

## 1. RSC-first: data fetching di server

```tsx
// src/app/(marketing)/blog/[slug]/page.tsx
import { notFound } from "next/navigation";
import { getPostBySlug } from "@/services/posts";

// Server Component — async langsung, tanpa useEffect/useState
export default async function BlogPost({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params; // Next 15: params Promise
  const post = await getPostBySlug(slug);
  if (!post) notFound();

  return (
    <article className="mx-auto max-w-3xl px-4 py-16">
      <h1 className="text-4xl font-semibold tracking-tight text-balance">{post.title}</h1>
      <p className="mt-4 text-muted-foreground">{post.excerpt}</p>
      {/* konten */}
    </article>
  );
}
```

Caching data fetch (`fetch` di server):
```ts
// revalidate tiap 1 jam (ISR)
const res = await fetch(url, { next: { revalidate: 3600 } });
// selalu fresh:  { cache: "no-store" }
// tag-based revalidation: { next: { tags: ["posts"] } } → revalidateTag("posts")
```

> `"use client"` hanya untuk bagian interaktif (form, carousel, toggle). Jangan jadikan seluruh page client — itu membunuh SEO & performa.

---

## 2. Static metadata

```tsx
// src/app/(marketing)/page.tsx
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Platform manajemen bisnis all-in-one",
  description: "Otomasi alur kerja, analitik real-time, dan kolaborasi tim dalam satu platform.",
  alternates: { canonical: "/" },
  openGraph: {
    title: "Platform manajemen bisnis all-in-one",
    description: "Otomasi, analitik, kolaborasi — satu platform.",
    url: "/",
    siteName: "MyApp",
    type: "website",
    images: [{ url: "/og/home.png", width: 1200, height: 630 }],
  },
  twitter: { card: "summary_large_image" },
};
```

### Root template & default (di root layout)

```tsx
// src/app/layout.tsx
export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_APP_URL!),
  title: { default: "MyApp", template: "%s | MyApp" },
  description: "...",
};
```

`metadataBase` bikin URL OG/canonical absolut. `template` → judul halaman jadi `Judul | MyApp`.

---

## 3. Dynamic metadata (`generateMetadata`)

```tsx
// src/app/(marketing)/blog/[slug]/page.tsx
import type { Metadata } from "next";
import { getPostBySlug } from "@/services/posts";

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params;
  const post = await getPostBySlug(slug);
  if (!post) return { title: "Tidak ditemukan" };

  return {
    title: post.title,
    description: post.excerpt,
    alternates: { canonical: `/blog/${slug}` },
    openGraph: {
      title: post.title,
      description: post.excerpt,
      type: "article",
      publishedTime: post.publishedAt,
      images: [{ url: post.coverUrl, width: 1200, height: 630 }],
    },
  };
}
```

> Request data (`getPostBySlug`) yang dipakai di `generateMetadata` **dan** page akan otomatis di-dedupe oleh Next (request memoization). Aman dipanggil dua kali.

---

## 4. Structured data (JSON-LD)

```tsx
// src/components/seo/json-ld.tsx
export function JsonLd({ data }: { data: Record<string, unknown> }) {
  return (
    <script
      type="application/ld+json"
      // JSON.stringify aman untuk data terkontrol; jangan masukkan input user mentah
      dangerouslySetInnerHTML={{ __html: JSON.stringify(data) }}
    />
  );
}
```

```tsx
// pemakaian di page
<JsonLd
  data={{
    "@context": "https://schema.org",
    "@type": "Organization",
    name: "MyApp",
    url: process.env.NEXT_PUBLIC_APP_URL,
    logo: `${process.env.NEXT_PUBLIC_APP_URL}/logo.png`,
  }}
/>
```

---

## 5. sitemap & robots

```ts
// src/app/sitemap.ts
import type { MetadataRoute } from "next";
import { getAllPostSlugs } from "@/services/posts";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const base = process.env.NEXT_PUBLIC_APP_URL!;
  const slugs = await getAllPostSlugs();

  const staticRoutes: MetadataRoute.Sitemap = [
    { url: `${base}/`, changeFrequency: "weekly", priority: 1 },
    { url: `${base}/pricing`, changeFrequency: "monthly", priority: 0.8 },
  ];

  const posts: MetadataRoute.Sitemap = slugs.map((slug) => ({
    url: `${base}/blog/${slug}`,
    changeFrequency: "monthly",
    priority: 0.6,
  }));

  return [...staticRoutes, ...posts];
}
```

```ts
// src/app/robots.ts
import type { MetadataRoute } from "next";

export default function robots(): MetadataRoute.Robots {
  const base = process.env.NEXT_PUBLIC_APP_URL!;
  return {
    rules: { userAgent: "*", allow: "/", disallow: ["/admin", "/api"] },
    sitemap: `${base}/sitemap.xml`,
  };
}
```

---

## 6. Streaming (Suspense) untuk bagian lambat

Render shell dulu, stream bagian yang butuh data lambat — LCP cepat, no blocking.

```tsx
import { Suspense } from "react";

export default function Page() {
  return (
    <>
      <Hero />
      <Suspense fallback={<ReviewsSkeleton />}>
        <Reviews /> {/* async Server Component yang fetch lambat */}
      </Suspense>
    </>
  );
}
```

`loading.tsx` di segmen route memberi streaming UI otomatis untuk seluruh halaman.

---

## 7. Halaman status

- `not-found.tsx` → 404 dengan CTA balik ke home (bukan halaman kosong).
- `error.tsx` (`"use client"`) → error boundary dengan tombol `reset()`.

```tsx
// src/app/(marketing)/error.tsx
"use client";
import { Button } from "@/components/ui/button";

export default function Error({ reset }: { error: Error; reset: () => void }) {
  return (
    <div className="mx-auto max-w-md px-4 py-24 text-center">
      <h1 className="text-2xl font-semibold tracking-tight">Ada yang tidak beres</h1>
      <p className="mt-2 text-muted-foreground">Coba muat ulang halaman ini.</p>
      <Button onClick={reset} className="mt-6">Coba lagi</Button>
    </div>
  );
}
```

---

## Checklist SEO/pages (wajib)

- [ ] Server Component default; `"use client"` hanya untuk interaktif
- [ ] `metadataBase` + `title.template` di root
- [ ] Setiap halaman publik punya `title`, `description`, `canonical`
- [ ] OpenGraph + Twitter card + OG image 1200x630
- [ ] `generateMetadata` untuk route dinamis
- [ ] JSON-LD untuk entitas relevan (Organization/Article/Product)
- [ ] `sitemap.ts` + `robots.ts` (disallow `/admin`, `/api`)
- [ ] Data fetch pakai caching tepat (`revalidate`/tags/`no-store`)
- [ ] Streaming/`loading.tsx` untuk bagian lambat
- [ ] `not-found.tsx` & `error.tsx` didesain (bukan kosong)
