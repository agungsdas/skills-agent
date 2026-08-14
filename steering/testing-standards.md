---
inclusion: always
---

# Testing Standards

## Kapan Wajib Test

| Situasi | Wajib? | Jenis Test |
|---------|--------|------------|
| Fitur baru (endpoint, usecase, page) | Ya | Unit + Integration |
| Bug fix | Ya | Minimal 1 test yang reproduce bug |
| Refactor | Tidak wajib tambah baru, tapi existing test HARUS tetap pass |
| Hotfix urgent | Boleh skip di awal, tapi HARUS ditambah dalam 1 sprint |
| Utility / helper function | Ya | Unit test |
| UI component (reusable) | Ya | Component test |
| One-off script / migration | Tidak wajib, tapi validasi manual HARUS didokumentasikan |

## Test Pyramid

Prioritas dari bawah ke atas:

1. **Unit Test** — fungsi/method individual, mock dependencies
2. **Integration Test** — interaksi antar layer (usecase + repo, API endpoint full)
3. **E2E Test** — flow lengkap dari user perspective (opsional, untuk critical path)

Rasio ideal: 70% unit, 20% integration, 10% E2E.

## Naming Convention

### Go

```go
func TestCreateInvoice_Success(t *testing.T) { ... }
func TestCreateInvoice_DuplicateNumber_ReturnsError(t *testing.T) { ... }
func TestCreateInvoice_EmptyPayload_ValidationFails(t *testing.T) { ... }
```

Format: `Test<Function>_<Scenario>_<ExpectedBehavior>`

### TypeScript / JavaScript

```typescript
describe("createInvoice", () => {
  it("should create invoice with valid payload", async () => { ... })
  it("should return error when invoice number is duplicate", async () => { ... })
  it("should validate required fields", async () => { ... })
})
```

Format: `should <expected behavior> [when <condition>]`

## Apa yang Di-test

### Unit Test (Usecase / Service)

- Happy path: input valid → output benar
- Validation: input invalid → error yang tepat
- Edge cases: nil/null, empty, zero, boundary values
- Error propagation: dependency error → error di-return dengan context

### Integration Test (API / Endpoint)

- Request-response cycle lengkap
- Auth: protected endpoint tanpa token → 401
- Auth: token valid tapi role salah → 403
- Validation: body invalid → 400 dengan detail field
- Not found: resource yang tidak ada → 404
- Pagination: limit, page, total benar

### Component Test (React)

- Render tanpa crash
- User interaction: click, type, submit
- State transitions: loading → success, loading → error
- Conditional rendering: empty state, error state
- Accessibility: role, aria-label bisa di-query

## Mocking Strategy

### Go

- Interface-based mocking — semua dependency via interface
- Mock di-generate atau ditulis manual di `_test.go`
- JANGAN mock database langsung — pakai repository interface
- External service: mock HTTP client atau service interface

### TypeScript

- API calls: mock fetch/axios atau MSW (Mock Service Worker)
- Database: mock repository/service layer, bukan Mongoose langsung
- Components: mock child components yang complex (chart, map)
- Zustand/Redux: pakai real store, bukan mock — test behavior, bukan implementation

## Rules

1. **Test HARUS bisa jalan independen** — tidak depend ke test lain, tidak depend ke order
2. **Test HARUS repeatable** — hasil sama setiap kali dijalankan (no time-dependency, no random)
3. **Test HARUS cepat** — unit test < 1 detik per file. Slow test = integration test, pisahkan
4. **Test failure message HARUS jelas** — "expected 5, got 3" lebih baik dari "assertion failed"
5. **Jangan test implementation detail** — test behavior/output, bukan internal state
6. **1 test = 1 assertion utama** — boleh multiple assertion kalau satu logical unit
7. **Setup/teardown yang bersih** — test tidak meninggalkan side effect (DB state, file, env)
8. **Jangan skip/disable test tanpa alasan** — kalau skip, tambahkan comment WHY dan kapan akan di-fix

## Coverage Target

| Layer | Minimum | Ideal |
|-------|---------|-------|
| Usecase / Service | 80% | 90%+ |
| Repository | 60% | 80% |
| Controller / Handler | 70% | 85% |
| Utility / Helper | 90% | 100% |
| UI Component (shared) | 70% | 85% |

Coverage bukan goal — tapi indicator. 100% coverage tanpa meaningful assertion = useless.

## Anti-Pattern

- ❌ Test yang cuma assert `!= nil` tanpa cek value
- ❌ Test tanpa assertion (just "doesn't crash")
- ❌ Hardcoded IDs/timestamps yang bisa stale
- ❌ Test yang depend ke external service (real API call)
- ❌ `t.Skip()` / `.skip()` tanpa explanation
- ❌ Giant test function yang test 10 hal sekaligus
- ❌ Copy-paste test tanpa adaptasi (same assertion, different name)
- ❌ Mock everything sampai test tidak bermakna

