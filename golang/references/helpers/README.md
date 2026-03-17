# Helpers

Lokasi: `src/helpers/`

## Sub-documents

- **BaseController** — Validation, User struct → `helpers/base-controller.md`
- **Validators** — CustomValidator, custom validation tags → `helpers/validators.md`
- **Utils** — strings, type, json, mongo, datetime, encryption helpers → `helpers/utils.md`

## Error Handler

File: `helpers/error-handler.go`

Global Fiber error handler yang menangani:
- `*fiber.Error` → return status code + message
- `validator.ValidationErrors` → return human-readable validation message
- Default → return 400 + error message

Di-set di `fiber.Config{ErrorHandler: Helpers.ErrorHandler}`

Response format:
```json
{"status": false, "message": "...", "data": null}
```

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

## Logger

Package: `Logger` — Lokasi: `helpers/logger/`

```go
type ILogger interface {
	NewCustomLogger() *Logger
	AccessLoggerMiddleware() fiber.Handler
	RequestLog(level string, logEntry interface{})
	Shutdown()
}
```

Logging ke CloudWatch + stdout. Pakai `Logger.Fields` untuk structured logging:
```go
log.Error(Logger.Fields{"error": err.Error()})
```

## Requestor (HTTP Client)

Package: `Requestor` — Lokasi: `helpers/requestor/`

```go
type IRequestor interface {
	Request(request *Entities.HttpRequest, body interface{}) (interface{}, error)
}
```

## Application Info

File: `helpers/application.go`

- `GetPackageName() string` — Parse module name dari go.mod
- `GetAppName() string` — Title case dari package name
- `GetVersion() string` — Parse version dari .cz.json (commitizen)

## Panic Recovery

File: `helpers/recover.go`

```go
func Recover(name string) {
	if r := recover(); r != nil {
		fmt.Printf("Recovered! (%v)", name)
	}
}
```
