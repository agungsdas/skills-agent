# Mongo Driver

Package: `Mongo` — Lokasi: `src/drivers/mongo/`

## Interface

```go
package Mongo

import (
	Models "mika/<service>/src/drivers/mongo/models"
	Helpers "mika/<service>/src/helpers"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type Mongo struct {
	Models Models.IModels
	DB     *mongo.Database
	Error  error
}

type IMongo interface {
	GetModels() Models.IModels
	GetError() error
	Migrate()
}

func (i *Mongo) GetError() error { return i.Error }
func (i *Mongo) GetModels() Models.IModels { return i.Models }

func (i *Mongo) Migrate() {
	Models.CreateIndexUser(i.DB)
}
```

## New() Constructor

```go
func New() IMongo {
	ctx, cancel := context.WithTimeout(context.Background(),
		time.Duration(Helpers.GetEnvAsInt("DATABASE_TIMEOUT", 10))*time.Second)
	defer cancel()

	dbURL := Helpers.GetEnv("DATABASE_URI", "")
	clientOptions := options.Client().ApplyURI(dbURL)
	client, err := mongo.Connect(ctx, clientOptions)
	if err != nil {
		return &Mongo{DB: nil, Error: err, Models: Models.New(nil)}
	}

	db := client.Database(Helpers.GetEnv("DATABASE_NAME", ""))
	return &Mongo{DB: db, Error: nil, Models: Models.New(db)}
}
```

## Env Vars

- `DATABASE_URI` — MongoDB connection string
- `DATABASE_NAME` — Database name
- `DATABASE_TIMEOUT` — Connection timeout in seconds (default: 10)

## Usage di main.go

```go
mongo := Mongo.New()

if mongo.GetError() != nil {
	log.Fatalf("Failed to Initialized DB Mongo: %v", mongo.GetError())
}

// Access models (returns *mongo.Collection)
mongo.GetModels().Patient()
mongo.GetModels().PatientInsurance()
```

---

## Models

Package: `Models` — Lokasi: `src/drivers/mongo/models/<nama>.go`

### Rules

1. Semua field pakai `bson` tag dengan camelCase — `bson:"refId"`, `bson:"createdAt"`
2. `ID primitive.ObjectID bson:"_id,omitempty"` — selalu ada
3. Timestamp fields pakai `bson:"...,omitempty"` (opsional)
4. Collection name: camelCase plural — `patientInsurances`, `patientDisclaimers`
5. Setiap model WAJIB punya:
   - `var <NAME>_COLLECTION_NAME = "<collectionName>"` — collection name constant
   - `func (i *Models) <Name>() *mongo.Collection` — getter yang return `*mongo.Collection`
   - `func CreateIndex<Name>(db *mongo.Database)` — index creation function
   - `func (data *<Name>) To<Name>Entity() *Entities.<Name>` — converter ke entity
6. Register di `models/interface.go`: tambah method di `IModels`, panggil `CreateIndex<Name>` di `createIndex()`

### Collection Naming Convention

Gunakan camelCase plural:

| Entity | Collection Name | Constant |
|--------|----------------|----------|
| Patient | `patients` | `PATIENT_COLLECTION_NAME = "patients"` |
| PatientDisclaimer | `patient_disclaimers` | `PATIENT_DISCLAIMER_COLLECTION_NAME = "patient_disclaimers"` |
| PatientInsurance | `patientInsurances` | `PATIENT_INSURANCE_COLLECTION_NAME = "patientInsurances"` |
| Country | `country` | `COUNTRY_COLLECTION_NAME = "country"` |

> **Note**: Collection naming di codebase ini tidak 100% konsisten (ada snake_case dan camelCase). Ikuti pattern yang sudah ada di service masing-masing.

### BSON Tag Convention

SELALU camelCase, TIDAK boleh snake_case:

```go
type PatientInsurance struct {
	ID           primitive.ObjectID `bson:"_id,omitempty"`
	RefId        string             `bson:"refId"`           // ✅ camelCase
	PatientRefId string             `bson:"patientRefId"`    // ✅ camelCase
	InsuranceId  string             `bson:"insuranceId"`     // ✅ camelCase
	IsActive     *bool              `bson:"isActive"`        // ✅ camelCase
	CreatedAt    *time.Time         `bson:"createdAt"`       // ✅ camelCase
}
```

JANGAN:
```go
	RefId string `bson:"ref_id"`     // ❌ snake_case
	RefId string `bson:"Ref_Id"`     // ❌ mixed case
```

### Template: Standard Model

```go
package Models

import (
	"context"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"

	Entities "mika/<service>/src/entities"
)

var PATIENT_INSURANCE_COLLECTION_NAME = "patientInsurances"

type PatientInsurance struct {
	ID           primitive.ObjectID `bson:"_id,omitempty"`
	RefId        string             `bson:"refId"`
	PatientRefId string             `bson:"patientRefId"`
	InsuranceId  string             `bson:"insuranceId"`
	Number       string             `bson:"number"`
	IsActive     *bool              `bson:"isActive"`
	CreatedAt    *time.Time         `bson:"createdAt"`
	UpdatedAt    *time.Time         `bson:"updatedAt"`
	DeletedAt    *time.Time         `bson:"deletedAt"`
}

func (i *Models) PatientInsurance() *mongo.Collection {
	return i.DB.Collection(PATIENT_INSURANCE_COLLECTION_NAME)
}

func CreateIndexPatientInsurance(db *mongo.Database) {
	db.Collection(PATIENT_INSURANCE_COLLECTION_NAME).Indexes().CreateMany(
		context.Background(), []mongo.IndexModel{
			CreateIndex("refId", true, false),
			CreateIndex("patientRefId", false, false),
			CreateIndex("insuranceId", false, false),
			CreateIndex("createdAt", false, false),
			CreateIndex("updatedAt", false, false),
			CreateIndex("deletedAt", false, false),
		})
}

func (pi *PatientInsurance) ToPatientInsuranceEntity() *Entities.PatientInsurance {
	return &Entities.PatientInsurance{
		RefId:        pi.RefId,
		PatientRefId: pi.PatientRefId,
		InsuranceId:  pi.InsuranceId,
		Number:       pi.Number,
		IsActive:     pi.IsActive,
		CreatedAt:    pi.CreatedAt,
		UpdatedAt:    pi.UpdatedAt,
		DeletedAt:    pi.DeletedAt,
	}
}
```

### Register di interface.go

Di `IModels` interface tambah method:
```go
PatientInsurance() *mongo.Collection
```

Di `createIndex()` function panggil:
```go
CreateIndexPatientInsurance(db)
```

### models/interface.go Pattern

```go
package Models

import (
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type Models struct {
	DB *mongo.Database
}

type IModels interface {
	User() *mongo.Collection
	Patient() *mongo.Collection
	PatientDisclaimer() *mongo.Collection
	PatientInsurance() *mongo.Collection
	// ... tambah method baru di sini
}

func CreateIndex(field string, isUnique bool, isCollation bool) mongo.IndexModel {
	opt := options.Index()
	if isUnique {
		opt.SetUnique(true)
	}
	if isCollation {
		opt.SetCollation(&options.Collation{
			Locale:   "en",
			Strength: 2,
		})
	}
	return mongo.IndexModel{
		Keys:    bson.D{{Key: field, Value: 1}},
		Options: opt,
	}
}

func CreatePartialUniqueIndex(field string, filter map[string]interface{}) mongo.IndexModel {
	opt := options.Index().SetUnique(true).SetPartialFilterExpression(filter)
	return mongo.IndexModel{
		Keys:    bson.D{{Key: field, Value: 1}},
		Options: opt,
	}
}

func CreateCompoundUniqueIndex(fields []string, filter map[string]interface{}) mongo.IndexModel {
	keys := bson.D{}
	for _, field := range fields {
		keys = append(keys, bson.E{Key: field, Value: 1})
	}
	opt := options.Index().SetUnique(true).SetPartialFilterExpression(filter)
	return mongo.IndexModel{
		Keys:    keys,
		Options: opt,
	}
}

func createIndex(db *mongo.Database) {
	CreateIndexUser(db)
	CreateIndexPatient(db)
	CreateIndexPatientDisclaimer(db)
	CreateIndexPatientInsurance(db)
	// ... tambah CreateIndex<Name> baru di sini
}

func New(db *mongo.Database) IModels {
	createIndex(db)
	return &Models{DB: db}
}
```

### Index Helper Functions

Tersedia 3 helper untuk membuat index:

| Function | Use Case |
|----------|----------|
| `CreateIndex(field, isUnique, isCollation)` | Single field index |
| `CreatePartialUniqueIndex(field, filter)` | Unique index dengan partial filter |
| `CreateCompoundUniqueIndex(fields, filter)` | Compound unique index dengan partial filter |

Contoh penggunaan:
```go
// Simple index
CreateIndex("refId", true, false)           // unique index on refId
CreateIndex("status", false, false)          // regular index on status
CreateIndex("name", false, true)             // case-insensitive index on name

// Partial unique index
CreatePartialUniqueIndex("email", map[string]interface{}{
	"deletedAt": nil,
})

// Compound unique index
CreateCompoundUniqueIndex([]string{"userId", "patientId"}, map[string]interface{}{
	"deletedAt": nil,
	"status":    bson.M{"$nin": []string{"REJECTED", "TRANSFERRED"}},
})
```
