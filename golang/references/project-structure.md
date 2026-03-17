# Project Structure

```
src/
├── main.go                                    # Entry point, bootstrap drivers & launch interface
├── definitions/
│   ├── applications/
│   │   ├── app.go                             # AppContext struct (Mongo, Postgres, Redis, Logger, Requestor, EventEmitter, NungguClients)
│   │   └── response.go                        # SuccessResponse, Meta
│   └── enums/
│       ├── date.go                            # DATE_FULL_FORMAT, DATE_TIME_FORMAT, dsb
│       ├── education.go
│       ├── job.go
│       ├── marital-status.go
│       ├── patient.go
│       ├── relation-type.go
│       ├── religion.go
│       ├── role.go                            # Enums.ROLE.SUPER_ADMIN (struct-based enum)
│       └── strings.go
├── drivers/
│   ├── mongo/
│   │   ├── interface.go                       # IMongo interface + New()
│   │   ├── mongo.go                           # MongoDB connection
│   │   └── models/
│   │       ├── interface.go                   # IModels, Models struct, New(), CreateIndex helpers
│   │       ├── user.go                        # func (i *Models) User() *mongo.Collection
│   │       ├── patient.go
│   │       ├── patient-disclaimer.go
│   │       ├── patient-external-identity.go
│   │       ├── patient-insurance.go
│   │       ├── user-address.go
│   │       ├── user-patient.go
│   │       ├── country.go
│   │       ├── demography-identity.go
│   │       ├── encryption.go
│   │       ├── master-ability.go
│   │       ├── master-role.go
│   │       └── role-ability.go
│   ├── postgres/
│   │   ├── interface.go                       # IPostgres interface + New() + GetGormWithHooks + GetPublicKey/GetPrivateKey
│   │   ├── migrator.go                        # MigrationUp, MigrationDown, MigrationStatus
│   │   ├── migrations/                        # Raw SQL files (-- up / -- down)
│   │   │   ├── 20251002112040_patient.sql
│   │   │   ├── 20251002112059_user-patient.sql
│   │   │   ├── 20251002112110_patient-disclaimer.sql
│   │   │   ├── 20251003133512_user.sql
│   │   │   ├── 20251003133520_user-address.sql
│   │   │   ├── 20251024112128_patient-external-identity.sql
│   │   │   └── 20251106133520_user-address-v2.sql
│   │   └── models/
│   │       ├── interface.go                   # IModels, New()
│   │       ├── migration-meta.go              # MigrationMeta model
│   │       ├── user.go                        # func (i *Models) User() *gorm.DB + gorm tags
│   │       ├── patient.go
│   │       ├── patient-disclaimer.go
│   │       ├── patient-external-identity.go
│   │       ├── patient-insurance.go
│   │       ├── user-address.go
│   │       ├── user-patient.go
│   │       ├── master-ability.go
│   │       ├── master-role.go
│   │       └── role-ability.go
│   ├── redis/
│   │   ├── interface.go                       # IRedis + New()
│   │   ├── create.go
│   │   ├── get.go
│   │   ├── delete.go
│   │   ├── ttl.go
│   │   └── incr.go
│   ├── nunggu/                                # Job queue service
│   │   ├── interface.go                       # INunggu + New()
│   │   ├── sync-patient.go
│   │   ├── sync-user.go
│   │   ├── on-patient-updated.go
│   │   └── on-patient-external-updated.go
│   ├── sap/                                   # SAP external service
│   │   ├── interface.go                       # ISAPService + New()
│   │   ├── mapper.go
│   │   ├── find-patient.go
│   │   ├── search-patient-sap.go
│   │   └── create-or-update-patient.go
│   ├── <other-service>-v1/                    # Microservice client
│   │   ├── interface.go                       # IAccountServiceV1 + New()
│   │   ├── get-users.go
│   │   ├── sync-user.go
│   │   └── upsert-user.go
│   ├── <other-service>-v2/                     # Microservice client
│   │   ├── interface.go
│   │   ├── create-patient.go
│   │   ├── get-patients.go
│   │   ├── sync-patient.go
│   │   ├── sync-user-patient.go
│   │   ├── update-patient.go
│   │   ├── upsert-patient.go
│   │   └── upsert-patient-external-identity.go
│   ├── authorizer/
│   │   └── authorizer.go                     # VerifyToken (stateless)
│   ├── cloudwatch/
│   │   └── cloudwatch.go                     # AWS CloudWatch logging
│   └── event-emitter/
│       └── event-emitter.go                  # In-process event emitter
├── entities/                                  # Pure domain structs (json + mapstructure tags only)
│   ├── user.go
│   ├── patient.go
│   ├── patient-disclaimer.go
│   ├── patient-external-identity.go
│   ├── patient-insurance.go
│   ├── user-address.go
│   ├── user-patient.go
│   ├── country.go
│   ├── demography-identity.go
│   ├── employee.go
│   ├── ecryption.go
│   ├── http-request.go
│   ├── migration-meta.go
│   ├── role-ability.go
│   └── master-data/
│       ├── ability.go
│       ├── role.go
│       └── role-ability.go
├── helpers/
│   ├── application.go                         # GetPackageName, GetAppName, GetVersion
│   ├── error-handler.go                       # Fiber global ErrorHandler
│   ├── get_env.go                             # GetEnv, GetEnvAsInt, GetEnvAsBool, GetEnvAsSlice, GetEnvAsByte
│   ├── recover.go                             # Panic recovery
│   ├── bcrypt.go                              # Bcrypt hash/compare
│   ├── base64.go                              # Base64 encode/decode
│   ├── validator.go                           # Validator wrapper
│   ├── base-controller/
│   │   └── controller.go                     # BaseController.Validation() → *User
│   ├── logger/
│   │   ├── interface.go                       # ILogger + New()
│   │   ├── access.go                          # AccessLoggerMiddleware() fiber.Handler
│   │   ├── log.go
│   │   └── requestor.go
│   ├── requestor/
│   │   ├── interface.go                       # IRequestor
│   │   └── requestor.go
│   ├── serializers/                           # Response shape structs
│   │   ├── user.go
│   │   ├── patient.go
│   │   ├── patient-disclaimer.go
│   │   ├── patient-external-identity.go
│   │   ├── patient-insurance.go
│   │   ├── user-address.go
│   │   ├── user-patient.go
│   │   ├── country.go
│   │   ├── demography-identity.go
│   │   ├── employee.go
│   │   └── user_role.go
│   ├── format/
│   │   ├── phone.go
│   │   └── time.go
│   ├── validators/
│   │   └── validator.go                      # CustomValidator + custom validation rules
│   └── utils/
│       ├── datetime/
│       │   ├── day.go
│       │   └── parse-datetime.go
│       ├── encryption/
│       │   ├── aes256.go
│       │   └── rsa.go
│       ├── json/
│       │   ├── interface-to-json.go
│       │   └── jsonraw-to-string.go
│       ├── mongo/
│       │   ├── bson.go
│       │   └── lookup.go
│       ├── strings/
│       │   ├── random-id.go                  # GenerateRefId (UUID v7)
│       │   ├── aes256.go
│       │   ├── capital-case.go
│       │   ├── constant-case.go
│       │   ├── get-value.go
│       │   ├── interface-to-string.go
│       │   ├── masking.go
│       │   ├── optional-string.go
│       │   ├── secret.go
│       │   └── struct-to-string.go
│       └── type/
│           ├── boolean.go                    # ToBoolPntr
│           ├── int.go
│           ├── map.go
│           ├── string.go                     # ToStringPntr
│           └── time.go                       # ToTimePntr
├── repositories/                              # Data access (per domain)
│   ├── user/
│   │   ├── interface.go                       # IUser + New(mongo, postgres)
│   │   ├── find-by-ref-id-mongo.go
│   │   ├── find-by-ref-id-sql.go
│   │   ├── find-by-legacy-id-mongo.go
│   │   ├── find-by-legacy-id-sql.go
│   │   ├── list-mongo.go
│   │   ├── list-sql.go
│   │   ├── count-mongo.go
│   │   ├── count-sql.go
│   │   ├── create-sql.go
│   │   ├── update-sql.go
│   │   ├── update-legacy-id-sql.go
│   │   ├── upsert-mongo.go
│   │   ├── upsert-sql.go
│   │   └── delete-by-ref-id-mongo.go
│   ├── patient/
│   │   ├── interface.go
│   │   ├── find-by-ref-id-mongo.go
│   │   ├── find-by-ref-id-sql.go
│   │   ├── list-mongo.go
│   │   ├── list-sql.go
│   │   ├── count-mongo.go
│   │   ├── count-sql.go
│   │   ├── create-sql.go
│   │   ├── update-sql.go
│   │   ├── update-legacy-id-sql.go
│   │   ├── upsert-mongo.go
│   │   ├── upsert-sql.go
│   │   └── delete-by-ref-id-mongo.go
│   ├── user-address/
│   │   ├── interface.go
│   │   ├── find-by-ref-id-mongo.go
│   │   ├── find-by-ref-id-sql.go
│   │   ├── list-by-user-ref-id-sql.go
│   │   ├── create-sql.go
│   │   ├── update-sql.go
│   │   ├── set-primary-sql.go
│   │   ├── upsert-mongo.go
│   │   ├── upsert-sql.go
│   │   └── delete-by-ref-id-mongo.go
│   ├── user-patient/
│   │   ├── interface.go
│   │   └── ... (mongo + sql operations)
│   ├── patient-disclaimer/
│   │   ├── interface.go
│   │   └── ... (mongo + sql operations)
│   ├── patient-external-identity/
│   │   ├── interface.go
│   │   └── ... (mongo + sql operations)
│   ├── patient-insurance/
│   │   ├── interface.go
│   │   └── ... (mongo + sql operations)
│   ├── country/
│   │   ├── interface.go
│   │   └── find.go
│   ├── demography-identity/
│   │   ├── interface.go
│   │   ├── find.go
│   │   ├── find-one.go
│   │   ├── find-by-ids.go
│   │   └── find-by-or-condition.go
│   └── master-data/
│       ├── ability/
│       │   ├── interface.go
│       │   ├── find.go
│       │   ├── find-one.go
│       │   ├── upsert.go
│       │   ├── upsert-on-sql.go
│       │   ├── delete.go
│       │   └── delete-sql.go
│       ├── role/
│       │   ├── interface.go
│       │   └── ... (find, upsert, delete)
│       └── role-ability/
│           ├── interface.go
│           └── ... (find, create-many, delete-many, upsert)
├── usecases/                                  # Business logic (per domain)
│   ├── user/
│   │   ├── interface.go                       # IUser + New(repos..., eventEmitter, gorm, logger, requestor)
│   │   ├── errors.go
│   │   ├── list.go
│   │   ├── detail.go
│   │   ├── create.go
│   │   ├── update.go
│   │   ├── update-status.go
│   │   ├── change-password.go
│   │   ├── list-patient.go
│   │   ├── delete-relation-patient.go
│   │   ├── update-relation-patient.go
│   │   ├── sync-from-v1.go
│   │   ├── sync-to-v1.go
│   │   └── sync-to-mongo.go
│   ├── patient/
│   │   ├── interface.go
│   │   ├── errors.go
│   │   ├── list.go
│   │   ├── detail.go
│   │   ├── create.go
│   │   ├── create-from-sap.go
│   │   ├── update.go
│   │   ├── update-complete.go
│   │   ├── delete.go
│   │   ├── search.go
│   │   ├── search-on-sap.go
│   │   ├── list-user.go
│   │   ├── delete-relation-user.go
│   │   ├── update-relation-user.go
│   │   ├── sync-from-v1.go
│   │   ├── sync-from-sap.go
│   │   ├── sync-from-external.go
│   │   ├── sync-to-v1.go
│   │   ├── sync-to-mongo.go
│   │   └── sync-external-identity-to-v1.go
│   ├── user-address/
│   │   ├── interface.go
│   │   ├── errors.go
│   │   ├── list.go
│   │   ├── detail.go
│   │   ├── create.go
│   │   ├── update.go
│   │   ├── delete.go
│   │   ├── set-primary.go
│   │   ├── validation.go
│   │   └── sync-to-mongo.go
│   ├── country/
│   │   ├── interface.go
│   │   └── list.go
│   ├── demography/
│   │   ├── interface.go
│   │   └── list.go
│   ├── patient-disclaimer/
│   │   ├── interface.go
│   │   ├── errors.go
│   │   ├── detail.go
│   │   └── sync-to-mongo.go
│   ├── patient-external-identity/
│   │   ├── interface.go
│   │   ├── errors.go
│   │   ├── detail.go
│   │   ├── delete.go
│   │   ├── create-update-to-sap.go
│   │   └── sync-to-mongo.go
│   ├── patient-insurance/
│   │   ├── interface.go
│   │   ├── errors.go
│   │   ├── detail.go
│   │   └── sync-to-mongo.go
│   ├── user-patient/
│   │   ├── interface.go
│   │   ├── errors.go
│   │   ├── detail.go
│   │   └── sync-to-mongo.go
│   └── master-data/
│       ├── ability/
│       │   ├── interface.go
│       │   ├── errors.go
│       │   ├── detail.go
│       │   ├── upsert.go
│       │   └── delete.go
│       └── role/
│           ├── interface.go
│           ├── errors.go
│           ├── detail.go
│           ├── upsert.go
│           └── delete.go
├── docs/                                      # Swagger auto-generated
│   ├── http-public/
│   │   ├── httpPublic_docs.go
│   │   ├── httpPublic_swagger.json
│   │   └── httpPublic_swagger.yaml
│   └── http-private/
│       ├── httpPrivate_docs.go
│       ├── httpPrivate_swagger.json
│       └── httpPrivate_swagger.yaml
└── interfaces/
    ├── event/
    │   ├── interface.go                       # New(appContext) + IInterface
    │   ├── launch.go                          # Register event services
    │   └── services/
    │       ├── interface.go                   # EventService + IEventService
    │       ├── sync-user.go                   # EventEmitter.On("SYNC_USER", ...)
    │       ├── sync-patient.go
    │       ├── sync-user-patient.go
    │       ├── sync-user-address.go
    │       ├── sync-patient-disclaimer.go
    │       └── sync-patient-external-identity.go
    ├── http-public/                           # Mobile app API (Bearer: MIKA_APP)
    │   ├── interface.go                       # New(appContext) + IInterface
    │   ├── launch.go                          # Fiber setup + middleware + route mounting
    │   ├── middlewares/
    │   │   ├── interface.go                   # IMiddleware + New(mongo, postgres, logger, eventEmitter)
    │   │   ├── authorization.go               # Bearer token check (UserType: MIKA_APP)
    │   │   └── panic-recover.go
    │   ├── routes/
    │   │   ├── v1/
    │   │   │   ├── interface.go               # IRoute + New(appContext, middlewares, router)
    │   │   │   ├── ping.go                    # MountPing()
    │   │   │   ├── user.go                    # MountUser()
    │   │   │   ├── patient.go                 # MountPatient()
    │   │   │   ├── demography.go              # MountDemography()
    │   │   │   ├── nationality.go             # MountNationality()
    │   │   │   └── user-address.go            # MountUserAddress()
    │   │   └── v2/
    │   │       ├── interface.go
    │   │       └── ping.go
    │   └── controllers/
    │       ├── v1/
    │       │   ├── interface.go               # Base IController (Ping only)
    │       │   ├── ping.go
    │       │   ├── user/
    │       │   │   ├── interface.go           # IController + New(appContext)
    │       │   │   └── <action>.go            # Handler per endpoint
    │       │   ├── patient/
    │       │   │   ├── interface.go
    │       │   │   └── <action>.go
    │       │   ├── country/
    │       │   │   ├── interface.go
    │       │   │   └── <action>.go
    │       │   ├── demography/
    │       │   │   ├── interface.go
    │       │   │   └── <action>.go
    │       │   └── user-address/
    │       │       ├── interface.go
    │       │       └── <action>.go
    │       └── v2/
    │           ├── interface.go
    │           └── ping.go
    ├── http-private/                          # CMS admin API (Bearer: MIKA_APP_CMS)
    │   ├── interface.go
    │   ├── launch.go
    │   ├── middlewares/
    │   │   ├── interface.go                   # Same pattern as http-public
    │   │   ├── authorization.go               # UserType: MIKA_APP_CMS
    │   │   └── panic-recover.go
    │   ├── routes/
    │   │   ├── v1/
    │   │   │   ├── interface.go
    │   │   │   ├── ping.go
    │   │   │   ├── user.go
    │   │   │   └── patient.go
    │   │   └── v2/
    │   │       ├── interface.go
    │   │       └── ping.go
    │   └── controllers/
    │       ├── v1/
    │       │   ├── interface.go
    │       │   ├── ping.go
    │       │   ├── user/
    │       │   │   └── ...
    │       │   ├── patient/
    │       │   │   └── ...
    │       │   └── user-address/
    │       │       └── ...
    │       └── v2/
    │           ├── interface.go
    │           └── ping.go
    └── http-internal/                         # Service-to-service API (minimal auth)
        ├── interface.go
        ├── launch.go
        ├── middlewares/
        │   ├── interface.go                   # Tanpa Authorization, hanya PanicRecover
        │   └── panic-recover.go
        ├── routes/
        │   ├── v1/
        │   │   ├── interface.go
        │   │   ├── ping.go
        │   │   ├── user.go
        │   │   ├── patient.go
        │   │   └── master-data.go
        │   └── v2/
        │       ├── interface.go
        │       └── ping.go
        └── controllers/
            ├── v1/
            │   ├── interface.go
            │   ├── ping.go
            │   ├── user/
            │   │   └── ...
            │   ├── patient/
            │   │   └── ...
            │   └── master-data/
            │       └── ...
            └── v2/
                ├── interface.go
                └── ping.go
```

## Naming Conventions

- Package alias: PascalCase — `import Entities "mika/<service>/src/entities"`
- File naming: kebab-case — `bulk-upsert.go`, `find-by-ref-id-sql.go`
- Folder naming: kebab-case — `base-controller/`, `event-emitter/`
- Collection names (MongoDB): camelCase plural — `patientInsurances`, `patientDisclaimers`
- Table names (PostgreSQL): snake_case plural — `users`, `patients`, `patient_insurances`
- BSON tags (MongoDB): camelCase — `bson:"refId"`, `bson:"createdAt"`
- GORM tags (PostgreSQL): type-based — `gorm:"type:varchar(255);uniqueIndex"`
- JSON tags: snake_case — `json:"ref_id"`, `json:"created_at"`
- Env vars: SCREAMING_SNAKE_CASE — `DATABASE_URI`, `HTTP_PUBLIC_PORT`
- Module path: `mika/<service-name>` — cek `go.mod`

## Interface Types

| Interface | Port Env | Default Port | Auth | Use Case |
|-----------|----------|-------------|------|----------|
| HTTP_PUBLIC | HTTP_PUBLIC_PORT | 3000 | MIKA_APP | Mobile app API |
| HTTP_PRIVATE | HTTP_PRIVATE_PORT | 3007 | MIKA_APP_CMS | CMS admin API |
| HTTP_INTERNAL | HTTP_INTERNAL_PORT | varies | minimal/none | Service-to-service |
| MIGRATION | N/A | N/A | N/A | Database migrations |
