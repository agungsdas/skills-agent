# Authorizer Driver

Package: `Authorizer` — Lokasi: `src/drivers/authorizer/`

## Pattern: Stateless Function

Tidak pakai struct, langsung function:

```go
package Authorizer

type ResponseVerifyToken struct {
	Status  bool       `json:"status"`
	Message string     `json:"message"`
	Data    *TokenData `json:"data"`
}

type TokenData struct {
	ID       string      `json:"user_id"`
	Device   string      `json:"device_id"`
	Type     string      `json:"type"`
	UserType string      `json:"user_type"`
	UserData interface{} `json:"user_data"`
}

func VerifyToken(token string) (*TokenData, error) {
	// GET /v1/profile/me ke URI_AUTHORIZER_SERVICE
}
```

## Env Vars

- `URI_AUTHORIZER_SERVICE` — Authorizer service base URL

## Usage di Middleware

```go
func (i *Middleware) Authorization(params *AuthorizationParams) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c *echo.Context) error {
			authHeader := c.Request().Header.Get("Authorization")
			token := strings.TrimPrefix(authHeader, "Bearer ")

			tokenData, err := Authorizer.VerifyToken(token, i.LocalCache)
			if err != nil {
				return echo.NewHTTPError(http.StatusUnauthorized, err.Error())
			}

			// Store token data in context
			c.Set("claims", tokenData)

			return next(c)
		}
	}
}
```

## TokenData Structure

```go
type TokenData struct {
	ID       string      `json:"user_id"`       // User ID
	Device   string      `json:"device_id"`     // Device ID
	Type     string      `json:"type"`          // Token type (access, refresh)
	UserType string      `json:"user_type"`     // User type (patient, doctor, admin)
	UserData interface{} `json:"user_data"`     // Additional user data
}
```

## File Structure

```
authorizer/
└── interface.go    # ResponseVerifyToken, TokenData, VerifyToken()
```

## Implementation Example

```go
func VerifyToken(token string) (*TokenData, error) {
	client := resty.New()
	
	var result ResponseVerifyToken
	
	resp, err := client.R().
		SetResult(&result).
		SetError(&result).
		SetHeader("Authorization", fmt.Sprintf("Bearer %s", token)).
		Get(fmt.Sprintf("%s/v1/profile/me", os.Getenv("URI_AUTHORIZER_SERVICE")))

	if err != nil {
		return nil, err
	}

	if !result.Status {
		return nil, fmt.Errorf(result.Message)
	}

	return result.Data, nil
}
```
