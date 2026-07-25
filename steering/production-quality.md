---
inclusion: always
---

# Production Quality: Zero Bug, Zero Assumption

**Setiap output HARUS production-grade. Bukan "good enough", bukan "bisa jalan", tapi PRODUCTION-READY tanpa bug.**

Berlaku untuk SEMUA domain — backend, frontend, infrastructure, database, apapun.

---

## Prinsip #1: Deep Dive — Jangan Pernah Berasumsi

### WAJIB baca dan pahami SEBELUM menulis code:

- **Baca SEMUA file yang terkait** — bukan cuma file yang akan diedit, tapi file yang depend ke situ dan file yang di-depend
- **Pahami flow end-to-end** — dari request masuk sampai response keluar, dari event trigger sampai side effect selesai
- **Baca existing tests** — pahami apa yang sudah di-cover dan apa yang belum
- **Baca existing patterns** — jangan introduce pattern baru kalau sudah ada pattern yang established
- **Cek types/interfaces** — pahami contract antar layer sebelum implementasi

### JANGAN pernah:

- ❌ Assume file/function/method ada tanpa verify — BACA dulu
- ❌ Assume behavior tanpa baca implementation — BACA dulu
- ❌ Assume data shape tanpa baca schema/type — BACA dulu
- ❌ Assume config/env sudah ada tanpa cek — BACA dulu
- ❌ Assume library API tanpa cek docs/source — BACA dulu
- ❌ Bikin code berdasarkan "kayaknya gini" — PASTIKAN dulu

### Kalau tidak tahu / tidak yakin:

- **TANYA** — "Gue perlu info tambahan soal X sebelum lanjut"
- **INVESTIGASI** — baca file, grep codebase, cek docs
- **JANGAN TEBAK** — satu asumsi salah = satu bug di production

---

## Prinsip #2: Zero Bug Tolerance

### Sebelum declare selesai, code HARUS memenuhi SEMUA:

1. **Correct** — logic benar, edge case di-handle, gak ada race condition
2. **Complete** — semua path di-handle (success, error, timeout, empty, nil/null)
3. **Consistent** — pattern sama dengan codebase existing
4. **Resilient** — external failure gak crash app, ada fallback/timeout/retry
5. **Observable** — bisa di-debug di production tanpa re-deploy (logging, tracing)
6. **Secure** — input validated, output sanitized, auth enforced, secrets protected

Kalau SATU SAJA tidak terpenuhi → belum selesai.

---

## Universal Standards (Semua Domain)

### Error Handling — ZERO silent failures

- SETIAP error HARUS di-handle explicitly — tidak ada yang boleh di-ignore
- Error HARUS propagate atau di-log — JANGAN swallow
- Timeout WAJIB di setiap external call (HTTP, DB, cache, queue, file I/O)
- Error message HARUS informatif: apa, kenapa, context

### Input Validation — Trust Nothing

- SEMUA external input di-validate SEBELUM masuk business logic
- Validate type, range, format, length, required
- Server-side validation WAJIB — client-side itu UX bonus, bukan security

### Resilience — Expect Failure

- External dependency bisa down kapan saja — handle gracefully
- Timeout di SETIAP external call — no unbounded waits
- Retry dengan backoff untuk transient errors
- Graceful shutdown: drain, finish in-flight, cleanup
- Idempotency: retry-safe operations

### Observability — See Everything

- Log di entry & exit points
- Correlation/request ID untuk tracing
- Log level yang tepat (Info, Warn, Error)
- JANGAN log sensitive data
- Structured logging — bukan printf debugging

### Security — Default Secure

- Auth check di SETIAP protected resource
- Rate limiting di public endpoints
- No hardcoded secrets
- Principle of least privilege

---

## Backend (Go)

- `go build ./...` zero errors, `go vet ./...` zero warnings
- Tidak ada `_ = err` — semua error di-handle
- Context propagation: SELALU pass dan respect cancellation
- Pagination WAJIB untuk list endpoints
- SETIAP query baru HARUS punya supporting index
- Shared state HARUS punya synchronization (mutex/channel/atomic)
- Goroutine HARUS punya exit path — no leaks
- Defer close/unlock untuk resource cleanup
- Connection pool yang ter-tune

---

## Frontend (Next.js / React)

- Loading state WAJIB — user harus tau something is happening
- Error state WAJIB — user harus tau kalau gagal + bisa retry
- Empty state WAJIB — no blank screens
- useEffect HARUS punya cleanup (abort, unsubscribe, clear timer)
- Race condition handling: AbortController untuk stale requests
- Accessibility: semantic HTML, aria-labels, keyboard nav, focus management
- No XSS: sanitize user input sebelum render
- Responsive: test di mobile viewport
- Server Components by default, Client Component hanya kalau butuh interactivity
- Dynamic import untuk heavy components

---

## Infrastructure (K8s / Helm)

- Resource requests AND limits WAJIB — no unbounded pods
- Health checks HARUS meaningful — cek actual dependencies, bukan cuma return 200
- Rollback plan yang jelas dan tested
- Secret rotation mechanism
- Rolling update dengan proper maxSurge/maxUnavailable

---

## Database

- Index berdasarkan actual query patterns — explain plan sebelum deploy
- Pagination WAJIB — no unlimited queries
- Migration HARUS reversible (punya down/rollback)
- created_at, updated_at di setiap collection/table
- Parameterized query — no string concatenation (prevent injection)
- TTL untuk ephemeral data (sessions, OTP, cache entries)

---

## Anti-Patterns — TIDAK BOLEH TERJADI

- ❌ Assume tanpa verify — ini sumber bug #1
- ❌ Error di-ignore atau di-swallow
- ❌ External call tanpa timeout
- ❌ List endpoint tanpa pagination
- ❌ Query tanpa index
- ❌ Goroutine tanpa exit path
- ❌ useEffect tanpa cleanup
- ❌ User input rendered tanpa sanitization
- ❌ Deploy tanpa meaningful health check
- ❌ Hardcoded secrets
- ❌ "Happy path only" implementation
- ❌ Shared mutable state tanpa lock
- ❌ Code yang "kayaknya benar" tapi belum di-verify

---

## Verification Protocol

SEBELUM bilang "selesai":

1. **Deep dive done** — semua file terkait sudah dibaca dan dipahami
2. **Build pass** — zero errors, zero warnings
3. **Logic verified** — baca ulang code, trace flow manual
4. **Edge cases covered** — nil, empty, zero, timeout, concurrent, duplicate
5. **Error paths complete** — setiap error ada handling yang proper
6. **Security checked** — input validated, auth enforced, output safe
7. **Performance safe** — no N+1, no unbounded, proper indexing
8. **Observable** — logging bermakna di tempat yang tepat
9. **Consistent** — same pattern as existing codebase
10. **No assumptions** — semua behavior sudah di-verify, bukan di-guess

**Kalau ragu di salah satu point → BELUM SELESAI. Investigate atau tanya.**
