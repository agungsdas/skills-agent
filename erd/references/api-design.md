# API Design & Contracts

## Template

```markdown
## API Design & Contracts

### API Overview

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| /api/[resource] | GET | Required | List resources |
| /api/[resource] | POST | Required | Create resource |
| /api/[resource]/[id] | GET | Required | Get resource by ID |
| /api/[resource]/[id] | PUT | Required | Update resource |
| /api/[resource]/[id] | DELETE | Required | Delete resource |

### Endpoint Details

#### `POST /api/[resource]`

**Description:** [Apa yang dilakukan endpoint ini]
**Auth:** Required — [Role yang diizinkan]
**Rate Limit:** [X requests/minute]

**Request:**

```json
{
  "field1": "string (required) — [description]",
  "field2": 123,
  "field3": "enum: value1 | value2 | value3",
  "field4": ["string"] 
}
```

**Request Validation:**

| Field | Type | Required | Validation | Default |
|-------|------|----------|------------|---------|
| field1 | string | Yes | min: 1, max: 255 | — |
| field2 | number | No | min: 0 | 0 |
| field3 | string | Yes | enum: [values] | — |
| field4 | string[] | No | max items: 10 | [] |

**Response (200 OK):**

```json
{
  "success": true,
  "message": "Resource created successfully",
  "data": {
    "refId": "uuid-v7",
    "field1": "value",
    "field2": 123,
    "createdAt": "2026-01-01T00:00:00.000Z"
  }
}
```

**Error Responses:**

| Status | Code | Message | When |
|--------|------|---------|------|
| 400 | VALIDATION_ERROR | "Field1 is required" | Missing required field |
| 401 | UNAUTHORIZED | "Authentication required" | No/invalid token |
| 403 | FORBIDDEN | "Insufficient permissions" | User lacks required role |
| 404 | NOT_FOUND | "Resource not found" | Invalid ID |
| 409 | CONFLICT | "Resource already exists" | Duplicate unique field |
| 422 | UNPROCESSABLE | "Invalid field value" | Business rule violation |
| 500 | INTERNAL_ERROR | "Internal server error" | Unexpected error |

**Error Response Format:**

```json
{
  "success": false,
  "message": "Human-readable error message",
  "error": {
    "code": "ERROR_CODE",
    "details": [
      { "field": "field1", "message": "Field1 is required" }
    ]
  }
}
```
```

## Pagination Pattern

```json
// Request
GET /api/[resource]?page=1&limit=20&sort=createdAt&order=desc

// Response
{
  "success": true,
  "data": [...],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "totalPages": 8
  }
}
```

## Filter & Search Pattern

```
GET /api/[resource]?search=keyword&status=active&createdFrom=2026-01-01&createdTo=2026-12-31
```

## API Versioning

- URL-based: `/api/v1/resource`, `/api/v2/resource`
- Atau header-based: `Accept: application/vnd.app.v1+json`
- Breaking changes = new version, backward compatible = same version

## Rules

1. Setiap endpoint HARUS punya: method, path, auth, request schema, response schema, error codes
2. Request validation rules harus explicit — type, required, min/max, enum values
3. Error responses harus consistent format di seluruh API
4. Pagination WAJIB untuk list endpoints — jangan return semua data
5. HTTP status codes harus semantically correct (jangan 200 untuk error)
6. Auth requirement per endpoint — jangan assume "semua butuh auth"
7. Rate limiting harus didefinisikan untuk endpoints yang rawan abuse
8. Response format konsisten: `{ success, message, data, meta, error }`
9. Gunakan refId (UUID v7) sebagai public identifier, bukan MongoDB ObjectId
10. Timestamps selalu ISO 8601 format (UTC)
