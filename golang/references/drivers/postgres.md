# PostgreSQL Driver (GORM)

Package: `Postgres` — Lokasi: `src/drivers/postgres/`

## Interface

```go
package Postgres

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

## New() Constructor

```go
func New() IPostgres {
	logMode := 0
	if os.Getenv("DB_DEBUG") == "TRUE" {
		logMode = 3
	}

	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s",
		os.Getenv("DB_HOST"),
		os.Getenv("DB_USERNAME"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_NAME"),
		os.Getenv("DB_PORT"))

	db, err := gorm.Open(gormPostgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.LogLevel(logMode)),
		NamingStrategy: schema.NamingStrategy{
			SingularTable: true,
		},
	})

	if err != nil {
		return &Postgres{DB: nil, Error: err, Models: nil}
	}

	// Connection pooling
	postgresDB, _ := db.DB()
	postgresDB.SetMaxOpenConns(50)
	postgresDB.SetMaxIdleConns(10)
	postgresDB.SetConnMaxLifetime(30 * time.Minute)

	return &Postgres{
		DB:          db,
		DBWithHooks: &DBWithHooks{DB: db},
		Models:      Models.New(db),
		Error:       nil,
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

// Run migrations
postgres.MigrationUp()
postgres.MigrationDown()
postgres.MigrationStatus()
```

## INTERFACE Commands

```bash
# Run migration up
INTERFACE=MIGRATION_UP go run src/main.go

# Run migration down
INTERFACE=MIGRATION_DOWN go run src/main.go

# Check migration status
INTERFACE=MIGRATION_STATUS go run src/main.go
```

---

## Models

Package: `Models` — Lokasi: `src/drivers/postgres/models/<nama>.go`

### Rules

1. Semua field pakai `gorm` tag dengan snake_case — `gorm:"column:ref_id"`, `gorm:"column:created_at"`
2. `ID uint gorm:"primaryKey;autoIncrement"` — primary key auto increment
3. Atau `ID string gorm:"primaryKey;type:uuid;default:gen_random_uuid()"` — UUID primary key
4. Timestamp fields pakai `gorm.Model` atau manual dengan `gorm:"autoCreateTime"`, `gorm:"autoUpdateTime"`
5. Table name WAJIB jamak (plural, akhiran `s`) — `orders`, `invoices`, `users`
6. Setiap model WAJIB punya:
   - `func (Model) TableName() string` — return table name (plural)
   - `func (data *Model) ToEntity() *Entities.Model` — converter ke entity
7. Soft delete pakai `gorm.DeletedAt` atau `DeletedAt *time.Time gorm:"index"`

### Table Naming Convention

SELALU gunakan plural (jamak):

| Entity | Table Name | TableName() |
|--------|-----------|-------------|
| User | `users` | `return "users"` |
| Order | `orders` | `return "orders"` |
| Invoice | `invoices` | `return "invoices"` |
| OrderItem | `order_items` | `return "order_items"` |
| UserRole | `user_roles` | `return "user_roles"` |

### GORM Tag Convention

SELALU snake_case untuk column names:

```go
type User struct {
	ID          uint       `gorm:"primaryKey;autoIncrement"`
	RefId       string     `gorm:"column:ref_id;type:varchar(100);uniqueIndex;not null"`
	PersonalId  string     `gorm:"column:personal_id;type:varchar(50);index"`
	Name        string     `gorm:"column:name;type:varchar(255);not null"`
	Email       string     `gorm:"column:email;type:varchar(255);uniqueIndex"`
	IsActive    *bool      `gorm:"column:is_active;default:true"`
	CreatedAt   time.Time  `gorm:"column:created_at;autoCreateTime"`
	UpdatedAt   time.Time  `gorm:"column:updated_at;autoUpdateTime"`
	DeletedAt   *time.Time `gorm:"column:deleted_at;index"`
}
```

JANGAN:
```go
	RefId string `gorm:"column:refId"`      // ❌ camelCase
	RefId string `gorm:"column:Ref_Id"`     // ❌ mixed case
```

### Template: Standard Model dengan Auto Increment ID

```go
package Models

import (
	"time"
	Entities "agungsdas/<service>/src/entities"
)

type Order struct {
	ID           uint       `gorm:"primaryKey;autoIncrement"`
	RefId        string     `gorm:"column:ref_id;type:varchar(100);uniqueIndex;not null"`
	OrderNumber  string     `gorm:"column:order_number;type:varchar(50);index;not null"`
	Status       string     `gorm:"column:status;type:varchar(50);index;not null"`
	Amount       string     `gorm:"column:amount;type:decimal(15,2)"`
	CustomerName string     `gorm:"column:customer_name;type:varchar(255)"`
	CreatedAt    time.Time  `gorm:"column:created_at;autoCreateTime"`
	UpdatedAt    time.Time  `gorm:"column:updated_at;autoUpdateTime"`
	DeletedAt    *time.Time `gorm:"column:deleted_at;index"`
}

func (Order) TableName() string {
	return "orders"
}

func (data *Order) ToOrderEntity() *Entities.Order {
	return &Entities.Order{
		MongoID:      "",
		RefId:        data.RefId,
		OrderNumber:  data.OrderNumber,
		Status:       data.Status,
		Amount:       data.Amount,
		CustomerName: data.CustomerName,
		CreatedAt:    &data.CreatedAt,
		UpdatedAt:    &data.UpdatedAt,
		DeletedAt:    data.DeletedAt,
	}
}
```

### Template: Model dengan UUID Primary Key

```go
package Models

import (
	"time"
	Entities "agungsdas/<service>/src/entities"
)

type User struct {
	ID         string     `gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	RefId      string     `gorm:"column:ref_id;type:varchar(100);uniqueIndex;not null"`
	PersonalId string     `gorm:"column:personal_id;type:varchar(50);index"`
	Name       string     `gorm:"column:name;type:varchar(255);not null"`
	Email      string     `gorm:"column:email;type:varchar(255);uniqueIndex"`
	IsActive   *bool      `gorm:"column:is_active;default:true"`
	CreatedAt  time.Time  `gorm:"column:created_at;autoCreateTime"`
	UpdatedAt  time.Time  `gorm:"column:updated_at;autoUpdateTime"`
	DeletedAt  *time.Time `gorm:"column:deleted_at;index"`
}

func (User) TableName() string {
	return "users"
}

func (data *User) ToUserEntity() *Entities.User {
	return &Entities.User{
		MongoID:    "",
		RefId:      data.RefId,
		PersonalId: data.PersonalId,
		Name:       data.Name,
		Email:      data.Email,
		IsActive:   data.IsActive,
		CreatedAt:  &data.CreatedAt,
		UpdatedAt:  &data.UpdatedAt,
		DeletedAt:  data.DeletedAt,
	}
}
```

### Template: Model dengan gorm.Model (Built-in Timestamps)

```go
package Models

import (
	"gorm.io/gorm"
	Entities "agungsdas/<service>/src/entities"
)

type Product struct {
	gorm.Model
	RefId       string  `gorm:"column:ref_id;type:varchar(100);uniqueIndex;not null"`
	Name        string  `gorm:"column:name;type:varchar(255);not null"`
	Description string  `gorm:"column:description;type:text"`
	Price       float64 `gorm:"column:price;type:decimal(15,2);not null"`
	Stock       int     `gorm:"column:stock;type:int;default:0"`
}

func (Product) TableName() string {
	return "products"
}

func (data *Product) ToProductEntity() *Entities.Product {
	return &Entities.Product{
		MongoID:     "",
		RefId:       data.RefId,
		Name:        data.Name,
		Description: data.Description,
		Price:       data.Price,
		Stock:       data.Stock,
		CreatedAt:   &data.CreatedAt,
		UpdatedAt:   &data.UpdatedAt,
		DeletedAt:   &data.DeletedAt.Time,
	}
}
```

### GORM Tag Options

#### Column Definition
```go
gorm:"column:field_name"              // Column name (snake_case)
gorm:"type:varchar(100)"              // Column type
gorm:"size:255"                       // Column size
gorm:"precision:10;scale:2"           // Decimal precision
```

#### Constraints
```go
gorm:"primaryKey"                     // Primary key
gorm:"uniqueIndex"                    // Unique index
gorm:"index"                          // Regular index
gorm:"not null"                       // NOT NULL constraint
gorm:"unique"                         // Unique constraint
gorm:"check:age > 0"                  // Check constraint
```

#### Default Values
```go
gorm:"default:true"                   // Default value
gorm:"default:gen_random_uuid()"      // UUID default
gorm:"default:CURRENT_TIMESTAMP"      // Timestamp default
```

#### Auto Timestamps
```go
gorm:"autoCreateTime"                 // Auto set on create
gorm:"autoUpdateTime"                 // Auto set on update
gorm:"autoCreateTime:nano"            // Nanosecond precision
gorm:"autoUpdateTime:milli"           // Millisecond precision
```

#### Relationships
```go
gorm:"foreignKey:UserID"              // Foreign key
gorm:"references:ID"                  // Reference field
gorm:"constraint:OnUpdate:CASCADE,OnDelete:SET NULL"
```

#### Other Options
```go
gorm:"-"                              // Ignore field
gorm:"-:migration"                    // Ignore in migration
gorm:"serializer:json"                // JSON serializer
gorm:"embedded"                       // Embedded struct
gorm:"embeddedPrefix:prefix_"         // Embedded with prefix
```

### Model dengan Relasi (One-to-Many)

```go
type Order struct {
	ID         uint        `gorm:"primaryKey;autoIncrement"`
	RefId      string      `gorm:"column:ref_id;type:varchar(100);uniqueIndex;not null"`
	OrderItems []OrderItem `gorm:"foreignKey:OrderID;references:ID"`
	CreatedAt  time.Time   `gorm:"column:created_at;autoCreateTime"`
	UpdatedAt  time.Time   `gorm:"column:updated_at;autoUpdateTime"`
}

type OrderItem struct {
	ID        uint      `gorm:"primaryKey;autoIncrement"`
	OrderID   uint      `gorm:"column:order_id;index;not null"`
	ProductID uint      `gorm:"column:product_id;index;not null"`
	Quantity  int       `gorm:"column:quantity;type:int;not null"`
	Price     float64   `gorm:"column:price;type:decimal(15,2);not null"`
	CreatedAt time.Time `gorm:"column:created_at;autoCreateTime"`
}

func (Order) TableName() string {
	return "orders"
}

func (OrderItem) TableName() string {
	return "order_items"
}
```

### Model dengan Relasi (Many-to-Many)

```go
type User struct {
	ID        uint      `gorm:"primaryKey;autoIncrement"`
	Name      string    `gorm:"column:name;type:varchar(255);not null"`
	Roles     []Role    `gorm:"many2many:user_roles;"`
	CreatedAt time.Time `gorm:"column:created_at;autoCreateTime"`
}

type Role struct {
	ID        uint      `gorm:"primaryKey;autoIncrement"`
	Name      string    `gorm:"column:name;type:varchar(100);uniqueIndex;not null"`
	Users     []User    `gorm:"many2many:user_roles;"`
	CreatedAt time.Time `gorm:"column:created_at;autoCreateTime"`
}
```

### Composite Primary Key

```go
type UserRole struct {
	UserID    uint      `gorm:"primaryKey;column:user_id"`
	RoleID    uint      `gorm:"primaryKey;column:role_id"`
	CreatedAt time.Time `gorm:"column:created_at;autoCreateTime"`
}

func (UserRole) TableName() string {
	return "user_roles"
}
```

### JSON/JSONB Column

```go
type Config struct {
	ID       uint           `gorm:"primaryKey;autoIncrement"`
	Name     string         `gorm:"column:name;type:varchar(100);not null"`
	Settings map[string]any `gorm:"column:settings;type:jsonb;serializer:json"`
	Metadata []string       `gorm:"column:metadata;type:jsonb;serializer:json"`
}

func (Config) TableName() string {
	return "configs"
}
```

### Enum dengan Check Constraint

```go
type Invoice struct {
	ID        uint      `gorm:"primaryKey;autoIncrement"`
	Status    string    `gorm:"column:status;type:varchar(50);check:status IN ('PENDING','APPROVED','REJECTED');not null"`
	CreatedAt time.Time `gorm:"column:created_at;autoCreateTime"`
}

func (Invoice) TableName() string {
	return "invoices"
}
```
