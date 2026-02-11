# Repositories

Package: `<Domain>Repository` — Lokasi: `src/repositories/<domain>/`

## Rules

1. Struct menyimpan `Mongo Mongo.IMongo`
2. Interface `I<Domain>` mendefinisikan semua method
3. Constructor: `New(mongo Mongo.IMongo) I<Domain>`
4. Satu file per operasi
5. Params struct didefinisikan di file operasi masing-masing
6. Return entity (bukan model) — selalu convert pakai `model.To<Name>Entity()`
7. List/Find return `([]Entities.<Name>, *Applications.Meta, error)` untuk pagination

## File Structure

```
src/repositories/<domain>/
├── interface.go       # Struct + Interface + New()
├── find.go            # ParamsFind + Find()
├── find-by-id.go      # FindById()
├── count.go           # ParamsCount + Count()
├── bulk-upsert.go     # ParamsBulkUpsert + BulkUpsert()
└── bulk-update.go     # ParamsBulkUpdate + BulkUpdate()
```

## Template interface.go

```go
package <Domain>Repository

import (
	Mongo "agungsdas/<service>/src/drivers/mongo"
	Entities "agungsdas/<service>/src/entities"
	Applications "agungsdas/<service>/src/definitions/applications"
)

type <Domain> struct {
	Mongo Mongo.IMongo
}

type I<Domain> interface {
	Find(params ParamsFind) ([]Entities.<Domain>, *Applications.Meta, error)
	FindById(refId string) (*Entities.<Domain>, error)
	Count(params ParamsCount) (int, error)
}

func New(mongo Mongo.IMongo) I<Domain> {
	return &<Domain>{Mongo: mongo}
}
```

## Template Find (dengan Pagination)

```go
type ParamsFind struct {
	Keyword  string
	Status   string
	Statuses []string
	Page     int
	PerPage  int
}

func (i *<Domain>) Find(params ParamsFind) ([]Entities.<Domain>, *Applications.Meta, error) {
	collection := i.Mongo.GetModels().Get<Domain>().Collection

	filters := bson.M{}
	andFilters := []bson.M{}

	// Keyword search (regex, case-insensitive)
	if params.Keyword != "" {
		andFilters = append(andFilters, bson.M{
			"$or": []bson.M{
				{"fieldA": bson.M{"$regex": params.Keyword, "$options": "i"}},
				{"fieldB": bson.M{"$regex": params.Keyword, "$options": "i"}},
			},
		})
	}

	// Exact match / $in filter
	if len(params.Statuses) > 0 {
		andFilters = append(andFilters, bson.M{"status": bson.M{"$in": params.Statuses}})
	}

	// Combine $and
	if len(andFilters) == 1 {
		filters = andFilters[0]
	} else if len(andFilters) > 1 {
		filters["$and"] = andFilters
	}

	// Pagination
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

## Template FindById

```go
func (i *<Domain>) FindById(refId string) (*Entities.<Domain>, error) {
	collection := i.Mongo.GetModels().Get<Domain>().Collection

	model := new(Models.<Domain>)
	err := collection.FindOne(context.Background(), bson.M{"refId": refId}).Decode(model)
	if err != nil { return nil, err }

	return model.To<Domain>Entity(), nil
}
```

## Template Count

```go
type ParamsCount struct {
	Keyword  string
	Statuses []string
}

func (i *<Domain>) Count(params ParamsCount) (int, error) {
	collection := i.Mongo.GetModels().Get<Domain>().Collection

	filters := bson.M{}
	// ... same filter logic as Find ...

	total, err := collection.CountDocuments(context.Background(), filters)
	if err != nil { return 0, err }

	return int(total), nil
}
```

## Template BulkUpsert

```go
func (i *<Domain>) BulkUpsert(ctx context.Context, params []ParamsBulkUpsert) ([]Entities.<Domain>, []Entities.<Domain>, error) {
	collection := i.Mongo.GetModels().Get<Domain>().Collection

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

	res, err := collection.BulkWrite(ctx, operations, options.BulkWrite())
	// ... handle UpsertedIDs for new records, query existing records ...
}
```

Pattern: `$set` untuk update fields, `$setOnInsert` untuk createdAt hanya saat insert baru.
