---
name: golang-clean-architecture
description: >
  Go microservice development skill using Clean Architecture pattern with GoFiber, MongoDB, Redis, and EventEmitter.
  Use when creating new Go services, adding new domains/features, writing entities, models, repositories, usecases,
  controllers, routes, middlewares, drivers, helpers, definitions, or any Go backend development in this codebase.
---

# Go Clean Architecture Service Pattern

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
Interface Layer (HTTP/Event) → Usecase Layer → Repository Layer → Driver Layer (MongoDB/Redis)
```

Setiap layer hanya depend ke layer di bawahnya. Tidak boleh ada circular dependency.

## Project Structure

Refer to: `references/project-structure.md`

## Layer-by-Layer Guide

### 1. Entities (Domain Objects)

Pure Go structs tanpa dependency ke database atau framework.

Refer to: `references/entities.md`

### 2. Mongo Models (Data Layer)

BSON-tagged structs dengan index definitions, collection setup, dan `ToEntity()` converter.

Refer to: `references/mongo-models.md`

### 3. Drivers (External Adapters)

Adapters untuk MongoDB, Redis, CloudWatch, Authorizer, EventEmitter.

Refer to: `references/drivers.md`

### 4. Definitions (Constants & Config)

AppContext (DI container), response structs, enums, domain-specific constants.

Refer to: `references/definitions.md`

### 5. Repositories (Data Access)

Data access layer yang berinteraksi dengan MongoDB melalui driver.

Refer to: `references/repositories.md`

### 6. Usecases (Business Logic)

Business logic layer yang orchestrate repository calls.

Refer to: `references/usecases.md`

### 7. Interfaces (Transport/Delivery)

HTTP controllers, routes, middlewares, dan event handlers.

Refer to: `references/interfaces.md`

### 8. Helpers (Shared Utilities)

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
