# Launch Pattern

File: `src/interfaces/http-<type>/launch.go`

```go
func (i *Interface) Launch() {
	middlewares := Middlewares.New(i.AppContext)

	e := echo.New()

	// Global error handler
	e.HTTPErrorHandler = Helpers.ErrorHandler

	// Middleware chain
	e.Use(middlewares.PanicRecover())
	e.Use(middleware.RequestID())
	e.Use(middleware.Secure())
	e.Use(i.Logger.AccessLoggerMiddleware())
	e.Use(middleware.CORSWithConfig(middleware.CORSConfig{
		AllowOrigins: []string{Helpers.GetEnv("CORS", "*")},
	}))

	basePath := e.Group(os.Getenv("BASE_PATH"))

	// Swagger (non-production only)
	if os.Getenv("ENVIRONMENT") != "production" {
		basePath.GET("/api-docs/*", func(c *echo.Context) error {
			httpSwagger.WrapHandler(c.Response(), c.Request())
			return nil
		}, middleware.BasicAuth(func(c *echo.Context, user string, password string) (bool, error) {
			return user == "mika" && password == "Merdeka2025!", nil
		}))
	}

	basePath.GET("", func(c *echo.Context) error {
		return c.String(http.StatusOK, fmt.Sprintf("API %s for %s", Helpers.GetAppName(), os.Getenv("ENVIRONMENT")))
	})

	v1 := V1Routes.New(i.AppContext, middlewares, basePath.Group("/v1"))
	v1.MountPing()
	v1.Mount<Domain>()

	v2 := V2Routes.New(i.AppContext, middlewares, basePath.Group("/v2"))
	v2.MountPing()

	if err := e.Start(fmt.Sprintf(":%s", Helpers.GetEnv("HTTP_<TYPE>_PORT", "3000"))); err != nil && err != http.ErrServerClosed {
		log.Fatal(err)
	}
}
```

## Middleware Chain Order

1. `PanicRecover()` — catch panics
2. `middleware.RequestID()` — generate request ID
3. `middleware.Secure()` — security headers
4. `AccessLoggerMiddleware()` — request logging
5. `middleware.CORSWithConfig()` — CORS config
