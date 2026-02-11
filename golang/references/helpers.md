# Helpers

Lokasi: `src/helpers/`

## BaseController

File: `helpers/base-controller/controller.go`

```go
type BaseController struct{}

type IBaseController interface {
	Validation(pPayload interface{}, c *fiber.Ctx) (*Entities.EmployeeLite, error)
}

func New() IBaseController { return &BaseController{} }
```

### Validation Flow:
1. Decode user profile dari `c.Locals("user")` → `*Entities.EmployeeLite`
2. `c.BodyParser(payload)` — parse JSON body
3. `c.QueryParser(payload)` — parse query params
4. `c.ParamsParser(payload)` — parse URL params
5. `validator.Validate(c, payload)` — run validation rules

## Validators

File: `helpers/validators/validator.go`

```go
type CustomValidator struct {
	Validator *validator.Validate
}

func InitValidator() *validator.Validate {
	v := validator.New()
	v.RegisterValidation("IsDateFormat", IsDate)
	v.RegisterValidation("IsDateTimeZFormat", IsDateTimeZ)
	v.RegisterValidation("GtDateAddDay", GtDate)
	v.RegisterValidation("IsJson", IsJson)
	v.RegisterValidation("IsConstantCase", IsConstantCase)
	return v
}
```

Library: `github.com/go-playground/validator/v10`

Custom validation tags:
- `IsDateFormat` — format "2006-01-02"
- `IsDateTimeZFormat` — format "2006-01-02 15:04:05 -07:00"
- `GtDateAddDay` — date greater than field + N days
- `IsJson` — valid JSON
- `IsConstantCase` — SCREAMING_SNAKE_CASE

## Error Handler

File: `helpers/error-handler.go`

Global Fiber error handler yang menangani:
- `*fiber.Error` → return status code + message
- `validator.ValidationErrors` → return human-readable validation message
- Default → return 400 + error message

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

## Utility Functions

### strings/
- `GenerateRefId() string` — UUID v7 via `github.com/google/uuid`
- `GenerateRandomStringFromString(input string) string` — MD5 hash
- `IsValidConstantCase(s string) bool`

### structs/
- `DiffModels(old, new interface{}) map[string]map[string]interface{}` — Struct diffing untuk change log. Excludes: ID, CreatedAt, UpdatedAt, DeletedAt. Handles `*time.Time` comparison.

### times/
- `StringToTime(str string, layout string) (*time.Time, error)`

### type/ (Pointer Helpers)
- `ToBoolPntr(b bool) *bool`
- `ToTimePntr(t time.Time) *time.Time`
- `ToStringPntr(s string) *string`

### json/
- `JSONRawToString(raw json.RawMessage) string` — Convert json.RawMessage ke string (handle numeric/string/null)

### mongo/
- BSON helpers dan aggregation lookup builder

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
