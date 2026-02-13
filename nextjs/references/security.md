# Security Best Practices

Panduan implementasi security di Next.js untuk melindungi aplikasi dari berbagai ancaman.

## Security Headers

### Next.js Config

```javascript
// next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'X-DNS-Prefetch-Control',
            value: 'on'
          },
          {
            key: 'Strict-Transport-Security',
            value: 'max-age=63072000; includeSubDomains; preload'
          },
          {
            key: 'X-Frame-Options',
            value: 'SAMEORIGIN'
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff'
          },
          {
            key: 'X-XSS-Protection',
            value: '1; mode=block'
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin'
          },
          {
            key: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=()'
          },
        ],
      },
    ];
  },
};

module.exports = nextConfig;
```

### Content Security Policy (CSP)

```javascript
// next.config.js
const cspHeader = `
  default-src 'self';
  script-src 'self' 'unsafe-eval' 'unsafe-inline' https://cdn.example.com;
  style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
  img-src 'self' blob: data: https:;
  font-src 'self' https://fonts.gstatic.com;
  object-src 'none';
  base-uri 'self';
  form-action 'self';
  frame-ancestors 'none';
  upgrade-insecure-requests;
`;

const nextConfig = {
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'Content-Security-Policy',
            value: cspHeader.replace(/\n/g, ''),
          },
        ],
      },
    ];
  },
};

module.exports = nextConfig;
```

## Authentication & Authorization

### Secure Password Hashing

```javascript
// src/lib/utils/password.js
import bcrypt from 'bcryptjs';

export async function hashPassword(password) {
  const salt = await bcrypt.genSalt(12);
  return bcrypt.hash(password, salt);
}

export async function verifyPassword(password, hashedPassword) {
  return bcrypt.compare(password, hashedPassword);
}

// Usage in API route
// src/app/api/auth/register/route.js
import { hashPassword } from '@/lib/utils/password';

export async function POST(request) {
  const { email, password } = await request.json();
  
  // Validate password strength
  if (password.length < 8) {
    return Response.json(
      { error: 'Password must be at least 8 characters' },
      { status: 400 }
    );
  }
  
  const hashedPassword = await hashPassword(password);
  
  // Save user with hashed password
  // ...
}
```

### JWT Token Management

```javascript
// src/lib/utils/jwt.js
import { SignJWT, jwtVerify } from 'jose';

const JWT_SECRET = new TextEncoder().encode(
  process.env.JWT_SECRET || 'your-secret-key-change-this'
);

export async function createToken(payload, expiresIn = '7d') {
  return new SignJWT(payload)
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime(expiresIn)
    .sign(JWT_SECRET);
}

export async function verifyToken(token) {
  try {
    const { payload } = await jwtVerify(token, JWT_SECRET);
    return payload;
  } catch (error) {
    return null;
  }
}

// Usage
// src/app/api/auth/login/route.js
import { createToken } from '@/lib/utils/jwt';
import { cookies } from 'next/headers';

export async function POST(request) {
  const { email, password } = await request.json();
  
  // Verify credentials
  const user = await verifyCredentials(email, password);
  
  if (!user) {
    return Response.json(
      { error: 'Invalid credentials' },
      { status: 401 }
    );
  }
  
  // Create token
  const token = await createToken({
    userId: user.id,
    email: user.email,
    role: user.role,
  });
  
  // Set secure cookie
  cookies().set('token', token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict',
    maxAge: 60 * 60 * 24 * 7, // 7 days
    path: '/',
  });
  
  return Response.json({ success: true, user });
}
```

## CSRF Protection

### CSRF Token Implementation

```javascript
// src/lib/utils/csrf.js
import crypto from 'crypto';

export function generateCSRFToken() {
  return crypto.randomBytes(32).toString('hex');
}

export function verifyCSRFToken(token, storedToken) {
  return token === storedToken;
}

// Middleware untuk set CSRF token
// src/middleware.js
import { NextResponse } from 'next/server';
import { generateCSRFToken } from '@/lib/utils/csrf';

export function middleware(request) {
  const response = NextResponse.next();
  
  // Set CSRF token in cookie if not exists
  if (!request.cookies.get('csrf-token')) {
    const csrfToken = generateCSRFToken();
    response.cookies.set('csrf-token', csrfToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
    });
  }
  
  return response;
}

// API route protection
// src/app/api/users/route.js
import { cookies } from 'next/headers';
import { verifyCSRFToken } from '@/lib/utils/csrf';

export async function POST(request) {
  const csrfToken = request.headers.get('x-csrf-token');
  const storedToken = cookies().get('csrf-token')?.value;
  
  if (!verifyCSRFToken(csrfToken, storedToken)) {
    return Response.json(
      { error: 'Invalid CSRF token' },
      { status: 403 }
    );
  }
  
  // Process request
  // ...
}
```

### CSRF Token in Forms

```javascript
// src/components/forms/SecureForm.js
'use client';

import { useState, useEffect } from 'react';
import { Form, Input, Button } from 'antd';

export default function SecureForm({ onSubmit }) {
  const [csrfToken, setCSRFToken] = useState('');
  
  useEffect(() => {
    // Get CSRF token from cookie
    const token = document.cookie
      .split('; ')
      .find(row => row.startsWith('csrf-token='))
      ?.split('=')[1];
    
    setCSRFToken(token || '');
  }, []);
  
  const handleSubmit = async (values) => {
    const response = await fetch('/api/users', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
      },
      body: JSON.stringify(values),
    });
    
    const data = await response.json();
    onSubmit?.(data);
  };
  
  return (
    <Form onFinish={handleSubmit}>
      <Form.Item name="name" rules={[{ required: true }]}>
        <Input placeholder="Name" />
      </Form.Item>
      <Form.Item>
        <Button type="primary" htmlType="submit">
          Submit
        </Button>
      </Form.Item>
    </Form>
  );
}
```

## Input Validation & Sanitization

### Server-Side Validation

```javascript
// src/lib/utils/validation.js
import validator from 'validator';

export function sanitizeInput(input) {
  if (typeof input !== 'string') return input;
  
  // Remove HTML tags
  return validator.escape(input.trim());
}

export function validateEmail(email) {
  return validator.isEmail(email);
}

export function validateURL(url) {
  return validator.isURL(url, {
    protocols: ['http', 'https'],
    require_protocol: true,
  });
}

export function validateUserInput(data) {
  const errors = {};
  
  // Sanitize inputs
  const sanitized = {
    name: sanitizeInput(data.name),
    email: sanitizeInput(data.email),
    phone: sanitizeInput(data.phone),
  };
  
  // Validate
  if (!sanitized.name || sanitized.name.length < 2) {
    errors.name = 'Name must be at least 2 characters';
  }
  
  if (!validateEmail(sanitized.email)) {
    errors.email = 'Invalid email address';
  }
  
  if (sanitized.phone && !validator.isMobilePhone(sanitized.phone)) {
    errors.phone = 'Invalid phone number';
  }
  
  return {
    isValid: Object.keys(errors).length === 0,
    errors,
    sanitized,
  };
}

// Usage in API route
// src/app/api/users/route.js
import { validateUserInput } from '@/lib/utils/validation';

export async function POST(request) {
  const body = await request.json();
  
  const { isValid, errors, sanitized } = validateUserInput(body);
  
  if (!isValid) {
    return Response.json({ errors }, { status: 400 });
  }
  
  // Use sanitized data
  const user = await createUser(sanitized);
  
  return Response.json({ user });
}
```

## XSS Prevention

### Sanitize HTML Content

```javascript
// src/lib/utils/sanitize.js
import DOMPurify from 'isomorphic-dompurify';

export function sanitizeHTML(dirty) {
  return DOMPurify.sanitize(dirty, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a', 'p', 'br'],
    ALLOWED_ATTR: ['href', 'target'],
  });
}

// Component untuk render HTML aman
// src/components/common/SafeHTML.js
'use client';

import { useMemo } from 'react';
import { sanitizeHTML } from '@/lib/utils/sanitize';

export default function SafeHTML({ html }) {
  const clean = useMemo(() => sanitizeHTML(html), [html]);
  
  return <div dangerouslySetInnerHTML={{ __html: clean }} />;
}
```

## SQL Injection Prevention

### Parameterized Queries

```javascript
// WRONG - Vulnerable to SQL injection
const query = `SELECT * FROM users WHERE email = '${email}'`;

// CORRECT - Use parameterized queries
// With Prisma
const user = await prisma.user.findUnique({
  where: { email },
});

// With raw SQL (PostgreSQL example)
import { sql } from '@vercel/postgres';

const result = await sql`
  SELECT * FROM users WHERE email = ${email}
`;
```

## Rate Limiting

### API Rate Limiting

```javascript
// src/lib/utils/rate-limit.js
const rateLimit = new Map();

export function checkRateLimit(identifier, limit = 10, window = 60000) {
  const now = Date.now();
  const userRequests = rateLimit.get(identifier) || [];
  
  // Remove old requests
  const recentRequests = userRequests.filter(time => now - time < window);
  
  if (recentRequests.length >= limit) {
    return {
      allowed: false,
      remaining: 0,
      resetAt: new Date(recentRequests[0] + window),
    };
  }
  
  recentRequests.push(now);
  rateLimit.set(identifier, recentRequests);
  
  return {
    allowed: true,
    remaining: limit - recentRequests.length,
    resetAt: new Date(now + window),
  };
}

// Usage in API route
// src/app/api/users/route.js
import { checkRateLimit } from '@/lib/utils/rate-limit';

export async function GET(request) {
  const ip = request.headers.get('x-forwarded-for') || 'unknown';
  
  const { allowed, remaining, resetAt } = checkRateLimit(ip, 100, 60000);
  
  if (!allowed) {
    return Response.json(
      { error: 'Too many requests' },
      { 
        status: 429,
        headers: {
          'X-RateLimit-Limit': '100',
          'X-RateLimit-Remaining': '0',
          'X-RateLimit-Reset': resetAt.toISOString(),
          'Retry-After': '60',
        },
      }
    );
  }
  
  // Process request
  const users = await getUsers();
  
  return Response.json(users, {
    headers: {
      'X-RateLimit-Limit': '100',
      'X-RateLimit-Remaining': remaining.toString(),
      'X-RateLimit-Reset': resetAt.toISOString(),
    },
  });
}
```

## Environment Variables Security

### Secure Environment Variables

```bash
# .env.local

# NEVER commit this file to git!
# Add .env.local to .gitignore

# Database
DATABASE_URL="postgresql://user:password@localhost:5432/mydb"

# JWT Secret (generate with: openssl rand -base64 32)
JWT_SECRET="your-super-secret-jwt-key-change-this"

# API Keys
NEXT_PUBLIC_API_URL="https://api.example.com"
API_SECRET_KEY="your-api-secret-key"

# Third-party services
STRIPE_SECRET_KEY="sk_test_..."
SENDGRID_API_KEY="SG...."

# Only NEXT_PUBLIC_* variables are exposed to browser
# Keep sensitive keys without NEXT_PUBLIC_ prefix
```

### Environment Variable Validation

```javascript
// src/lib/utils/env.js
export function validateEnv() {
  const required = [
    'DATABASE_URL',
    'JWT_SECRET',
    'API_SECRET_KEY',
  ];
  
  const missing = required.filter(key => !process.env[key]);
  
  if (missing.length > 0) {
    throw new Error(
      `Missing required environment variables: ${missing.join(', ')}`
    );
  }
}

// Call in app startup
// src/app/layout.js
import { validateEnv } from '@/lib/utils/env';

if (process.env.NODE_ENV === 'production') {
  validateEnv();
}
```

## File Upload Security

### Secure File Upload

```javascript
// src/app/api/upload/route.js
import { writeFile } from 'fs/promises';
import { join } from 'path';
import crypto from 'crypto';

const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const MAX_SIZE = 5 * 1024 * 1024; // 5MB

export async function POST(request) {
  try {
    const formData = await request.formData();
    const file = formData.get('file');
    
    if (!file) {
      return Response.json(
        { error: 'No file uploaded' },
        { status: 400 }
      );
    }
    
    // Validate file type
    if (!ALLOWED_TYPES.includes(file.type)) {
      return Response.json(
        { error: 'Invalid file type. Only JPEG, PNG, and WebP allowed' },
        { status: 400 }
      );
    }
    
    // Validate file size
    if (file.size > MAX_SIZE) {
      return Response.json(
        { error: 'File too large. Maximum size is 5MB' },
        { status: 400 }
      );
    }
    
    // Generate secure filename
    const ext = file.name.split('.').pop();
    const filename = `${crypto.randomUUID()}.${ext}`;
    
    const bytes = await file.arrayBuffer();
    const buffer = Buffer.from(bytes);
    
    // Save to secure location
    const uploadDir = join(process.cwd(), 'public', 'uploads');
    const path = join(uploadDir, filename);
    
    await writeFile(path, buffer);
    
    return Response.json({
      success: true,
      filename,
      url: `/uploads/${filename}`,
    });
  } catch (error) {
    return Response.json(
      { error: 'Upload failed' },
      { status: 500 }
    );
  }
}
```

## Security Checklist

### Development
- [ ] Use HTTPS in production
- [ ] Set secure headers (CSP, HSTS, etc.)
- [ ] Implement CSRF protection
- [ ] Validate and sanitize all inputs
- [ ] Use parameterized queries
- [ ] Hash passwords with bcrypt
- [ ] Use secure JWT tokens
- [ ] Implement rate limiting
- [ ] Validate file uploads
- [ ] Keep dependencies updated

### Authentication
- [ ] Enforce strong passwords
- [ ] Implement account lockout
- [ ] Use secure session management
- [ ] Implement 2FA (optional)
- [ ] Secure password reset flow
- [ ] Log authentication attempts

### API Security
- [ ] Authenticate API requests
- [ ] Validate request origins (CORS)
- [ ] Implement rate limiting
- [ ] Validate input data
- [ ] Use HTTPS only
- [ ] Hide error details in production

### Data Protection
- [ ] Encrypt sensitive data
- [ ] Use environment variables
- [ ] Never commit secrets to git
- [ ] Implement proper access control
- [ ] Audit data access
- [ ] Regular security backups

### Monitoring
- [ ] Log security events
- [ ] Monitor failed login attempts
- [ ] Track API usage
- [ ] Set up alerts
- [ ] Regular security audits
- [ ] Penetration testing

## Security Tools

### Dependency Scanning

```bash
# Check for vulnerabilities
npm audit

# Fix vulnerabilities
npm audit fix

# Check with Snyk
npx snyk test
```

### Security Headers Testing

```bash
# Test security headers
curl -I https://your-app.com

# Use online tools
# - securityheaders.com
# - observatory.mozilla.org
```

## Best Practices

1. **Defense in Depth**: Multiple layers of security
2. **Least Privilege**: Minimal access rights
3. **Fail Securely**: Secure defaults, fail closed
4. **Keep Updated**: Regular dependency updates
5. **Security by Design**: Build security from start
6. **Audit Regularly**: Regular security reviews
7. **Educate Team**: Security awareness training
8. **Incident Response**: Have a plan ready
9. **Monitor Always**: Continuous monitoring
10. **Test Thoroughly**: Security testing in CI/CD
