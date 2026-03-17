---
name: golang-clean-architecture
description: >
  Go microservice development skill using Clean Architecture pattern with GoFiber, MongoDB, PostgreSQL (GORM), Redis, and EventEmitter.
  Use when creating new Go services, adding new domains/features, writing entities, models, repositories, usecases,
  controllers, routes, middlewares, drivers, helpers, definitions, or any Go backend development in this codebase.
---

# Go Clean Architecture Service Pattern

Kamu adalah senior backend engineer dengan pengalaman bertahun-tahun di Go ecosystem.
Kamu memahami best practices clean architecture, concurrency patterns, performance tuning, dan production-grade microservice development.

Skill ini mendefinisikan pattern development Go microservice yang digunakan di seluruh codebase.
Setiap service mengikuti Clean Architecture dengan layer separation yang ketat.

## When to use this skill

- Membuat service Go baru dari scratch
- Menambah domain/feature baru ke service yang sudah ada
- Membuat entity, model, repository, usecase, controller, route, middleware, driver, helper, atau definition baru
- Review atau refactor kode Go di codebase ini
- Debugging atau tracing flow dari HTTP request sampai database

## Architecture Overview

```
Interface Layer (HTTP/Event) → Usecase Layer → Repository Layer → Driver Layer (MongoDB/PostgreSQL/Redis)
```

Setiap layer hanya depend ke layer di bawahnya. Tidak boleh ada circular dependency.

## Project Structure

Refer to: `references/project-structure.md`

## Layer-by-Layer Guide

### 1. Entities (Domain Objects)

Pure Go structs tanpa dependency ke database atau framework.
TIDAK boleh ada `bson` atau `gorm` tags di entities — hanya `json` dan `mapstructure`.

Refer to: `references/entities.md`

### 2. Drivers (External Adapters)

Adapters untuk semua external dependencies. Setiap driver punya file dokumentasi tersendiri, termasuk models di dalamnya.

Refer to: `references/drivers/README.md`

#### Database Drivers
- **MongoDB** — driver + BSON models (`bson:"camelCase"`) → `references/drivers/mongo.md`
- **PostgreSQL** — driver GORM + models (`gorm:"column:snake_case"`) → `references/drivers/postgres.md`
- **Redis** — caching driver → `references/drivers/redis.md`

#### External Service Drivers
- **SAP** — SAP external service → `references/drivers/sap.md`
- **Nunggu** — Job queue service → `references/drivers/nunggu.md`
- **Microservice Clients** — pattern untuk panggil service lain → `references/drivers/service-client.md`

#### Infrastructure Drivers
- **Authorizer** — token verification → `references/drivers/authorizer.md`
- **Event Emitter** — in-process event emitter → `references/drivers/event-emitter.md`
- **CloudWatch** — AWS CloudWatch logging → `references/drivers/cloudwatch.md`

#### Bootstrap
- **main.go** — init semua drivers & launch interface → `references/drivers/bootstrap.md`

### 3. Definitions (Constants & Config)

AppContext (DI container), response structs, enums, domain-specific constants.

Refer to: `references/definitions.md`

### 4. Repositories (Data Access)

Data access layer yang berinteraksi dengan MongoDB/PostgreSQL melalui driver.

Refer to: `references/repositories.md`

### 5. Usecases (Business Logic)

Business logic layer yang orchestrate repository calls.

Refer to: `references/usecases.md`

### 6. Interfaces (Transport/Delivery)

HTTP controllers, routes, middlewares, dan event handlers.

Refer to: `references/interfaces.md`

### 7. Helpers (Shared Utilities)

Base controller, validators, serializers, logger, requestor, dan utility functions.

Refer to: `references/helpers.md`

## Critical Rules

1. Package naming: PascalCase alias — `import Entities "agungsdas/<service>/src/entities"`
2. Satu file = satu fungsi/operasi (find.go, bulk-upsert.go, list.go)
3. Interface selalu di `interface.go` dalam setiap package
4. Constructor selalu `New(...)` yang return interface, bukan struct
5. Usecase di-instantiate di dalam controller handler, bukan di constructor
6. Response selalu pakai `Applications.SuccessResponse{Status: true, Message: "OK", ...}`
7. Error handling: return error ke atas, ditangani oleh `Helpers.ErrorHandler` di Fiber
8. RefId generation: `Strings.GenerateRefId()` (UUID v7) atau `Strings.GenerateRandomStringFromString()` (MD5 hash)
9. Pointer helpers untuk nullable fields: `Type.ToBoolPntr()`, `Type.ToTimePntr()`, `Type.ToStringPntr()`
10. Validation pakai `go-playground/validator` dengan custom rules di `helpers/validators/`
11. Entity struct TIDAK boleh punya `bson` atau `gorm` tags — database tags hanya di level Models
12. MongoDB models pakai `bson:"camelCase"`, PostgreSQL models pakai `gorm:"column:snake_case"`
