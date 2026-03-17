# Usecases

Package: `<Domain>Usecase` — Lokasi: `src/usecases/<domain>/`

## Rules

1. Struct menyimpan semua dependency: repositories, event emitter, logger, dsb
2. Interface `I<Domain>` mendefinisikan semua method
3. Constructor: `New(...)` return `I<Domain>`
4. Satu file per operasi
5. `errors.go` berisi semua `var Err... = errors.New(...)` untuk domain
6. Error handling: log error → return domain-specific error (bukan raw DB error)
7. TIDAK boleh import fiber atau HTTP-related packages
8. Params struct didefinisikan di file operasi masing-masing
9. Usecase di-instantiate di dalam controller handler, bukan di constructor controller

## File Structure

```
src/usecases/<domain>/
├── interface.go    # Struct + Interface + New()
├── errors.go       # Error variables
├── list.go         # ParamsList + List()
├── detail.go       # Detail()
├── count.go        # ParamsCount + Count()
├── bulk-create.go  # ParamsBulkCreate + BulkCreate()
└── update-*.go     # Update operations
```

## Template interface.go

```go
package <Domain>Usecase

import (
	Applications "mika/<service>/src/definitions/applications"
	Postgres "mika/<service>/src/drivers/postgres"
	Entities "mika/<service>/src/entities"
	Logger "mika/<service>/src/helpers/logger"
	Requestor "mika/<service>/src/helpers/requestor"
	<Domain>Repository "mika/<service>/src/repositories/<domain>"
	OtherRepository "mika/<service>/src/repositories/<other>"

	"github.com/jiyeyuran/go-eventemitter"
)

type <Domain> struct {
	<Domain>Repository <Domain>Repository.I<Domain>
	OtherRepository    OtherRepository.IOther
	Gorm               *Postgres.DBWithHooks
	EventEmitter       eventemitter.IEventEmitter
	Logger             Logger.ILogger
}

type I<Domain> interface {
	List(params *ParamsList) ([]Entities.<Domain>, *Applications.Meta, error)
	Detail(refId string) (*Entities.<Domain>, error)
}

func New(
	repo <Domain>Repository.I<Domain>,
	otherRepo OtherRepository.IOther,
	eventEmitter eventemitter.IEventEmitter,
	gorm *Postgres.DBWithHooks,
	logger Logger.ILogger,
	requestor Requestor.IRequestor,
) I<Domain> {
	return &<Domain>{
		<Domain>Repository: repo,
		OtherRepository:    otherRepo,
		Gorm:               gorm,
		EventEmitter:       eventEmitter,
		Logger:             logger,
	}
}
```

Dipanggil di controller handler:
```go
usecase := <Domain>Usecase.New(
	<Domain>Repository.New(i.Mongo, i.Postgres),
	OtherRepository.New(i.Mongo, i.Postgres),
	i.EventEmitter,
	i.Postgres.GetGormWithHooks(),
	i.Logger,
	i.Requestor,
)
```

## Template errors.go

```go
package <Domain>Usecase

import "errors"

var Err<Domain>NotFound = errors.New("<domain> \"%v\" not found")
var ErrFailedCreate<Domain> = errors.New("failed to create <domain>")
```

Error messages pakai `%v` placeholder untuk `fmt.Errorf()`.

## Template List

```go
type ParamsList struct {
	Keyword  string
	Status   string
	Statuses []string
	Page     int
	PerPage  int
}

func (i *<Domain>) List(params *ParamsList) ([]Entities.<Domain>, *Applications.Meta, error) {
	results, meta, err := i.<Domain>Repository.Find(<Domain>Repository.ParamsFind{
		Keyword:  params.Keyword,
		Statuses: params.Statuses,
		Page:     params.Page,
		PerPage:  params.PerPage,
	})

	if err != nil {
		log.Error(Logger.Fields{"error": err.Error()})
		return nil, nil, errors.New("failed to get <domain>")
	}

	return results, meta, nil
}
```

## Template Detail

```go
func (i *<Domain>) Detail(refId string) (*Entities.<Domain>, error) {
	result, err := i.<Domain>Repository.FindById(refId)
	if err != nil {
		log.Error(Logger.Fields{"error": err.Error()})
		return nil, fmt.Errorf(Err<Domain>NotFound.Error(), refId)
	}
	return result, nil
}
```

## Event Emission Pattern

Setelah operasi write (create/update), emit event untuk sync:

```go
if len(syncIds) > 0 {
	i.EventEmitter.Emit("SYNC_<DOMAIN>", syncIds)
}
```

## Multi-Repository Usecase

Jika usecase butuh banyak repository, tambahkan semua di struct:

```go
type InvoiceProgress struct {
	InvoiceRepository          InvoiceRepository.IInvoice
	InvoiceProgressRepository  InvoiceProgressRepository.IInvoiceProgress
	DepartmentStatusRepository DepartmentStatusRepository.IDepartmentStatus
	ChangeLogRepository        ChangeLogRepository.IChangeLog
	EventEmitter               eventemitter.IEventEmitter
	Logger                     Logger.ILogger
}
```
