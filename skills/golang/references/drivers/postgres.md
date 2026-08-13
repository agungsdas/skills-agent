# PostgreSQL Driver (GORM)

Package: `Postgres` — Lokasi: `src/drivers/postgres/`

## Interface

```go
package Postgres

import (
	"context"
	"crypto/rsa"

	"gorm.io/gorm"

	Models "mika/<service>/src/drivers/postgres/models"
)

type Postgres struct {
	Models      Models.IModels
	DB          *gorm.DB
	DBWithHooks *DBWithHooks
	Error       error
	PublicKey   *rsa.PublicKey
	PrivateKey  *rsa.PrivateKey
}

type DBWithHooks struct {
	*gorm.DB
}

type AfterCommitter interface {
	AfterCommit(ctx context.Context)
}

type IPostgres interface {
	GetModels() Models.IModels
	GetError() error
	GetGorm() *gorm.DB
	GetGormWithHooks() *DBWithHooks
	MigrationUp() error
	MigrationDown() error
	MigrationStatus() error
	GetPublicKey() *rsa.PublicKey
	GetPrivateKey() *rsa.PrivateKey
}
```

**Key Points**:
- `GetPublicKey()` / `GetPrivateKey()` — RSA keys untuk field-level encryption (AES/RSA)
- `GetGormWithHooks()` — GORM instance yang support `AfterCommit` hooks via `HookTransaction()`
- `GetModels()` — Access registered GORM models

## New() Constructor

```go
func New() IPostgres {
	logMode := 0
	if os.Getenv("DB_DEBUG") == "TRUE" {
		logMode = 3
	}

	dbOptions := &PostgresConnection{
		host:     os.Getenv("DB_HOST"),
		port:     os.Getenv("DB_PORT"),
		user:     os.Getenv("DB_USERNAME"),
		password: os.Getenv("DB_PASSWORD"),
		database: os.Getenv("DB_NAME"),
		logMode:  logMode,
		maxIdleConnection:             10,
		maxOpenConnection:             50,
		connectionMaxLifetimeInSecond: 1800,
	}

	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s",
		dbOptions.host, dbOptions.user, dbOptions.password, dbOptions.database, dbOptions.port)

	// Load RSA keys for field-level encryption
	privateKey, errLoadPrivateKey := Encryption.LoadPrivateKey()
	if errLoadPrivateKey != nil {
		return &Postgres{DB: nil, Error: errLoadPrivateKey, Models: nil, PrivateKey: nil, PublicKey: nil}
	}

	publicKey, errLoadPublicKey := Encryption.LoadPublicKey()
	if errLoadPublicKey != nil {
		return &Postgres{DB: nil, Error: errLoadPublicKey, Models: nil, PrivateKey: nil, PublicKey: nil}
	}

	db, err := gorm.Open(gormPostgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.LogLevel(dbOptions.logMode)),
		NamingStrategy: schema.NamingStrategy{
			SingularTable: true,
		},
	})

	if err != nil {
		return &Postgres{DB: nil, Error: err, Models: nil, PrivateKey: nil, PublicKey: nil}
	}

	// Connection pooling
	postgresDB, _ := db.DB()
	postgresDB.SetMaxOpenConns(dbOptions.maxOpenConnection)
	postgresDB.SetConnMaxLifetime(time.Duration(dbOptions.connectionMaxLifetimeInSecond) * time.Minute)
	postgresDB.SetMaxIdleConns(dbOptions.maxIdleConnection)

	// Auto-migrate migration_meta table
	Models.MigrateMigrationMeta(db)

	return &Postgres{
		DB:          db,
		Error:       nil,
		DBWithHooks: &DBWithHooks{DB: db},
		Models:      Models.New(db),
		PrivateKey:  privateKey,
		PublicKey:   publicKey,
	}
}
```

## HookTransaction Pattern

Untuk trigger AfterCommit hooks setelah transaction berhasil:

```go
func (db *DBWithHooks) HookTransaction() func(fn func(tx *gorm.DB) ([]AfterCommitter, error)) error {
	return func(fn func(tx *gorm.DB) ([]AfterCommitter, error)) error {
		var afterCommitObjs []AfterCommitter

		err := db.DB.Transaction(func(tx *gorm.DB) error {
			var innerErr error
			afterCommitObjs, innerErr = fn(tx)
			return innerErr
		})

		if err == nil {
			for _, obj := range afterCommitObjs {
				obj.AfterCommit(db.DB.Statement.Context)
			}
		}

		return err
	}
}
```

## Env Vars

- `DB_HOST` — PostgreSQL host
- `DB_PORT` — PostgreSQL port
- `DB_USERNAME` — Database username
- `DB_PASSWORD` — Database password
- `DB_NAME` — Database name
- `DB_DEBUG` — Set "TRUE" untuk enable query logging

## Usage di main.go

```go
postgres := Postgres.New()

if postgres.GetError() != nil {
	log.Fatalf("Failed to Initialized DB Postgres: %v", postgres.GetError())
}

// Access GORM
db := postgres.GetGorm()

// Access models
postgres.GetModels().Patient()

// Access encryption keys
privateKey := postgres.GetPrivateKey()
publicKey := postgres.GetPublicKey()

// Run migrations
postgres.MigrationUp()
postgres.MigrationDown()
postgres.MigrationStatus()
```

---

## Migration System

Migrations menggunakan raw SQL files di `src/drivers/postgres/migrations/`.

### Migration File Format

Satu file `.sql` berisi both up dan down, dipisahkan oleh `-- down`:

```sql
-- up
CREATE TABLE patient_portal_accesses (
    id BIGSERIAL PRIMARY KEY,
    ref_id VARCHAR(36) NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    user_id VARCHAR(36) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMP
);

CREATE INDEX idx_ppa_user_id ON patient_portal_accesses(user_id);

-- down
DROP TABLE IF EXISTS patient_portal_accesses;
```

### Migration Naming Convention

Format: `YYYYMMDD_<description>.sql`

Contoh:
- `20260315_create_patient_portal_accesses.sql`
- `20260315_create_patient_portal_securities.sql`

### Migration Commands

Di `main.go`, migration dijalankan via `INTERFACE=MIGRATION`:

```go
case "MIGRATION":
	cmd := os.Args[1]
	switch cmd {
	case "up":
		err := postgres.MigrationUp()
		// Also run mongo migrations
		mongo.Migrate()
	case "down":
		err := postgres.MigrationDown()
	case "status":
		err := postgres.MigrationStatus()
	}
```

### Migration Tracking

Migrations di-track via `migration_metas` table (auto-created):

```go
type MigrationMeta struct {
	ID        uint      `gorm:"primaryKey;autoIncrement"`
	Name      string    `gorm:"type:varchar(255);uniqueIndex"`
	AppliedAt time.Time `gorm:"type:timestamp"`
}
```

---

## Models

Package: `Models` — Lokasi: `src/drivers/postgres/models/<nama>.go`

### Rules

1. Semua field pakai `gorm` tag — `gorm:"type:varchar(255);uniqueIndex"`, `gorm:"type:timestamp;index"`
2. Primary key: `ID uint gorm:"primaryKey;autoIncrement;unique"` dengan `gorm.Model` embedded, atau manual
3. Table name WAJIB plural — `users`, `patients`, `patient_disclaimers`
4. Setiap model WAJIB punya:
   - `func (<Model>) TableName() string` — return table name (plural, snake_case)
   - `func (i *Models) <Model>() *gorm.DB` — getter yang return `*gorm.DB` (scoped model)
   - `func Migrate<Model>(db *gorm.DB)` — auto-migrate function
   - `func (data *<Model>) To<Model>Entity(...) *Entities.<Model>` — converter ke entity
5. Soft delete pakai `DeletedAt *time.Time gorm:"type:timestamp;index"`
6. Model yang butuh sync ke Mongo bisa implement `AfterCommit(ctx context.Context)` via EventEmitter

### Table Naming Convention

SELALU gunakan plural (jamak), snake_case:

| Entity | Table Name | TableName() |
|--------|-----------|-------------|
| User | `users` | `return "users"` |
| Patient | `patients` | `return "patients"` |
| PatientDisclaimer | `patient_disclaimers` | `return "patient_disclaimers"` |
| UserPatient | `user_patients` | `return "user_patients"` |
| PatientInsurance | `patient_insurances` | `return "patient_insurances"` |

### GORM Tag Convention

Gunakan `gorm:"type:<type>;constraint"` pattern:

```go
type Patient struct {
	gorm.Model
	ID        uint       `gorm:"primaryKey;autoIncrement;unique"`
	RefId     string     `gorm:"type:varchar(255);uniqueIndex"`
	LegacyId  string     `gorm:"type:varchar(255)"`
	Name      []byte     `gorm:"type:bytea"`           // encrypted field
	Gender    []byte     `gorm:"type:bytea;index"`      // encrypted + indexed
	Status    string     `gorm:"type:varchar(100);index"`
	CreatedAt *time.Time `gorm:"type:timestamp;index"`
	UpdatedAt *time.Time `gorm:"type:timestamp;index"`
	DeletedAt *time.Time `gorm:"type:timestamp;index"`
}
```

**Encrypted Fields**: Sensitive data (Name, BirthDate, Phone, IDNumber, etc.) disimpan sebagai `[]byte` (`bytea`) dan di-encrypt/decrypt via RSA keys.

### Template: Standard Model (dengan gorm.Model)

```go
package Models

import (
	"time"

	"gorm.io/gorm"

	Entities "mika/<service>/src/entities"
)

type PatientDisclaimer struct {
	gorm.Model
	ID           uint       `gorm:"primaryKey;autoIncrement;unique"`
	RefId        string     `gorm:"type:varchar(255);uniqueIndex"`
	PatientRefId string     `gorm:"type:varchar(255);index"`
	Type         string     `gorm:"type:varchar(100);index"`
	IsAgree      bool       `gorm:"type:bool;index"`
	CreatedAt    *time.Time `gorm:"type:timestamp;index"`
	UpdatedAt    *time.Time `gorm:"type:timestamp;index"`
	DeletedAt    *time.Time `gorm:"type:timestamp;index"`
}

func (PatientDisclaimer) TableName() string {
	return "patient_disclaimers"
}

func (i *Models) PatientDisclaimer() *gorm.DB {
	return i.DB.Model(&PatientDisclaimer{})
}

func MigratePatientDisclaimer(db *gorm.DB) {
	db.AutoMigrate(&PatientDisclaimer{})
}

func (pd *PatientDisclaimer) ToPatientDisclaimerEntity() *Entities.PatientDisclaimer {
	return &Entities.PatientDisclaimer{
		RefId:        pd.RefId,
		PatientRefId: pd.PatientRefId,
		Type:         pd.Type,
		IsAgree:      pd.IsAgree,
		CreatedAt:    pd.CreatedAt,
		UpdatedAt:    pd.UpdatedAt,
		DeletedAt:    pd.DeletedAt,
	}
}
```

### Template: Model dengan Encrypted Fields

```go
package Models

import (
	"crypto/rsa"
	"time"

	"gorm.io/gorm"

	Entities "mika/<service>/src/entities"
	Encryptions "mika/<service>/src/helpers/utils/encryption"
)

type Patient struct {
	gorm.Model
	ID          uint       `gorm:"primaryKey;autoIncrement;unique"`
	RefId       string     `gorm:"type:varchar(255);uniqueIndex"`
	LegacyId    string     `gorm:"type:varchar(255)"`
	Name        []byte     `gorm:"type:bytea"`
	BirthDate   []byte     `gorm:"type:bytea"`
	Phone       []byte     `gorm:"type:bytea"`
	IDNumber    []byte     `gorm:"type:bytea"`
	Nationality []byte     `gorm:"type:bytea;index"`
	CreatedAt   *time.Time `gorm:"type:timestamp;index"`
	UpdatedAt   *time.Time `gorm:"type:timestamp;index"`
	DeletedAt   *time.Time `gorm:"type:timestamp;index"`
}

func (Patient) TableName() string {
	return "patients"
}

func (p *Patient) ToPatientEntity(privateKey *rsa.PrivateKey) *Entities.Patient {
	return &Entities.Patient{
		RefId:       p.RefId,
		Name:        Encryptions.DecryptField(p.Name, privateKey),
		Phone:       Encryptions.DecryptField(p.Phone, privateKey),
		Nationality: Encryptions.DecryptField(p.Nationality, privateKey),
		CreatedAt:   p.CreatedAt,
		UpdatedAt:   p.UpdatedAt,
		DeletedAt:   p.DeletedAt,
	}
}
```

**Note**: `ToEntity()` untuk encrypted models menerima `privateKey *rsa.PrivateKey` sebagai parameter.

### Template: Model dengan AfterCommit Hook

```go
func (i *PatientDisclaimer) AfterCommit(ctx context.Context) {
	instance := ctx.Value(Enums.EventEmitterKey)
	if instance != nil && instance.(eventemitter.IEventEmitter) != nil {
		if i.RefId != "" {
			instance.(eventemitter.IEventEmitter).Emit("SYNC_PATIENT_DISCLAIMER", i.RefId)
		}

		for _, refId := range i.RefIds {
			if refId != "" {
				instance.(eventemitter.IEventEmitter).Emit("DIRECT_SYNC_PATIENT_DISCLAIMER", refId)
			}
		}
	}
}
```

Tambahkan field `RefIds []string gorm:"-"` di model untuk batch sync.

### models/interface.go Pattern

```go
package Models

import (
	"gorm.io/gorm"
)

type Models struct {
	DB *gorm.DB
}

type IModels interface {
	User() *gorm.DB
	Patient() *gorm.DB
	UserPatient() *gorm.DB
	PatientDisclaimer() *gorm.DB
	PatientInsurance() *gorm.DB
	MigrationMeta() *gorm.DB
	// ... tambah method baru di sini
}

func New(db *gorm.DB) IModels {
	return &Models{DB: db}
}
```

**Key Points**:
- Setiap model method return `*gorm.DB` (scoped ke model tersebut via `i.DB.Model(&<Model>{})`)
- `MigrationMeta()` selalu ada untuk migration tracking
- Tambah method baru di `IModels` saat menambah model baru

### GORM Tag Options Reference

#### Column Definition
```go
gorm:"type:varchar(255)"              // Column type
gorm:"type:bytea"                     // Binary (for encrypted fields)
gorm:"type:text"                      // Text
gorm:"type:bool"                      // Boolean
gorm:"type:timestamp"                 // Timestamp
gorm:"type:int"                       // Integer
gorm:"type:decimal(15,2)"             // Decimal
```

#### Constraints
```go
gorm:"primaryKey;autoIncrement;unique" // Primary key
gorm:"uniqueIndex"                     // Unique index
gorm:"index"                           // Regular index
```

#### Special
```go
gorm:"-"                               // Ignore field (not persisted)
```
