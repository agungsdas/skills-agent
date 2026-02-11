# Mongo Models

Package: `Models` — Lokasi: `src/drivers/mongo/models/<nama>.go`

## Rules

1. Semua field pakai `bson` tag dengan camelCase — `bson:"refId"`, `bson:"createdAt"`
2. `ID primitive.ObjectID bson:"_id,omitempty"` — selalu ada
3. Timestamp fields pakai `bson:"...,omitempty"`
4. Collection name WAJIB jamak (plural, akhiran `s`) — `orders`, `invoices`, `department_statuses`
5. Setiap model WAJIB punya:
   - `var <NAME>_COLLECTION_NAME = "<snake_case_plural>"` — HARUS plural (s)
   - `var <name>Indexes = []Index{...}`
   - `func (i *Context) New<Name>()` — setup collection + create indexes
   - `func (i *Context) Get<Name>() Model` — getter
   - `func (data *<Name>) To<Name>Entity() *Entities.<Name>` — converter ke entity
6. Register di `models/interface.go`: tambah field di Context, method di IModels, panggil di New()

## Collection Naming Convention

SELALU gunakan plural (jamak):

| Entity | Collection Name | Constant |
|--------|----------------|----------|
| Invoice | `invoices` | `INVOICE_COLLECTION_NAME = "invoices"` |
| Order | `orders` | `ORDER_COLLECTION_NAME = "orders"` |
| ChangeLog | `change_logs` | `CHANGE_LOG_COLLECTION_NAME = "change_logs"` |
| DepartmentStatus | `department_statuses` | `DEPARTMENT_STATUS_COLLECTION_NAME = "department_statuses"` |
| BatchSummary | `batch_summaries` | `BATCH_SUMMARY_COLLECTION_NAME = "batch_summaries"` |
| InvoiceProgress | `invoice_progress` | `INVOICE_PROGRESS_COLLECTION_NAME = "invoice_progress"` (MV) |
| MappingRole | `mapping_roles` | `MAPPING_ROLE_COLLECTION_NAME = "mapping_roles"` |

## BSON Tag Convention

SELALU camelCase, TIDAK boleh snake_case:

```go
type Order struct {
	ID              primitive.ObjectID `bson:"_id,omitempty"`
	RefId           string             `bson:"refId"`           // ✅ camelCase
	OrderNumber     string             `bson:"orderNumber"`     // ✅ camelCase
	DocumentDate    *time.Time         `bson:"documentDate"`    // ✅ camelCase
	CompanyCode     string             `bson:"companyCode"`     // ✅ camelCase
	CreatedAt       *time.Time         `bson:"createdAt,omitempty"`
}
```

JANGAN:
```go
	RefId string `bson:"ref_id"`     // ❌ snake_case
	RefId string `bson:"Ref_Id"`     // ❌ mixed case
```

## Template: Standard Model

```go
package Models

import (
	"context"
	Entities "agungsdas/<service>/src/entities"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

var ORDER_COLLECTION_NAME = "orders"

var orderIndexes = []Index{
	{Field: "refId", IndexConfig: IndexConfig{IsUnique: true}},
	{Field: "orderNumber", IndexConfig: IndexConfig{}},
	{Field: "status", IndexConfig: IndexConfig{}},
	{Field: "createdAt", IndexConfig: IndexConfig{}},
	{Field: "updatedAt", IndexConfig: IndexConfig{}},
}

type Order struct {
	ID          primitive.ObjectID `bson:"_id,omitempty"`
	RefId       string             `bson:"refId"`
	OrderNumber string             `bson:"orderNumber"`
	Status      string             `bson:"status"`
	Amount      string             `bson:"amount"`
	CreatedAt   *time.Time         `bson:"createdAt,omitempty"`
	UpdatedAt   *time.Time         `bson:"updatedAt,omitempty"`
	DeletedAt   *time.Time         `bson:"deletedAt,omitempty"`
}

func (i *Context) GetOrder() Model {
	return i.Order
}

func (i *Context) NewOrder() {
	model := Model{
		Name:       ORDER_COLLECTION_NAME,
		Collection: i.DB.Collection(ORDER_COLLECTION_NAME),
	}

	indexes := []mongo.IndexModel{}
	for _, idx := range orderIndexes {
		indexes = append(indexes, CreateIndexModel(idx))
	}

	model.Indexes = indexes
	model.Collection.Indexes().CreateMany(context.Background(), model.Indexes)

	i.Order = model
}

func (data *Order) ToOrderEntity() *Entities.Order {
	return &Entities.Order{
		MongoID:     data.ID.Hex(),
		RefId:       data.RefId,
		OrderNumber: data.OrderNumber,
		Status:      data.Status,
		Amount:      data.Amount,
		CreatedAt:   data.CreatedAt,
		UpdatedAt:   data.UpdatedAt,
		DeletedAt:   data.DeletedAt,
	}
}
```

## Register di interface.go

Di `Context` struct tambah field:
```go
Order Model
```

Di `IModels` interface tambah:
```go
GetOrder() Model
```

Di `New()` function panggil:
```go
modelsContext.NewOrder()
```

## Index Config Options

```go
IndexConfig{IsUnique: true}       // Unique index
IndexConfig{IsDescending: true}   // Descending sort
IndexConfig{IsCollation: true}    // Case-insensitive collation (locale: "en", strength: 2)
IndexConfig{}                     // Default ascending index
```

---

## Template: Materialized View (MV) Model

Materialized View adalah collection yang dibentuk dari aggregation pipeline (`$lookup` + `$merge`).
Data di-sync on-demand via EventEmitter, bukan real-time.

Contoh: `InvoiceProgress` adalah MV dari `invoices` + `department_statuses`.

### Struct MV

MV struct biasanya embed/reference model lain:

```go
var INVOICE_PROGRESS_COLLECTION_NAME = "invoice_progress"

type InvoiceProgress struct {
	ID                      primitive.ObjectID `bson:"_id,omitempty"`
	RefId                   string             `bson:"refId"`
	MainBatchId             string             `bson:"mainBatchId"`
	Invoice                 *Invoice           `bson:"invoice"`
	DepartmentStatuses      []DepartmentStatus `bson:"departmentStatuses"`
	CurrentDepartmentStatus *DepartmentStatus  `bson:"currentDepartmentStatus"`
}
```

### Index MV

MV indexes gabungan dari source model indexes dengan prefix:

```go
func (i *Context) NewInvoiceProgress() {
	model := Model{
		Name:       INVOICE_PROGRESS_COLLECTION_NAME,
		Collection: i.DB.Collection(INVOICE_PROGRESS_COLLECTION_NAME),
	}

	indexes := []mongo.IndexModel{
		CreateIndexModel(Index{Field: "refId", IndexConfig: IndexConfig{}}),
	}

	// Re-use indexes dari source model dengan prefix
	for _, invoiceIndex := range invoiceIndexes {
		indexes = append(indexes, CreateIndexModel(Index{
			Field:       fmt.Sprintf("invoice.%v", invoiceIndex.Field),
			IndexConfig: invoiceIndex.IndexConfig,
		}))
	}

	for _, deptIndex := range departmentStatusIndexes {
		indexes = append(indexes, CreateIndexModel(Index{
			Field:       fmt.Sprintf("departmentStatuses.%v", deptIndex.Field),
			IndexConfig: deptIndex.IndexConfig,
		}))
		indexes = append(indexes, CreateIndexModel(Index{
			Field:       fmt.Sprintf("currentDepartmentStatus.%v", deptIndex.Field),
			IndexConfig: deptIndex.IndexConfig,
		}))
	}

	model.Indexes = indexes
	model.Collection.Indexes().CreateMany(context.Background(), indexes)

	i.InvoiceProgress = model
}
```

### MigrateView (Sync Pipeline)

Menjalankan aggregation pipeline dan `$merge` hasilnya ke collection MV.
Bisa full sync atau partial (by refIds):

```go
func (i *Context) MigrateViewInvoiceProgress(refIds []string) error {
	invoiceProgress := InvoiceProgress{}
	pipeline := invoiceProgress.GetPipeline(true)

	if len(refIds) > 0 {
		pipeline = append([]bson.M{
			{"$match": bson.M{"refId": bson.M{"$in": refIds}}},
		}, pipeline...)
	}

	cursor, err := i.Invoice.Collection.Aggregate(context.Background(), pipeline)
	if err != nil { return err }
	defer cursor.Close(context.Background())

	return nil
}
```

### GetPipeline (Aggregation Pipeline)

Pattern: `$lookup` → `$addFields` → `$project` → `$match` → `$merge`

```go
func (data *InvoiceProgress) GetPipeline(withMerge bool) []bson.M {
	pipeline := []bson.M{
		// 1. $lookup — join dengan collection lain
		{
			"$lookup": bson.M{
				"from": "department_statuses",
				"let":  bson.M{"refId": "$refId"},
				"pipeline": bson.A{
					bson.M{"$match": bson.M{"$expr": bson.M{"$and": bson.A{
						bson.M{"$eq": bson.A{"$relationId", "$refId"}},
						bson.M{"$eq": bson.A{"$relationCollection", "INVOICE"}},
					}}}},
					bson.M{"$sort": bson.M{"createdAt": -1}},
				},
				"as": "allDepartmentStatuses",
			},
		},
		// 2. $addFields — compute derived fields
		{
			"$addFields": bson.M{
				"departmentStatuses": "$allDepartmentStatuses",
				"currentDepartmentStatus": bson.M{
					"$let": bson.M{
						"vars": bson.M{
							"current": bson.M{"$filter": bson.M{
								"input": "$allDepartmentStatuses",
								"as":    "status",
								"cond":  bson.M{"$eq": bson.A{"$status.isCurrent", true}},
							}},
						},
						"in": bson.M{"$cond": bson.A{
							bson.M{"$gt": bson.A{bson.M{"$size": "$current"}, 0}},
							bson.M{"$arrayElemAt": bson.A{"$current", 0}},
							nil,
						}},
					},
				},
			},
		},
		// 3. $project — shape output
		{
			"$project": bson.M{
				"invoice":                 "$$ROOT",
				"refId":                   "$refId",
				"mainBatchId":             "$currentDepartmentStatus.mainBatchId",
				"departmentStatuses":      1,
				"currentDepartmentStatus": 1,
			},
		},
	}

	// 4. $merge — tulis ke collection MV
	if withMerge {
		pipeline = append(pipeline, bson.M{
			"$match": bson.M{"departmentStatuses.0": bson.M{"$exists": true}},
		})
		pipeline = append(pipeline, bson.M{
			"$merge": bson.M{
				"into":           INVOICE_PROGRESS_COLLECTION_NAME,
				"whenMatched":    "merge",
				"whenNotMatched": "insert",
			},
		})
	}

	return pipeline
}
```

### ToEntity untuk MV

Convert nested models ke entities:

```go
func (data *InvoiceProgress) ToInvoiceProgressEntity() *Entities.InvoiceProgress {
	newData := &Entities.InvoiceProgress{
		MongoID:     data.ID.Hex(),
		RefId:       data.RefId,
		MainBatchId: data.MainBatchId,
	}

	if data.Invoice != nil {
		newData.Invoice = *data.Invoice.ToInvoiceEntity()
	}

	departmentStatuses := []Entities.DepartmentStatus{}
	for _, ds := range data.DepartmentStatuses {
		departmentStatuses = append(departmentStatuses, *ds.ToDepartmentStatusEntity())
	}
	newData.DepartmentStatuses = departmentStatuses

	if data.CurrentDepartmentStatus != nil {
		newData.CurrentDepartmentStatus = data.CurrentDepartmentStatus.ToDepartmentStatusEntity()
		// Business logic bisa ditambah di sini (workflow, rules)
	}

	return newData
}
```

### Sync MV via EventEmitter

```go
// Event service handler:
func (i *EventService) SyncInvoiceProgress() {
	modelsContext := &Models.Context{DB: i.Mongo.GetDB()}
	modelsContext.NewInvoice()

	i.EventEmitter.On("SYNC_INVOICE_PROGRESS", func(refIds []string) {
		modelsContext.MigrateViewInvoiceProgress(refIds)
	})
}

// Usecase trigger setelah write:
i.EventEmitter.Emit("SYNC_INVOICE_PROGRESS", syncInvoiceIds)
```

### Register MV di MigrateView

```go
func (i *Context) MigrateView() {
	i.MigrateViewInvoiceProgress([]string{})
	i.MigrateViewBatchSummary([]string{})
}
```

Dipanggil saat `INTERFACE=MIGRATE_VIEW` di main.go untuk full re-sync.
