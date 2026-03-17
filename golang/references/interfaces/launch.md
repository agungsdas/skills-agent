# Launch Pattern

File: `src/interfaces/http-<type>/launch.go`

```go
func (i *Interface) Launch() {
	middlewares := Middlewares.New(i.Mongo, i.Postgres, i.Logger, i.EventEmitter)

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
	app.Use(func(c *fiber.Ctx) error {
		log.WithContext(c.Context())
		return c.Next()
	})

	basePath := app.Group(os.Getenv("BASE_PATH"))

	// Swagger (non-production only)
	if os.Getenv("ENVIRONMENT") != "production" {
		basePathApp := os.Getenv("BASE_PATH")
		urlSwagger := basePathApp + "/api-docs/doc.json"
		basePath.Get("/api-docs/*", basicauth.New(basicauth.Config{
			Users: map[string]string{"mika": "Merdeka2025!"},
		}), swagger.New(swagger.Config{
			InstanceName: "http<Type>",
			URL:          urlSwagger,
		}))
	}

	basePath.Get("", func(c *fiber.Ctx) error {
		return c.SendString(fmt.Sprintf("API %s for %s", Helpers.GetAppName(), os.Getenv("ENVIRONMENT")))
	})

	v1 := V1Routes.New(i.AppContext, middlewares, basePath.Group("/v1"))
	v1.MountPing()
	v1.Mount<Domain>()

	v2 := V2Routes.New(i.AppContext, middlewares, basePath.Group("/v2"))
	v2.MountPing()

	app.Listen(fmt.Sprintf(":%s", Helpers.GetEnv("HTTP_<TYPE>_PORT", "3000")))
}
```

## Middleware Chain Order

1. `PanicRecover()` — catch panics
2. `requestid.New()` — generate request ID
3. `helmet.New()` — security headers
4. `AccessLoggerMiddleware()` — request logging
5. `cors.New()` — CORS config
6. `log.WithContext()` — attach context to logger
