# Helpers

Lokasi: `src/helpers/`

## Sub-documents

- **BaseController** — Validation, User struct → `helpers/base-controller.md`
- **Validators** — CustomValidator, custom validation tags → `helpers/validators.md`
- **Utils** — strings, type, json, mongo, datetime, encryption helpers → `helpers/utils.md`

## Error Handler

File: `helpers/error-handler.go`

Global Echo error handler. Signature:

```go
func ErrorHandler(c *echo.Context, err error)
```

Menangani:
- `*echo.HTTPError` → return status code + message
- `validator.ValidationErrors` → return human-readable validation message per field
- Default error → return 400 + error message

Di-set di `e.HTTPErrorHandler = Helpers.ErrorHandler`

Response format:
```json
{"status": false, "message": "\"name\" is required", "data": null}
```

## Logger

Package: `Logger` — Lokasi: `helpers/logger/`

Logger menggunakan `log/slog` sebagai backbone dengan custom `slog.Handler` yang push ke CloudWatch.

```go
type ILogger interface {
	NewCustomLogger() *Logger
	AccessLoggerMiddleware() echo.MiddlewareFunc
	RequestLog(level string, logEntry any)
	Shutdown()
	Slog() *slog.Logger
	// + Trace/Debug/Info/Warn/Error/Fatal/Panic methods
}
```

### Arsitektur

```
slog.Info("msg", "key", val)  →  cloudwatchSlogHandler.Handle()  →  writeLog()  →  logChannel  →  processLogs()
                                                                                                        │
                                                                                          ┌─────────────┴─────────────┐
                                                                                          │                           │
                                                                                   CloudWatch != nil           CloudWatch == nil
                                                                                          │                           │
                                                                                   PutLogEvents              printLocal() (pretty)
```

### Cara Pakai (di mana pun dalam codebase)

```go
import "log/slog"

slog.Info("user created", "userId", userId)
slog.Error("failed to create", "error", err.Error(), "personalId", pid)
slog.Warn("approaching limit", "current", count, "max", 100)
```

TIDAK perlu inject Logger. `slog.SetDefault()` sudah dipanggil di `Logger.New()`.

### Output di Local (tanpa CloudWatch)

```
 16:14:53 ┃ INFO  ┃ src/usecases/user/create.go:42
 → {
     "userId": "12345",
     "name": "John"
   }
```

Warna: INFO=hijau, WARN=kuning, ERROR=merah, DEBUG=cyan.

### Output di CloudWatch

Flat JSON satu baris per log entry:
```json
{"request_id":"","timestamp":"2026-06-01T16:14:53+07:00","level":"INFO","interface":"HTTP","message":{"userId":"12345"},"file":"src/usecases/user/create.go","function":"...","line":42}
```

### Access Logger Middleware

`AccessLoggerMiddleware()` return `echo.MiddlewareFunc` yang log setiap request/response:
- Method, URL, status code, latency
- Request headers, body
- Response body
- Token data (user_id, device_id, user_type)
- Filters out health check user agents (kube, elb)

## Requestor (HTTP Client)

Package: `Requestor` — Lokasi: `helpers/requestor/`

```go
type IRequestor interface {
	Request(options *HttpRequestOptions) *resty.Client
}

func New() IRequestor {
	return &Requestor{}
}
```

Features:
- Auto-logging request/response via `slog`
- Configurable timeout (default 60s)
- Retry with exponential backoff
- Basic auth support

Usage:
```go
client := i.Requestor.Request(&Requestor.HttpRequestOptions{
	Timeout:  30,
	MaxRetry: 3,
})

var result ResponseType
client.R().
	SetResult(&result).
	SetAuthToken(token).
	Get("/v1/endpoint")
```

## BaseController

Refer to: `helpers/base-controller.md`

## Serializers

Lokasi: `helpers/serializers/`

Response shape structs (bukan entity, bukan model). Digunakan untuk transform entity ke format response yang diinginkan.

```go
package Serializers

type User struct {
	ID        string     `json:"id"`
	Name      string     `json:"name"`
	CreatedAt *time.Time `json:"created_at"`
	CreatedBy *UserLite  `json:"created_by"`
}

type UserLite struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}
```

## Environment Helpers

File: `helpers/get_env.go`

```go
func GetEnv(key string, defaultVal string) string
func GetEnvAsInt(name string, defaultVal int) int
func GetEnvAsBool(name string, defaultVal bool) bool
func GetEnvAsSlice(name string, defaultVal []string, sep string) []string
func GetEnvAsByte(name string, defaultVal []byte) []byte
```

## Application Info

File: `helpers/application.go`

- `GetPackageName() string` — Parse module name dari go.mod
- `GetAppName() string` — Title case dari package name
- `GetVersion() string` — Parse version dari .cz.json (commitizen)
