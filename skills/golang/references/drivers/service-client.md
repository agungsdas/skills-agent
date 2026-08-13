# Service Driver Pattern (Microservice Client)

Package: `<ServiceName>` — Lokasi: `src/drivers/<service-name>/`

Contoh folder: `<other-service>-v1/`, `notification-service/`

## Interface Template

```go
package <ServiceName>

type I<ServiceName> interface {
	GetUser(personalId string) (*Entities.User, error)
	GetUsers(personalIds []string) ([]Entities.User, error)
	UpdateUser(refId string, params *ParamUpdateUser) (*Entities.User, error)
}

type <ServiceName> struct {
	Client *resty.Client
}

func New(requestor Requestor.IRequestor) I<ServiceName> {
	return &<ServiceName>{
		Client: requestor.Request(nil).SetBaseURL(Helpers.GetEnv("<SERVICE_NAME>_HOST", "")),
	}
}
```

## Method Implementation Example

```go
func (i *<ServiceName>) GetUser(personalId string) (*Entities.User, error) {
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

`<SERVICE_NAME>_HOST` — Base URL untuk service target

Contoh:
- `OTHER_SERVICE_V1_HOST`
- `NOTIFICATION_SERVICE_HOST`

## Usage di main.go

```go
// Init service clients
otherServiceV1 := OtherServiceV1.New(requestor)

// Add to AppContext
appContext := Applications.AppContext{
	// ...
	OtherServiceV1: otherServiceV1,
}
```

## Usage di Usecase

```go
// Get user from other service
user, err := i.OtherServiceV1.GetUser(personalId)
if err != nil {
	return nil, err
}

// Get multiple users
users, err := i.OtherServiceV1.GetUsers([]string{"P001", "P002"})
```

## File Structure

```
<service-name>/
├── interface.go              # Struct, interface, New()
├── get-user.go               # GetUser() method
├── get-users.go              # GetUsers() method
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
