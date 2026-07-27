# Animation — Terukur & Purposeful (bukan dekorasi)

Patuh `nextjs-core/references/design-principles.md` §8: durasi 150–300ms, `ease-out` masuk, animasikan `transform`+`opacity`, **wajib** hormati `prefers-reduced-motion`, tidak ada loop norak.

Library: **`motion`** (Framer Motion generasi baru). Install: `pnpm add motion` · import dari `motion/react`.
Komponen animasi = **Client Component** (`"use client"`). Konten harus tetap terbaca tanpa JS (progressive enhancement).

---

## 1. FadeIn on scroll (reusable, reduced-motion aware)

```tsx
// src/components/motion/fade-in.tsx
"use client";

import { motion, useReducedMotion } from "motion/react";
import type { ReactNode } from "react";

export function FadeIn({
  children,
  delay = 0,
  className,
}: {
  children: ReactNode;
  delay?: number;
  className?: string;
}) {
  const reduce = useReducedMotion();

  return (
    <motion.div
      className={className}
      initial={reduce ? false : { opacity: 0, y: 12 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-80px" }}
      transition={{ duration: 0.4, ease: "easeOut", delay }}
    >
      {children}
    </motion.div>
  );
}
```

`reduce ? false` → saat user minta reduced motion, elemen langsung tampil final tanpa animasi.

---

## 2. Stagger (daftar item muncul berurutan halus)

```tsx
// src/components/motion/stagger.tsx
"use client";

import { motion, useReducedMotion } from "motion/react";
import type { ReactNode } from "react";

export function Stagger({ children, className }: { children: ReactNode; className?: string }) {
  const reduce = useReducedMotion();
  return (
    <motion.div
      className={className}
      initial="hidden"
      whileInView="show"
      viewport={{ once: true, margin: "-80px" }}
      variants={{ show: { transition: { staggerChildren: reduce ? 0 : 0.06 } } }}
    >
      {children}
    </motion.div>
  );
}

export function StaggerItem({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <motion.div
      className={className}
      variants={{ hidden: { opacity: 0, y: 12 }, show: { opacity: 1, y: 0 } }}
      transition={{ duration: 0.35, ease: "easeOut" }}
    >
      {children}
    </motion.div>
  );
}
```

Pemakaian: bungkus grid feature dengan `<Stagger>` dan tiap kartu dengan `<StaggerItem>`.

---

## 3. Page transition (opsional, halus)

```tsx
// src/app/(marketing)/template.tsx  — template re-mount tiap navigasi
"use client";

import { motion } from "motion/react";

export default function Template({ children }: { children: React.ReactNode }) {
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.2, ease: "easeOut" }}
    >
      {children}
    </motion.div>
  );
}
```

> Jaga transisi tetap singkat (≤200ms) supaya navigasi terasa cepat, bukan lambat.

---

## 4. Micro-interaction (hover/tap)

Untuk hover sederhana, cukup **Tailwind transition** (tanpa JS):

```tsx
<button className="transition-colors hover:bg-accent focus-visible:ring-2 focus-visible:ring-ring">
```

Pakai `motion` hanya kalau butuh spring/gesture yang tak bisa dicapai CSS.

---

## Checklist animation (wajib)

- [ ] `useReducedMotion` dihormati di setiap animasi non-esensial
- [ ] Durasi 150–300ms, `ease-out` untuk masuk
- [ ] Hanya `transform`/`opacity` (no layout thrash)
- [ ] `viewport={{ once: true }}` agar tak re-animate berulang
- [ ] Konten tetap tampil & terbaca tanpa JS
- [ ] Tidak ada animasi loop yang mengganggu
