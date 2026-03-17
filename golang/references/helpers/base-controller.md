# BaseController

File: `helpers/base-controller/controller.go`

## Struct & Interface

```go
package BaseController

import (
	Entities "mika/<service>/src/entities"
	Validators "mika/<service>/src/helpers/validators"

	"github.com/gofiber/fiber/v2"
	"github.com/mitchellh/mapstructure"
)

type (
	BaseController  struct{}
	IBaseController interface {
		Validation(pPayload interface{}, c *fiber.Ctx) (*User, error)
	}

	User struct {
		UserType     string         `json:"userType"`
		UserId       string         `json:"userId"`
		DeviceId     string         `json:"deviceId"`
		UserToken    string         `json:"userToken"`
		EmployeeData *Entities.User `json:"employeeData"`
	}
)

func New() IBaseController {
	return &BaseController{}
}
```

## Validation Flow

```go
func (i *BaseController) Validation(payload interface{}, c *fiber.Ctx) (*User, error) {
	profile := new(User)
	validator := &Validators.CustomValidator{Validator: Validators.InitValidator()}

	// 1. Decode user profile dari c.Locals("user")
	if err := mapstructure.Decode(c.Locals("user"), profile); err != nil {
		return nil, fiber.NewError(http.StatusBadRequest, "Invalid user profile")
	}

	if payload != nil {
		// 2. Parse JSON body
		if err := c.BodyParser(payload); err != nil && len(c.Body()) > 0 {
			return nil, fiber.NewError(fiber.StatusBadRequest, "Invalid JSON")
		}

		// 3. Parse query params
		if err := c.QueryParser(payload); err != nil && len(c.Queries()) > 0 {
			return nil, fiber.NewError(fiber.StatusBadRequest, "Invalid Query Params")
		}

		// 4. Parse URL params
		if err := c.ParamsParser(payload); err != nil && len(c.AllParams()) > 0 {
			return nil, fiber.NewError(fiber.StatusBadRequest, "Invalid Url Params")
		}

		// 5. Run validation rules
		if err := validator.Validate(c, payload); err != nil {
			return nil, err
		}
	}

	return profile, nil
}
```

Return: `(*BaseController.User, error)`
