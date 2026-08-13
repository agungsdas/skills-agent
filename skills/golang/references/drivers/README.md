# Drivers

Lokasi: `src/drivers/<driver-name>/`

## Rules

1. Setiap driver punya `interface.go` dengan struct, interface, dan `New()` constructor
2. Operasi banyak → pisah per file (redis: create.go, get.go, delete.go, ttl.go, incr.go)
3. Config dari env var via `Helpers.GetEnv()`
4. Di-instantiate di `main.go`, dimasukkan ke `AppContext`

## Available Drivers

- [mongo.md](./mongo.md) - MongoDB driver + BSON models, indexes, materialized views
- [postgres.md](./postgres.md) - PostgreSQL driver (GORM) + models, migrations, relations
- [redis.md](./redis.md) - Redis driver untuk caching
- [nunggu.md](./nunggu.md) - Job queue service driver
- [sap.md](./sap.md) - SAP external service driver
- [service-client.md](./service-client.md) - Microservice client pattern
- [authorizer.md](./authorizer.md) - Token verification driver
- [event-emitter.md](./event-emitter.md) - In-process event emitter
- [cloudwatch.md](./cloudwatch.md) - AWS CloudWatch logging
- [bootstrap.md](./bootstrap.md) - Bootstrap pattern di main.go

## Driver Categories

### Database Drivers
- MongoDB (mongo.md)
- PostgreSQL (postgres.md)
- Redis (redis.md)

### External Service Drivers
- SAP (sap.md)
- Nunggu Job Queue (nunggu.md)
- Microservice Clients (service-client.md)

### Infrastructure Drivers
- Authorizer (authorizer.md)
- Event Emitter (event-emitter.md)
- CloudWatch (cloudwatch.md)
