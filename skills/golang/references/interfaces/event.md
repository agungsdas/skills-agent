# Event Interface

Lokasi: `src/interfaces/event/`

## Structure

```
src/interfaces/event/
├── interface.go         # New(appContext) + IInterface
├── launch.go            # Register event services
└── services/
    ├── interface.go     # EventService + IEventService
    └── sync-<domain>.go # EventEmitter.On() handlers
```

## Service Pattern

```go
// services/interface.go
type EventService struct {
	*Applications.AppContext
}

type IEventService interface {
	Ping()
	Sync<Domain>()
}

func NewEventService(appContext *Applications.AppContext) IEventService {
	return &EventService{appContext}
}
```

## Handler Pattern

```go
// services/sync-<domain>.go
func (i *EventService) Sync<Domain>() {
	i.EventEmitter.On("SYNC_<DOMAIN>", func(refIds []string) {
		// Sync logic here
	})
}
```

## Launch

```go
// launch.go
func (i Interface) Launch() {
	svc := ServicesEvent.NewEventService(i.AppContext)
	svc.Ping()
	svc.Sync<Domain>()
}
```
