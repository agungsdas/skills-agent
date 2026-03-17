# SAP Driver (External Service)

Package: `SAPService` — Lokasi: `src/drivers/sap/`

## Interface

```go
package SAPService

type ISAPService interface {
	SearchPatient(params *ParamSearchPatientSAP) ([]Entities.Patient, error)
	FindPatient(params *ParamFindPatient) (*Entities.Patient, error)
	CreateUpdatePatient(params *ParamPatient) (*SAPPatientData, error)
}

type SAPService struct {
	Logger                       Logger.ILogger
	DemographyIdentityRepository DemographyIdentityRepository.IDemographyIdentity
	CountryRepository            CountryRepository.ICountry
	Client                       *resty.Client
}

func New(
	demographyIdentityRepository DemographyIdentityRepository.IDemographyIdentity,
	countryRepository CountryRepository.ICountry,
	logger Logger.ILogger,
	requestor Requestor.IRequestor,
) ISAPService {
	return &SAPService{
		Logger:                       logger,
		DemographyIdentityRepository: demographyIdentityRepository,
		CountryRepository:            countryRepository,
		Client:                       requestor.Request(nil).SetBaseURL(Helpers.GetEnv("SAP_HOST", "")),
	}
}
```

## Env Vars

- `SAP_HOST` — SAP service base URL

## Pattern: External Service Driver

Driver untuk external service biasanya:

1. **Inject dependencies** — logger, requestor, repositories yang dibutuhkan
2. **Pakai requestor.Request()** — HTTP client dengan logging built-in
3. **Method-method untuk operasi** — ke external API

## Usage di main.go

```go
// Init repositories first
demographyIdentityRepo := DemographyIdentityRepository.New(mongo)
countryRepo := CountryRepository.New(mongo)

// Init SAP driver
sapService := SAPService.New(
	demographyIdentityRepo,
	countryRepo,
	logger,
	requestor,
)

// Add to AppContext
appContext := Applications.AppContext{
	// ...
	SAPService: sapService,
}
```

## Usage di Usecase

```go
// Search patients
patients, err := i.SAPService.SearchPatient(&SAPService.ParamSearchPatientSAP{
	Name: "John Doe",
	NIK:  "1234567890",
})

// Find single patient
patient, err := i.SAPService.FindPatient(&SAPService.ParamFindPatient{
	PatientID: "P123456",
})

// Create or update patient
result, err := i.SAPService.CreateUpdatePatient(&SAPService.ParamPatient{
	Name:      "John Doe",
	BirthDate: "1990-01-01",
	Gender:    "M",
})
```

## File Structure

```
sap/
├── interface.go           # Struct, interface, New()
├── search-patient.go      # SearchPatient() method
├── find-patient.go        # FindPatient() method
└── create-update-patient.go  # CreateUpdatePatient() method
```
