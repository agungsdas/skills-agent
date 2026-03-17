# Bootstrap Pattern (main.go)

Lokasi: `src/main.go`

## Full Bootstrap Example

```go
package main

import (
	"log"
	"os"

	"github.com/joho/godotenv"

	Applications "agungsdas/<service>/src/definitions/applications"
	Cloudwatch "agungsdas/<service>/src/drivers/cloudwatch"
	EventEmitter "agungsdas/<service>/src/drivers/event-emitter"
	Mongo "agungsdas/<service>/src/drivers/mongo"
	Nunggu "agungsdas/<service>/src/drivers/nunggu"
	Postgres "agungsdas/<service>/src/drivers/postgres"
	Redis "agungsdas/<service>/src/drivers/redis"
	SAPService "agungsdas/<service>/src/drivers/sap"
	AccountServiceV1 "agungsdas/<service>/src/drivers/account-service-v1"
	Logger "agungsdas/<service>/src/helpers/logger"
	Requestor "agungsdas/<service>/src/helpers/requestor"
	Event "agungsdas/<service>/src/interfaces/event"
	HttpInternal "agungsdas/<service>/src/interfaces/http-internal"
	HttpPrivate "agungsdas/<service>/src/interfaces/http-private"
	DemographyIdentityRepository "agungsdas/<service>/src/repositories/demography-identity"
	CountryRepository "agungsdas/<service>/src/repositories/country"
)

func main() {
	// Load .env file
	godotenv.Load()
	
	// Init infrastructure drivers
	mongo := Mongo.New()
	postgres := Postgres.New()
	redis := Redis.New()
	eventEmitter := EventEmitter.New()
	cloudwatch := Cloudwatch.InitCloudwatch()
	logger := Logger.New(cloudwatch.Client)
	requestor := Requestor.New(logger)
	nunggu := Nunggu.New()

	// Check database errors
	if mongo.GetError() != nil {
		log.Fatalf("Failed to Initialized DB Mongo: %v", mongo.GetError())
	}
	if postgres.GetError() != nil {
		log.Fatalf("Failed to Initialized DB Postgres: %v", postgres.GetError())
	}

	// Init repositories (for service drivers that need them)
	demographyIdentityRepo := DemographyIdentityRepository.New(mongo)
	countryRepo := CountryRepository.New(mongo)

	// Init service drivers
	sapService := SAPService.New(demographyIdentityRepo, countryRepo, logger, requestor)
	accountServiceV1 := AccountServiceV1.New(requestor)

	// Create AppContext (DI Container)
	appContext := Applications.AppContext{
		Mongo:            mongo,
		Postgres:         postgres,
		Redis:            redis,
		EventEmitter:     eventEmitter,
		Logger:           logger,
		Requestor:        requestor,
		Nunggu:           nunggu,
		SAPService:       sapService,
		AccountServiceV1: accountServiceV1,
	}

	// Launch event listeners
	event := Event.New(&appContext)
	event.Launch()

	// Launch interface based on INTERFACE env var
	switch os.Getenv("INTERFACE") {
	case "HTTP_PRIVATE":
		HttpPrivate.New(&appContext).Launch()
	case "HTTP_INTERNAL":
		HttpInternal.New(&appContext).Launch()
	case "MIGRATE_VIEW":
		mongo.MigrateView()
	case "MIGRATION_UP":
		postgres.MigrationUp()
	case "MIGRATION_DOWN":
		postgres.MigrationDown()
	case "MIGRATION_STATUS":
		postgres.MigrationStatus()
	default:
		log.Fatal("INTERFACE env var not set or invalid")
	}
}
```

## Bootstrap Order

1. **Load environment** — `godotenv.Load()`
2. **Init infrastructure drivers** — mongo, postgres, redis, cloudwatch, logger, requestor
3. **Check database errors** — Fail fast jika database connection gagal
4. **Init repositories** — Untuk service drivers yang butuh dependencies
5. **Init service drivers** — SAP, Nunggu, microservice clients
6. **Create AppContext** — DI container dengan semua dependencies
7. **Launch event listeners** — Register event handlers
8. **Launch interface** — HTTP server atau migration command

## INTERFACE Commands

```bash
# HTTP Private (user-facing API)
INTERFACE=HTTP_PRIVATE go run src/main.go

# HTTP Internal (service-to-service API)
INTERFACE=HTTP_INTERNAL go run src/main.go

# MongoDB Materialized View Migration
INTERFACE=MIGRATE_VIEW go run src/main.go

# PostgreSQL Migration Up
INTERFACE=MIGRATION_UP go run src/main.go

# PostgreSQL Migration Down
INTERFACE=MIGRATION_DOWN go run src/main.go

# PostgreSQL Migration Status
INTERFACE=MIGRATION_STATUS go run src/main.go
```

## AppContext Structure

```go
type AppContext struct {
	// Database drivers
	Mongo    Mongo.IMongo
	Postgres Postgres.IPostgres
	Redis    Redis.IRedis

	// Infrastructure
	EventEmitter eventemitter.IEventEmitter
	Logger       Logger.ILogger
	Requestor    Requestor.IRequestor

	// Job queue
	Nunggu Nunggu.INunggu

	// External services
	SAPService SAPService.ISAPService

	// Microservice clients
	AccountServiceV1 AccountServiceV1.IAccountServiceV1
	ClinicServiceV1  ClinicServiceV1.IClinicServiceV1
}
```

## Minimal Bootstrap (MongoDB Only)

```go
func main() {
	godotenv.Load()
	
	mongo := Mongo.New()
	redis := Redis.New()
	eventEmitter := EventEmitter.New()
	cloudwatch := Cloudwatch.InitCloudwatch()
	logger := Logger.New(cloudwatch.Client)
	requestor := Requestor.New(logger)

	if mongo.GetError() != nil {
		log.Fatalf("Failed to Initialized DB Mongo: %v", mongo.GetError())
	}

	appContext := Applications.AppContext{
		Mongo:        mongo,
		Redis:        redis,
		EventEmitter: eventEmitter,
		Logger:       logger,
		Requestor:    requestor,
	}

	event := Event.New(&appContext)
	event.Launch()

	switch os.Getenv("INTERFACE") {
	case "HTTP_PRIVATE":
		HttpPrivate.New(&appContext).Launch()
	case "MIGRATE_VIEW":
		mongo.MigrateView()
	}
}
```

## Error Handling

```go
// Fail fast untuk critical drivers
if mongo.GetError() != nil {
	log.Fatalf("Failed to Initialized DB Mongo: %v", mongo.GetError())
}

// Graceful degradation untuk optional drivers
if cloudwatch.Client == nil {
	log.Println("CloudWatch not configured, using stdout logging only")
}
```
