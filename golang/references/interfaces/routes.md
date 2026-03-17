# Routes

File: `src/interfaces/http-<type>/routes/v1/interface.go`

## Struct & Interface

```go
package V1Routes

import (
	Applications "mika/<service>/src/definitions/applications"
	Middlewares "mika/<service>/src/interfaces/http-<type>/middlewares"

	"github.com/gofiber/fiber/v2"
)

type Route struct {
	*Applications.AppContext
	Router      fiber.Router
	Middlewares Middlewares.IMiddleware
}

type IRoute interface {
	MountPing()
	Mount<Domain>()
}

func New(appContext *Applications.AppContext, middlewares Middlewares.IMiddleware, router fiber.Router) IRoute {
	return &Route{
		appContext,
		router,
		middlewares,
	}
}
```

## Mount Method

Satu file per domain: `routes/v1/<domain>.go`

```go
func (i *Route) Mount<Domain>() {
	g := i.Router.Group("/<domain-kebab>")
	controller := <Domain>V1Controller.New(i.AppContext)

	g.Get("", i.Middlewares.Authorization(), controller.List)
	g.Post("", i.Middlewares.Authorization(), controller.Create)
	g.Get("/:refId", i.Middlewares.Authorization(), controller.Detail)
	g.Patch("/:refId", i.Middlewares.Authorization(), controller.Update)
}
```

Jangan lupa: tambah `Mount<Domain>()` di `IRoute` interface dan panggil di `launch.go`.
