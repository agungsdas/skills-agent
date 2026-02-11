# Drivers

Lokasi: `src/drivers/<driver-name>/`

## Rules

1. Setiap driver punya `interface.go` dengan struct, interface, dan `New()` constructor
2. Operasi banyak → pisah per file (redis: create.go, get.go, delete.go, ttl.go, incr.go)
3. Config dari env var via `Helpers.GetEnv()`
4. Di-instantiate di `main.go`, dimasukkan ke `AppContext`

## Mongo Driver

```go
package Mongo

type Mongo struct {
	Models Models.IModels
	DB     *mongo.Database
	Error  error
}

type IMongo interface {
	GetModels() Models.IModels
	MigrateView()
	GetDB() *mongo.Database
	GetError() error
}

func New() IMongo {
	// Connect ke MongoDB, init models, return &Mongo{}
}
```

## Redis Driver

```go
package Redis

type Redis struct {
	Client *redis.Client
	Prefix string  // format: "<service-name>-<environment>-"
}

type IRedis interface {
	Create(ctx context.Context, key *string, data interface{}, expInSecond *int64) error
	Get(ctx context.Context, key *string) (*string, error)
	Ttl(ctx context.Context, key *string) (*time.Duration, error)
	Delete(ctx context.Context, key *string) error
	Incr(ctx context.Context, key *string, expInSecond *int64) (*int64, error)
}

func New() IRedis {
	// Parse REDIS_HOST, REDIS_PORT, REDIS_USERNAME, REDIS_PASSWORD, REDIS_TLS
}
```

## Authorizer (Stateless)

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

## Event Emitter

```go
package EventEmitter

func New() eventemitter.IEventEmitter {
	return eventemitter.NewEventEmitter(eventemitter.WithMaxListeners(1))
}
```

Library: `github.com/jiyeyuran/go-eventemitter`

## CloudWatch

```go
package Cloudwatch

type Cloudwatch struct {
	Client *cloudwatchlogs.Client
}

func InitCloudwatch() *Cloudwatch {
	// Baca CLOUDWATCH_ACCESS_KEY_ID, CLOUDWATCH_SECRET_ACCESS_KEY, CLOUDWATCH_REGION, CLOUDWATCH_LOG_GROUP
	// Return nil Client jika env == "local" atau config kosong
}
```

## Bootstrap Pattern (main.go)

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
		Mongo: mongo, Redis: redis, EventEmitter: eventEmitter,
		Logger: logger, Requestor: requestor,
	}

	event := Event.New(&appContext)
	event.Launch()

	switch os.Getenv("INTERFACE") {
	case "HTTP_PRIVATE":
		HttpPrivate.New(&appContext).Launch()
	case "HTTP_INTERNAL":
		HttpInternal.New(&appContext).Launch()
	case "MIGRATE_VIEW":
		mongo.MigrateView()
	}
}
```
