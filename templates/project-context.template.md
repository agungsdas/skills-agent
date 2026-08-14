# Project Context

> Copy file ini ke `.kiro/steering/project-context.md` di root project kamu.
> Isi sesuai project. Hapus section yang tidak relevan.
> File ini akan di-load otomatis setiap session kalau `inclusion: always`.

---

## Tech Stack

| Layer | Stack |
|-------|-------|
| Language | <!-- e.g. Go 1.22, TypeScript 5.x, Python 3.12 --> |
| Framework | <!-- e.g. Echo v5, Next.js 15, FastAPI --> |
| Database | <!-- e.g. MongoDB 7, PostgreSQL 16 --> |
| Cache | <!-- e.g. Redis 7 --> |
| UI | <!-- e.g. shadcn/ui + Tailwind v4 --> |
| Auth | <!-- e.g. jose + bcrypt, NextAuth v5 --> |
| Testing | <!-- e.g. go test, vitest, pytest --> |
| Deployment | <!-- e.g. ArgoCD + Helm, Vercel, Docker Compose --> |

## Module / Service Name

<!-- Nama module/package project ini -->
<!-- Go: lihat go.mod → module mika/service-name -->
<!-- Node: lihat package.json → "name" -->
<!-- Python: lihat pyproject.toml → [project] name -->

```
name: my-project
```

## Project Structure

<!-- High-level folder structure. Hanya folder utama, jangan terlalu detail -->
<!-- Sesuaikan dengan stack. Contoh per stack: -->

<!-- Go Clean Architecture -->
<!--
```
src/
├── entities/
├── drivers/
├── definitions/
├── repositories/
├── usecases/
├── interfaces/
└── helpers/
```
-->

<!-- Next.js App Router -->
<!--
```
src/
├── app/              # Routes (App Router)
├── components/       # UI components
│   └── ui/           # shadcn components
├── lib/              # Utilities, helpers
├── models/           # Mongoose schemas
├── repositories/     # Data access
├── services/         # Business logic / API transport
├── hooks/            # React hooks
├── stores/           # Redux / Zustand
└── types/            # TypeScript types
```
-->

<!-- Python FastAPI -->
<!--
```
app/
├── api/              # Route handlers
├── models/           # Pydantic / SQLAlchemy models
├── services/         # Business logic
├── repositories/     # Data access
├── core/             # Config, security, deps
└── tests/
```
-->

## Reference Files

File-file ini adalah contoh implementasi yang sudah benar. Kalau bikin domain/feature baru, ikuti pattern dari sini:

| Domain/Feature | File Reference |
|---------------|----------------|
| <!-- e.g. Invoice --> | <!-- e.g. src/entities/invoice.go, src/usecases/invoice/ --> |
| <!-- e.g. User --> | <!-- e.g. src/app/api/users/route.ts, src/models/user.ts --> |

## Naming Conventions

<!-- Hapus baris yang tidak relevan dengan stack project kamu -->

| Item | Convention | Contoh |
|------|-----------|--------|
| File name | <!-- kebab-case / snake_case --> | <!-- bulk-upsert.go / user_service.py --> |
| JSON field | camelCase | `invoiceNumber` |
| Env variable | SCREAMING_SNAKE | `DATABASE_URL` |
| API endpoint | kebab-case | `/v1/invoice-detail` |
| Entity/Model | PascalCase | `InvoiceDetail` |
| DB field (Mongo) | camelCase | `bson:"invoiceNumber"` |
| DB field (PG) | snake_case | `gorm:"column:invoice_number"` / `Column("invoice_number")` |
| Component (React) | PascalCase | `InvoiceTable.tsx` |
| Hook (React) | camelCase `use` prefix | `useInvoices.ts` |
| Python function | snake_case | `create_invoice()` |
| Python class | PascalCase | `InvoiceService` |

## Response Format

<!-- Definisikan response format yang dipakai di project ini -->

```json
{
  "status": true,
  "message": "OK",
  "data": {},
  "meta": {
    "page": 1,
    "limit": 10,
    "total": 100
  }
}
```

## Error Handling Pattern

<!-- Bagaimana error di-handle dan di-return -->

```json
{
  "status": false,
  "message": "Invoice not found",
  "error": "NOT_FOUND"
}
```

## Environment Variables

<!-- Env var yang WAJIB ada untuk run project -->

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | Yes | Database connection string |
| `REDIS_URL` | No | Redis connection string |
| `JWT_SECRET` | Yes | JWT signing key |
| `PORT` | No | Server port (default: 8080) |

## Commands

<!-- Command utama untuk development -->

| Command | Fungsi |
|---------|--------|
| <!-- e.g. `make local` --> | <!-- Run dev server --> |
| <!-- e.g. `npm run dev` --> | <!-- Run dev server --> |
| <!-- e.g. `make build` --> | <!-- Build binary/bundle --> |
| <!-- e.g. `npm run test` --> | <!-- Run tests --> |
| <!-- e.g. `make migration-up` --> | <!-- Run migrations --> |

## Domain-Specific Rules

<!-- Rules khusus project ini yang tidak ada di skill umum -->

- <!-- e.g. Semua monetary value dalam cents (integer), bukan float -->
- <!-- e.g. Soft delete: pakai deletedAt field, jangan hard delete -->
- <!-- e.g. All dates stored as UTC, displayed in WIB (Asia/Jakarta) -->
- <!-- e.g. File upload via presigned URL (Cloudflare R2), bukan direct upload -->

## External Services

<!-- Service / API lain yang di-call project ini -->

| Service | Purpose | Integration |
|---------|---------|-------------|
| <!-- e.g. SAP --> | <!-- e.g. Sync master data --> | <!-- e.g. src/drivers/sap/ --> |
| <!-- e.g. Stripe --> | <!-- e.g. Payment processing --> | <!-- e.g. src/services/stripe.ts --> |

## Notes

<!-- Hal-hal penting lain yang perlu diketahui sebelum mulai kerja -->

- <!-- e.g. Migration pakai golang-migrate, bukan GORM auto-migrate -->
- <!-- e.g. Event emitter untuk async side effects, bukan goroutine langsung -->
- <!-- e.g. Monorepo: apps/web (Next.js) + apps/api (Go) + packages/shared -->
