# Controllers

File: `src/interfaces/http-<type>/controllers/v1/<domain>/interface.go`

## Struct & Interface

```go
package <Domain>V1Controller

import (
	Applications "mika/<service>/src/definitions/applications"
	BaseController "mika/<service>/src/helpers/base-controller"

	"github.com/gofiber/fiber/v2"
)

type Controller struct {
	*Applications.AppContext
	BaseController BaseController.IBaseController
}

type IController interface {
	List(c *fiber.Ctx) (err error)
	Detail(c *fiber.Ctx) (err error)
	Create(c *fiber.Ctx) (err error)
}

func New(appContext *Applications.AppContext) IController {
	return &Controller{appContext, BaseController.New()}
}
```

## Handler Pattern — List

```go
type listRequest struct {
	Keyword string `query:"keyword"`
	Page    *int   `query:"page" validate:"omitempty,gte=1"`
	PerPage *int   `query:"per_page"`
}

func (i *Controller) List(c *fiber.Ctx) (err error) {
	payload := new(listRequest)
	user, err := i.BaseController.Validation(payload, c)
	if err != nil { return err }

	// Instantiate usecase (DI manual di handler)
	usecase := <Domain>Usecase.New(
		<Domain>Repository.New(i.Mongo, i.Postgres),
		// ... other repositories ...
		i.EventEmitter,
		i.Postgres.GetGormWithHooks(),
		i.Logger,
		i.Requestor,
	)

	result, meta, err := usecase.List(&<Domain>Usecase.ParamsList{
		Keyword: payload.Keyword,
	})
	if err != nil { return err }

	return c.JSON(Applications.SuccessResponse{
		Status: true, Message: "OK", Meta: meta, Data: result,
	})
}
```

## Handler Pattern — Detail

```go
type detailRequest struct {
	RefId string `param:"refId" json:"-" validate:"required"`
}

func (i *Controller) Detail(c *fiber.Ctx) (err error) {
	payload := new(detailRequest)
	user, err := i.BaseController.Validation(payload, c)
	if err != nil { return err }

	usecase := <Domain>Usecase.New(
		<Domain>Repository.New(i.Mongo, i.Postgres),
		// ... dependencies ...
	)

	result, err := usecase.Detail(payload.RefId, user.UserId)
	if err != nil { return err }

	return c.JSON(Applications.SuccessResponse{
		Status: true, Message: "OK", Data: result,
	})
}
```

## Key Points

- Request struct: `query`, `json`, `param` tags + `validate` tag
- Selalu `i.BaseController.Validation(payload, c)` untuk parse & validate — return `(*BaseController.User, error)`
- Usecase di-instantiate di dalam handler (bukan constructor)
- Repository di-instantiate dengan `New(i.Mongo, i.Postgres)` di dalam handler
- Response: `Applications.SuccessResponse{Status: true, Message: "OK", ...}`
- Error: cukup return, ditangani `Helpers.ErrorHandler` di Fiber
