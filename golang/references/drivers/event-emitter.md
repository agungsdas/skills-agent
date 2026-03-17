# Event Emitter Driver

Package: `EventEmitter` — Lokasi: `src/drivers/event-emitter/`

## Interface

```go
package EventEmitter

func New() eventemitter.IEventEmitter {
	return eventemitter.NewEventEmitter(eventemitter.WithMaxListeners(1))
}
```

## Library

`github.com/jiyeyuran/go-eventemitter`

## Usage Pattern

### 1. Register Event Listener (di Event Service)

```go
// src/interfaces/event/services/sync-invoice-progress.go
func (i *EventService) SyncInvoiceProgress() {
	modelsContext := &Models.Context{DB: i.Mongo.GetDB()}
	modelsContext.NewInvoice()

	i.EventEmitter.On("SYNC_INVOICE_PROGRESS", func(refIds []string) {
		modelsContext.MigrateViewInvoiceProgress(refIds)
	})
}
```

### 2. Emit Event (di Usecase)

```go
// Emit event setelah write operation
i.EventEmitter.Emit("SYNC_INVOICE_PROGRESS", syncInvoiceIds)
```

## Event Naming Convention

- SCREAMING_SNAKE_CASE
- Prefix dengan action: `SYNC_`, `ON_`, `AFTER_`, `BEFORE_`
- Contoh: `SYNC_INVOICE_PROGRESS`, `ON_PATIENT_UPDATED`, `AFTER_ORDER_CREATED`

## Common Event Patterns

### Sync Materialized View

```go
// Register
i.EventEmitter.On("SYNC_INVOICE_PROGRESS", func(refIds []string) {
	modelsContext.MigrateViewInvoiceProgress(refIds)
})

// Emit
i.EventEmitter.Emit("SYNC_INVOICE_PROGRESS", []string{"REF001", "REF002"})
```

### Trigger Background Job

```go
// Register
i.EventEmitter.On("SYNC_PATIENT_MONGO", func(patientRefId string) {
	i.Nunggu.SyncPatientMongo(&Nunggu.CreateJob{
		Key:  patientRefId,
		Data: map[string]interface{}{"ref_id": patientRefId},
	})
})

// Emit
i.EventEmitter.Emit("SYNC_PATIENT_MONGO", patientRefId)
```

### Send Notification

```go
// Register
i.EventEmitter.On("SEND_EMAIL_NOTIFICATION", func(params map[string]interface{}) {
	i.NotificationService.SendEmail(params)
})

// Emit
i.EventEmitter.Emit("SEND_EMAIL_NOTIFICATION", map[string]interface{}{
	"to":      "user@example.com",
	"subject": "Order Confirmation",
	"body":    "Your order has been confirmed",
})
```

## Event Service Registration

Di `src/interfaces/event/launch.go`:

```go
func (i *Event) Launch() {
	eventService := Services.New(i.AppContext)

	eventService.SyncInvoiceProgress()
	eventService.SyncPatientMongo()
	eventService.SendNotification()
}
```

## File Structure

```
event/
├── interface.go
├── launch.go
└── services/
    ├── interface.go
    ├── sync-invoice-progress.go
    ├── sync-patient-mongo.go
    └── send-notification.go
```

## Best Practices

1. **Async by default** — Event handlers run asynchronously
2. **Error handling** — Handle errors inside event handler, jangan throw
3. **Idempotent** — Event handler harus idempotent (bisa dipanggil berulang)
4. **Lightweight** — Jangan blocking operation di event handler, delegate ke job queue jika perlu
5. **Single responsibility** — Satu event untuk satu purpose
