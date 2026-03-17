# Validators

File: `helpers/validators/validator.go`

## CustomValidator

```go
type CustomValidator struct {
	Validator *validator.Validate
}

func InitValidator() *validator.Validate {
	v := validator.New()
	v.RegisterValidation("IsDateFormat", IsDate)
	v.RegisterValidation("IsDateTimeZFormat", IsDateTimeZ)
	v.RegisterValidation("GtDateAddDay", GtDate)
	v.RegisterValidation("IsJson", IsJson)
	v.RegisterValidation("IsConstantCase", IsConstantCase)
	return v
}
```

Library: `github.com/go-playground/validator/v10`

## Custom Validation Tags

| Tag | Description | Format |
|-----|-------------|--------|
| `IsDateFormat` | Valid date | `2006-01-02` |
| `IsDateTimeZFormat` | Valid datetime with timezone | `2006-01-02 15:04:05 -07:00` |
| `GtDateAddDay` | Date greater than field + N days | — |
| `IsJson` | Valid JSON string | — |
| `IsConstantCase` | SCREAMING_SNAKE_CASE | — |

## Usage di Request Struct

```go
type createRequest struct {
	Name      string `json:"name" validate:"required"`
	Email     string `json:"email" validate:"required,email"`
	Status    string `json:"status" validate:"required,IsConstantCase"`
	StartDate string `json:"start_date" validate:"omitempty,IsDateFormat"`
	Page      *int   `query:"page" validate:"omitempty,gte=1"`
}
```
