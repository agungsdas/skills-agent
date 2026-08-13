# Routes

File: `src/interfaces/http-<type>/routes/v1/interface.go`

## Struct & Interface

```go
package V1Routes

import (
	Applications "mika/<service>/src/definitions/applications"
	Middlewares "mika/<service>/src/interfaces/http-<type>/middlewares"

	"github.com/labstack/echo/v5"
)

type Route struct {
	*Applications.AppContext
	Router      *echo.Group
	Middlewares Middlewares.IMiddleware
}

type IRoute interface {
	MountPing()
	Mount<Domain>()
}

func New(appContext *Applications.AppContext, middlewares Middlewares.IMiddleware, router *echo.Group) IRoute {
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

	// Tanpa authorization (public endpoint)
	g.GET("", controller.List)
	g.GET("/:refId", controller.Detail)

	// Dengan authorization (protected endpoint)
	g.POST("", controller.Create, i.Middlewares.Authorization(&Middlewares.AuthorizationParams{
		UserType: []string{"INTERNAL_LDAP"},
		Roles:    []string{"ADMIN", "SUPER_ADMIN"},
	}))
	g.PATCH("/:refId", controller.Update, i.Middlewares.Authorization(&Middlewares.AuthorizationParams{
		UserType: []string{"INTERNAL_LDAP"},
	}))
}
```

### AuthorizationParams

```go
type AuthorizationParams struct {
	Roles      []string  // Role-based access: "ADMIN", "SUPER_ADMIN", etc.
	UserType   []string  // User type filter: "INTERNAL_LDAP", "MIKA_APP", etc.
	AllowBasic bool      // Allow Basic Auth (for service-to-service)
}
```

- `Roles` — filter berdasarkan role employee (SUPER_ADMIN selalu bypass)
- `UserType` — filter berdasarkan tipe user dari token
- `AllowBasic` — izinkan Basic Auth (biasanya untuk internal/service-to-service)

Jangan lupa: tambah `Mount<Domain>()` di `IRoute` interface dan panggil di `launch.go`.

## HTTP Method Mapping (Echo v5)

| Method | Echo |
|--------|------|
| GET | `g.GET(path, handler, ...middleware)` |
| POST | `g.POST(path, handler, ...middleware)` |
| PUT | `g.PUT(path, handler, ...middleware)` |
| PATCH | `g.PATCH(path, handler, ...middleware)` |
| DELETE | `g.DELETE(path, handler, ...middleware)` |

Note: Di Echo v5, middleware di-pass sebagai variadic argument setelah handler (bukan sebelum).
