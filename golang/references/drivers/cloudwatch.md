# CloudWatch Driver

Package: `Cloudwatch` — Lokasi: `src/drivers/cloudwatch/`

## Interface

```go
package Cloudwatch

type Cloudwatch struct {
	Client *cloudwatchlogs.Client
}

func InitCloudwatch() *Cloudwatch {
	// Baca CLOUDWATCH_ACCESS_KEY_ID, CLOUDWATCH_SECRET_ACCESS_KEY, 
	// CLOUDWATCH_REGION, CLOUDWATCH_LOG_GROUP
	// Return nil Client jika env == "local" atau config kosong
}
```

## Env Vars

- `CLOUDWATCH_ACCESS_KEY_ID` — AWS access key ID
- `CLOUDWATCH_SECRET_ACCESS_KEY` — AWS secret access key
- `CLOUDWATCH_REGION` — AWS region (contoh: `ap-southeast-1`)
- `CLOUDWATCH_LOG_GROUP` — CloudWatch log group name

## Usage di main.go

```go
cloudwatch := Cloudwatch.InitCloudwatch()
logger := Logger.New(cloudwatch.Client)

// Logger akan otomatis kirim log ke CloudWatch jika client tidak nil
```

## Implementation Pattern

```go
func InitCloudwatch() *Cloudwatch {
	env := os.Getenv("ENVIRONMENT")
	
	// Skip CloudWatch di local environment
	if env == "local" {
		return &Cloudwatch{Client: nil}
	}

	accessKeyId := os.Getenv("CLOUDWATCH_ACCESS_KEY_ID")
	secretAccessKey := os.Getenv("CLOUDWATCH_SECRET_ACCESS_KEY")
	region := os.Getenv("CLOUDWATCH_REGION")
	logGroup := os.Getenv("CLOUDWATCH_LOG_GROUP")

	// Return nil client jika config tidak lengkap
	if accessKeyId == "" || secretAccessKey == "" || region == "" || logGroup == "" {
		return &Cloudwatch{Client: nil}
	}

	cfg, err := config.LoadDefaultConfig(context.TODO(),
		config.WithRegion(region),
		config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(
			accessKeyId,
			secretAccessKey,
			"",
		)),
	)

	if err != nil {
		log.Printf("Failed to load AWS config: %v", err)
		return &Cloudwatch{Client: nil}
	}

	return &Cloudwatch{
		Client: cloudwatchlogs.NewFromConfig(cfg),
	}
}
```

## Logger Integration

Logger akan check apakah CloudWatch client ada:

```go
func (l *Logger) Info(message string, data interface{}) {
	// Log to stdout
	log.Printf("[INFO] %s: %v", message, data)

	// Log to CloudWatch if client exists
	if l.CloudwatchClient != nil {
		l.sendToCloudWatch("INFO", message, data)
	}
}
```

## File Structure

```
cloudwatch/
└── interface.go    # Cloudwatch struct, InitCloudwatch()
```

## Notes

- CloudWatch client bisa nil (untuk local development)
- Logger harus handle nil client gracefully
- Jangan panic jika CloudWatch gagal, fallback ke stdout logging
