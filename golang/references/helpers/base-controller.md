# BaseController

File: `helpers/base-controller/controller.go`

## Struct & Interface

```go
package BaseController

import (
	Entities "mika/<service>/src/entities"
	Validators "mika/<service>/src/helpers/validators"

	"github.com/labstack/echo/v5"
	"github.com/mitchellh/mapstructure"
)

type (
	BaseController  struct{}
	IBaseController interface {
		Validation(pPayload interface{}, c *echo.Context) (*User, error)
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
func (i *BaseController) Validation(payload interface{}, c *echo.Context) (*User, error) {
	profile := new(User)
	validator := &Validators.CustomValidator{Validator: Validators.InitValidator()}

	// 1. Decode user profile dari c.Get("user")
	if err := mapstructure.Decode(c.Get("user"), profile); err != nil {
		return nil, echo.NewHTTPError(http.StatusBadRequest, "Invalid user profile")
	}

	if payload != nil {
		// 2. Parse JSON body
		body, _ := io.ReadAll(c.Request().Body)
		if len(body) > 0 {
			if err := json.Unmarshal(body, payload); err != nil {
				return nil, echo.NewHTTPError(http.StatusBadRequest, "Invalid JSON")
			}
		}

		// 3. Parse query params
		queryParams := c.QueryParams()
		if len(queryParams) > 0 {
			queryMap := make(map[string]string)
			for k, v := range queryParams {
				if len(v) > 0 {
					queryMap[k] = v[0]
				}
			}
			mapstructure.WeakDecode(queryMap, payload)
		}

		// 4. Parse path params
		pathValues := c.PathValues()
		if len(pathValues) > 0 {
			pathMap := make(map[string]string)
			for _, pv := range pathValues {
				pathMap[pv.Name] = pv.Value
			}
			mapstructure.WeakDecode(pathMap, payload)
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
