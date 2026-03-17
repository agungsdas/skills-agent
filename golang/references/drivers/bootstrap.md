# Bootstrap Pattern (main.go)

Lokasi: `src/main.go`

## Full Bootstrap Example

```go
package main

import (
	"fmt"
	"log"
	"os"

	"github.com/joho/godotenv"
	fiberlog "github.com/gofiber/fiber/v2/log"

	Applications "mika/<service>/src/definitions/applications"
	Cloudwatch "mika/<service>/src/drivers/cloudwatch"
	EventEmitter "mika/<service>/src/drivers/event-emitter"
	Mongo "mika/<service>/src/drivers/mongo"
	Nunggu "mika/<service>/src/drivers/nunggu"
	Postgres "mika/<service>/src/drivers/postgres"
	Redis "mika/<service>/src/drivers/redis"
	Logger "mika/<service>/src/helpers/logger"
	Requestor "mika/<service>/src/helpers/requestor"
	Event "mika/<service>/src/interfaces/event"
	HttpInternal "mika/<service>/src/interfaces/http-internal"
	HttpPrivate "mika/<service>/src/interfaces/http-private"
	HttpPublic "mika/<service>/src/interfaces/http-public"
)

func main() {
	godotenv.Load()

	// Init infrastructure drivers
	mongo := Mongo.New()
	postgres := Postgres.New()
	redis := Redis.New()
	nungguClients := Nunggu.New()
	eventEmitter := EventEmitter.New()
	cloudwatch := Cloudwatch.InitCloudwatch()
	logger := Logger.New(cloudwatch.Client)
	requestor := Requestor.New(logger)
	appInterface := os.Getenv("INTERFACE")

	// Check database errors — fail fast
	if mongo.GetError() != nil {
		log.Fatalf("Failed to Initialized DB Mongo: %v", mongo.GetError())
	}
	if postgres.GetError() != nil {
		log.Fatalf("Failed to Initialized DB Postgres: %v", postgres.GetError())
	}
	if appInterface == "" {
		log.Fatalf("Interface not found")
	}

	// Set fiber logger & defer shutdown
	fiberlog.SetLogger(logger.NewCustomLogger())
	defer logger.Shutdown()

	// Create AppContext (DI Container)
	appContext := Applications.AppContext{
		Mongo:         mongo,
		Postgres:      postgres,
		Redis:         redis,
		NungguClients: nungguClients,
		EventEmitter:  eventEmitter,
		Logger:        logger,
		Requestor:     requestor,
	}

	// Launch event listeners
	event := Event.New(&appContext)
	event.Launch()

	// Launch interface based on INTERFACE env var
	switch appInterface {
	case "HTTP_PUBLIC":
		HttpPublic.New(&appContext).Launch()
	case "HTTP_PRIVATE":
		HttpPrivate.New(&appContext).Launch()
	case "HTTP_INTERNAL":
		HttpInternal.New(&appContext).Launch()
	case "MIGRATION":
		cmd := os.Args[1]
		switch cmd {
		case "up":
			err := postgres.MigrationUp()
			if err != nil {
				log.Fatalf("Failed to migrate up: %v", err)
			}
			mongo.Migrate()
		case "down":
			err := postgres.MigrationDown()
			if err != nil {
				log.Fatalf("Failed to migrate down: %v", err)
			}
		case "status":
			err := postgres.MigrationStatus()
			if err != nil {
				log.Fatalf("Failed to get migration status: %v", err)
			}
		default:
			fmt.Println("Unknown command. Use up, down, or status.")
		}
	}
}
```

## Bootstrap Order

1. **Load environment** — `godotenv.Load()`
2. **Init infrastructure drivers** — mongo, postgres, redis, cloudwatch, logger, requestor
3. **Check database errors** — Fail fast jika database connection gagal
4. **Set fiber logger** — `fiberlog.SetLogger()` + `defer logger.Shutdown()`
5. **Create AppContext** — DI container dengan semua dependencies
6. **Launch event listeners** — Register event handlers
7. **Launch interface** — HTTP server atau migration command

## INTERFACE Commands

```bash
# HTTP Public (mobile app API)
INTERFACE=HTTP_PUBLIC go run src/main.go

# HTTP Private (CMS admin API)
INTERFACE=HTTP_PRIVATE go run src/main.go

# HTTP Internal (service-to-service API)
INTERFACE=HTTP_INTERNAL go run src/main.go

# PostgreSQL Migration
INTERFACE=MIGRATION go run src/main.go up
INTERFACE=MIGRATION go run src/main.go down
INTERFACE=MIGRATION go run src/main.go status
```
