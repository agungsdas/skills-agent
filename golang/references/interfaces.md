# Interfaces (Transport Layer)

Lokasi: `src/interfaces/`

## Jenis Interface

| Type | Lokasi | Auth | Use Case |
|------|--------|------|----------|
| `http-private` | `/interfaces/http-private/` | Bearer token + role | User-facing API |
| `http-internal` | `/interfaces/http-internal/` | Minimal/none | Service-to-service |
| `event` | `/interfaces/event/` | N/A | In-process event listener |

Framework: GoFiber (`github.com/gofiber/fiber/v2`)

## Interface Entry Point

Setiap interface punya pattern yang sama:

```go
package Http<Type>

type Interface struct {
	*Applications.AppContext
}

type IInterface interface {
	Launch()
}

func New(appContext *Applications.AppContext) IInterface {
	return &Interface{appContext}
}
```

## Launch Pattern (Fiber Setup)

```go
func (i *Interface) Launch() {
	middlewares := Middlewares.New(i.Mongo, i.Logger)

	app := fiber.New(fiber.Config{
		CaseSensitive: true,
		StrictRouting: false,
		JSONEncoder:   json.Marshal,
		JSONDecoder:   json.Unmarshal,
		ErrorHandler:  Helpers.ErrorHandler,
		AppName:       fmt.Sprintf("%s - %s@v%s", os.Getenv("INTERFACE"), Helpers.GetPackageName(), Helpers.GetVersion()),
		ServerHeader:  fmt.Sprintf("%s@%s", Helpers.GetPackageName(), Helpers.GetVersion()),
	})

	app.Use(middlewares.PanicRecover())
	app.Use(requestid.New())
	app.Use(helmet.New())
	app.Use(i.Logger.AccessLoggerMiddleware())
	app.Use(cors.New(cors.Config{AllowOrigins: Helpers.GetEnv("CORS", "*")}))

	basePath := app.Group(os.Getenv("BASE_PATH"))

	v1 := V1Routes.New(i.AppContext, middlewares, basePath.Group("/v1"))
	v1.MountPing()
	v1.Mount<Domain>()

	app.Listen(fmt.Sprintf(":%s", Helpers.GetEnv("HTTP_<TYPE>_PORT", "3007")))
}
```

## Middleware Pattern

```go
package Middlewares

type Middleware struct {
	Mongo  Mongo.IMongo
	Logger Logger.ILogger
}

type IMiddleware interface {
	Authorization(params *AuthorizationParams) fiber.Handler
	PanicRecover() fiber.Handler
}

func New(mongo Mongo.IMongo, logger Logger.ILogger) IMiddleware {
	return &Middleware{Mongo: mongo, Logger: logger}
}
```

### Authorization Middleware

```go
type AuthorizationParams struct {
	Roles      []string
	AllowBasic bool
}
```

Flow: Parse Bearer token → `Authorizer.VerifyToken()` → Check `UserType == "INTERNAL_LDAP"` → Decode employee dari `UserData` → Check roles → Set `c.Locals("user", employee)`

## Route Pattern

```go
package V1Routes

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
	return &Route{appContext, router, middlewares}
}
```

### Mount Method

```go
func (i *Route) Mount<Domain>() {
	g := i.Router.Group("/<domain-kebab>")
	controller := <Domain>V1Controller.New(i.AppContext)

	g.Get("", i.Middlewares.Authorization(&Middlewares.AuthorizationParams{
		Roles: []string{Enums.ROLE.SUPER_ADMIN, Enums.ROLE.ADMIN},
	}), controller.List)

	g.Get("/count", i.Middlewares.Authorization(&Middlewares.AuthorizationParams{
		Roles: []string{Enums.ROLE.SUPER_ADMIN, Enums.ROLE.ADMIN},
	}), controller.Count)

	g.Get("/:id", i.Middlewares.Authorization(&Middlewares.AuthorizationParams{
		Roles: []string{Enums.ROLE.SUPER_ADMIN, Enums.ROLE.ADMIN},
	}), controller.Detail)

	g.Post("", i.Middlewares.Authorization(&Middlewares.AuthorizationParams{
		Roles: []string{Enums.ROLE.SUPER_ADMIN, Enums.ROLE.ADMIN},
	}), controller.Create)
}
```

Jangan lupa: tambah `Mount<Domain>()` di `IRoute` interface dan panggil di `launch.go`.

## Controller Pattern

```go
package <Domain>V1Controller

type Controller struct {
	*Applications.AppContext
	BaseController BaseController.IBaseController
}

type IController interface {
	List(c *fiber.Ctx) (err error)
	Detail(c *fiber.Ctx) (err error)
}

func New(appContext *Applications.AppContext) IController {
	return &Controller{appContext, BaseController.New()}
}
```

### Handler Pattern

```go
type listRequest struct {
	Keyword  string   `query:"keyword"`
	Status   []string `query:"status" validate:"omitempty,dive,oneof=PENDING IN_PROGRESS COMPLETED"`
	Page     *int     `query:"page" validate:"omitempty,gte=1"`
	PerPage  *int     `query:"per_page"`
}

func (i *Controller) List(c *fiber.Ctx) (err error) {
	payload := new(listRequest)
	_, err = i.BaseController.Validation(payload, c)
	if err != nil { return err }

	// Instantiate usecase (DI manual di handler)
	usecase := <Domain>Usecase.New(
		<Domain>Repository.New(i.Mongo),
		i.EventEmitter,
		i.Logger,
	)

	params := <Domain>Usecase.ParamsList{Keyword: payload.Keyword}
	if payload.Page != nil { params.Page = *payload.Page }
	if payload.PerPage != nil { params.PerPage = *payload.PerPage }

	result, meta, err := usecase.List(&params)
	if err != nil { return err }

	return c.JSON(Applications.SuccessResponse{
		Status: true, Message: "OK", Meta: meta, Data: result,
	})
}
```

### Key Points Controller:
- Request struct: `query`, `json`, `params` tags + `validate` tag
- Selalu `i.BaseController.Validation(payload, c)` untuk parse & validate
- Usecase di-instantiate di dalam handler (bukan constructor)
- Response: `Applications.SuccessResponse`
- Error: cukup return, ditangani `Helpers.ErrorHandler`

## Event Interface Pattern

```go
// services/interface.go
type EventService struct {
	*Applications.AppContext
}

type IEventService interface {
	Ping()
	Sync<Domain>()
}

func NewEventService(appContext *Applications.AppContext) IEventService {
	return &EventService{appContext}
}

// services/sync-<domain>.go
func (i *EventService) Sync<Domain>() {
	i.EventEmitter.On("SYNC_<DOMAIN>", func(refIds []string) {
		// Sync logic here
	})
}

// launch.go
func (i Interface) Launch() {
	svc := ServicesEvent.NewEventService(i.AppContext)
	svc.Ping()
	svc.Sync<Domain>()
}
```
