# Redis Driver

Package: `Redis` — Lokasi: `src/drivers/redis/`

## Interface

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

## File Structure

```
redis/
├── interface.go    # Struct, interface, New()
├── create.go       # Create() method
├── get.go          # Get() method
├── delete.go       # Delete() method
├── ttl.go          # Ttl() method
└── incr.go         # Incr() method
```

## Env Vars

- `REDIS_HOST` — Redis host
- `REDIS_PORT` — Redis port
- `REDIS_USERNAME` — Redis username (optional)
- `REDIS_PASSWORD` — Redis password (optional)
- `REDIS_TLS` — Enable TLS ("TRUE" / "FALSE")

## Usage di main.go

```go
redis := Redis.New()

// Create with expiration
redis.Create(ctx, &key, data, &expInSecond)

// Get value
value, err := redis.Get(ctx, &key)

// Delete key
redis.Delete(ctx, &key)

// Get TTL
ttl, err := redis.Ttl(ctx, &key)

// Increment counter
count, err := redis.Incr(ctx, &key, &expInSecond)
```

## Key Prefix Pattern

Redis keys automatically prefixed dengan `<service-name>-<environment>-`:

```go
// Input key: "user:123"
// Actual key: "<service-name>-<environment>-user:123"
```
