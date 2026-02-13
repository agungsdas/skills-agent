# Middleware

Panduan implementasi middleware di Next.js untuk authentication, authorization, redirects, dan request processing.

## Middleware File

Middleware berjalan sebelum request completed, di edge runtime.

```javascript
// src/middleware.js
import { NextResponse } from 'next/server';

export function middleware(request) {
  // Middleware logic here
  return NextResponse.next();
}

// Specify which paths middleware runs on
export const config = {
  matcher: [
    /*
     * Match all request paths except:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     */
    '/((?!api|_next/static|_next/image|favicon.ico).*)',
  ],
};
```

## Authentication Middleware

### Basic Auth Check

```javascript
// src/middleware.js
import { NextResponse } from 'next/server';

export function middleware(request) {
  const token = request.cookies.get('token')?.value;
  const { pathname } = request.nextUrl;
  
  // Public routes yang tidak perlu auth
  const publicRoutes = ['/login', '/register', '/'];
  const isPublicRoute = publicRoutes.some(route => pathname.startsWith(route));
  
  // Jika tidak ada token dan bukan public route, redirect ke login
  if (!token && !isPublicRoute) {
    const loginUrl = new URL('/login', request.url);
    loginUrl.searchParams.set('from', pathname);
    return NextResponse.redirect(loginUrl);
  }
  
  // Jika ada token dan mencoba akses login/register, redirect ke dashboard
  if (token && (pathname === '/login' || pathname === '/register')) {
    return NextResponse.redirect(new URL('/dashboard', request.url));
  }
  
  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
```

### JWT Verification

```javascript
// src/middleware.js
import { NextResponse } from 'next/server';
import { jwtVerify } from 'jose';

const JWT_SECRET = new TextEncoder().encode(
  process.env.JWT_SECRET || 'your-secret-key'
);

async function verifyToken(token) {
  try {
    const { payload } = await jwtVerify(token, JWT_SECRET);
    return payload;
  } catch (error) {
    return null;
  }
}

export async function middleware(request) {
  const token = request.cookies.get('token')?.value;
  const { pathname } = request.nextUrl;
  
  const publicRoutes = ['/login', '/register', '/'];
  const isPublicRoute = publicRoutes.some(route => pathname.startsWith(route));
  
  if (!isPublicRoute) {
    if (!token) {
      return NextResponse.redirect(new URL('/login', request.url));
    }
    
    const payload = await verifyToken(token);
    if (!payload) {
      // Token invalid, clear cookie dan redirect
      const response = NextResponse.redirect(new URL('/login', request.url));
      response.cookies.delete('token');
      return response;
    }
    
    // Add user info to headers untuk diakses di server components
    const requestHeaders = new Headers(request.headers);
    requestHeaders.set('x-user-id', payload.userId);
    requestHeaders.set('x-user-role', payload.role);
    
    return NextResponse.next({
      request: {
        headers: requestHeaders,
      },
    });
  }
  
  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
```

## Role-Based Access Control

```javascript
// src/middleware.js
import { NextResponse } from 'next/server';
import { jwtVerify } from 'jose';

const JWT_SECRET = new TextEncoder().encode(process.env.JWT_SECRET);

// Define role-based routes
const roleRoutes = {
  admin: ['/admin', '/users/manage'],
  manager: ['/dashboard/analytics', '/reports'],
  user: ['/dashboard', '/profile'],
};

async function verifyToken(token) {
  try {
    const { payload } = await jwtVerify(token, JWT_SECRET);
    return payload;
  } catch (error) {
    return null;
  }
}

function hasAccess(userRole, pathname) {
  // Admin has access to everything
  if (userRole === 'admin') return true;
  
  // Check if user role has access to the route
  const allowedRoutes = roleRoutes[userRole] || [];
  return allowedRoutes.some(route => pathname.startsWith(route));
}

export async function middleware(request) {
  const token = request.cookies.get('token')?.value;
  const { pathname } = request.nextUrl;
  
  const publicRoutes = ['/login', '/register', '/'];
  const isPublicRoute = publicRoutes.some(route => pathname.startsWith(route));
  
  if (!isPublicRoute) {
    if (!token) {
      return NextResponse.redirect(new URL('/login', request.url));
    }
    
    const payload = await verifyToken(token);
    if (!payload) {
      const response = NextResponse.redirect(new URL('/login', request.url));
      response.cookies.delete('token');
      return response;
    }
    
    // Check role-based access
    if (!hasAccess(payload.role, pathname)) {
      return NextResponse.redirect(new URL('/unauthorized', request.url));
    }
    
    const requestHeaders = new Headers(request.headers);
    requestHeaders.set('x-user-id', payload.userId);
    requestHeaders.set('x-user-role', payload.role);
    
    return NextResponse.next({
      request: {
        headers: requestHeaders,
      },
    });
  }
  
  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
```

## Request/Response Modification

### Add Custom Headers

```javascript
// src/middleware.js
import { NextResponse } from 'next/server';

export function middleware(request) {
  const response = NextResponse.next();
  
  // Add custom headers
  response.headers.set('x-custom-header', 'my-value');
  response.headers.set('x-request-id', crypto.randomUUID());
  
  // Security headers
  response.headers.set('X-Frame-Options', 'DENY');
  response.headers.set('X-Content-Type-Options', 'nosniff');
  response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
  
  return response;
}
```

### Rate Limiting

```javascript
// src/middleware.js
import { NextResponse } from 'next/server';

const rateLimit = new Map();

function checkRateLimit(ip, limit = 100, window = 60000) {
  const now = Date.now();
  const userRequests = rateLimit.get(ip) || [];
  
  // Remove old requests
  const recentRequests = userRequests.filter(time => now - time < window);
  
  if (recentRequests.length >= limit) {
    return false;
  }
  
  recentRequests.push(now);
  rateLimit.set(ip, recentRequests);
  
  return true;
}

export function middleware(request) {
  const ip = request.ip || request.headers.get('x-forwarded-for') || 'unknown';
  
  if (!checkRateLimit(ip)) {
    return new NextResponse('Too Many Requests', {
      status: 429,
      headers: {
        'Retry-After': '60',
      },
    });
  }
  
  return NextResponse.next();
}

export const config = {
  matcher: '/api/:path*',
};
```

## Redirects & Rewrites

### Conditional Redirects

```javascript
// src/middleware.js
import { NextResponse } from 'next/server';

export function middleware(request) {
  const { pathname } = request.nextUrl;
  
  // Redirect old URLs to new ones
  if (pathname.startsWith('/old-path')) {
    return NextResponse.redirect(
      new URL(pathname.replace('/old-path', '/new-path'), request.url)
    );
  }
  
  // Redirect based on user agent (mobile detection)
  const userAgent = request.headers.get('user-agent') || '';
  const isMobile = /mobile/i.test(userAgent);
  
  if (isMobile && pathname === '/') {
    return NextResponse.redirect(new URL('/mobile', request.url));
  }
  
  return NextResponse.next();
}
```

### Rewrite URLs

```javascript
// src/middleware.js
import { NextResponse } from 'next/server';

export function middleware(request) {
  const { pathname } = request.nextUrl;
  
  // Rewrite /blog/:slug to /posts/:slug
  if (pathname.startsWith('/blog/')) {
    const slug = pathname.replace('/blog/', '');
    return NextResponse.rewrite(new URL(`/posts/${slug}`, request.url));
  }
  
  return NextResponse.next();
}
```

## Internationalization (i18n)

```javascript
// src/middleware.js
import { NextResponse } from 'next/server';

const locales = ['en', 'id', 'ja'];
const defaultLocale = 'en';

function getLocale(request) {
  // Check cookie
  const localeCookie = request.cookies.get('locale')?.value;
  if (localeCookie && locales.includes(localeCookie)) {
    return localeCookie;
  }
  
  // Check Accept-Language header
  const acceptLanguage = request.headers.get('accept-language');
  if (acceptLanguage) {
    const preferredLocale = acceptLanguage
      .split(',')[0]
      .split('-')[0]
      .toLowerCase();
    
    if (locales.includes(preferredLocale)) {
      return preferredLocale;
    }
  }
  
  return defaultLocale;
}

export function middleware(request) {
  const { pathname } = request.nextUrl;
  
  // Check if pathname already has locale
  const pathnameHasLocale = locales.some(
    locale => pathname.startsWith(`/${locale}/`) || pathname === `/${locale}`
  );
  
  if (pathnameHasLocale) {
    return NextResponse.next();
  }
  
  // Redirect to locale-prefixed URL
  const locale = getLocale(request);
  const newUrl = new URL(`/${locale}${pathname}`, request.url);
  
  return NextResponse.redirect(newUrl);
}

export const config = {
  matcher: ['/((?!api|_next|favicon.ico).*)'],
};
```

## API Route Protection

```javascript
// src/middleware.js
import { NextResponse } from 'next/server';

export function middleware(request) {
  const { pathname } = request.nextUrl;
  
  // Protect API routes
  if (pathname.startsWith('/api/')) {
    const token = request.headers.get('authorization')?.replace('Bearer ', '');
    
    // Public API endpoints
    const publicEndpoints = ['/api/auth/login', '/api/auth/register'];
    if (publicEndpoints.includes(pathname)) {
      return NextResponse.next();
    }
    
    if (!token) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }
    
    // Verify token (simplified)
    // In production, use proper JWT verification
    if (token !== process.env.API_SECRET) {
      return NextResponse.json(
        { error: 'Invalid token' },
        { status: 401 }
      );
    }
  }
  
  return NextResponse.next();
}

export const config = {
  matcher: '/api/:path*',
};
```

## Logging & Monitoring

```javascript
// src/middleware.js
import { NextResponse } from 'next/server';

export function middleware(request) {
  const start = Date.now();
  const { pathname, search } = request.nextUrl;
  const method = request.method;
  
  // Clone response to read it
  const response = NextResponse.next();
  
  // Log request
  console.log({
    timestamp: new Date().toISOString(),
    method,
    path: pathname + search,
    userAgent: request.headers.get('user-agent'),
    ip: request.ip || request.headers.get('x-forwarded-for'),
  });
  
  // Add timing header
  response.headers.set('X-Response-Time', `${Date.now() - start}ms`);
  
  return response;
}
```

## Multiple Middleware Pattern

```javascript
// src/middleware.js
import { NextResponse } from 'next/server';

// Middleware functions
async function authMiddleware(request) {
  const token = request.cookies.get('token')?.value;
  if (!token) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
  return null; // Continue to next middleware
}

function securityMiddleware(request) {
  const response = NextResponse.next();
  response.headers.set('X-Frame-Options', 'DENY');
  response.headers.set('X-Content-Type-Options', 'nosniff');
  return response;
}

function loggingMiddleware(request) {
  console.log(`${request.method} ${request.nextUrl.pathname}`);
  return null; // Continue to next middleware
}

// Chain middlewares
export async function middleware(request) {
  const { pathname } = request.nextUrl;
  
  // Run logging for all requests
  loggingMiddleware(request);
  
  // Run auth for protected routes
  const publicRoutes = ['/login', '/register', '/'];
  const isPublicRoute = publicRoutes.some(route => pathname.startsWith(route));
  
  if (!isPublicRoute) {
    const authResult = await authMiddleware(request);
    if (authResult) return authResult;
  }
  
  // Run security headers
  return securityMiddleware(request);
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
```

## Best Practices

1. **Keep It Light**: Middleware runs on edge, avoid heavy computations
2. **Use Matchers**: Specify exact paths to avoid unnecessary runs
3. **Avoid Database Calls**: Use JWT/tokens instead of DB lookups
4. **Cache When Possible**: Cache verification results
5. **Error Handling**: Always handle errors gracefully
6. **Security First**: Validate all inputs, sanitize data
7. **Logging**: Log important events for debugging
8. **Testing**: Test middleware thoroughly
9. **Performance**: Monitor middleware execution time
10. **Documentation**: Document middleware behavior

## Common Patterns

### Maintenance Mode

```javascript
export function middleware(request) {
  const isMaintenanceMode = process.env.MAINTENANCE_MODE === 'true';
  const { pathname } = request.nextUrl;
  
  if (isMaintenanceMode && pathname !== '/maintenance') {
    return NextResponse.redirect(new URL('/maintenance', request.url));
  }
  
  return NextResponse.next();
}
```

### Feature Flags

```javascript
export function middleware(request) {
  const { pathname } = request.nextUrl;
  
  // Check feature flag
  const newFeatureEnabled = process.env.NEW_FEATURE_ENABLED === 'true';
  
  if (pathname.startsWith('/new-feature') && !newFeatureEnabled) {
    return NextResponse.redirect(new URL('/404', request.url));
  }
  
  return NextResponse.next();
}
```

### A/B Testing

```javascript
export function middleware(request) {
  const { pathname } = request.nextUrl;
  
  if (pathname === '/') {
    // Check if user already has variant
    let variant = request.cookies.get('ab-test-variant')?.value;
    
    if (!variant) {
      // Assign random variant
      variant = Math.random() < 0.5 ? 'A' : 'B';
    }
    
    const response = variant === 'A' 
      ? NextResponse.rewrite(new URL('/home-a', request.url))
      : NextResponse.rewrite(new URL('/home-b', request.url));
    
    response.cookies.set('ab-test-variant', variant, {
      maxAge: 60 * 60 * 24 * 30, // 30 days
    });
    
    return response;
  }
  
  return NextResponse.next();
}
```
