# Adding New External API Driver (Go Gateway)

## Pattern

Every external service gets its own driver under `gateway/src/drivers/{service-name}/`.

## Step 1: Create Interface

```go
// gateway/src/drivers/new-service/interface.go
package NewService

import (
    Helpers "github.com/mika/ai-agent-gateway/src/helpers"
    Requestor "github.com/mika/ai-agent-gateway/src/helpers/requestor"
)

type NewService struct {
    BaseURL   string
    APIKey    string
    Requestor Requestor.IRequestor
}

type INewService interface {
    GetSomething(id string) (*Something, error)
    CreateSomething(params CreateParams) (*Something, error)
}

func New(requestor Requestor.IRequestor) INewService {
    return &NewService{
        BaseURL:   Helpers.GetEnv("NEW_SERVICE_URL", ""),
        APIKey:    Helpers.GetEnv("NEW_SERVICE_API_KEY", ""),
        Requestor: requestor,
    }
}
```

## Step 2: Implement Methods

```go
// gateway/src/drivers/new-service/get-something.go
package NewService

import "net/http"

func (i *NewService) GetSomething(id string) (*Something, error) {
    var result struct {
        Data Something `json:"data"`
    }
    
    resp, err := i.Requestor.Request(&Requestor.HttpRequestOptions{Timeout: 10}).R().
        SetHeader("Authorization", "Bearer " + i.APIKey).
        SetResult(&result).
        Get(i.BaseURL + "/something/" + id)
    
    if err != nil {
        return nil, err
    }
    if resp.IsError() {
        return nil, fmt.Errorf("service returned %d", resp.StatusCode())
    }
    
    return &result.Data, nil
}
```

## Step 3: Add to AppContext

```go
// gateway/src/definitions/applications/app.go
type AppContext struct {
    ...existing...
    NewService NewService.INewService
}
```

## Step 4: Initialize in main.go

```go
newService := NewService.New(requestor)

appContext := &Applications.AppContext{
    ...existing...
    NewService: newService,
}
```

## Step 5: Use in Usecase

```go
// In usecase
data, err := u.AppContext.NewService.GetSomething(id)
```

## Auth Patterns

### Basic Auth (like Partner Service):
```go
req.SetBasicAuth(i.AccessKeyID, i.SecretAccessKey)
```

### Bearer Token:
```go
req.SetHeader("Authorization", "Bearer " + i.APIKey)
```

### Token with refresh (like Partner Service):
See `drivers/partner-service/auth.go` — ensureToken + refresh on 401 pattern.

## Rules

- Always use Requestor (never raw net/http) — ensures logging + retry
- All credentials from env vars — never hardcode
- Timeout explicit on every request
- Return domain structs, not raw JSON maps
- Error wrapping with context: `fmt.Errorf("service: %w", err)`
