# Project Structure

```
src/
├── main.go                          # Entry point, bootstrap drivers & launch interface
├── definitions/
│   ├── applications/
│   │   ├── app.go                   # AppContext struct (DI container)
│   │   └── response.go             # SuccessResponse, Meta
│   ├── enums/                       # Konstanta global (date format, roles)
│   └── <domain>/                    # Domain-specific definitions (workflow, status, department)
├── drivers/
│   ├── mongo/
│   │   ├── interface.go             # IMongo interface + New()
│   │   ├── mongo.go                 # Connect() helper
│   │   └── models/                  # BSON structs + ToEntity + indexes
│   │       └── interface.go         # IModels, Model struct, New(), MigrateView()
│   ├── postgres/
│   │   ├── interface.go             # IPostgres interface + New()
│   │   ├── migrator.go              # MigrationUp, MigrationDown, MigrationStatus
│   │   └── models/                  # GORM structs + ToEntity + migrations
│   │       └── interface.go         # IModels, New()
│   ├── redis/
│   │   ├── interface.go             # IRedis + New()
│   │   └── <operation>.go           # Satu file per operasi (create, get, delete, ttl, incr)
│   ├── nunggu/                      # Job queue service (opsional)
│   │   ├── interface.go             # INunggu + New()
│   │   └── <topic>.go               # Method per topic (sync-patient-mongo, sync-user-mongo)
│   ├── sap/                         # SAP external service (opsional)
│   │   ├── interface.go             # ISAPService + New()
│   │   └── <operation>.go           # SearchPatient, FindPatient, CreateUpdatePatient
│   ├── <service-name>/              # Microservice client (contoh: account-service-v1, clinic-service-v1)
│   │   ├── interface.go             # I<ServiceName> + New()
│   │   └── <operation>.go           # Method per endpoint
│   ├── authorizer/                  # Token verification (stateless function)
│   ├── cloudwatch/                  # AWS CloudWatch logging
│   └── event-emitter/               # In-process event emitter
├── entities/                        # Pure domain structs (json tags, no DB dependency)
├── helpers/
│   ├── application.go               # GetPackageName, GetAppName, GetVersion
│   ├── error-handler.go             # Fiber global ErrorHandler
│   ├── get_env.go                   # GetEnv, GetEnvAsInt, GetEnvAsBool, GetEnvAsSlice, GetEnvAsByte
│   ├── recover.go                   # Panic recovery
│   ├── base-controller/controller.go # BaseController.Validation()
│   ├── logger/                      # Custom logger (CloudWatch + Fiber)
│   ├── requestor/                   # HTTP client wrapper (resty)
│   ├── serializers/                 # Response shape structs
│   ├── validators/validator.go      # CustomValidator + custom validation rules
│   └── utils/
│       ├── json/                    # JSONRawToString
│       ├── mongo/                   # BSON helpers, lookup builder
│       ├── strings/                 # GenerateRefId, GenerateRandomStringFromString, IsValidConstantCase
│       ├── structs/                 # DiffModels (change log diffing), ToMap
│       ├── times/                   # StringToTime
│       └── type/                    # ToBoolPntr, ToTimePntr, ToStringPntr
├── repositories/                    # Data access (per domain folder)
│   └── <domain>/
│       ├── interface.go             # I<Domain> + New(mongo)
│       └── <operation>.go           # Params struct + method implementation
├── usecases/                        # Business logic (per domain folder)
│   └── <domain>/
│       ├── interface.go             # I<Domain> + New(...repos, eventEmitter, logger)
│       ├── errors.go                # var Err... = errors.New(...)
│       └── <operation>.go           # Params struct + method implementation
└── interfaces/
    ├── event/
    │   ├── interface.go             # New(appContext) + Launch()
    │   ├── launch.go                # Register event services
    │   └── services/
    │       ├── interface.go         # EventService + IEventService
    │       └── <handler>.go         # EventEmitter.On() handlers
    ├── http-private/                # User-facing API (authenticated)
    │   ├── interface.go
    │   ├── launch.go                # Fiber setup + middleware + route mounting
    │   ├── middlewares/
    │   │   ├── interface.go         # IMiddleware + New(mongo, logger)
    │   │   ├── authorization.go     # Bearer token + role checking
    │   │   └── panic-recover.go
    │   ├── routes/v1/
    │   │   ├── interface.go         # IRoute + New(appContext, middlewares, router)
    │   │   └── <domain>.go          # Mount<Domain>()
    │   └── controllers/v1/
    │       ├── interface.go         # Base IController (ping only)
    │       └── <domain>/
    │           ├── interface.go     # IController + New(appContext)
    │           └── <action>.go      # Handler per endpoint
    └── http-internal/               # Service-to-service API (no/minimal auth)
        └── (struktur sama dengan http-private)
```

## Naming Conventions

- Package alias: PascalCase — `import Entities "agungsdas/<service>/src/entities"`
- File naming: kebab-case — `bulk-upsert.go`, `invoice-progress.go`
- Folder naming: kebab-case — `base-controller/`, `event-emitter/`
- Collection names (MongoDB): snake_case plural — `department_statuses`, `change_logs`, `invoices`
- Table names (PostgreSQL): snake_case plural — `users`, `orders`, `patient_insurances`
- BSON tags (MongoDB): camelCase — `bson:"refId"`, `bson:"createdAt"`
- GORM tags (PostgreSQL): snake_case — `gorm:"column:ref_id"`, `gorm:"column:created_at"`
- JSON tags: snake_case — `json:"ref_id"`, `json:"created_at"`
- Env vars: SCREAMING_SNAKE_CASE — `DATABASE_URI`, `HTTP_PRIVATE_PORT`
