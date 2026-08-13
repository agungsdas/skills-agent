# shadcn/ui — Component Catalog & Decision Map

Peta "kebutuhan → komponen" biar tidak reinvent. **Selalu cek katalog ini dulu sebelum bikin komponen dari nol.**
Semua di-`add` dengan: `pnpm dlx shadcn@latest add <nama>` (masuk ke `components/ui/`, kamu own kodenya).

> Untuk migrasi Ant Design → shadcn, lihat tabel di `setup.md` §9. Dokumen ini fokus ke "butuh X pakai apa".

---

## Form & Input

| Butuh | Komponen |
|-------|----------|
| Aksi / tombol | `button`, grup tombol → `button-group` |
| Teks input | `input`; dengan icon/addon → `input-group`; kode OTP → `input-otp`; multiline → `textarea` |
| Label & wrapper field | `label`, `field`, dan `form` (integrasi react-hook-form + Zod) |
| Pilih dari list | dropdown → `select`; native mobile → `native-select`; **searchable** → `combobox`; command palette → `command` |
| Boolean | `checkbox`, `switch`; pilihan tunggal → `radio-group` |
| Toggle | `toggle`, `toggle-group` |
| Angka/range | `slider` |
| Tanggal | tampilan → `calendar`; input tanggal → `date-picker` (calendar + popover) |

> Form kompleks → lihat dashboard track `forms.md` (RHF + Zod + `form`).

---

## Overlay & Feedback

| Butuh | Komponen |
|-------|----------|
| Modal | `dialog`; konfirmasi destruktif → `alert-dialog` |
| Panel samping / bawah | `sheet` (samping), `drawer` (bawah, mobile-friendly) |
| Popup kecil | `popover`; preview saat hover → `hover-card`; hint singkat → `tooltip` |
| Menu aksi | `dropdown-menu`; klik-kanan → `context-menu` |
| Notifikasi transiten (toast) | **`sonner`** (komponen `toast` lama sudah deprecated) |
| Pesan inline | `alert` |
| Status proses | `progress`; loading area → `skeleton`; loading kecil → `spinner` |
| State kosong | `empty` |

---

## Navigasi

| Butuh | Komponen |
|-------|----------|
| Menu utama | `navigation-menu`, `menubar` |
| Sidebar aplikasi | `sidebar` (lihat dashboard track `app-shell.md`) |
| Tab | `tabs` |
| Breadcrumb | `breadcrumb` |
| Pagination | `pagination` |

---

## Layout & Data Display

| Butuh | Komponen |
|-------|----------|
| Kontainer/surface | `card` |
| Pemisah | `separator` |
| Rasio aspek media | `aspect-ratio` |
| Area scroll kustom | `scroll-area` |
| Panel bisa di-resize | `resizable` |
| Tabel | statis → `table`; data-heavy (sort/filter/paginate) → **`data-table`** (TanStack, lihat dashboard track) |
| Chart | `chart` (wrapper Recharts, warna token `--chart-*`) |
| Badge/status | `badge` |
| Avatar | `avatar` |
| Akordeon / collapse | `accordion`, `collapsible` |
| Carousel | `carousel` |
| Tipografi konten | `typography` |
| Keyboard shortcut | `kbd` |
| List item generik | `item` |

---

## AI / Chat (relevan untuk UI agent)

Kalau bikin antarmuka chatbot/asisten (nyambung ke skill `ai-agent`):

| Butuh | Komponen |
|-------|----------|
| Gelembung chat | `bubble` |
| Pesan / thread | `message`, `message-scroller` |
| Lampiran file di chat | `attachment` |

---

## Utility

| Butuh | Komponen |
|-------|----------|
| RTL/LTR | `direction` |
| Marker (peta) | `marker` |

---

## Yang TIDAK disediakan shadcn → pakai ekosistem (lalu skin dengan token)

| Butuh | Rekomendasi |
|-------|-------------|
| Rich text editor / WYSIWYG | **Tiptap** |
| Drag & drop file upload | **react-dropzone** (bungkus dengan style token) |
| Tabel super-advanced | **TanStack Table** (sudah jadi basis `data-table`) |
| Date range picker kompleks | **react-day-picker** (basis `calendar`) |
| Chart lanjutan | **Recharts** (basis `chart`) |
| Drag & drop list/kanban | **dnd-kit** |

> Prinsip: kalau shadcn punya → pakai. Kalau butuh library luar → tetap **skin pakai token** (`design-principles.md`) supaya konsisten. Jangan impor UI library lain (mis. Ant Design).

---

## Tips

- Lihat semua komponen resmi: `https://ui.shadcn.com/docs/components`.
- **Blocks** shadcn (`https://ui.shadcn.com/blocks`) menyediakan komposisi jadi (dashboard, login, sidebar) — cek dulu sebelum menyusun dari nol.
- Tambah banyak sekaligus: `pnpm dlx shadcn@latest add button card input dialog ...`.
- Semua komponen = kode di repo kamu → boleh diedit; kalau overwrite via CLI, commit dulu.
