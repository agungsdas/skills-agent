# Definitions

Lokasi: `src/definitions/`

## AppContext (DI Container)

Package: `Applications` — File: `definitions/applications/app.go`

```go
type AppContext struct {
	Mongo        Mongo.IMongo
	Redis        Redis.IRedis
	Logger       Logger.ILogger
	Requestor    Requestor.IRequestor
	EventEmitter eventemitter.IEventEmitter
}
```

Tambah field baru di sini jika ada driver baru, lalu inisialisasi di `main.go`.

## Response Structs

File: `definitions/applications/response.go`

```go
type Meta struct {
	Page      int `json:"page"`
	PerPage   int `json:"per_page"`
	TotalPage int `json:"total_page"`
	Total     int `json:"total"`
}

type SuccessResponse struct {
	Status  bool        `json:"status"`
	Message string      `json:"message"`
	Meta    interface{} `json:"meta"`
	Data    interface{} `json:"data"`
}
```

Semua endpoint return `SuccessResponse` dengan `Status: true, Message: "OK"`.

## Enum — Simple Constants

Package: domain-specific (contoh: `Invoices`)

```go
const (
	STATUS_PENDING    = "PENDING"
	STATUS_INPROGRESS = "IN_PROGRESS"
	STATUS_COMPLETED  = "COMPLETED"
)
```

## Enum — Dot Notation (Struct-based)

Package: `Enums`

```go
type role struct {
	SUPER_ADMIN string
	ADMIN       string
	DEVELOPER   string
}

var ROLE = role{
	SUPER_ADMIN: "SUPER_ADMIN",
	ADMIN:       "ADMIN",
	DEVELOPER:   "DEVELOPER",
}
```

Akses: `Enums.ROLE.SUPER_ADMIN`

## Date Format Constants

```go
var DATE_FULL_FORMAT = "2006-01-02 15:04:05 -07:00"
var DATE_TIME_FORMAT = "2006-01-02 15:04:05"
var ONLY_DATE_FORMAT = "2006-01-02"
var ONLY_TIME_FORMAT = "15:04:05"
```

## Domain-Specific Definitions

Contoh: `definitions/invoices/`

- `department.go` — `const DEPT_TUKFAK = "TUKFAK"` dst
- `status.go` — `const STATUS_PENDING = "PENDING"` dst
- `processor.go` — `const ORC_SAP = "SAP"` dst
- `workflow.go` — Workflow registry map + `init()` function
- `workflow-<sub>.go` — Workflow definitions per sub-domain
- `gl-department-rules.go` — Business rules map

## Workflow Pattern

```go
var InvoiceWorkflows map[string]Entities.Workflow = map[string]Entities.Workflow{}

func InvoiceWorkflowKey(department, status string) string {
	key := fmt.Sprintf("%v|%v", department, status)
	return Strings.GenerateRandomStringFromString(fmt.Sprintf("INVOICE|%v", key))
}

func GetInvoiceWorkflow(department, status string) Entities.Workflow {
	return InvoiceWorkflows[InvoiceWorkflowKey(department, status)]
}

func init() {
	run<Sub1>Workflow()
	run<Sub2>Workflow()
}
```

Setiap workflow sub-file mendefinisikan `Entities.Workflow` dengan `Actions map[string]*Entities.Action`.
Setiap Action punya `Process []Entities.Process` yang mendefinisikan operasi database (INSERT/UPDATE/DELETE).
