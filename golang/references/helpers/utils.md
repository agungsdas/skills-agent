# Utility Functions

Lokasi: `helpers/utils/`

## strings/

- `GenerateRefId() string` — UUID v7 via `github.com/google/uuid`
- `GenerateRandomStringFromString(input string) string` — MD5 hash
- `IsValidConstantCase(s string) bool`
- `CapitalCase(s string) string`
- `Masking(s string) string`
- `InterfaceToString(v interface{}) string`
- `StructToString(v interface{}) string`

## type/ (Pointer Helpers)

- `ToBoolPntr(b bool) *bool`
- `ToTimePntr(t time.Time) *time.Time`
- `ToStringPntr(s string) *string`

## datetime/

- `ParseDateTimeDirect(str string, layout string) (*time.Time, error)`
- `GetDayName(t time.Time) string`

## encryption/

- `EncryptAES256(plaintext string, key []byte) (string, error)`
- `DecryptAES256(ciphertext string, key []byte) (string, error)`
- `EncryptRSA(plaintext string, publicKey *rsa.PublicKey) ([]byte, error)`
- `DecryptRSA(ciphertext []byte, privateKey *rsa.PrivateKey) (string, error)`

## json/

- `InterfaceToJSON(v interface{}) json.RawMessage`
- `JSONRawToString(raw json.RawMessage) string` — handle numeric/string/null

## mongo/

- BSON helpers dan aggregation lookup builder

## structs/

- `DiffModels(old, new interface{}) map[string]map[string]interface{}` — Struct diffing untuk change log. Excludes: ID, CreatedAt, UpdatedAt, DeletedAt. Handles `*time.Time` comparison.
