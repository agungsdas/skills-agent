# Middlewares

File: `src/interfaces/http-<type>/middlewares/interface.go`

## Struct & Interface

```go
package Middlewares

import (
	Applications "mika/<service>/src/definitions/applications"

	"github.com/labstack/echo/v5"
)

type Middleware struct {
	*Applications.AppContext
}

type IMiddleware interface {
	Authorization(params *AuthorizationParams) echo.MiddlewareFunc
	PanicRecover() echo.MiddlewareFunc
}

func New(appContext *Applications.AppContext) IMiddleware {
	return &Middleware{
		appContext,
	}
}
```

Key Points:
- `New()` menerima `*Applications.AppContext`
- `Authorization()` menerima `*AuthorizationParams`, return `echo.MiddlewareFunc`
- Logging di middleware pakai `slog` langsung
- Pattern sama untuk http, http-private, dan http-internal

## AuthorizationParams

```go
type AuthorizationParams struct {
	Roles      []string  // Role-based access control
	UserType   []string  // Filter by user type from token
	AllowBasic bool      // Allow Basic Auth (service-to-service)
}
```

## Authorization Middleware

```go
func (i *Middleware) Authorization(params *AuthorizationParams) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c *echo.Context) error {
			authHeader := c.Request().Header.Get("Authorization")

			if authHeader == "" {
				return echo.NewHTTPError(http.StatusUnauthorized, "Authorization header is missing")
			}

			// Basic Auth support (untuk service-to-service)
			if params.AllowBasic && strings.HasPrefix(authHeader, "Basic ") {
				token := strings.TrimPrefix(authHeader, "Basic ")
				decodedToken, err := base64.StdEncoding.DecodeString(token)
				if err != nil {
					return echo.NewHTTPError(http.StatusUnauthorized, "Failed to decode Authorization token")
				}

				credentials := strings.Split(string(decodedToken), ":")
				if len(credentials) != 2 {
					return echo.NewHTTPError(http.StatusUnauthorized, "Invalid Basic Auth token format")
				}

				c.Set("username", credentials[0])
				c.Set("password", credentials[1])

				return next(c)
			}

			// Bearer token verification
			token := strings.TrimPrefix(authHeader, "Bearer ")

			claims, err := Authorizer.VerifyToken(token, i.LocalCache)
			if err != nil {
				return echo.NewHTTPError(http.StatusUnauthorized, err.Error())
			}

			// UserType check
			if len(params.UserType) > 0 && !slices.Contains(params.UserType, claims.UserType) {
				return echo.NewHTTPError(http.StatusUnauthorized, "You don't have access!")
			}

			c.Set("claims", claims)

			// Employee data extraction (untuk INTERNAL_LDAP users)
			var employeeData = new(Entities.EmployeeLite)
			if claims.UserType == "INTERNAL_LDAP" {
				userData := make(map[string]interface{})
				mapstructure.Decode(claims.UserData, &userData)

				if userData["employee"] == nil {
					return echo.NewHTTPError(http.StatusUnauthorized, "Employee data not found")
				}

				mapstructure.Decode(userData["employee"], &employeeData)

				// Role-based access control
				roles := []string{}
				for _, v := range employeeData.Roles {
					roles = append(roles, v.Role)
				}

				if len(params.Roles) > 0 {
					isApproved := slices.ContainsFunc(roles, func(role string) bool {
						return slices.Contains(params.Roles, role)
					})

					if !isApproved && !slices.Contains(roles, "SUPER_ADMIN") {
						return echo.NewHTTPError(http.StatusUnauthorized, "You don't have access!")
					}
				}
			}

			c.Set("user", BaseController.User{
				UserType:     claims.UserType,
				UserId:       claims.ID,
				DeviceId:     claims.Device,
				UserToken:    token,
				EmployeeData: employeeData,
			})

			return next(c)
		}
	}
}
```

## PanicRecover Middleware

```go
func (i *Middleware) PanicRecover() echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c *echo.Context) error {
			defer func() {
				if r := recover(); r != nil {
					slog.Error("panic recovered",
						"error", fmt.Sprintf("%v", r),
						"stack", string(debug.Stack()),
					)
					c.JSON(http.StatusInternalServerError, map[string]any{
						"status":  false,
						"message": "Internal Server Error",
					})
				}
			}()
			return next(c)
		}
	}
}
```

## Usage di Routes

```go
// Public endpoint (tanpa auth)
g.GET("", controller.List)

// Protected endpoint dengan UserType filter
g.POST("", controller.Create, i.Middlewares.Authorization(&Middlewares.AuthorizationParams{
	UserType: []string{"INTERNAL_LDAP"},
}))

// Protected endpoint dengan Role filter
g.DELETE("/:refId", controller.Delete, i.Middlewares.Authorization(&Middlewares.AuthorizationParams{
	UserType: []string{"INTERNAL_LDAP"},
	Roles:    []string{"ADMIN", "SUPER_ADMIN"},
}))

// Basic Auth (service-to-service)
g.POST("/sync", controller.Sync, i.Middlewares.Authorization(&Middlewares.AuthorizationParams{
	AllowBasic: true,
}))
```
