# Middleware (TypeScript)

Panduan implementasi middleware di Next.js untuk authentication, authorization, redirects, dan request processing.

## Middleware File

Middleware berjalan sebelum request completed, di edge runtime.

```typescript
// src/middleware.ts
import { NextResponse, type NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  // Middleware logic here
  return NextResponse.next();
}

export const config = {
  matcher: [
    '/((?!api|_next/static|_next/image|favicon.ico).*)',
  ],
};
```

## Authentication Middleware

```typescript
// src/middleware.ts
import { NextResponse, type NextRequest } from 'next/server';

const PUBLIC_ROUTES = ['/login', '/daftar', '/lupa-password', '/'];
const AUTH_ROUTES = ['/login', '/daftar', '/lupa-password'];

export function middleware(request: NextRequest) {
  const token = request.cookies.get('token')?.value;
  const { pathname } = request.nextUrl;
  
  const isPublicRoute = PUBLIC_ROUTES.some(route => pathname === route);
  const isAuthRoute = AUTH_ROUTES.some(route => pathname.startsWith(route));
  
  // Tidak ada token & bukan public route → redirect ke login
  if (!token && !isPublicRoute) {
    const loginUrl = new URL('/login', request.url);
    loginUrl.searchParams.set('from', pathname);
    return NextResponse.redirect(loginUrl);
  }
  
  // Ada token & mencoba akses auth routes → redirect ke home
  if (token && isAuthRoute) {
    return NextResponse.redirect(new URL('/', request.url));
  }
  
  return NextResponse.next();
}

export const config = {
  matcher: [
    '/((?!api|_next/static|_next/image|favicon.ico|images|icons).*)',
  ],
};
```

## Role-Based Access Control

```typescript
// src/middleware.ts
import { NextResponse, type NextRequest } from 'next/server';
import { jwtDecode } from 'jwt-decode';

interface TokenPayload {
  id: string;
  userType: string;
  roles?: string[];
  exp: number;
}

const ADMIN_ROUTES = ['/admin', '/pengaturan/admin'];

export function middleware(request: NextRequest) {
  const token = request.cookies.get('token')?.value;
  const { pathname } = request.nextUrl;
  
  if (!token) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
  
  try {
    const decoded = jwtDecode<TokenPayload>(token);
    
    // Check token expiry
    if (decoded.exp * 1000 < Date.now()) {
      const response = NextResponse.redirect(new URL('/login', request.url));
      response.cookies.delete('token');
      return response;
    }
    
    // Check admin routes
    const isAdminRoute = ADMIN_ROUTES.some(route => pathname.startsWith(route));
    if (isAdminRoute && decoded.userType !== 'INTERNAL_LDAP') {
      return NextResponse.redirect(new URL('/', request.url));
    }
    
  } catch {
    return NextResponse.redirect(new URL('/login', request.url));
  }
  
  return NextResponse.next();
}
```

## Request Headers

```typescript
// Menambahkan custom headers
export function middleware(request: NextRequest) {
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set('x-request-id', crypto.randomUUID());
  
  const response = NextResponse.next({
    request: { headers: requestHeaders },
  });
  
  // Security headers
  response.headers.set('X-Frame-Options', 'DENY');
  response.headers.set('X-Content-Type-Options', 'nosniff');
  response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
  
  return response;
}
```

## Best Practices

1. **Edge Runtime**: Middleware runs di edge — tidak bisa pakai Node.js APIs
2. **Cookie-based Auth**: Gunakan cookies untuk token (bukan localStorage) agar accessible di middleware
3. **Lightweight**: Keep middleware ringan, hindari heavy computation
4. **Matcher**: Gunakan matcher config untuk limit routes yang di-process
5. **Token Validation**: Validate token expiry di middleware, full validation di API
6. **Redirect Loops**: Hati-hati dengan redirect loops (public routes harus di-exclude)
