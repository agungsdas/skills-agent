# Project Context

> Copy file ini ke `.kiro/steering/project-context.md` di root project kamu.
> Isi sesuai project. Hapus section yang tidak relevan.
> File ini akan di-load otomatis setiap session kalau `inclusion: always`.

---

## Tech Stack

| Layer | Stack |
|-------|-------|
| Language | <!-- e.g. Go 1.22, TypeScript 5.x --> |
| Framework | <!-- e.g. Echo v5, Next.js 15 --> |
| Database | <!-- e.g. MongoDB 7, PostgreSQL 16 --> |
| Cache | <!-- e.g. Redis 7 --> |
| UI | <!-- e.g. shadcn/ui + Tailwind v4 --> |
| Auth | <!-- e.g. jose + bcrypt, NextAuth v5 --> |
| Deployment | <!-- e.g. ArgoCD + Helm, Vercel --> |

## Module / Service Name

<!-- Nama module di go.mod atau package.json name -->

```
module: mika/service-name
```

## Project Structure

<!-- High-level folder structure. Hanya folder utama, jangan terlalu detail -->

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

## Reference Files

File-file ini adalah contoh implementasi yang sudah benar. Kalau bikin domain/feature baru, ikuti pattern dari sini:

| Domain/Feature | File Reference |
|---------------|----------------|
| <!-- e.g. Invoice --> | <!-- e.g. src/entities/invoice.go, src/usecases/invoice/ --> |
| <!-- e.g. Payment --> | <!-- e.g. src/entities/payment.go --> |

## Naming Conventions

| Item | Convention | Contoh |
|------|-----------|--------|
| Entity struct | PascalCase | `InvoiceDetail` |
| File name | kebab-case | `bulk-upsert.go` |
| JSON field | camelCase | `invoiceNumber` |
| DB field (Mongo) | camelCase | `bson:"invoiceNumber"` |
| DB field (PG) | snake_case | `gorm:"column:invoice_number"` |
| Env variable | SCREAMING_SNAKE | `DATABASE_URL` |
| API endpoint | kebab-case | `/v1/invoice-detail` |
| Component (React) | PascalCase | `InvoiceTable.tsx` |
| Hook (React) | camelCase `use` prefix | `useInvoices.ts` |

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
| `DATABASE_URL` | Yes | MongoDB connection string |
| `REDIS_URL` | Yes | Redis connection string |
| `JWT_SECRET` | Yes | JWT signing key |
| `PORT` | No | Server port (default: 8080) |

## Domain-Specific Rules

<!-- Rules khusus project ini yang tidak ada di skill umum -->

- <!-- e.g. Semua monetary value dalam cents (integer), bukan float -->
- <!-- e.g. RefId selalu UUID v7 via Strings.GenerateRefId() -->
- <!-- e.g. Soft delete: pakai deletedAt field, jangan hard delete -->

## External Services

<!-- Service lain yang di-call project ini -->

| Service | Purpose | Driver File |
|---------|---------|-------------|
| <!-- e.g. SAP --> | <!-- e.g. Sync master data --> | <!-- e.g. src/drivers/sap/ --> |

## Notes

<!-- Hal-hal penting lain yang perlu diketahui sebelum mulai kerja -->

- <!-- e.g. Migration pakai golang-migrate, bukan GORM auto-migrate -->
- <!-- e.g. Event emitter untuk async side effects, bukan goroutine langsung -->
