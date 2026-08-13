# Interfaces (Transport Layer)

Lokasi: `src/interfaces/`

Framework: Echo v5 (`github.com/labstack/echo/v5`)

## Jenis Interface

| Type | Lokasi | Auth | Use Case |
|------|--------|------|----------|
| `http-public` | `/interfaces/http-public/` | Bearer token (any user type) | Mobile app / public-facing API |
| `http-private` | `/interfaces/http-private/` | Bearer token (INTERNAL_LDAP only) | CMS admin / intranet API |
| `http-internal` | `/interfaces/http-internal/` | Minimal/none | Service-to-service |
| `event` | `/interfaces/event/` | N/A | In-process event listener |

## Perbedaan Antar Interface

- **HTTP_PUBLIC** — exposed ke internet, bisa diakses mobile app / end user. Auth bisa berbagai user type.
- **HTTP_PRIVATE** — hanya intranet (CMS/backoffice). Auth harus INTERNAL_LDAP + role check.
- **HTTP_INTERNAL** — antar service, tanpa auth atau minimal auth (Basic Auth). Tidak exposed ke internet.

## Port Defaults

- `HTTP_PUBLIC_PORT`: 3000
- `HTTP_PRIVATE_PORT`: 3007
- `HTTP_INTERNAL_PORT`: varies

## Interface Entry Point

Setiap interface punya pattern yang sama:

```go
package Http<Type>

import (
	Applications "mika/<service>/src/definitions/applications"
)

type Interface struct {
	*Applications.AppContext
}

type IInterface interface {
	Launch()
}

func New(appContext *Applications.AppContext) IInterface {
	return &Interface{appContext}
}
```

## Sub-documents

- **Launch** — Echo setup, middleware chain, swagger, route mounting → `interfaces/launch.md`
- **Middlewares** — Middleware struct, Authorization, PanicRecover → `interfaces/middlewares.md`
- **Routes** — Route struct, Mount pattern → `interfaces/routes.md`
- **Controllers** — Controller struct, handler pattern, request/response → `interfaces/controllers.md`
- **Event** — Event interface, EventEmitter.On() handlers → `interfaces/event.md`
