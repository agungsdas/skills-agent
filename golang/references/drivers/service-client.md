# Service Driver Pattern (Microservice Client)

Package: `<ServiceName>` — Lokasi: `src/drivers/<service-name>/`

Contoh: `account-service-v1`, `clinic-service-v1`, `notification-service`

## Interface Template

```go
package AccountServiceV1

type IAccountServiceV1 interface {
	GetUserByPersonalId(personalId string) (*Entities.User, error)
	GetUsersByPersonalIds(personalIds []string) ([]Entities.User, error)
	UpdateUser(refId string, params *ParamUpdateUser) (*Entities.User, error)
}

type AccountServiceV1 struct {
	Client *resty.Client
}

func New(requestor Requestor.IRequestor) IAccountServiceV1 {
	return &AccountServiceV1{
		Client: requestor.Request(nil).SetBaseURL(Helpers.GetEnv("ACCOUNT_SERVICE_V1_HOST", "")),
	}
}
```

## Method Implementation Example

```go
func (i *AccountServiceV1) GetUserByPersonalId(personalId string) (*Entities.User, error) {
	var result struct {
		Status  bool           `json:"status"`
		Message string         `json:"message"`
		Data    *Entities.User `json:"data"`
	}

	resp, err := i.Client.R().
		SetResult(&result).
		SetError(&result).
		SetQueryParam("personal_id", personalId).
		Get("/v1/users")

	if err != nil {
		return nil, err
	}

	if !result.Status {
		return nil, fmt.Errorf(result.Message)
	}

	return result.Data, nil
}
```

## Env Vars Pattern

`<SERVICE_NAME>_HOST` — Base URL untuk service

Contoh:
- `ACCOUNT_SERVICE_V1_HOST`
- `CLINIC_SERVICE_V1_HOST`
- `NOTIFICATION_SERVICE_HOST`

## Usage di main.go

```go
// Init service clients
accountServiceV1 := AccountServiceV1.New(requestor)
clinicServiceV1 := ClinicServiceV1.New(requestor)

// Add to AppContext
appContext := Applications.AppContext{
	// ...
	AccountServiceV1: accountServiceV1,
	ClinicServiceV1:  clinicServiceV1,
}
```

## Usage di Usecase

```go
// Get user from account service
user, err := i.AccountServiceV1.GetUserByPersonalId(personalId)
if err != nil {
	return nil, err
}

// Get multiple users
users, err := i.AccountServiceV1.GetUsersByPersonalIds([]string{"P001", "P002"})
```

## File Structure

```
account-service-v1/
├── interface.go              # Struct, interface, New()
├── get-user.go               # GetUserByPersonalId() method
├── get-users.go              # GetUsersByPersonalIds() method
├── update-user.go            # UpdateUser() method
└── sync-user.go              # SyncUser() method
```

## Response Struct Pattern

Setiap method biasanya define response struct inline:

```go
var result struct {
	Status  bool           `json:"status"`
	Message string         `json:"message"`
	Data    *Entities.User `json:"data"`
	Meta    *Meta          `json:"meta"`
}
```

Atau bisa define di file terpisah jika dipakai berulang:

```go
type ResponseUser struct {
	Status  bool           `json:"status"`
	Message string         `json:"message"`
	Data    *Entities.User `json:"data"`
}
```

## Error Handling Pattern

```go
resp, err := i.Client.R().
	SetResult(&result).
	SetError(&result).
	Get("/v1/endpoint")

// Check HTTP error
if err != nil {
	return nil, err
}

// Check business logic error
if !result.Status {
	return nil, fmt.Errorf(result.Message)
}

return result.Data, nil
```
