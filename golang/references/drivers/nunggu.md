# Nunggu Driver (Job Queue Service)

Package: `Nunggu` — Lokasi: `src/drivers/nunggu/`

## Interface

```go
package Nunggu

type Nunggu struct {
	Client       *resty.Client
	NungguSecret string
}

type CreateJob struct {
	Key        string
	StartTime  time.Time
	Data       interface{}
	MaxAttempt int
}

type INunggu interface {
	SyncPatientMongo(params *CreateJob) (interface{}, error)
	SyncUserMongo(params *CreateJob) (interface{}, error)
	OnPatientExternalUpdated(params *CreateJob) (interface{}, error)
	OnPatientUpdated(params *CreateJob) (interface{}, error)
}

func New() INunggu {
	return &Nunggu{
		Client:       resty.New().SetBaseURL(Helpers.GetEnv("NUNGGU_BASE_URL_API", "")),
		NungguSecret: Helpers.GetEnv("NUNGGU_TOKEN", ""),
	}
}
```

## sendRequest Helper

```go
func (i *Nunggu) sendRequest(topicId string, params *CreateJob) (interface{}, error) {
	body := map[string]interface{}{
		"data": params.Data,
	}

	if !params.StartTime.IsZero() {
		body["start_time"] = params.StartTime.Format(Enums.DATE_FULL_FORMAT)
	}

	if params.Key != "" {
		body["key"] = params.Key
	}

	if params.MaxAttempt > 0 {
		body["max_attempt"] = params.MaxAttempt
	}

	var results interface{}
	req := i.Client.R()
	req.SetResult(&results)
	req.SetError(&results)
	req.SetBasicAuth(topicId, i.NungguSecret)
	req.SetHeader("Accept", "application/json")
	req.SetHeader("Content-Type", "application/json")
	req.SetBody(body)

	if _, err := req.Post("/v1/job"); err != nil {
		return nil, err
	}

	return results, nil
}
```

## Env Vars

- `NUNGGU_BASE_URL_API` — Nunggu service base URL
- `NUNGGU_TOKEN` — Authentication token

## Usage Pattern

Setiap method (SyncPatientMongo, SyncUserMongo, dll) panggil `sendRequest()` dengan topicId yang berbeda:

```go
func (i *Nunggu) SyncPatientMongo(params *CreateJob) (interface{}, error) {
	return i.sendRequest("sync-patient-mongo", params)
}

func (i *Nunggu) SyncUserMongo(params *CreateJob) (interface{}, error) {
	return i.sendRequest("sync-user-mongo", params)
}
```

## Usage di Usecase

```go
// Schedule immediate job
nunggu.SyncPatientMongo(&Nunggu.CreateJob{
	Key:        patientRefId,
	Data:       map[string]interface{}{"ref_id": patientRefId},
	MaxAttempt: 3,
})

// Schedule delayed job
nunggu.SyncPatientMongo(&Nunggu.CreateJob{
	Key:        patientRefId,
	StartTime:  time.Now().Add(5 * time.Minute),
	Data:       map[string]interface{}{"ref_id": patientRefId},
	MaxAttempt: 3,
})
```

## File Structure

```
nunggu/
├── interface.go              # Struct, interface, New(), sendRequest()
├── sync-patient-mongo.go     # SyncPatientMongo() method
├── sync-user-mongo.go        # SyncUserMongo() method
├── on-patient-updated.go     # OnPatientUpdated() method
└── on-patient-external-updated.go  # OnPatientExternalUpdated() method
```
