# Controllers

## Dua Pattern Controller

Ada 2 pattern controller yang digunakan:

### Pattern 1: Domain Controller (per domain, di subfolder)

File: `src/interfaces/http-<type>/controllers/v1/<domain>/interface.go`

Digunakan untuk domain yang punya banyak handler (CRUD, list, detail, dll).

```go
package <Domain>V1Controller

import (
	Applications "mika/<service>/src/definitions/applications"

	"github.com/labstack/echo/v5"
)

type Controller struct {
	*Applications.AppContext
}

type IController interface {
	List(c *echo.Context) error
	Detail(c *echo.Context) error
	Create(c *echo.Context) error
}

func New(appContext *Applications.AppContext) IController {
	return &Controller{
		appContext,
	}
}
```

### Pattern 2: Simple Controller (di root controllers/v1/)

File: `src/interfaces/http-<type>/controllers/v1/interface.go`

Digunakan untuk handler sederhana (ping, health check) yang tidak perlu subfolder.

```go
package V1Controller

import (
	Applications "mika/<service>/src/definitions/applications"

	"github.com/labstack/echo/v5"
)

type Controller struct {
	*Applications.AppContext
}

type IController interface {
	Ping(c *echo.Context) error
}

func New(appContext *Applications.AppContext) IController {
	return &Controller{
		appContext,
	}
}
```

## PENTING: BaseController ada di AppContext

`BaseController` BUKAN field terpisah di controller struct. Dia sudah ada di `AppContext`:

```go
// di definitions/applications/app.go
type AppContext struct {
	BaseController     BaseController.IBaseController
	Mongo              Mongo.IMongo
	Redis              Redis.IRedis
	// ... other dependencies ...
}
```

Karena controller embed `*Applications.AppContext`, akses BaseController via `i.BaseController`.

## Handler Pattern — List

```go
type listRequest struct {
	Keyword             string `query:"keyword"`
	ConsultationChannel string `query:"consultation_channel" validate:"required,oneof=CALL_CENTER MIKA_APP KIOSK"`
	StartDate           string `query:"start_date" validate:"omitempty,IsDateFormat"`
	Page                *int   `query:"page" validate:"omitempty,gte=1"`
	PerPage             *int   `query:"per_page"`
}

func (i *Controller) List(c *echo.Context) error {
	payload := new(listRequest)
	_, err := i.BaseController.Validation(payload, c)
	if err != nil {
		return err
	}

	// Instantiate usecase (DI manual di handler)
	usecase := <Domain>Usecase.New(
		c.Request().Context(),
		<Domain>Repository.New(i.Mongo),
		// ... other repositories ...
		i.SAPService,
		i.EventEmitter,
	)

	result, err := usecase.List(&<Domain>Usecase.ParamsList{
		Keyword: payload.Keyword,
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, Applications.SuccessResponse{
		Status:  true,
		Message: "OK",
		Data:    result,
	})
}
```

## Handler Pattern — Detail

```go
type detailRequest struct {
	RefId string `param:"refId" json:"-" validate:"required"`
}

func (i *Controller) Detail(c *echo.Context) error {
	payload := new(detailRequest)
	user, err := i.BaseController.Validation(payload, c)
	if err != nil {
		return err
	}

	usecase := <Domain>Usecase.New(
		c.Request().Context(),
		<Domain>Repository.New(i.Mongo),
		// ... dependencies ...
	)

	result, err := usecase.Detail(payload.RefId, user.UserId)
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, Applications.SuccessResponse{
		Status:  true,
		Message: "OK",
		Data:    result,
	})
}
```

## Handler Pattern — Create/Update

```go
type createRequest struct {
	Name        string  `json:"name" validate:"required"`
	Description *string `json:"description"`
	IsActive    *bool   `json:"is_active"`
}

func (i *Controller) Create(c *echo.Context) error {
	payload := new(createRequest)
	user, err := i.BaseController.Validation(payload, c)
	if err != nil {
		return err
	}

	usecase := <Domain>Usecase.New(
		c.Request().Context(),
		<Domain>Repository.New(i.Mongo),
		i.EventEmitter,
	)

	result, err := usecase.Create(&<Domain>Usecase.ParamsCreate{
		Name:        payload.Name,
		Description: payload.Description,
		CreatedBy:   user.UserId,
	})
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, Applications.SuccessResponse{
		Status:  true,
		Message: "OK",
		Data:    result,
	})
}
```

## Swagger Documentation

Gunakan godoc annotations di atas handler:

```go
// List godoc
// @Summary      List <Domain>
// @Description  Get a list of <domain> with optional filters
// @Security     BearerAccessToken
// @Tags         <Domain>
// @Accept       json
// @Produce      json
// @Param        payload query listRequest true "Payload"
// @Success      200  {object}  Applications.SuccessResponse{data=[]Serializers.<Domain>}
// @Failure      400  {object}  Applications.SuccessResponse
// @Router       /v1/<domain> [get]
func (i *Controller) List(c *echo.Context) error {
	// ...
}
```

## Key Points

- Controller struct hanya embed `*Applications.AppContext` — TIDAK ada field tambahan
- Return type handler: `error` (bukan `(err error)`)
- `i.BaseController.Validation(payload, c)` — return `(*BaseController.User, error)`
- Underscore `_` untuk user jika tidak dipakai: `_, err := i.BaseController.Validation(...)`
- Usecase di-instantiate di dalam handler, bukan di constructor
- Repository di-instantiate dengan `New(i.Mongo)` di dalam handler
- Usecase biasanya menerima `c.Request().Context()` sebagai parameter pertama
- Response: `c.JSON(http.StatusOK, Applications.SuccessResponse{Status: true, Message: "OK", ...})`
- Error: cukup return, ditangani `Helpers.ErrorHandler` di Echo
- Satu file per handler: `list.go`, `detail.go`, `create.go`, `check-availability.go`
