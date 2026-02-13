# Monitoring & Error Tracking

Panduan implementasi monitoring, logging, dan error tracking untuk Next.js applications.

## Error Tracking dengan Sentry

### Setup Sentry

```bash
npm install @sentry/nextjs
```

```javascript
// sentry.client.config.js
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  
  // Performance Monitoring
  tracesSampleRate: 1.0,
  
  // Session Replay
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,
  
  environment: process.env.NODE_ENV,
  
  // Filter out sensitive data
  beforeSend(event, hint) {
    // Don't send errors in development
    if (process.env.NODE_ENV === 'development') {
      return null;
    }
    
    // Remove sensitive data
    if (event.request) {
      delete event.request.cookies;
      delete event.request.headers;
    }
    
    return event;
  },
  
  integrations: [
    new Sentry.BrowserTracing(),
    new Sentry.Replay({
      maskAllText: true,
      blockAllMedia: true,
    }),
  ],
});
```

```javascript
// sentry.server.config.js
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  tracesSampleRate: 1.0,
  environment: process.env.NODE_ENV,
  
  beforeSend(event) {
    if (process.env.NODE_ENV === 'development') {
      return null;
    }
    return event;
  },
});
```

```javascript
// sentry.edge.config.js
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  tracesSampleRate: 1.0,
  environment: process.env.NODE_ENV,
});
```

### Error Boundary dengan Sentry

```javascript
// src/app/error.js
'use client';

import { useEffect } from 'react';
import * as Sentry from '@sentry/nextjs';
import { Button, Result } from 'antd';

export default function Error({ error, reset }) {
  useEffect(() => {
    // Log error to Sentry
    Sentry.captureException(error);
  }, [error]);
  
  return (
    <Result
      status="error"
      title="Something went wrong"
      subTitle="We've been notified and are working on a fix."
      extra={
        <Button type="primary" onClick={reset}>
          Try Again
        </Button>
      }
    />
  );
}
```

### Manual Error Reporting

```javascript
// src/lib/utils/error-reporter.js
import * as Sentry from '@sentry/nextjs';

export function reportError(error, context = {}) {
  console.error('Error:', error);
  
  if (process.env.NODE_ENV === 'production') {
    Sentry.captureException(error, {
      extra: context,
    });
  }
}

export function reportMessage(message, level = 'info', context = {}) {
  console.log(`[${level}]`, message);
  
  if (process.env.NODE_ENV === 'production') {
    Sentry.captureMessage(message, {
      level,
      extra: context,
    });
  }
}

// Usage
import { reportError } from '@/lib/utils/error-reporter';

try {
  await riskyOperation();
} catch (error) {
  reportError(error, {
    operation: 'riskyOperation',
    userId: user.id,
  });
}
```

## Logging

### Winston Logger

```bash
npm install winston
```

```javascript
// src/lib/utils/logger.js
import winston from 'winston';

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: {
    service: 'nextjs-app',
    environment: process.env.NODE_ENV,
  },
  transports: [
    // Write all logs to console
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      ),
    }),
    
    // Write errors to file
    new winston.transports.File({
      filename: 'logs/error.log',
      level: 'error',
    }),
    
    // Write all logs to file
    new winston.transports.File({
      filename: 'logs/combined.log',
    }),
  ],
});

// Create log directory if not exists
if (typeof window === 'undefined') {
  const fs = require('fs');
  const path = require('path');
  const logDir = path.join(process.cwd(), 'logs');
  
  if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir);
  }
}

export default logger;

// Helper functions
export const log = {
  info: (message, meta = {}) => logger.info(message, meta),
  error: (message, meta = {}) => logger.error(message, meta),
  warn: (message, meta = {}) => logger.warn(message, meta),
  debug: (message, meta = {}) => logger.debug(message, meta),
};
```

### Usage in API Routes

```javascript
// src/app/api/users/route.js
import { log } from '@/lib/utils/logger';

export async function GET(request) {
  const startTime = Date.now();
  
  try {
    log.info('Fetching users', {
      ip: request.headers.get('x-forwarded-for'),
      userAgent: request.headers.get('user-agent'),
    });
    
    const users = await getUsers();
    
    log.info('Users fetched successfully', {
      count: users.length,
      duration: Date.now() - startTime,
    });
    
    return Response.json({ users });
  } catch (error) {
    log.error('Failed to fetch users', {
      error: error.message,
      stack: error.stack,
      duration: Date.now() - startTime,
    });
    
    return Response.json(
      { error: 'Failed to fetch users' },
      { status: 500 }
    );
  }
}
```

## Performance Monitoring

### Web Vitals Tracking

```javascript
// src/app/layout.js
import { Analytics } from '@vercel/analytics/react';
import { SpeedInsights } from '@vercel/speed-insights/next';

export default function RootLayout({ children }) {
  return (
    <html lang="id">
      <body>
        {children}
        <Analytics />
        <SpeedInsights />
      </body>
    </html>
  );
}
```

### Custom Web Vitals Reporter

```javascript
// src/lib/utils/web-vitals.js
export function reportWebVitals(metric) {
  // Log to console in development
  if (process.env.NODE_ENV === 'development') {
    console.log(metric);
  }
  
  // Send to analytics in production
  if (process.env.NODE_ENV === 'production') {
    const body = JSON.stringify({
      name: metric.name,
      value: metric.value,
      rating: metric.rating,
      delta: metric.delta,
      id: metric.id,
    });
    
    // Send to your analytics endpoint
    fetch('/api/analytics/web-vitals', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body,
      keepalive: true,
    });
  }
}

// Usage in app
// src/app/layout.js
'use client';

import { useReportWebVitals } from 'next/web-vitals';
import { reportWebVitals } from '@/lib/utils/web-vitals';

export function WebVitalsReporter() {
  useReportWebVitals(reportWebVitals);
  return null;
}
```

### API Performance Tracking

```javascript
// src/lib/utils/performance.js
export class PerformanceTracker {
  constructor(name) {
    this.name = name;
    this.startTime = Date.now();
    this.marks = {};
  }
  
  mark(label) {
    this.marks[label] = Date.now() - this.startTime;
  }
  
  finish() {
    const duration = Date.now() - this.startTime;
    
    return {
      name: this.name,
      duration,
      marks: this.marks,
    };
  }
}

// Usage
// src/app/api/users/route.js
import { PerformanceTracker } from '@/lib/utils/performance';
import { log } from '@/lib/utils/logger';

export async function GET(request) {
  const perf = new PerformanceTracker('GET /api/users');
  
  try {
    const users = await getUsers();
    perf.mark('database_query');
    
    const processed = processUsers(users);
    perf.mark('processing');
    
    const result = perf.finish();
    log.info('Request completed', result);
    
    return Response.json({ users: processed });
  } catch (error) {
    log.error('Request failed', {
      ...perf.finish(),
      error: error.message,
    });
    
    return Response.json(
      { error: 'Failed to fetch users' },
      { status: 500 }
    );
  }
}
```

## Application Monitoring

### Health Check Endpoint

```javascript
// src/app/api/health/route.js
export async function GET() {
  const health = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV,
    version: process.env.npm_package_version,
  };
  
  // Check database connection
  try {
    await checkDatabaseConnection();
    health.database = 'connected';
  } catch (error) {
    health.database = 'disconnected';
    health.status = 'degraded';
  }
  
  // Check external services
  try {
    await checkExternalServices();
    health.services = 'available';
  } catch (error) {
    health.services = 'unavailable';
    health.status = 'degraded';
  }
  
  const statusCode = health.status === 'ok' ? 200 : 503;
  
  return Response.json(health, { status: statusCode });
}
```

### Metrics Endpoint

```javascript
// src/app/api/metrics/route.js
import { log } from '@/lib/utils/logger';

const metrics = {
  requests: 0,
  errors: 0,
  responseTime: [],
};

export function trackRequest(duration, error = false) {
  metrics.requests++;
  if (error) metrics.errors++;
  metrics.responseTime.push(duration);
  
  // Keep only last 1000 response times
  if (metrics.responseTime.length > 1000) {
    metrics.responseTime.shift();
  }
}

export async function GET() {
  const avgResponseTime = metrics.responseTime.length > 0
    ? metrics.responseTime.reduce((a, b) => a + b, 0) / metrics.responseTime.length
    : 0;
  
  return Response.json({
    requests: metrics.requests,
    errors: metrics.errors,
    errorRate: metrics.requests > 0 
      ? (metrics.errors / metrics.requests * 100).toFixed(2) + '%'
      : '0%',
    avgResponseTime: avgResponseTime.toFixed(2) + 'ms',
    timestamp: new Date().toISOString(),
  });
}
```

## User Activity Tracking

### Activity Logger

```javascript
// src/lib/utils/activity-logger.js
import { log } from './logger';

export function logUserActivity(userId, action, details = {}) {
  log.info('User activity', {
    userId,
    action,
    ...details,
    timestamp: new Date().toISOString(),
  });
  
  // Send to analytics service
  if (process.env.NODE_ENV === 'production') {
    fetch('/api/analytics/activity', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        userId,
        action,
        details,
        timestamp: new Date().toISOString(),
      }),
    });
  }
}

// Usage
import { logUserActivity } from '@/lib/utils/activity-logger';

// In component or API route
logUserActivity(user.id, 'login', {
  ip: request.headers.get('x-forwarded-for'),
  userAgent: request.headers.get('user-agent'),
});

logUserActivity(user.id, 'create_post', {
  postId: post.id,
  title: post.title,
});
```

## Real-time Monitoring Dashboard

### Simple Monitoring Component

```javascript
// src/components/admin/MonitoringDashboard.js
'use client';

import { useState, useEffect } from 'react';
import { Card, Row, Col, Statistic } from 'antd';

export default function MonitoringDashboard() {
  const [health, setHealth] = useState(null);
  const [metrics, setMetrics] = useState(null);
  
  useEffect(() => {
    const fetchData = async () => {
      const [healthRes, metricsRes] = await Promise.all([
        fetch('/api/health'),
        fetch('/api/metrics'),
      ]);
      
      setHealth(await healthRes.json());
      setMetrics(await metricsRes.json());
    };
    
    fetchData();
    const interval = setInterval(fetchData, 5000); // Update every 5s
    
    return () => clearInterval(interval);
  }, []);
  
  if (!health || !metrics) return <div>Loading...</div>;
  
  return (
    <div>
      <h1>System Monitoring</h1>
      
      <Row gutter={16}>
        <Col span={6}>
          <Card>
            <Statistic
              title="Status"
              value={health.status}
              valueStyle={{ 
                color: health.status === 'ok' ? '#3f8600' : '#cf1322' 
              }}
            />
          </Card>
        </Col>
        
        <Col span={6}>
          <Card>
            <Statistic
              title="Total Requests"
              value={metrics.requests}
            />
          </Card>
        </Col>
        
        <Col span={6}>
          <Card>
            <Statistic
              title="Error Rate"
              value={metrics.errorRate}
              valueStyle={{ 
                color: parseFloat(metrics.errorRate) > 5 ? '#cf1322' : '#3f8600' 
              }}
            />
          </Card>
        </Col>
        
        <Col span={6}>
          <Card>
            <Statistic
              title="Avg Response Time"
              value={metrics.avgResponseTime}
            />
          </Card>
        </Col>
      </Row>
    </div>
  );
}
```

## Error Notifications

### Email Notifications

```javascript
// src/lib/utils/notifications.js
import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: process.env.SMTP_PORT,
  secure: true,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

export async function sendErrorNotification(error, context = {}) {
  if (process.env.NODE_ENV !== 'production') return;
  
  const html = `
    <h2>Error Occurred</h2>
    <p><strong>Message:</strong> ${error.message}</p>
    <p><strong>Stack:</strong></p>
    <pre>${error.stack}</pre>
    <p><strong>Context:</strong></p>
    <pre>${JSON.stringify(context, null, 2)}</pre>
    <p><strong>Time:</strong> ${new Date().toISOString()}</p>
  `;
  
  try {
    await transporter.sendMail({
      from: process.env.SMTP_FROM,
      to: process.env.ERROR_NOTIFICATION_EMAIL,
      subject: `[ERROR] ${error.message}`,
      html,
    });
  } catch (emailError) {
    console.error('Failed to send error notification:', emailError);
  }
}
```

### Slack Notifications

```javascript
// src/lib/utils/slack.js
export async function sendSlackNotification(message, level = 'info') {
  if (process.env.NODE_ENV !== 'production') return;
  
  const colors = {
    info: '#36a64f',
    warning: '#ff9900',
    error: '#ff0000',
  };
  
  const payload = {
    attachments: [
      {
        color: colors[level],
        title: `[${level.toUpperCase()}] Application Alert`,
        text: message,
        footer: 'Next.js App',
        ts: Math.floor(Date.now() / 1000),
      },
    ],
  };
  
  try {
    await fetch(process.env.SLACK_WEBHOOK_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
  } catch (error) {
    console.error('Failed to send Slack notification:', error);
  }
}

// Usage
import { sendSlackNotification } from '@/lib/utils/slack';

// On critical error
sendSlackNotification(
  `Database connection failed: ${error.message}`,
  'error'
);

// On important event
sendSlackNotification(
  `New user registered: ${user.email}`,
  'info'
);
```

## Best Practices

1. **Log Levels**: Use appropriate log levels (debug, info, warn, error)
2. **Structured Logging**: Use JSON format for easy parsing
3. **Context**: Include relevant context in logs
4. **PII Protection**: Never log sensitive data (passwords, tokens)
5. **Performance**: Don't log too much in hot paths
6. **Retention**: Set log retention policies
7. **Alerts**: Set up alerts for critical errors
8. **Monitoring**: Monitor key metrics continuously
9. **Testing**: Test error tracking in staging
10. **Documentation**: Document monitoring setup

## Monitoring Checklist

- [ ] Error tracking configured (Sentry)
- [ ] Logging system implemented (Winston)
- [ ] Performance monitoring enabled
- [ ] Health check endpoint created
- [ ] Metrics endpoint implemented
- [ ] User activity tracking
- [ ] Alert notifications setup
- [ ] Monitoring dashboard created
- [ ] Log retention configured
- [ ] Security events logged
- [ ] API performance tracked
- [ ] Database queries monitored
- [ ] External service health checked
- [ ] Error notifications configured
- [ ] Uptime monitoring setup
