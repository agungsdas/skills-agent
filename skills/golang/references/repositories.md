# Repositories

Package: `<Domain>Repository` — Lokasi: `src/repositories/<domain>/`

## Rules

1. Struct menyimpan driver dependencies sesuai kebutuhan — bisa Mongo only, Postgres only, atau kombinasi
2. Interface `I<Domain>` mendefinisikan semua method
3. Constructor: `New(...)` — parameter sesuai driver yang dibutuhkan
4. Satu file per operasi
5. Params struct didefinisikan di file operasi masing-masing
6. Return entity (bukan model) — selalu convert pakai `model.To<Name>Entity()`
7. List/Find return `([]Entities.<Name>, *Applications.Meta, error)` untuk pagination (Mongo) atau `([]Entities.<Name>, int64, error)` untuk SQL
8. Method naming convention: suffix `Mongo` untuk MongoDB operations, suffix `Sql` untuk PostgreSQL operations (jika repo punya keduanya)

## File Structure

```
src/repositories/<domain>/
├── interface.go              # Struct + Interface + New()
├── <operation>-mongo.go      # MongoDB operations (jika pakai Mongo)
├── <operation>-sql.go        # PostgreSQL operations (jika pakai Postgres)
└── <operation>.go            # Single-DB operations (jika hanya 1 DB)
```

## Constructor Variants

Tergantung kebutuhan domain, constructor bisa berbeda-beda:

### Variant 1: Mongo + Postgres (dual database)

Digunakan ketika domain butuh akses ke kedua database (contoh: data di-sync antara Mongo dan Postgres).

```go
package <Domain>Repository

import (
	Mongo "mika/<service>/src/drivers/mongo"
	Postgres "mika/<service>/src/drivers/postgres"
)

type <Domain> struct {
	Mongo    Mongo.IMongo
	Postgres Postgres.IPostgres
}

func New(mongo Mongo.IMongo, postgres Postgres.IPostgres) I<Domain> {
	return &<Domain>{Mongo: mongo, Postgres: postgres}
}
```

### Variant 2: Mongo only

Digunakan ketika domain hanya butuh MongoDB (contoh: audit trail, documents, read-only lookup).

```go
package <Domain>Repository

import (
	Mongo "mika/<service>/src/drivers/mongo"
)

type <Domain> struct {
	Mongo Mongo.IMongo
}

func New(mongo Mongo.IMongo) I<Domain> {
	return &<Domain>{Mongo: mongo}
}
```

### Variant 3: Postgres only

Digunakan ketika domain hanya butuh PostgreSQL (contoh: transactional data tanpa sync ke Mongo).

```go
package <Domain>Repository

import (
	Postgres "mika/<service>/src/drivers/postgres"
)

type <Domain> struct {
	Postgres Postgres.IPostgres
}

func New(postgres Postgres.IPostgres) I<Domain> {
	return &<Domain>{Postgres: postgres}
}
```

> **Pilih variant yang sesuai kebutuhan domain.** Jangan inject driver yang tidak dipakai.

---

## Template interface.go (Dual Database — Mongo + Postgres)

```go
package <Domain>Repository

import (
	"context"

	"gorm.io/gorm"

	Applications "mika/<service>/src/definitions/applications"
	Mongo "mika/<service>/src/drivers/mongo"
	Postgres "mika/<service>/src/drivers/postgres"
	Entities "mika/<service>/src/entities"
)

type <Domain> struct {
	Mongo    Mongo.IMongo
	Postgres Postgres.IPostgres
}

type I<Domain> interface {
	// MongoDB operations
	FindByRefIdMongo(refId string) (*Entities.<Domain>, error)
	ListMongo(params *ParamsListMongo) ([]Entities.<Domain>, *Applications.Meta, error)
	UpsertMongo(ctx context.Context, params []ParamsUpsertMongo) error
	DeleteByRefIdMongo(ctx context.Context, refId string) error
	CountMongo(params *ParamsCountMongo) (int64, error)

	// PostgreSQL operations
	FindByRefIdSql(refId string, showDeletedData bool, dbTransaction *gorm.DB) (*Entities.<Domain>, error)
	ListSql(params *ParamsListSql, dbTransaction *gorm.DB) ([]Entities.<Domain>, int64, error)
	CreateSql(params *ParamsCreateSql, showDeletedData bool, dbTransaction *gorm.DB) (*Entities.<Domain>, error)
	UpsertSql(params *ParamsUpsertSql, showDeletedData bool, dbTransaction *gorm.DB) (*Entities.<Domain>, error)
	UpdateSql(params *ParamsUpdateSql, showDeletedData bool, dbTransaction *gorm.DB) (*Entities.<Domain>, error)
	DeleteByRefIdSql(refId string, dbTransaction *gorm.DB) error
	CountSql(params *ParamsCountSql, showDeletedData bool, dbTransaction *gorm.DB) (int64, error)
}

func New(mongo Mongo.IMongo, postgres Postgres.IPostgres) I<Domain> {
	return &<Domain>{Mongo: mongo, Postgres: postgres}
}
```

---

## SQL Operation Templates

### FindByRefIdSql

```go
func (i *<Domain>) FindByRefIdSql(refId string, showDeletedData bool, dbTransaction *gorm.DB) (*Entities.<Domain>, error) {
	models := i.Postgres.GetModels().<Domain>()
	if dbTransaction != nil {
		models = dbTransaction.Model(&Models.<Domain>{})
	}

	models = models.Where("ref_id = ?", refId)

	if showDeletedData {
		models = models.Unscoped()
	}

	var data *Models.<Domain> = nil
	if err := models.First(&data).Error; err != nil {
		return nil, err
	}

	if data == nil {
		return nil, errors.New("<domain> not found")
	}

	return data.To<Domain>Entity(i.Postgres.GetPrivateKey()), nil
}
```

**Key Points SQL**:
- Gunakan `i.Postgres.GetModels().<Domain>()` untuk default query
- Override dengan `dbTransaction.Model(&Models.<Domain>{})` jika ada transaction
- `showDeletedData` → `models.Unscoped()` untuk include soft-deleted records
- Convert model ke entity via `To<Domain>Entity()` — beberapa model butuh `privateKey` untuk decrypt fields

### ListSql

```go
type ParamsListSql struct {
	Keyword string
	Status  string
	Page    int
	PerPage int
}

func (i *<Domain>) ListSql(params *ParamsListSql, dbTransaction *gorm.DB) ([]Entities.<Domain>, int64, error) {
	models := i.Postgres.GetModels().<Domain>()
	if dbTransaction != nil {
		models = dbTransaction.Model(&Models.<Domain>{})
	}

	if params.Status != "" {
		models = models.Where("status = ?", params.Status)
	}

	if params.Keyword != "" {
		models = models.Where("name ILIKE ?", "%"+params.Keyword+"%")
	}

	var total int64
	models.Count(&total)

	offset := (params.Page - 1) * params.PerPage
	models = models.Offset(offset).Limit(params.PerPage).Order("created_at DESC")

	var data []Models.<Domain>
	if err := models.Find(&data).Error; err != nil {
		return nil, 0, err
	}

	results := []Entities.<Domain>{}
	for _, d := range data {
		results = append(results, *d.To<Domain>Entity(i.Postgres.GetPrivateKey()))
	}

	return results, total, nil
}
```

### CreateSql

```go
type ParamsCreateSql struct {
	RefId  string
	Name   string
	Status string
}

func (i *<Domain>) CreateSql(params *ParamsCreateSql, showDeletedData bool, dbTransaction *gorm.DB) (*Entities.<Domain>, error) {
	db := i.Postgres.GetGorm()
	if dbTransaction != nil {
		db = dbTransaction
	}

	model := Models.<Domain>{
		RefId:  params.RefId,
		Name:   params.Name,
		Status: params.Status,
	}

	if err := db.Create(&model).Error; err != nil {
		return nil, err
	}

	return model.To<Domain>Entity(i.Postgres.GetPrivateKey()), nil
}
```

---

## MongoDB Operation Templates

### FindByRefIdMongo

```go
func (i *<Domain>) FindByRefIdMongo(refId string) (*Entities.<Domain>, error) {
	collection := i.Mongo.GetModels().<Domain>()

	filters := bson.M{}
	filters["refId"] = refId

	data := new(Models.<Domain>)
	err := collection.FindOne(context.Background(), filters).Decode(data)

	if err != nil {
		return nil, err
	}

	return data.To<Domain>Entity(), nil
}
```

### ListMongo (dengan Pagination)

```go
type ParamsListMongo struct {
	Keyword  string
	Statuses []string
	Page     int
	PerPage  int
}

func (i *<Domain>) ListMongo(params *ParamsListMongo) ([]Entities.<Domain>, *Applications.Meta, error) {
	collection := i.Mongo.GetModels().<Domain>()

	filters := bson.M{}
	andFilters := []bson.M{}

	if params.Keyword != "" {
		andFilters = append(andFilters, bson.M{
			"$or": []bson.M{
				{"fieldA": bson.M{"$regex": params.Keyword, "$options": "i"}},
				{"fieldB": bson.M{"$regex": params.Keyword, "$options": "i"}},
			},
		})
	}

	if len(params.Statuses) > 0 {
		andFilters = append(andFilters, bson.M{"status": bson.M{"$in": params.Statuses}})
	}

	if len(andFilters) == 1 {
		filters = andFilters[0]
	} else if len(andFilters) > 1 {
		filters["$and"] = andFilters
	}

	page := params.Page
	if page < 1 { page = 1 }
	limit := params.PerPage
	if limit < 1 && limit != -1 { limit = 20 }
	offset := (page - 1) * limit

	findOptions := options.Find()
	if limit != -1 {
		findOptions.SetSkip(int64(offset))
		findOptions.SetLimit(int64(limit))
	}

	cursor, err := collection.Find(context.Background(), filters, findOptions)
	total, _ := collection.CountDocuments(context.Background(), filters)
	if err != nil { return nil, nil, err }

	results := []Entities.<Domain>{}
	for cursor.Next(context.Background()) {
		model := Models.<Domain>{}
		if err := cursor.Decode(&model); err != nil { return nil, nil, err }
		results = append(results, *model.To<Domain>Entity())
	}

	return results, &Applications.Meta{
		Page:      page,
		PerPage:   limit,
		TotalPage: int(math.Ceil(float64(total) / float64(limit))),
		Total:     int(total),
	}, nil
}
```

### BulkUpsert (MongoDB)

```go
func (i *<Domain>) UpsertMongo(ctx context.Context, params []ParamsUpsertMongo) error {
	collection := i.Mongo.GetModels().<Domain>()

	operations := []mongo.WriteModel{}
	for _, p := range params {
		model := Models.<Domain>{ /* map fields */ UpdatedAt: Type.ToTimePntr(time.Now()) }
		operations = append(operations, mongo.NewUpdateOneModel().
			SetFilter(bson.M{"refId": p.RefId}).
			SetUpdate(bson.M{
				"$set": model,
				"$setOnInsert": bson.M{"createdAt": time.Now()},
			}).
			SetUpsert(true))
	}

	_, err := collection.BulkWrite(ctx, operations, options.BulkWrite())
	return err
}
```

Pattern: `$set` untuk update fields, `$setOnInsert` untuk createdAt hanya saat insert baru.
