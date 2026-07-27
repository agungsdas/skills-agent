# Landing Sections — Modern, Production, Zero Slop

Komponen section untuk halaman customer-facing (landing, marketing, product).
Semua patuh `nextjs-core/references/design-principles.md`: token-based, hairline border > shadow, tipografi berhierarki, dark-mode otomatis, responsive, a11y.

Prinsip khusus web:
- **Server Component default** — section statis tidak butuh `"use client"`.
- **Lega** (density longgar): section `py-20 md:py-28`, container `max-w-6xl`.
- **Hero boleh center; section konten rata kiri** (hindari "semua ditengahin").
- Motion opsional & terukur (lihat `animation.md`) — konten tetap terbaca tanpa JS.

Butuh komponen: `pnpm dlx shadcn@latest add button badge accordion card avatar`

---

## 1. Section primitive (konsistensi spacing)

```tsx
// src/components/sections/section.tsx
import { cn } from "@/lib/utils";

export function Section({ className, children, ...props }: React.ComponentProps<"section">) {
  return (
    <section className={cn("py-20 md:py-28", className)} {...props}>
      <div className="mx-auto max-w-6xl px-4 md:px-6">{children}</div>
    </section>
  );
}

export function SectionHeader({ eyebrow, title, description }: { eyebrow?: string; title: string; description?: string }) {
  return (
    <div className="max-w-2xl">
      {eyebrow && <p className="text-sm font-medium text-muted-foreground">{eyebrow}</p>}
      <h2 className="mt-2 text-3xl font-semibold tracking-tight text-balance md:text-4xl">{title}</h2>
      {description && <p className="mt-4 text-lg text-muted-foreground text-pretty">{description}</p>}
    </div>
  );
}
```

---

## 2. Hero (bersih, tanpa gradient slop)

```tsx
// src/components/sections/hero.tsx
import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";

export function Hero() {
  return (
    <section className="mx-auto max-w-5xl px-4 py-24 text-center md:py-32">
      <div className="flex justify-center">
        <Badge variant="secondary" className="rounded-full">
          Baru · Analitik real-time
        </Badge>
      </div>

      <h1 className="mt-6 text-4xl font-semibold tracking-tight text-balance md:text-6xl">
        Kelola bisnis kamu dalam satu platform
      </h1>

      <p className="mx-auto mt-6 max-w-2xl text-lg text-muted-foreground text-pretty">
        Otomasi alur kerja, pantau metrik, dan kolaborasi tim — tanpa ribet, tanpa tool berserakan.
      </p>

      <div className="mt-8 flex flex-col items-center justify-center gap-3 sm:flex-row">
        <Button asChild size="lg">
          <Link href="/register">
            Mulai gratis <ArrowRight className="size-4" />
          </Link>
        </Button>
        <Button asChild size="lg" variant="outline">
          <Link href="/demo">Lihat demo</Link>
        </Button>
      </div>

      <p className="mt-4 text-sm text-muted-foreground">Tanpa kartu kredit · Batalkan kapan saja</p>
    </section>
  );
}
```

Catatan anti-slop: solid `bg-background` (tanpa gradient ungu-biru), `text-balance`/`text-pretty` untuk baris rapi, CTA jelas satu primary + satu outline (bukan 4 tombol seramai pasar).

---

## 3. Feature grid (kartu hairline, ikon dalam kotak — bukan blob gradient)

```tsx
// src/components/sections/features.tsx
import { Workflow, ShieldCheck, BarChart3, Users, Zap, Sparkles } from "lucide-react";
import { Section, SectionHeader } from "./section";

const features = [
  { icon: Workflow, title: "Otomasi alur kerja", desc: "Rangkai proses berulang jadi otomatis dalam hitungan menit." },
  { icon: BarChart3, title: "Analitik real-time", desc: "Metrik penting tersaji langsung, tanpa export manual." },
  { icon: ShieldCheck, title: "Aman by default", desc: "Enkripsi, audit log, dan kontrol akses granular." },
  { icon: Users, title: "Kolaborasi tim", desc: "Peran & izin jelas untuk setiap anggota." },
  { icon: Zap, title: "Cepat", desc: "Dibangun di atas infrastruktur modern, respons instan." },
  { icon: Sparkles, title: "Integrasi luas", desc: "Terhubung dengan tool yang sudah kamu pakai." },
];

export function Features() {
  return (
    <Section>
      <SectionHeader
        eyebrow="Fitur"
        title="Semua yang kamu butuh, tanpa yang tidak"
        description="Fokus ke pekerjaan, bukan ke mengatur tool."
      />
      <div className="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {features.map(({ icon: Icon, title, desc }) => (
          <div key={title} className="rounded-xl border bg-card p-6 transition-colors hover:border-foreground/20">
            <div className="flex size-10 items-center justify-center rounded-lg border bg-background">
              <Icon className="size-5" aria-hidden />
            </div>
            <h3 className="mt-4 font-medium">{title}</h3>
            <p className="mt-2 text-sm text-muted-foreground">{desc}</p>
          </div>
        ))}
      </div>
    </Section>
  );
}
```

---

## 4. Social proof (logo strip)

```tsx
// src/components/sections/logo-cloud.tsx
import { Section } from "./section";

const logos = ["Acme", "Globex", "Umbrella", "Initech", "Hooli"];

export function LogoCloud() {
  return (
    <Section className="py-12 md:py-16">
      <p className="text-center text-sm text-muted-foreground">Dipercaya oleh tim di berbagai perusahaan</p>
      <div className="mt-8 flex flex-wrap items-center justify-center gap-x-10 gap-y-6 opacity-70">
        {logos.map((name) => (
          <span key={name} className="text-lg font-semibold tracking-tight text-muted-foreground">
            {name}
          </span>
        ))}
      </div>
    </Section>
  );
}
```

---

## 5. Testimonial

```tsx
// src/components/sections/testimonial.tsx
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Section } from "./section";

export function Testimonial() {
  return (
    <Section>
      <figure className="mx-auto max-w-3xl">
        <blockquote className="text-center text-2xl font-medium tracking-tight text-balance md:text-3xl">
          &ldquo;Sejak pindah, tim kami hemat belasan jam per minggu. Setup-nya juga jujur, nggak bikin pusing.&rdquo;
        </blockquote>
        <figcaption className="mt-8 flex items-center justify-center gap-3">
          <Avatar>
            <AvatarFallback>RD</AvatarFallback>
          </Avatar>
          <div className="text-left text-sm">
            <div className="font-medium">Rangga D.</div>
            <div className="text-muted-foreground">Head of Ops, Globex</div>
          </div>
        </figcaption>
      </figure>
    </Section>
  );
}
```

---

## 6. CTA band (kontras via surface, bukan gradient)

```tsx
// src/components/sections/cta.tsx
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Section } from "./section";

export function CTA() {
  return (
    <Section>
      <div className="rounded-2xl border bg-card px-6 py-16 text-center">
        <h2 className="text-3xl font-semibold tracking-tight text-balance md:text-4xl">
          Siap mulai?
        </h2>
        <p className="mx-auto mt-4 max-w-xl text-muted-foreground">
          Coba gratis 14 hari. Tanpa kartu kredit.
        </p>
        <Button asChild size="lg" className="mt-8">
          <Link href="/register">Buat akun</Link>
        </Button>
      </div>
    </Section>
  );
}
```

---

## 7. FAQ (shadcn Accordion — a11y bawaan)

```tsx
// src/components/sections/faq.tsx
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from "@/components/ui/accordion";
import { Section, SectionHeader } from "./section";

const faqs = [
  { q: "Apakah ada free trial?", a: "Ya, 14 hari penuh tanpa kartu kredit." },
  { q: "Bisa batalkan kapan saja?", a: "Bisa, langsung dari dashboard, tanpa penalti." },
  { q: "Apakah data saya aman?", a: "Data dienkripsi saat transit dan saat disimpan." },
];

export function FAQ() {
  return (
    <Section>
      <SectionHeader title="Pertanyaan umum" />
      <div className="mt-8 max-w-2xl">
        <Accordion type="single" collapsible>
          {faqs.map((f, i) => (
            <AccordionItem key={i} value={`item-${i}`}>
              <AccordionTrigger className="text-left">{f.q}</AccordionTrigger>
              <AccordionContent className="text-muted-foreground">{f.a}</AccordionContent>
            </AccordionItem>
          ))}
        </Accordion>
      </div>
    </Section>
  );
}
```

---

## 8. Merangkai halaman

```tsx
// src/app/(marketing)/page.tsx  — Server Component
import { Hero } from "@/components/sections/hero";
import { LogoCloud } from "@/components/sections/logo-cloud";
import { Features } from "@/components/sections/features";
import { Testimonial } from "@/components/sections/testimonial";
import { FAQ } from "@/components/sections/faq";
import { CTA } from "@/components/sections/cta";

export default function HomePage() {
  return (
    <>
      <Hero />
      <LogoCloud />
      <Features />
      <Testimonial />
      <FAQ />
      <CTA />
    </>
  );
}
```

---

## Checklist section (wajib)

- [ ] Server Component (kecuali butuh interaktivitas)
- [ ] Warna 100% token; nol gradient slop, nol shadow-2xl
- [ ] Hierarki tipografi jelas (SectionHeader), `text-balance`/`text-pretty`
- [ ] Spacing konsisten via `Section` primitive
- [ ] Responsive 360/768/1280, `grid` breakpoints
- [ ] Dark mode terverifikasi (otomatis via token)
- [ ] Ikon `lucide` + `aria-hidden`; link/tombol semantik
- [ ] Kontras AA di light & dark
