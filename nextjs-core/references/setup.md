# Core Setup — shadcn/ui + Tailwind v4 (Single Source of Truth)

Fondasi styling untuk semua skill Next.js. **Tailwind adalah satu-satunya sumber kebenaran styling.**
Tidak ada UI library lain (tidak ada Ant Design), tidak ada `preflight: false`, tidak ada CSS-in-JS runtime.

Stack: **Next.js 15+ (App Router) · React 19 · TypeScript · Tailwind v4 · shadcn/ui (new-york) · next-themes · lucide-react**.

> Baca juga: `design-principles.md` (hukum desain & token). Setup di sini meng-implement token dari dokumen itu.

---

## 1. Kenapa shadcn (bukan library import)

shadcn bukan dependency yang di-import — komponennya **di-copy ke repo** (`src/components/ui/`), jadi kamu **own** kodenya.
Styling 100% Tailwind + CSS variables. Konsekuensinya: tidak ada version lock, tidak ada override-war, dan Tailwind benar-benar jadi SSOT.
*(Dirangkum dari [dokumentasi shadcn](https://ui.shadcn.com/docs/tailwind-v4); disesuaikan untuk kebutuhan skill ini.)*

---

## 2. Instalasi

```bash
# 1. Project baru (Tailwind v4 + TS + App Router + src/)
pnpm create next-app@latest my-app --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"

# 2. Init shadcn — pilih base color: Neutral, style: new-york
pnpm dlx shadcn@latest init

# 3. Dependency wajib: dark mode + font
pnpm add next-themes geist

# 4. Tambah komponen sesuai kebutuhan (contoh set awal)
pnpm dlx shadcn@latest add button card input label dropdown-menu dialog sheet sonner skeleton badge separator
```

Catatan Tailwind v4 (berlaku 2025+):
- **Tidak ada `tailwind.config.js`** lagi — konfigurasi CSS-first via `@theme` di `globals.css`, content auto-detected.
- Animasi pakai **`tw-animate-css`** (bukan `tailwindcss-animate` yang sudah deprecated).
- Warna pakai **oklch**. Toast pakai **sonner** (komponen `toast` lama deprecated).

---

## 3. `components.json`

```json
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "new-york",
  "rsc": true,
  "tsx": true,
  "tailwind": {
    "config": "",
    "css": "src/app/globals.css",
    "baseColor": "neutral",
    "cssVariables": true,
    "prefix": ""
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  },
  "iconLibrary": "lucide"
}
```

`tailwind.config` sengaja kosong (Tailwind v4 tidak pakai file config). `cssVariables: true` → semua warna lewat token (wajib untuk SSOT & dark mode).

---

## 4. `globals.css` (token — implementasi design-principles)

Neutral base, oklch, light + dark. **Ini satu-satunya tempat warna didefinisikan.** Ganti brand accent? Cukup di sini.

```css
/* src/app/globals.css */
@import "tailwindcss";
@import "tw-animate-css";

@custom-variant dark (&:is(.dark *));

:root {
  --radius: 0.625rem;

  --background: oklch(1 0 0);
  --foreground: oklch(0.145 0 0);
  --card: oklch(1 0 0);
  --card-foreground: oklch(0.145 0 0);
  --popover: oklch(1 0 0);
  --popover-foreground: oklch(0.145 0 0);

  /* Monochrome-forward: primary = near-black. Ganti ke hue brand kalau perlu (tetap 1 accent). */
  --primary: oklch(0.205 0 0);
  --primary-foreground: oklch(0.985 0 0);

  --secondary: oklch(0.97 0 0);
  --secondary-foreground: oklch(0.205 0 0);
  --muted: oklch(0.97 0 0);
  --muted-foreground: oklch(0.556 0 0);
  --accent: oklch(0.97 0 0);
  --accent-foreground: oklch(0.205 0 0);

  --destructive: oklch(0.577 0.245 27.325);
  --success: oklch(0.6 0.145 163);
  --warning: oklch(0.795 0.16 86);
  --border: oklch(0.922 0 0);
  --input: oklch(0.922 0 0);
  --ring: oklch(0.708 0 0);

  --chart-1: oklch(0.646 0.222 41.116);
  --chart-2: oklch(0.6 0.118 184.704);
  --chart-3: oklch(0.398 0.07 227.392);
  --chart-4: oklch(0.828 0.189 84.429);
  --chart-5: oklch(0.769 0.188 70.08);

  --sidebar: oklch(0.985 0 0);
  --sidebar-foreground: oklch(0.145 0 0);
  --sidebar-primary: oklch(0.205 0 0);
  --sidebar-primary-foreground: oklch(0.985 0 0);
  --sidebar-accent: oklch(0.97 0 0);
  --sidebar-accent-foreground: oklch(0.205 0 0);
  --sidebar-border: oklch(0.922 0 0);
  --sidebar-ring: oklch(0.708 0 0);
}

.dark {
  --background: oklch(0.145 0 0);
  --foreground: oklch(0.985 0 0);
  --card: oklch(0.205 0 0);
  --card-foreground: oklch(0.985 0 0);
  --popover: oklch(0.205 0 0);
  --popover-foreground: oklch(0.985 0 0);

  --primary: oklch(0.922 0 0);
  --primary-foreground: oklch(0.205 0 0);
  --secondary: oklch(0.269 0 0);
  --secondary-foreground: oklch(0.985 0 0);
  --muted: oklch(0.269 0 0);
  --muted-foreground: oklch(0.708 0 0);
  --accent: oklch(0.269 0 0);
  --accent-foreground: oklch(0.985 0 0);

  --destructive: oklch(0.704 0.191 22.216);
  --success: oklch(0.7 0.15 162);
  --warning: oklch(0.84 0.16 84);
  --border: oklch(1 0 0 / 10%);
  --input: oklch(1 0 0 / 15%);
  --ring: oklch(0.556 0 0);

  --chart-1: oklch(0.488 0.243 264.376);
  --chart-2: oklch(0.696 0.17 162.48);
  --chart-3: oklch(0.769 0.188 70.08);
  --chart-4: oklch(0.627 0.265 303.9);
  --chart-5: oklch(0.645 0.246 16.439);

  --sidebar: oklch(0.205 0 0);
  --sidebar-foreground: oklch(0.985 0 0);
  --sidebar-primary: oklch(0.488 0.243 264.376);
  --sidebar-primary-foreground: oklch(0.985 0 0);
  --sidebar-accent: oklch(0.269 0 0);
  --sidebar-accent-foreground: oklch(0.985 0 0);
  --sidebar-border: oklch(1 0 0 / 10%);
  --sidebar-ring: oklch(0.556 0 0);
}

@theme inline {
  --radius-sm: calc(var(--radius) - 4px);
  --radius-md: calc(var(--radius) - 2px);
  --radius-lg: var(--radius);
  --radius-xl: calc(var(--radius) + 4px);

  --font-sans: var(--font-geist-sans);
  --font-mono: var(--font-geist-mono);

  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-card: var(--card);
  --color-card-foreground: var(--card-foreground);
  --color-popover: var(--popover);
  --color-popover-foreground: var(--popover-foreground);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  --color-secondary: var(--secondary);
  --color-secondary-foreground: var(--secondary-foreground);
  --color-muted: var(--muted);
  --color-muted-foreground: var(--muted-foreground);
  --color-accent: var(--accent);
  --color-accent-foreground: var(--accent-foreground);
  --color-destructive: var(--destructive);
  --color-success: var(--success);
  --color-warning: var(--warning);
  --color-border: var(--border);
  --color-input: var(--input);
  --color-ring: var(--ring);
  --color-chart-1: var(--chart-1);
  --color-chart-2: var(--chart-2);
  --color-chart-3: var(--chart-3);
  --color-chart-4: var(--chart-4);
  --color-chart-5: var(--chart-5);
  --color-sidebar: var(--sidebar);
  --color-sidebar-foreground: var(--sidebar-foreground);
  --color-sidebar-primary: var(--sidebar-primary);
  --color-sidebar-primary-foreground: var(--sidebar-primary-foreground);
  --color-sidebar-accent: var(--sidebar-accent);
  --color-sidebar-accent-foreground: var(--sidebar-accent-foreground);
  --color-sidebar-border: var(--sidebar-border);
  --color-sidebar-ring: var(--sidebar-ring);
}

@layer base {
  * {
    @apply border-border outline-ring/50;
  }
  body {
    @apply bg-background text-foreground;
  }
}
```

---

## 5. `lib/utils.ts` — `cn()` helper

```ts
// src/lib/utils.ts
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

---

## 6. Font (next/font, no layout shift)

Pakai **Geist** (default, modern) — self-hosted via package `geist`, di-wire ke `--font-sans`/`--font-mono` (lihat `@theme inline`).

```tsx
// src/app/layout.tsx (potongan)
import { GeistSans } from "geist/font/sans";
import { GeistMono } from "geist/font/mono";
```

Alternatif brand: `Inter` via `next/font/google` — assign ke `--font-geist-sans` variable atau ubah mapping `--font-sans`.

---

## 7. Root Layout + Dark Mode (next-themes)

Dark/light **wajib**. `next-themes` handle deteksi, persist, dan anti-flash. **`suppressHydrationWarning` wajib** di `<html>` karena next-themes meng-update class sebelum hydration.

```tsx
// src/app/layout.tsx
import type { Metadata } from "next";
import { GeistSans } from "geist/font/sans";
import { GeistMono } from "geist/font/mono";
import { ThemeProvider } from "@/components/providers/theme-provider";
import { Toaster } from "@/components/ui/sonner";
import "./globals.css";

export const metadata: Metadata = {
  title: { default: "My App", template: "%s | My App" },
  description: "...",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="id" suppressHydrationWarning>
      <body className={`${GeistSans.variable} ${GeistMono.variable} font-sans antialiased`}>
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          {children}
          <Toaster richColors position="top-right" />
        </ThemeProvider>
      </body>
    </html>
  );
}
```

### ThemeProvider

```tsx
// src/components/providers/theme-provider.tsx
"use client";

import * as React from "react";
import { ThemeProvider as NextThemesProvider } from "next-themes";

export function ThemeProvider({
  children,
  ...props
}: React.ComponentProps<typeof NextThemesProvider>) {
  return <NextThemesProvider {...props}>{children}</NextThemesProvider>;
}
```

### Mode Toggle (light / dark / system)

```tsx
// src/components/commons/mode-toggle.tsx
"use client";

import { Moon, Sun } from "lucide-react";
import { useTheme } from "next-themes";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

export function ModeToggle() {
  const { setTheme } = useTheme();

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="outline" size="icon">
          <Sun className="size-[1.2rem] scale-100 rotate-0 transition-all dark:scale-0 dark:-rotate-90" />
          <Moon className="absolute size-[1.2rem] scale-0 rotate-90 transition-all dark:scale-100 dark:rotate-0" />
          <span className="sr-only">Ganti tema</span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuItem onClick={() => setTheme("light")}>Terang</DropdownMenuItem>
        <DropdownMenuItem onClick={() => setTheme("dark")}>Gelap</DropdownMenuItem>
        <DropdownMenuItem onClick={() => setTheme("system")}>Sistem</DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
```

> Untuk baca theme aktif di komponen, gunakan `resolvedTheme` dari `useTheme()` (bukan `theme`, karena `theme` bisa bernilai `"system"`). Guard dengan `mounted` state kalau butuh render kondisional agar tidak mismatch.

---

## 8. Menambah komponen

```bash
pnpm dlx shadcn@latest add <component>      # contoh: table, form, select, calendar, popover, tabs, avatar, alert-dialog
```

Komponen masuk ke `src/components/ui/`. Boleh diedit langsung (kamu own kodenya). Kalau overwrite via CLI, commit dulu.

---

## 9. Migrasi dari Ant Design → shadcn/ui

Pemetaan untuk mengganti komponen Ant Design lama:

| Ant Design | shadcn/ui | Catatan |
|------------|-----------|---------|
| `Button` | `button` | — |
| `Form` + `Form.Item` | `form` + **react-hook-form + zod** | Lihat `dashboard` track |
| `Input`, `Input.Password` | `input` | password: `type="password"` |
| `Select` | `select` / `combobox` | combobox untuk searchable |
| `Table` | **Data Table (TanStack Table)** | Lihat `dashboard` track |
| `Modal` | `dialog` | — |
| `Drawer` | `sheet` | — |
| `message` / `notification` | `sonner` | `toast()` dari sonner |
| `Popconfirm` | `alert-dialog` | konfirmasi destruktif |
| `Tabs` | `tabs` | — |
| `DatePicker` | `calendar` + `popover` | pola Date Picker |
| `Upload` | custom `input[type=file]` / dropzone | — |
| `Menu` / sider | `navigation-menu` / `sidebar` | — |
| `Skeleton` | `skeleton` | — |
| `Spin` | `spinner` / inline loader | — |
| `Card`, `Statistic` | `card` + tipografi token | — |
| `Checkbox`/`Switch`/`Radio` | `checkbox`/`switch`/`radio-group` | — |
| `Tag` | `badge` | — |
| `Tooltip` | `tooltip` | — |
| `Pagination` | `pagination` | — |
| `ConfigProvider` theme + `darkAlgorithm` | CSS variables + `next-themes` | dark mode via token |

Yang **dihapus** saat migrasi: `antd`, `@ant-design/icons`, `@ant-design/nextjs-registry`, `AntdRegistry`, dan `corePlugins.preflight: false`.

---

## 10. Aturan SSOT (wajib)

1. **Warna hanya dari token** (`bg-background`, `text-muted-foreground`, dst) — nol hex hardcoded, nol inline style warna.
2. **Satu tempat definisi warna**: `globals.css`. Ganti brand = edit token, bukan komponen.
3. **Dark mode via token yang sama** — jangan bikin styling dark terpisah manual.
4. **`suppressHydrationWarning`** wajib di `<html>`.
5. **Tidak ada UI library lain** — semua komponen dari shadcn (`components/ui/`) atau custom Tailwind.
6. **`preflight` aktif** (default Tailwind) — hack `preflight: false` era Ant Design sudah dihapus.
7. Ikuti skala tipografi, spacing, radius, motion dari `design-principles.md`.
