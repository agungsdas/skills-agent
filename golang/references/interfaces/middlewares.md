# Middlewares

File: `src/interfaces/http-<type>/middlewares/interface.go`

## Struct & Interface

```go
package Middlewares

import (
	Mongo "mika/<service>/src/drivers/mongo"
	Postgres "mika/<service>/src/drivers/postgres"
	Logger "mika/<service>/src/helpers/logger"

	"github.com/gofiber/fiber/v2"
	"github.com/jiyeyuran/go-eventemitter"
)

type Middleware struct {
	Mongo        Mongo.IMongo
	Postgres     Postgres.IPostgres
	Logger       Logger.ILogger
	EventEmitter eventemitter.IEventEmitter
}

type IMiddleware interface {
	Authorization() fiber.Handler
	PanicRecover() fiber.Handler
}

func New(
	mongo Mongo.IMongo,
	postgres Postgres.IPostgres,
	logger Logger.ILogger,
	eventEmitter eventemitter.IEventEmitter,
) IMiddleware {
	return &Middleware{
		Mongo:        mongo,
		Postgres:     postgres,
		Logger:       logger,
		EventEmitter: eventEmitter,
	}
}
```

Key Points:
- `New()` menerima 4 parameter: `mongo`, `postgres`, `logger`, `eventEmitter`
- `Authorization()` tanpa parameter, return `fiber.Handler`
- Pattern sama untuk http-public, http-private, dan http-internal (kecuali http-internal mungkin tanpa Authorization)

## Authorization Middleware

Perbedaan utama antara http-public dan http-private ada di `UserType` check:

**http-public** (Mobile App):
```go
func (i *Middleware) Authorization() fiber.Handler {
	return func(c *fiber.Ctx) error {
		authHeader := c.Get("Authorization")
		if authHeader == "" {
			return fiber.NewError(fiber.StatusUnauthorized, "Authorization header is missing")
		}

		token := strings.TrimPrefix(authHeader, "Bearer ")
		claims, err := Authorizer.VerifyToken(token)
		if err != nil {
			return fiber.NewError(fiber.StatusUnauthorized, err.Error())
		}

		c.Locals("claims", claims)
		c.Locals("user", BaseController.User{
			UserType:  claims.UserType,
			UserId:    claims.ID,
			DeviceId:  claims.Device,
			UserToken: token,
		})

		if claims.UserType != "MIKA_APP" {
			return errors.New("invalid user type")
		}

		userData := make(map[string]interface{})
		mapstructure.Decode(claims.UserData, &userData)

		if userData["userId"] == nil {
			return fiber.NewError(fiber.StatusUnauthorized, "User data not found")
		}

		return c.Next()
	}
}
```

**http-private** (CMS Admin):
```go
// Sama persis, kecuali UserType check:
if claims.UserType != "MIKA_APP_CMS" {
	return errors.New("invalid user type")
}
```

**User struct** (dari `BaseController` package):
```go
type User struct {
	UserType     string         `json:"userType"`
	UserId       string         `json:"userId"`
	DeviceId     string         `json:"deviceId"`
	UserToken    string         `json:"userToken"`
	EmployeeData *Entities.User `json:"employeeData"`
}
```
