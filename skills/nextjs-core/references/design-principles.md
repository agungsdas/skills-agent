# Design Principles — Production Grade, Zero AI Slop

Dokumen ini adalah **hukum desain** untuk semua skill Next.js (`nextjs-customer-facing` & `nextjs-dashboard`).
Setiap UI yang dihasilkan WAJIB lolos prinsip di sini. Kalau ragu, patuhi dokumen ini, bukan "kayaknya bagus".

Basis desain: **shadcn/ui (Radix + Tailwind) dengan Tailwind sebagai single source of truth.**
Arah visual: **neutral-first, monochrome-forward, satu accent** — timeless, bukan tren musiman (referensi rasa: Linear, Vercel, Stripe).

---

## 1. Prinsip Inti (taste)

1. **Restraint menang.** Ruang kosong, hierarki jelas, dan konsistensi lebih berharga daripada dekorasi. Kalau sebuah elemen tidak menambah makna, buang.
2. **Hierarki, bukan keramaian.** Satu fokus utama per layar. Ukuran, weight, dan warna dipakai untuk memandu mata, bukan untuk pamer.
3. **Konsisten itu profesional.** Spacing, radius, warna, dan motion semua ambil dari skala token yang sama. Tidak ada magic number.
4. **Token, bukan nilai mentah.** Warna/spacing/radius selalu lewat token. Tidak ada hex hardcoded, tidak ada `11px` random.
5. **Fungsional = bagian dari desain.** Loading, empty, error, keyboard, dark mode itu bukan afterthought. Desain yang cuma cakep di happy path = belum jadi.

---

## 2. "AI Slop" — DILARANG KERAS

Ini ciri desain yang bikin produk kelihatan di-generate asal. Haram hukumnya:

| Slop | Kenapa dilarang | Ganti dengan |
|------|-----------------|--------------|
| Gradient ungu→biru di hero | Cliché generator, tanpa makna brand | Solid `bg-background` + hierarki tipografi |
| Drop shadow besar & blur di tiap card | Kelihatan murah, berat, kuno | Hairline `border` + surface `bg-card` |
| Glassmorphism / blur di mana-mana | Noise, kontras jelek, a11y buruk | Surface solid + border tipis |
| Emoji dipakai sebagai icon UI | Tidak konsisten lintas OS, tidak profesional | `lucide-react`, stroke seragam |
| Semua di-`center`, layout simetris | Boring, tanpa hierarki | Grid asimetris terukur, alignment kiri untuk teks |
| Radius campur (pill + sharp + rounded) | Berantakan | Satu `--radius`, turunannya konsisten |
| 6 ukuran font tanpa skala | Hierarki kacau | Type scale (§4) |
| Teks `text-gray-400` di atas putih | Kontras < AA, kelihatan pudar | `text-muted-foreground` (sudah AA) |
| shadcn default mentah tanpa tuning | Kelihatan "starter template" | Tune token, radius, spacing, font ke brand |
| Warna-warni tanpa alasan | Tidak ada sistem | 60/30/10 + 1 accent (§7) |
| Motion bouncy/loop norak | Mengganggu, tidak dewasa | Motion terukur & purposeful (§8) |

Aturan emas: **kalau sebuah efek visual tidak punya alasan fungsional atau hierarkis, itu slop. Hapus.**

---

## 3. Design Tokens (Single Source of Truth)

Semua warna lewat **semantic CSS variables** (konvensi shadcn), di-wire ke Tailwind. Detail wiring ada di `nextjs-core/references/setup.md`.
Pakai **oklch** (perceptual uniform, lebih konsisten antar hue/lightness).

```css
/* globals.css — representasi; set lengkap digenerate oleh shadcn init */
:root {
  --background: oklch(1 0 0);
  --foreground: oklch(0.145 0 0);
  --card: oklch(1 0 0);
  --card-foreground: oklch(0.145 0 0);
  --popover: oklch(1 0 0);
  --popover-foreground: oklch(0.145 0 0);

  /* Monochrome-forward: primary = near-black. Accent dipakai HEMAT. */
  --primary: oklch(0.205 0 0);
  --primary-foreground: oklch(0.985 0 0);

  --secondary: oklch(0.97 0 0);
  --secondary-foreground: oklch(0.205 0 0);
  --muted: oklch(0.97 0 0);
  --muted-foreground: oklch(0.556 0 0);   /* teks sekunder, sudah kontras AA */
  --accent: oklch(0.97 0 0);
  --accent-foreground: oklch(0.205 0 0);

  --destructive: oklch(0.577 0.245 27.325);
  --border: oklch(0.922 0 0);             /* hairline */
  --input: oklch(0.922 0 0);
  --ring: oklch(0.708 0 0);               /* focus ring */

  --radius: 0.625rem;                     /* 10px — turunannya konsisten */
}

.dark {
  --background: oklch(0.145 0 0);
  --foreground: oklch(0.985 0 0);
  --card: oklch(0.205 0 0);               /* elevation halus via lightness */
  --card-foreground: oklch(0.985 0 0);
  --popover: oklch(0.205 0 0);
  --popover-foreground: oklch(0.985 0 0);
  --primary: oklch(0.985 0 0);
  --primary-foreground: oklch(0.205 0 0);
  --secondary: oklch(0.269 0 0);
  --secondary-foreground: oklch(0.985 0 0);
  --muted: oklch(0.269 0 0);
  --muted-foreground: oklch(0.708 0 0);
  --border: oklch(1 0 0 / 10%);
  --input: oklch(1 0 0 / 15%);
  --ring: oklch(0.556 0 0);
}
```

**Brand accent (opsional, swappable):** kalau brand butuh warna (bukan monochrome), ganti `--primary` ke SATU hue brand
(mis. `oklch(0.55 0.2 250)` untuk biru) + `--primary-foreground` yang kontras. **Tetap satu accent** — jangan tambah warna lain untuk dekorasi.

**Aturan pemakaian token:**
- Background halaman → `bg-background`, teks → `text-foreground`.
- Surface (card, panel) → `bg-card` + `border`.
- Teks sekunder → `text-muted-foreground` (JANGAN `text-gray-*`).
- Aksi utama / state aktif → `bg-primary` / `text-primary`.
- Dark mode otomatis ikut karena token yang sama. Tidak ada warna hardcoded.

---

## 4. Typography

Font default: **Geist Sans** + **Geist Mono** via `next/font` (self-hosted, no layout shift). Boleh diganti Inter untuk brand tertentu.

| Token | Size / Line | Pemakaian |
|-------|-------------|-----------|
| `text-xs` | 12 / 16 | Label, caption, meta |
| `text-sm` | 14 / 20 | Body sekunder, tabel, form helper |
| `text-base` | 16 / 24 | Body utama |
| `text-lg` | 18 / 28 | Lead paragraph |
| `text-xl` | 20 / 28 | Judul kartu |
| `text-2xl` | 24 / 32 | Judul section (dashboard) |
| `text-3xl` | 30 / 36 | Page title |
| `text-4xl`+ | 36+ / tight | Hero (web only), `tracking-tight` |

Aturan:
- Heading → `font-semibold tracking-tight`. Body → `font-normal`, warna `text-muted-foreground` untuk sekunder.
- Maksimal **2 level heading** yang menonjol per layar. Sisanya turun ke body.
- Panjang baris body ideal 60–75 karakter (`max-w-prose` / `max-w-2xl`).
- JANGAN pakai lebih dari skala di atas. Kalau butuh "di antara", berarti hierarki kamu salah.

---

## 5. Spacing & Layout

Base unit **4px**. Semua spacing kelipatan skala Tailwind (`1=4, 2=8, 3=12, 4=16, 6=24, 8=32, 12=48, 16=64, 24=96`).

- **Web (customer-facing):** section `py-16 md:py-24`, container `max-w-6xl/7xl mx-auto px-4 md:px-6`, gap antar blok longgar.
- **Dashboard:** page `p-4 md:p-6`, card `p-6`, gap antar widget `gap-4 md:gap-6`. Padat tapi tetap ada napas.
- Padding dalam card konsisten (`p-6`). Jangan campur `p-5` di satu tempat, `p-7` di tempat lain.
- Whitespace itu fitur. Kalau ragu, kasih ruang lebih, bukan lebih rapat.
- Layout pakai grid/flex terukur; hindari "semua ditengahin". Teks rata kiri.

---

## 6. Radius, Border, Shadow, Elevation

- **Radius:** semua turun dari `--radius`. Card `rounded-xl`, button/input `rounded-md`, badge/pill kecil `rounded-full` HANYA untuk chip/avatar. Konsisten, tidak dicampur asal.
- **Border:** pemisah utama adalah **hairline `border-border`**, bukan shadow. Border tipis = bersih & modern.
- **Shadow:** dipakai **hemat**, hanya untuk elemen yang benar-benar mengambang (dropdown, popover, dialog, toast) → `shadow-sm`/`shadow-md`. **DILARANG** `shadow-2xl` di card statis.
- **Elevation** dibangun dari kombinasi `bg-card` (beda lightness dari background) + `border`, bukan blur besar.

---

## 7. Color Usage

Aturan **60 / 30 / 10**:
- **60%** neutral background (`background`, `card`).
- **30%** surface & teks sekunder (`muted`, `border`, `muted-foreground`).
- **10%** accent (`primary`) — untuk CTA utama, nav aktif, focus, data kunci.

- Accent dipakai **hemat**. Kalau semua tombol biru, tidak ada yang menonjol.
- Warna status hanya untuk **makna**: `destructive` (hapus/error), `success`/`warning` (token `--success`/`--warning`, sudah ada di `setup.md`) untuk konfirmasi/peringatan. Jangan dekoratif.
- Chart pakai token `--chart-1..5` yang harmonis, bukan warna random.

---

## 8. Motion

Purposeful, bukan dekorasi.

- **Durasi:** micro-interaction (hover, toggle) `150ms`; enter/exit elemen `200–300ms`.
- **Easing:** masuk `ease-out`, keluar `ease-in`. Hindari bounce kecuali memang playful & disengaja.
- **Property:** animasikan `transform` & `opacity` saja (GPU-friendly, no layout thrash).
- **Framer Motion** untuk orkestrasi (stagger list, shared layout, page transition) — bukan untuk animasiin semua hal.
- **WAJIB** hormati `prefers-reduced-motion`: matikan/observe animasi non-esensial.
- Tidak ada loop infinite yang mengganggu (kecuali loader yang memang perlu).

---

## 9. Density: Web vs Dashboard

Token sama, skala beda:
- **Web** → lega, tipografi lebih besar, whitespace generous, fokus storytelling & konversi.
- **Dashboard** → padat & efisien, `text-sm` untuk tabel/row, tinggi baris kompak, tapi tetap ada breathing room. Prioritas: kepadatan informasi + keterbacaan.

---

## 10. State Completeness (WAJIB semua ada)

Setiap surface async WAJIB desain 4 state ini. Ini bagian dari Definition of Done:

1. **Loading** → **Skeleton** yang menyerupai layout final (bukan spinner di tengah layar). Spinner hanya untuk inline/tombol.
2. **Empty** → icon/ilustrasi ringan + heading singkat + 1 kalimat penjelas + **1 primary action**. Jangan layar kosong.
3. **Error** → pesan jelas + tombol **retry**. Detail teknis disembunyikan di production (jangan bocorkan stack ke user).
4. **Success / data** → konten sebenarnya; feedback aksi via toast/inline yang halus.

---

## 11. Accessibility (non-negotiable)

- **Kontras** minimal WCAG AA: 4.5:1 teks normal, 3:1 teks besar & elemen UI. Berlaku di light & dark.
- **Focus** selalu terlihat: `focus-visible:ring-2 ring-ring`. JANGAN hapus outline tanpa pengganti.
- **Keyboard**: semua elemen interaktif bisa diakses & dioperasikan via keyboard; urutan tab logis.
- **Semantic HTML**: `<button>` untuk aksi (bukan `<div onClick>`), heading berjenjang, landmark (`<nav> <main> <header>`).
- **Icon-only button** wajib `aria-label`. Form input wajib `<label>` terkait.
- Hormati `prefers-reduced-motion`.
- Full compliance butuh uji manual dengan assistive tech; poin di atas adalah baseline wajib.

---

## 12. Do / Don't (konkret)

```tsx
/* ❌ SLOP */
<div className="bg-gradient-to-r from-purple-500 to-blue-500 rounded-3xl shadow-2xl p-8">
  <h1 className="text-white text-center">Welcome 🚀</h1>
  <p className="text-gray-300 text-center">Best app ever</p>
</div>

/* ✅ PRODUCTION */
<section className="rounded-xl border bg-card p-8">
  <h1 className="text-3xl font-semibold tracking-tight text-foreground">Welcome</h1>
  <p className="mt-2 text-muted-foreground">Kelola semua di satu tempat.</p>
</section>
```

```tsx
/* ❌ hardcoded + kontras jelek */
<span style={{ color: '#9ca3af' }}>Status</span>

/* ✅ token */
<span className="text-muted-foreground">Status</span>
```

```tsx
/* ❌ div sebagai tombol + emoji icon */
<div onClick={onSave}>💾 Save</div>

/* ✅ button + lucide + focus ring */
<Button onClick={onSave}>
  <Save className="size-4" /> Save
</Button>
```

---

## 13. Definition of Done (ship gate desain)

Sebuah komponen/halaman belum selesai sampai SEMUA ini ✔:

- [ ] Warna/spacing/radius 100% dari token — nol hex/magic number
- [ ] Light **dan** dark mode dicek, dua-duanya rapi & kontras AA
- [ ] 4 state ada: loading (skeleton), empty, error (retry), success
- [ ] Responsive dicek di 360px / 768px / 1280px — no overflow, no layout shift
- [ ] Keyboard-navigable + focus ring terlihat
- [ ] Kontras teks & UI ≥ AA (light & dark)
- [ ] Motion terukur & aman untuk `prefers-reduced-motion`
- [ ] Ikut type scale & spacing scale — tidak ada ukuran di luar sistem
- [ ] Tidak ada satu pun item dari daftar "AI Slop" (§2)

Kalau ada satu yang belum ✔ → **belum selesai.**
