# Deployment

Panduan deployment Next.js application ke berbagai platform dan environment.

## Vercel Deployment (Recommended)

### Setup Vercel

```bash
# Install Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy
vercel
```

### Vercel Configuration

```json
// vercel.json
{
  "buildCommand": "npm run build",
  "devCommand": "npm run dev",
  "installCommand": "npm install",
  "framework": "nextjs",
  "regions": ["sin1"],
  "env": {
    "DATABASE_URL": "@database-url",
    "JWT_SECRET": "@jwt-secret"
  },
  "build": {
    "env": {
      "NEXT_PUBLIC_API_URL": "https://api.example.com"
    }
  }
}
```

### Environment Variables di Vercel

```bash
# Via CLI
vercel env add DATABASE_URL production
vercel env add JWT_SECRET production

# Via Dashboard
# 1. Go to Project Settings
# 2. Navigate to Environment Variables
# 3. Add variables for Production, Preview, Development
```

### Deployment Workflow

```bash
# Deploy to preview
vercel

# Deploy to production
vercel --prod

# Deploy specific branch
git push origin main  # Auto-deploy if connected to Git
```

## Docker Deployment

### Dockerfile

```dockerfile
# Dockerfile
FROM node:18-alpine AS base

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./
RUN npm ci

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Set environment variables
ENV NEXT_TELEMETRY_DISABLED 1
ENV NODE_ENV production

# Build application
RUN npm run build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy necessary files
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"]
```

### Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - postgres
    restart: unless-stopped

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=myuser
      - POSTGRES_PASSWORD=mypassword
      - POSTGRES_DB=mydb
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - app
    restart: unless-stopped

volumes:
  postgres_data:
```

### Next.js Config untuk Docker

```javascript
// next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  
  // Disable telemetry
  telemetry: false,
  
  // Image optimization
  images: {
    domains: ['example.com'],
    unoptimized: process.env.NODE_ENV === 'development',
  },
};

module.exports = nextConfig;
```

### Build & Run Docker

```bash
# Build image
docker build -t my-nextjs-app .

# Run container
docker run -p 3000:3000 \
  -e DATABASE_URL="postgresql://..." \
  -e JWT_SECRET="your-secret" \
  my-nextjs-app

# Using docker-compose
docker-compose up -d

# View logs
docker-compose logs -f app

# Stop
docker-compose down
```

## Nginx Configuration

### Nginx Reverse Proxy

```nginx
# nginx.conf
events {
    worker_connections 1024;
}

http {
    upstream nextjs {
        server app:3000;
    }

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=mylimit:10m rate=10r/s;

    server {
        listen 80;
        server_name example.com www.example.com;

        # Redirect to HTTPS
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name example.com www.example.com;

        # SSL Configuration
        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;

        # Security Headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        # Gzip compression
        gzip on;
        gzip_vary on;
        gzip_min_length 1024;
        gzip_types text/plain text/css text/xml text/javascript application/javascript application/json;

        # Rate limiting
        limit_req zone=mylimit burst=20 nodelay;

        # Static files
        location /_next/static {
            proxy_pass http://nextjs;
            proxy_cache_valid 200 60m;
            add_header Cache-Control "public, max-age=3600, immutable";
        }

        # Images
        location ~* \.(jpg|jpeg|png|gif|ico|svg|webp)$ {
            proxy_pass http://nextjs;
            expires 1y;
            add_header Cache-Control "public, immutable";
        }

        # API routes
        location /api {
            proxy_pass http://nextjs;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
        }

        # All other routes
        location / {
            proxy_pass http://nextjs;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
        }
    }
}
```

## CI/CD Pipeline

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches:
      - main

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run linter
        run: npm run lint
      
      - name: Run tests
        run: npm test
      
      - name: Build
        run: npm run build
        env:
          NEXT_PUBLIC_API_URL: ${{ secrets.NEXT_PUBLIC_API_URL }}

  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prod'
```

### GitLab CI/CD

```yaml
# .gitlab-ci.yml
stages:
  - test
  - build
  - deploy

variables:
  DOCKER_IMAGE: registry.gitlab.com/$CI_PROJECT_PATH
  DOCKER_TAG: $CI_COMMIT_SHORT_SHA

test:
  stage: test
  image: node:18-alpine
  script:
    - npm ci
    - npm run lint
    - npm test
  only:
    - main
    - merge_requests

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker build -t $DOCKER_IMAGE:$DOCKER_TAG .
    - docker push $DOCKER_IMAGE:$DOCKER_TAG
  only:
    - main

deploy:
  stage: deploy
  image: alpine:latest
  before_script:
    - apk add --no-cache openssh-client
    - eval $(ssh-agent -s)
    - echo "$SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add -
    - mkdir -p ~/.ssh
    - chmod 700 ~/.ssh
  script:
    - ssh $DEPLOY_USER@$DEPLOY_HOST "
        docker pull $DOCKER_IMAGE:$DOCKER_TAG &&
        docker stop my-nextjs-app || true &&
        docker rm my-nextjs-app || true &&
        docker run -d 
          --name my-nextjs-app 
          -p 3000:3000 
          -e DATABASE_URL=$DATABASE_URL 
          -e JWT_SECRET=$JWT_SECRET 
          --restart unless-stopped 
          $DOCKER_IMAGE:$DOCKER_TAG
      "
  only:
    - main
```

## Environment-Specific Configuration

### Multiple Environments

```bash
# .env.development
NEXT_PUBLIC_API_URL=http://localhost:3001
DATABASE_URL=postgresql://localhost:5432/mydb_dev

# .env.staging
NEXT_PUBLIC_API_URL=https://api-staging.example.com
DATABASE_URL=postgresql://staging-db:5432/mydb_staging

# .env.production
NEXT_PUBLIC_API_URL=https://api.example.com
DATABASE_URL=postgresql://prod-db:5432/mydb_prod
```

### Environment Loader

```javascript
// src/lib/config/env.js
const environments = {
  development: {
    apiUrl: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001',
    enableDebug: true,
  },
  staging: {
    apiUrl: process.env.NEXT_PUBLIC_API_URL,
    enableDebug: true,
  },
  production: {
    apiUrl: process.env.NEXT_PUBLIC_API_URL,
    enableDebug: false,
  },
};

export const config = environments[process.env.NODE_ENV] || environments.development;
```

## Database Migration

### Prisma Migration

```bash
# Generate migration
npx prisma migrate dev --name init

# Apply migration in production
npx prisma migrate deploy

# In CI/CD
- name: Run migrations
  run: npx prisma migrate deploy
  env:
    DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

### Migration Script

```javascript
// scripts/migrate.js
const { execSync } = require('child_process');

async function migrate() {
  try {
    console.log('Running database migrations...');
    execSync('npx prisma migrate deploy', { stdio: 'inherit' });
    console.log('Migrations completed successfully');
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

migrate();
```

## Health Checks

### Kubernetes Health Checks

```yaml
# kubernetes/deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nextjs-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nextjs-app
  template:
    metadata:
      labels:
        app: nextjs-app
    spec:
      containers:
      - name: nextjs-app
        image: my-nextjs-app:latest
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: database-url
        livenessProbe:
          httpGet:
            path: /api/health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
```

## Rollback Strategy

### Docker Rollback

```bash
# Tag current version
docker tag my-nextjs-app:latest my-nextjs-app:backup

# Deploy new version
docker pull my-nextjs-app:new-version
docker stop my-nextjs-app
docker run -d --name my-nextjs-app my-nextjs-app:new-version

# If issues, rollback
docker stop my-nextjs-app
docker rm my-nextjs-app
docker run -d --name my-nextjs-app my-nextjs-app:backup
```

### Vercel Rollback

```bash
# List deployments
vercel ls

# Rollback to specific deployment
vercel rollback [deployment-url]
```

## Performance Optimization

### Build Optimization

```javascript
// next.config.js
const nextConfig = {
  // Enable SWC minification
  swcMinify: true,
  
  // Compress output
  compress: true,
  
  // Remove console logs in production
  compiler: {
    removeConsole: process.env.NODE_ENV === 'production',
  },
  
  // Optimize images
  images: {
    formats: ['image/avif', 'image/webp'],
    minimumCacheTTL: 60,
  },
};
```

### CDN Configuration

```javascript
// next.config.js
const nextConfig = {
  assetPrefix: process.env.NODE_ENV === 'production' 
    ? 'https://cdn.example.com' 
    : undefined,
};
```

## Monitoring Post-Deployment

### Deployment Checklist

- [ ] Environment variables configured
- [ ] Database migrations applied
- [ ] SSL certificates installed
- [ ] DNS configured correctly
- [ ] Health checks passing
- [ ] Monitoring enabled
- [ ] Error tracking configured
- [ ] Backup strategy in place
- [ ] Rollback plan documented
- [ ] Performance metrics baseline
- [ ] Security headers verified
- [ ] CORS configured
- [ ] Rate limiting enabled
- [ ] Logs accessible
- [ ] Team notified

### Post-Deployment Verification

```bash
# Check health
curl https://example.com/api/health

# Check response time
curl -w "@curl-format.txt" -o /dev/null -s https://example.com

# Check SSL
openssl s_client -connect example.com:443 -servername example.com

# Check headers
curl -I https://example.com
```

## Best Practices

1. **Automate Everything**: Use CI/CD for consistent deployments
2. **Test Before Deploy**: Run tests in CI pipeline
3. **Environment Parity**: Keep dev/staging/prod similar
4. **Zero Downtime**: Use rolling deployments
5. **Monitor Actively**: Set up alerts and monitoring
6. **Backup Regularly**: Automated database backups
7. **Document Process**: Clear deployment documentation
8. **Security First**: Secure secrets and credentials
9. **Performance**: Monitor and optimize
10. **Rollback Ready**: Always have rollback plan
