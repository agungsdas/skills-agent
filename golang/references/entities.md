# Entities

Package: `Entities` — Lokasi: `src/entities/<nama>.go` — Module: `agungsdas/<service>`

## Rules

1. Pure Go struct, TIDAK boleh import package database (mongo, bson)
2. Semua field pakai `json` tag dengan snake_case
3. `MongoID string json:"-"` — selalu hidden dari response
4. Pointer `*time.Time` untuk waktu nullable, `*bool` untuk boolean nullable
5. Timestamp pattern: `CreatedAt *time.Time`, `UpdatedAt *time.Time`, `DeletedAt *time.Time`
6. Satu file per entity
7. Method `ToSerializer()` boleh ada untuk convert ke response shape (import dari `helpers/serializers`)

## Template

```go
package Entities

import "time"

type <Name> struct {
	MongoID   string     `json:"-"`
	RefId     string     `json:"ref_id"`
	// ... domain fields dengan json:"snake_case" ...
	CreatedAt *time.Time `json:"created_at"`
	UpdatedAt *time.Time `json:"updated_at"`
	DeletedAt *time.Time `json:"deleted_at"`
}
```

## Entity dengan Relasi

```go
type InvoiceProgress struct {
	MongoID                 string             `json:"-"`
	RefId                   string             `json:"ref_id"`
	Invoice                 Invoice            `json:"invoice"`
	DepartmentStatuses      []DepartmentStatus `json:"department_statuses"`
	CurrentDepartmentStatus *DepartmentStatus  `json:"current_department_status"`
	Workflow                Workflow           `json:"workflow"`
}
```

## Entity dengan ToSerializer

```go
func (user *User) ToUserSerializer(isComplete bool) *Serializers.User {
	newUser := &Serializers.User{
		ID:   user.PersonalId,
		Name: user.Name,
	}
	if isComplete && user.CreatedUser != nil {
		newUser.CreatedBy = user.CreatedUser.ToUserLiteSerializer()
	}
	return newUser
}
```

## Entity dengan Embedded Struct (mapstructure)

Untuk data yang datang dari external service / JWT claims, pakai `mapstructure` tag:

```go
type EmployeeLite struct {
	PersonalId string `mapstructure:"personalId"`
	Name       string `mapstructure:"name"`
	Email      string `mapstructure:"email"`
	Roles      []Role `mapstructure:"roles"`
}
```
