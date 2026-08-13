---
name: golang-clean-architecture
description: >
  Go microservice development skill using Clean Architecture pattern with Echo v5, MongoDB, PostgreSQL (GORM), Redis, and EventEmitter.
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

## Tech Stack

- **Framework**: Echo v5 (`github.com/labstack/echo/v5`)
- **Database**: MongoDB (`go.mongodb.org/mongo-driver`), PostgreSQL (`gorm.io/gorm`)
- **Cache**: Redis (`github.com/go-redis/redis/v8`)
- **Logging**: `log/slog` dengan custom CloudWatch handler
- **Validation**: `github.com/go-playground/validator/v10`
- **HTTP Client**: `github.com/go-resty/resty/v2`
- **Events**: `github.com/jiyeyuran/go-eventemitter`
- **Swagger**: `github.com/swaggo/swag` + `github.com/swaggo/http-swagger`

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
- **Authorizer** — token verification (bypass mode di local) → `references/drivers/authorizer.md`
- **Event Emitter** — in-process event emitter → `references/drivers/event-emitter.md`
- **CloudWatch** — AWS CloudWatch logging via slog handler → `references/drivers/cloudwatch.md`

#### Bootstrap
- **main.go** — init semua drivers & launch interface → `references/drivers/bootstrap.md`

### 3. Definitions (Constants & Config)

AppContext (DI container), response structs, enums, domain-specific constants.

Refer to: `references/definitions.md`

### 4. Repositories (Data Access)

Data access layer yang berinteraksi dengan MongoDB/PostgreSQL melalui driver.

Refer to: `references/repositories.md`

### 5. Usecases (Business Logic)

Business logic layer yang orchestrate repository calls. Logging via `slog` langsung.

Refer to: `references/usecases.md`

### 6. Interfaces (Transport/Delivery)

HTTP controllers, routes, middlewares, dan event handlers.

Refer to: `references/interfaces/README.md`

### 7. Helpers (Shared Utilities)

Base controller, validators, serializers, logger, requestor, dan utility functions.

Refer to: `references/helpers/README.md`

## Logging

Semua logging menggunakan `log/slog` standard library. Custom slog handler otomatis push ke CloudWatch jika configured.

```go
import "log/slog"

// Di mana pun dalam codebase
slog.Info("user created", "userId", userId, "name", name)
slog.Error("failed to create", "error", err.Error())
slog.Warn("rate limit approaching", "current", count)
```

- Di local (tanpa CloudWatch): pretty-printed colored output di terminal
- Di production (dengan CloudWatch): JSON flat ke CloudWatch log stream
- TIDAK perlu inject Logger ke usecase/repository — cukup `import "log/slog"`

## Swagger

Generate swagger docs:
```bash
make generate-swagger
```

Swagger annotations di controller handler:
```go
// @Summary  Create User
// @Tags     User
// @Accept   json
// @Produce  json
// @Security BearerAccessToken
// @Param    payload body createRequest true "Payload"
// @Router   /v1/user [post]
func (i *Controller) CreateUser(c *echo.Context) error { ... }
```

Swagger UI accessible di `/api-docs/*` (non-production, basic auth protected).

## Critical Rules

1. Package naming: PascalCase alias — `import Entities "mika/<service>/src/entities"`
2. Module path: cek `go.mod` untuk module path yang benar
3. Satu file = satu fungsi/operasi (find.go, bulk-upsert.go, list.go)
4. Interface selalu di `interface.go` dalam setiap package
5. Constructor selalu `New(...)` yang return interface, bukan struct
6. Usecase di-instantiate di dalam controller handler, bukan di constructor
7. Response selalu pakai `c.JSON(http.StatusOK, Applications.SuccessResponse{Status: true, Message: "OK", ...})`
8. Error handling: return error ke atas, ditangani oleh `Helpers.ErrorHandler` di Echo
9. RefId generation: `Strings.GenerateRefId()` (UUID v7) atau `Strings.GenerateRandomStringFromString()` (MD5 hash)
10. Pointer helpers untuk nullable fields: `Type.ToBoolPntr()`, `Type.ToTimePntr()`, `Type.ToStringPntr()`
11. Validation pakai `go-playground/validator` dengan custom rules di `helpers/validators/`
12. Entity struct TIDAK boleh punya `bson` atau `gorm` tags — database tags hanya di level Models
13. MongoDB models pakai `bson:"camelCase"`, PostgreSQL models pakai `gorm:"column:snake_case"`
14. Logging pakai `log/slog` langsung — TIDAK inject Logger ke usecase/repository
15. Handler signature: `func (i *Controller) Method(c *echo.Context) error`
16. Middleware signature: `echo.MiddlewareFunc` = `func(next echo.HandlerFunc) echo.HandlerFunc`
17. Route registration: `g.GET(path, handler, ...middleware)` — middleware setelah handler
18. Struct tags untuk binding: `json:"field"` (body), `query:"field"` (query), `param:"field"` (path)

## Makefile Commands

```bash
make local-http              # Run HTTP server with Air (hot reload)
make local-http-internal     # Run HTTP Internal server with Air
make local                   # Run both HTTP + HTTP Internal
make build                   # Build binary
make generate-swagger        # Generate swagger docs
make migration-create name=x # Create new migration file
make migration-up            # Run pending migrations
make migration-down          # Rollback last migration
make migration-status        # Show migration status
make rename module=x/y       # Rename module path
```
