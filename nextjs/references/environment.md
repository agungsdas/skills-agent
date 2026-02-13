# Environment Variables & Configuration

Panduan lengkap untuk mengelola environment variables dan configuration di Next.js.

## Environment Variables Basics

### File Structure

```
my-nextjs-app/
├── .env                    # Loaded in all environments
├── .env.local             # Local overrides (gitignored)
├── .env.development       # Development environment
├── .env.production        # Production environment
├── .env.test              # Test environment
└── .env.example           # Template (committed to git)
```

### Loading Priority

```
.env.$(NODE_ENV).local > .env.local > .env.$(NODE_ENV) > .env
```

## Environment Variable Types

### Public Variables (Browser)

```bash
# .env.local
# Exposed to browser (prefix with NEXT_PUBLIC_)
NEXT_PUBLIC_API_URL=https://api.example.com
NEXT_PUBLIC_APP_NAME=My App
NEXT_PUBLIC_ANALYTICS_ID=UA-XXXXXXXXX-X
NEXT_PUBLIC_SENTRY_DSN=https://xxx@sentry.io/xxx
```

```javascript
// Accessible in browser
console.log(process.env.NEXT_PUBLIC_API_URL);
```

### Private Variables (Server-only)

```bash
# .env.local
# Server-only (NO NEXT_PUBLIC_ prefix)
DATABASE_URL=postgresql://user:pass@localhost:5432/mydb
JWT_SECRET=your-super-secret-key
API_SECRET_KEY=your-api-secret
STRIPE_SECRET_KEY=sk_test_xxx
SENDGRID_API_KEY=SG.xxx
```

```javascript
// Only accessible on server
// src/app/api/users/route.js
export async function GET() {
  const dbUrl = process.env.DATABASE_URL; // ✅ Works
  const jwtSecret = process.env.JWT_SECRET; // ✅ Works
  
  // These are undefined in browser
  return Response.json({ data: 'secret' });
}
```

## Environment Files

### Development Environment

```bash
# .env.development
NODE_ENV=development

# API URLs
NEXT_PUBLIC_API_URL=http://localhost:3001
NEXT_PUBLIC_WS_URL=ws://localhost:3001

# Database
DATABASE_URL=postgresql://localhost:5432/mydb_dev

# External Services
STRIPE_SECRET_KEY=sk_test_xxx
SENDGRID_API_KEY=SG.xxx

# Feature Flags
NEXT_PUBLIC_ENABLE_ANALYTICS=false
NEXT_PUBLIC_ENABLE_NEW_FEATURE=true

# Debug
DEBUG=true
LOG_LEVEL=debug
```

### Production Environment

```bash
# .env.production
NODE_ENV=production

# API URLs
NEXT_PUBLIC_API_URL=https://api.example.com
NEXT_PUBLIC_WS_URL=wss://api.example.com

# Database
DATABASE_URL=postgresql://prod-db:5432/mydb_prod

# External Services
STRIPE_SECRET_KEY=sk_live_xxx
SENDGRID_API_KEY=SG.xxx

# Feature Flags
NEXT_PUBLIC_ENABLE_ANALYTICS=true
NEXT_PUBLIC_ENABLE_NEW_FEATURE=false

# Debug
DEBUG=false
LOG_LEVEL=error
```

### Example Template

```bash
# .env.example
# Copy this to .env.local and fill in your values

# Application
NEXT_PUBLIC_APP_NAME=My App
NEXT_PUBLIC_API_URL=

# Database
DATABASE_URL=

# Authentication
JWT_SECRET=
JWT_EXPIRES_IN=7d

# External Services
STRIPE_SECRET_KEY=
SENDGRID_API_KEY=
SENTRY_DSN=

# Feature Flags
NEXT_PUBLIC_ENABLE_ANALYTICS=false
```

## Configuration Management

### Centralized Config

```javascript
// src/lib/config/index.js
const config = {
  app: {
    name: process.env.NEXT_PUBLIC_APP_NAME || 'My App',
    url: process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000',
    env: process.env.NODE_ENV || 'development',
  },
  
  api: {
    url: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001',
    timeout: parseInt(process.env.API_TIMEOUT || '30000'),
  },
  
  database: {
    url: process.env.DATABASE_URL,
    poolSize: parseInt(process.env.DB_POOL_SIZE || '10'),
  },
  
  auth: {
    jwtSecret: process.env.JWT_SECRET,
    jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
    bcryptRounds: parseInt(process.env.BCRYPT_ROUNDS || '12'),
  },
  
  services: {
    stripe: {
      secretKey: process.env.STRIPE_SECRET_KEY,
      publicKey: process.env.NEXT_PUBLIC_STRIPE_PUBLIC_KEY,
    },
    sendgrid: {
      apiKey: process.env.SENDGRID_API_KEY,
      fromEmail: process.env.SENDGRID_FROM_EMAIL,
    },
    sentry: {
      dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
      environment: process.env.NODE_ENV,
    },
  },
  
  features: {
    analytics: process.env.NEXT_PUBLIC_ENABLE_ANALYTICS === 'true',
    newFeature: process.env.NEXT_PUBLIC_ENABLE_NEW_FEATURE === 'true',
    maintenance: process.env.MAINTENANCE_MODE === 'true',
  },
  
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    pretty: process.env.NODE_ENV === 'development',
  },
};

export default config;
```

### Type-safe Config (with JSDoc)

```javascript
// src/lib/config/typed-config.js

/**
 * @typedef {Object} AppConfig
 * @property {string} name
 * @property {string} url
 * @property {'development' | 'production' | 'test'} env
 */

/**
 * @typedef {Object} Config
 * @property {AppConfig} app
 * @property {Object} api
 * @property {string} api.url
 * @property {number} api.timeout
 */

/**
 * @type {Config}
 */
const config = {
  app: {
    name: process.env.NEXT_PUBLIC_APP_NAME || 'My App',
    url: process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000',
    env: process.env.NODE_ENV || 'development',
  },
  api: {
    url: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001',
    timeout: parseInt(process.env.API_TIMEOUT || '30000'),
  },
};

export default config;
```

## Environment Validation

### Validation Function

```javascript
// src/lib/config/validate.js
class ConfigError extends Error {
  constructor(message) {
    super(message);
    this.name = 'ConfigError';
  }
}

export function validateEnv() {
  const required = {
    // Server-side required
    DATABASE_URL: process.env.DATABASE_URL,
    JWT_SECRET: process.env.JWT_SECRET,
    
    // Client-side required
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL,
  };
  
  const missing = Object.entries(required)
    .filter(([key, value]) => !value)
    .map(([key]) => key);
  
  if (missing.length > 0) {
    throw new ConfigError(
      `Missing required environment variables: ${missing.join(', ')}\n` +
      `Please check your .env.local file.`
    );
  }
  
  // Validate formats
  if (required.DATABASE_URL && !required.DATABASE_URL.startsWith('postgresql://')) {
    throw new ConfigError('DATABASE_URL must be a valid PostgreSQL connection string');
  }
  
  if (required.JWT_SECRET && required.JWT_SECRET.length < 32) {
    throw new ConfigError('JWT_SECRET must be at least 32 characters long');
  }
  
  console.log('✅ Environment variables validated successfully');
}

// Run validation on startup
if (process.env.NODE_ENV === 'production') {
  validateEnv();
}
```

### Zod Validation

```bash
npm install zod
```

```javascript
// src/lib/config/schema.js
import { z } from 'zod';

const envSchema = z.object({
  // App
  NODE_ENV: z.enum(['development', 'production', 'test']),
  NEXT_PUBLIC_APP_NAME: z.string().min(1),
  NEXT_PUBLIC_API_URL: z.string().url(),
  
  // Database
  DATABASE_URL: z.string().url(),
  
  // Auth
  JWT_SECRET: z.string().min(32),
  JWT_EXPIRES_IN: z.string().default('7d'),
  
  // External Services
  STRIPE_SECRET_KEY: z.string().optional(),
  SENDGRID_API_KEY: z.string().optional(),
  
  // Feature Flags
  NEXT_PUBLIC_ENABLE_ANALYTICS: z.string().transform(val => val === 'true'),
});

export function validateEnv() {
  try {
    const parsed = envSchema.parse(process.env);
    return parsed;
  } catch (error) {
    console.error('❌ Invalid environment variables:');
    console.error(error.flatten().fieldErrors);
    throw new Error('Invalid environment variables');
  }
}

export const env = validateEnv();
```

## Feature Flags

### Feature Flag System

```javascript
// src/lib/config/features.js
export const features = {
  analytics: {
    enabled: process.env.NEXT_PUBLIC_ENABLE_ANALYTICS === 'true',
    provider: process.env.NEXT_PUBLIC_ANALYTICS_PROVIDER || 'google',
  },
  
  newDashboard: {
    enabled: process.env.NEXT_PUBLIC_ENABLE_NEW_DASHBOARD === 'true',
    rolloutPercentage: parseInt(process.env.NEW_DASHBOARD_ROLLOUT || '0'),
  },
  
  maintenance: {
    enabled: process.env.MAINTENANCE_MODE === 'true',
    message: process.env.MAINTENANCE_MESSAGE || 'We are currently under maintenance',
  },
  
  experimental: {
    newFeature: process.env.NEXT_PUBLIC_EXPERIMENTAL_FEATURE === 'true',
  },
};

export function isFeatureEnabled(featureName) {
  const feature = features[featureName];
  
  if (!feature) return false;
  if (typeof feature.enabled === 'boolean') return feature.enabled;
  
  return false;
}

// Usage
import { isFeatureEnabled } from '@/lib/config/features';

if (isFeatureEnabled('analytics')) {
  // Initialize analytics
}
```

### Feature Flag Hook

```javascript
// src/lib/hooks/useFeature.js
'use client';

import { features } from '@/lib/config/features';

export function useFeature(featureName) {
  const feature = features[featureName];
  
  if (!feature) {
    console.warn(`Feature "${featureName}" not found`);
    return false;
  }
  
  return feature.enabled || false;
}

// Usage
import { useFeature } from '@/lib/hooks/useFeature';

function MyComponent() {
  const analyticsEnabled = useFeature('analytics');
  
  if (analyticsEnabled) {
    // Track event
  }
  
  return <div>Component</div>;
}
```

## Multi-Environment Setup

### Environment Switcher

```javascript
// src/lib/config/environment.js
const environments = {
  development: {
    name: 'Development',
    apiUrl: 'http://localhost:3001',
    debug: true,
    logLevel: 'debug',
  },
  
  staging: {
    name: 'Staging',
    apiUrl: 'https://api-staging.example.com',
    debug: true,
    logLevel: 'info',
  },
  
  production: {
    name: 'Production',
    apiUrl: 'https://api.example.com',
    debug: false,
    logLevel: 'error',
  },
};

export function getEnvironment() {
  const env = process.env.NODE_ENV || 'development';
  return environments[env] || environments.development;
}

export const currentEnv = getEnvironment();
```

## Secrets Management

### Using Environment Variables

```bash
# .env.local (NEVER commit this file)
DATABASE_URL=postgresql://user:password@localhost:5432/mydb
JWT_SECRET=your-super-secret-jwt-key-min-32-chars
API_SECRET_KEY=your-api-secret-key
STRIPE_SECRET_KEY=sk_test_xxx
```

### Generating Secrets

```bash
# Generate random secret
openssl rand -base64 32

# Generate UUID
uuidgen

# Generate hex string
openssl rand -hex 32
```

### Secret Rotation

```javascript
// src/lib/utils/secrets.js
export function rotateSecret(oldSecret, newSecret) {
  // Support both old and new secrets during rotation period
  return {
    current: newSecret,
    previous: oldSecret,
  };
}

// Usage in JWT verification
import { rotateSecret } from '@/lib/utils/secrets';

const secrets = rotateSecret(
  process.env.JWT_SECRET_OLD,
  process.env.JWT_SECRET
);

// Try current secret first, fallback to previous
try {
  return verifyToken(token, secrets.current);
} catch (error) {
  if (secrets.previous) {
    return verifyToken(token, secrets.previous);
  }
  throw error;
}
```

## Runtime Configuration

### Public Runtime Config

```javascript
// next.config.js
const nextConfig = {
  publicRuntimeConfig: {
    // Available on both server and client
    apiUrl: process.env.NEXT_PUBLIC_API_URL,
    appName: process.env.NEXT_PUBLIC_APP_NAME,
  },
  serverRuntimeConfig: {
    // Only available on server
    databaseUrl: process.env.DATABASE_URL,
    jwtSecret: process.env.JWT_SECRET,
  },
};

module.exports = nextConfig;
```

```javascript
// Usage
import getConfig from 'next/config';

const { publicRuntimeConfig, serverRuntimeConfig } = getConfig();

console.log(publicRuntimeConfig.apiUrl); // Works everywhere
console.log(serverRuntimeConfig.databaseUrl); // Only works on server
```

## Configuration Best Practices

### 1. Never Commit Secrets

```bash
# .gitignore
.env.local
.env.*.local
.env.production
```

### 2. Use .env.example

```bash
# .env.example
# Copy to .env.local and fill in values

DATABASE_URL=
JWT_SECRET=
STRIPE_SECRET_KEY=
```

### 3. Validate on Startup

```javascript
// src/app/layout.js
import { validateEnv } from '@/lib/config/validate';

// Validate in production
if (process.env.NODE_ENV === 'production') {
  validateEnv();
}

export default function RootLayout({ children }) {
  return <html>{children}</html>;
}
```

### 4. Use Descriptive Names

```bash
# GOOD
DATABASE_URL=
JWT_SECRET=
STRIPE_SECRET_KEY=

# BAD
DB=
SECRET=
KEY=
```

### 5. Document Variables

```javascript
// src/lib/config/index.js
/**
 * Application configuration
 * 
 * Environment Variables:
 * - DATABASE_URL: PostgreSQL connection string
 * - JWT_SECRET: Secret key for JWT signing (min 32 chars)
 * - NEXT_PUBLIC_API_URL: Public API endpoint
 */
const config = {
  // ...
};
```

## Platform-Specific Configuration

### Vercel

```bash
# Set via CLI
vercel env add DATABASE_URL production
vercel env add JWT_SECRET production

# Or via dashboard
# Project Settings > Environment Variables
```

### Docker

```yaml
# docker-compose.yml
services:
  app:
    build: .
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}
      - JWT_SECRET=${JWT_SECRET}
    env_file:
      - .env.production
```

### Kubernetes

```yaml
# kubernetes/secret.yml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
stringData:
  database-url: postgresql://...
  jwt-secret: your-secret-key
```

```yaml
# kubernetes/deployment.yml
spec:
  containers:
  - name: app
    env:
    - name: DATABASE_URL
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: database-url
```

## Configuration Checklist

- [ ] Create .env.example template
- [ ] Add .env.local to .gitignore
- [ ] Separate public and private variables
- [ ] Validate required variables
- [ ] Use descriptive variable names
- [ ] Document all variables
- [ ] Implement feature flags
- [ ] Setup multi-environment configs
- [ ] Secure secrets properly
- [ ] Test in all environments
- [ ] Setup secret rotation plan
- [ ] Monitor configuration changes

## Common Patterns

### API URL Configuration

```javascript
// src/lib/config/api.js
export const API_CONFIG = {
  baseURL: process.env.NEXT_PUBLIC_API_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
};

// Different URLs per service
export const SERVICE_URLS = {
  auth: process.env.NEXT_PUBLIC_AUTH_SERVICE_URL,
  users: process.env.NEXT_PUBLIC_USER_SERVICE_URL,
  products: process.env.NEXT_PUBLIC_PRODUCT_SERVICE_URL,
};
```

### Database Configuration

```javascript
// src/lib/config/database.js
export const DB_CONFIG = {
  url: process.env.DATABASE_URL,
  pool: {
    min: parseInt(process.env.DB_POOL_MIN || '2'),
    max: parseInt(process.env.DB_POOL_MAX || '10'),
  },
  ssl: process.env.NODE_ENV === 'production',
};
```

### Logging Configuration

```javascript
// src/lib/config/logging.js
export const LOG_CONFIG = {
  level: process.env.LOG_LEVEL || 'info',
  pretty: process.env.NODE_ENV === 'development',
  destination: process.env.LOG_DESTINATION || 'stdout',
};
```
