# API Routes

Panduan membuat API endpoints dengan Next.js App Router.

## Basic API Route

```javascript
// src/app/api/hello/route.js
export async function GET(request) {
  return Response.json({ message: 'Hello World' });
}
```

## HTTP Methods

### GET Request

```javascript
// src/app/api/users/route.js
export async function GET(request) {
  // Get query parameters
  const { searchParams } = new URL(request.url);
  const page = searchParams.get('page') || 1;
  const limit = searchParams.get('limit') || 10;
  
  try {
    // Fetch data from database
    const users = await fetchUsersFromDB({ page, limit });
    
    return Response.json({
      success: true,
      data: users,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
      }
    });
  } catch (error) {
    return Response.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}
```

### POST Request

```javascript
// src/app/api/users/route.js
export async function POST(request) {
  try {
    const body = await request.json();
    
    // Validate request body
    if (!body.name || !body.email) {
      return Response.json(
        { success: false, error: 'Name and email are required' },
        { status: 400 }
      );
    }
    
    // Create user in database
    const newUser = await createUserInDB(body);
    
    return Response.json(
      { success: true, data: newUser },
      { status: 201 }
    );
  } catch (error) {
    return Response.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}
```

### PUT Request

```javascript
// src/app/api/users/[id]/route.js
export async function PUT(request, { params }) {
  try {
    const { id } = params;
    const body = await request.json();
    
    // Update user in database
    const updatedUser = await updateUserInDB(id, body);
    
    if (!updatedUser) {
      return Response.json(
        { success: false, error: 'User not found' },
        { status: 404 }
      );
    }
    
    return Response.json({
      success: true,
      data: updatedUser
    });
  } catch (error) {
    return Response.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}
```

### DELETE Request

```javascript
// src/app/api/users/[id]/route.js
export async function DELETE(request, { params }) {
  try {
    const { id } = params;
    
    // Delete user from database
    const deleted = await deleteUserFromDB(id);
    
    if (!deleted) {
      return Response.json(
        { success: false, error: 'User not found' },
        { status: 404 }
      );
    }
    
    return Response.json({
      success: true,
      message: 'User deleted successfully'
    });
  } catch (error) {
    return Response.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}
```

## Dynamic Routes

```javascript
// src/app/api/users/[id]/route.js
export async function GET(request, { params }) {
  const { id } = params;
  
  try {
    const user = await getUserFromDB(id);
    
    if (!user) {
      return Response.json(
        { success: false, error: 'User not found' },
        { status: 404 }
      );
    }
    
    return Response.json({
      success: true,
      data: user
    });
  } catch (error) {
    return Response.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}
```

## Request Headers

```javascript
// src/app/api/protected/route.js
export async function GET(request) {
  // Get authorization header
  const authHeader = request.headers.get('authorization');
  
  if (!authHeader) {
    return Response.json(
      { success: false, error: 'Unauthorized' },
      { status: 401 }
    );
  }
  
  const token = authHeader.replace('Bearer ', '');
  
  try {
    // Verify token
    const user = await verifyToken(token);
    
    return Response.json({
      success: true,
      data: user
    });
  } catch (error) {
    return Response.json(
      { success: false, error: 'Invalid token' },
      { status: 401 }
    );
  }
}
```

## Response Headers

```javascript
// src/app/api/data/route.js
export async function GET(request) {
  const data = { message: 'Hello' };
  
  return Response.json(data, {
    status: 200,
    headers: {
      'Content-Type': 'application/json',
      'Cache-Control': 'public, s-maxage=60, stale-while-revalidate=30',
      'X-Custom-Header': 'custom-value',
    },
  });
}
```

## Cookies

```javascript
// src/app/api/auth/login/route.js
import { cookies } from 'next/headers';

export async function POST(request) {
  const body = await request.json();
  
  try {
    // Authenticate user
    const { token, user } = await authenticateUser(body);
    
    // Set cookie
    cookies().set('token', token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 60 * 60 * 24 * 7, // 7 days
      path: '/',
    });
    
    return Response.json({
      success: true,
      data: user
    });
  } catch (error) {
    return Response.json(
      { success: false, error: 'Invalid credentials' },
      { status: 401 }
    );
  }
}

// Get cookie
export async function GET(request) {
  const token = cookies().get('token');
  
  if (!token) {
    return Response.json(
      { success: false, error: 'Not authenticated' },
      { status: 401 }
    );
  }
  
  return Response.json({
    success: true,
    data: { token: token.value }
  });
}
```

## File Upload

```javascript
// src/app/api/upload/route.js
import { writeFile } from 'fs/promises';
import { join } from 'path';

export async function POST(request) {
  try {
    const formData = await request.formData();
    const file = formData.get('file');
    
    if (!file) {
      return Response.json(
        { success: false, error: 'No file uploaded' },
        { status: 400 }
      );
    }
    
    const bytes = await file.arrayBuffer();
    const buffer = Buffer.from(bytes);
    
    // Save file
    const filename = `${Date.now()}-${file.name}`;
    const path = join(process.cwd(), 'public', 'uploads', filename);
    await writeFile(path, buffer);
    
    return Response.json({
      success: true,
      data: {
        filename,
        url: `/uploads/${filename}`,
        size: file.size,
        type: file.type,
      }
    });
  } catch (error) {
    return Response.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}
```

## Middleware Pattern

```javascript
// src/lib/api/middleware.js
export function withAuth(handler) {
  return async (request, context) => {
    const authHeader = request.headers.get('authorization');
    
    if (!authHeader) {
      return Response.json(
        { success: false, error: 'Unauthorized' },
        { status: 401 }
      );
    }
    
    try {
      const token = authHeader.replace('Bearer ', '');
      const user = await verifyToken(token);
      
      // Add user to context
      context.user = user;
      
      return handler(request, context);
    } catch (error) {
      return Response.json(
        { success: false, error: 'Invalid token' },
        { status: 401 }
      );
    }
  };
}

// Usage
// src/app/api/protected/route.js
import { withAuth } from '@/lib/api/middleware';

async function handler(request, context) {
  const { user } = context;
  
  return Response.json({
    success: true,
    data: { user }
  });
}

export const GET = withAuth(handler);
```

## Error Handling

```javascript
// src/lib/api/errors.js
export class APIError extends Error {
  constructor(message, status = 500) {
    super(message);
    this.status = status;
  }
}

export function handleAPIError(error) {
  if (error instanceof APIError) {
    return Response.json(
      { success: false, error: error.message },
      { status: error.status }
    );
  }
  
  console.error('API Error:', error);
  
  return Response.json(
    { success: false, error: 'Internal server error' },
    { status: 500 }
  );
}

// Usage
// src/app/api/users/route.js
import { APIError, handleAPIError } from '@/lib/api/errors';

export async function GET(request) {
  try {
    const users = await fetchUsers();
    
    if (!users) {
      throw new APIError('Users not found', 404);
    }
    
    return Response.json({
      success: true,
      data: users
    });
  } catch (error) {
    return handleAPIError(error);
  }
}
```

## Validation

```javascript
// src/lib/api/validation.js
export function validateEmail(email) {
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return regex.test(email);
}

export function validateUserInput(data) {
  const errors = {};
  
  if (!data.name || data.name.trim().length === 0) {
    errors.name = 'Name is required';
  }
  
  if (!data.email || !validateEmail(data.email)) {
    errors.email = 'Valid email is required';
  }
  
  if (!data.password || data.password.length < 6) {
    errors.password = 'Password must be at least 6 characters';
  }
  
  return {
    isValid: Object.keys(errors).length === 0,
    errors
  };
}

// Usage
// src/app/api/users/route.js
import { validateUserInput } from '@/lib/api/validation';

export async function POST(request) {
  const body = await request.json();
  
  const { isValid, errors } = validateUserInput(body);
  
  if (!isValid) {
    return Response.json(
      { success: false, errors },
      { status: 400 }
    );
  }
  
  // Create user...
}
```

## CORS

```javascript
// src/app/api/public/route.js
export async function GET(request) {
  const data = { message: 'Public API' };
  
  return Response.json(data, {
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  });
}

export async function OPTIONS(request) {
  return new Response(null, {
    status: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  });
}
```

## Rate Limiting

```javascript
// src/lib/api/rateLimit.js
const rateLimit = new Map();

export function checkRateLimit(ip, limit = 10, window = 60000) {
  const now = Date.now();
  const userRequests = rateLimit.get(ip) || [];
  
  // Remove old requests outside the window
  const recentRequests = userRequests.filter(time => now - time < window);
  
  if (recentRequests.length >= limit) {
    return false;
  }
  
  recentRequests.push(now);
  rateLimit.set(ip, recentRequests);
  
  return true;
}

// Usage
// src/app/api/limited/route.js
import { checkRateLimit } from '@/lib/api/rateLimit';

export async function GET(request) {
  const ip = request.headers.get('x-forwarded-for') || 'unknown';
  
  if (!checkRateLimit(ip)) {
    return Response.json(
      { success: false, error: 'Too many requests' },
      { status: 429 }
    );
  }
  
  return Response.json({ success: true, data: 'OK' });
}
```

## API Best Practices

1. **Consistent Response Format**: Gunakan format response yang konsisten
2. **Error Handling**: Implement proper error handling dan status codes
3. **Validation**: Validate semua input dari client
4. **Authentication**: Protect sensitive endpoints dengan authentication
5. **Rate Limiting**: Implement rate limiting untuk prevent abuse
6. **CORS**: Configure CORS dengan benar untuk public APIs
7. **Logging**: Log errors dan important events
8. **Documentation**: Document API endpoints dan parameters
