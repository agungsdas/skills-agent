# API Routes (TypeScript)

Panduan membuat API endpoints dengan Next.js App Router dan TypeScript.

## Basic API Route

```typescript
// src/app/api/hello/route.ts
import { NextResponse } from 'next/server';

export async function GET() {
  return NextResponse.json({ message: 'Hello World' });
}
```

## HTTP Methods

### GET Request

```typescript
// src/app/api/users/route.ts
import { NextResponse, type NextRequest } from 'next/server';

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const page = Number(searchParams.get('page')) || 1;
  const limit = Number(searchParams.get('limit')) || 10;
  
  try {
    const users = await fetchUsersFromDB({ page, limit });
    
    return NextResponse.json({
      status: true,
      message: 'OK',
      data: users,
      meta: { page, per_page: limit, total: users.length },
    });
  } catch (error) {
    return NextResponse.json(
      { status: false, message: 'Failed to fetch users' },
      { status: 500 }
    );
  }
}
```

### POST Request

```typescript
// src/app/api/users/route.ts
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    
    // Validation
    if (!body.name || !body.email) {
      return NextResponse.json(
        { status: false, message: 'Name and email are required' },
        { status: 400 }
      );
    }
    
    const user = await createUser(body);
    
    return NextResponse.json(
      { status: true, message: 'User created', data: user },
      { status: 201 }
    );
  } catch (error) {
    return NextResponse.json(
      { status: false, message: 'Failed to create user' },
      { status: 500 }
    );
  }
}
```

### Dynamic Route

```typescript
// src/app/api/users/[id]/route.ts
import { NextResponse, type NextRequest } from 'next/server';

interface RouteParams {
  params: { id: string };
}

export async function GET(request: NextRequest, { params }: RouteParams) {
  const { id } = params;
  
  try {
    const user = await getUserById(id);
    
    if (!user) {
      return NextResponse.json(
        { status: false, message: 'User not found' },
        { status: 404 }
      );
    }
    
    return NextResponse.json({ status: true, data: user });
  } catch (error) {
    return NextResponse.json(
      { status: false, message: 'Internal server error' },
      { status: 500 }
    );
  }
}

export async function PATCH(request: NextRequest, { params }: RouteParams) {
  const { id } = params;
  const body = await request.json();
  
  try {
    const user = await updateUser(id, body);
    return NextResponse.json({ status: true, message: 'Updated', data: user });
  } catch (error) {
    return NextResponse.json(
      { status: false, message: 'Failed to update' },
      { status: 500 }
    );
  }
}

export async function DELETE(request: NextRequest, { params }: RouteParams) {
  const { id } = params;
  
  try {
    await deleteUser(id);
    return NextResponse.json({ status: true, message: 'Deleted' });
  } catch (error) {
    return NextResponse.json(
      { status: false, message: 'Failed to delete' },
      { status: 500 }
    );
  }
}
```

## Authentication di API Routes

```typescript
// src/app/api/profile/route.ts
import { NextResponse, type NextRequest } from 'next/server';
import { verifyToken } from '@/helpers/auth';

export async function GET(request: NextRequest) {
  const token = request.headers.get('Authorization')?.replace('Bearer ', '');
  
  if (!token) {
    return NextResponse.json(
      { status: false, message: 'Unauthorized' },
      { status: 401 }
    );
  }
  
  try {
    const user = await verifyToken(token);
    return NextResponse.json({ status: true, data: user });
  } catch {
    return NextResponse.json(
      { status: false, message: 'Invalid token' },
      { status: 401 }
    );
  }
}
```

## Response Pattern

Selalu gunakan consistent response format:

```typescript
// Success
NextResponse.json({
  status: true,
  message: 'OK',
  data: result,
  meta: { page, per_page, total, total_page },
});

// Error
NextResponse.json(
  { status: false, message: 'Error description' },
  { status: 400 | 401 | 404 | 500 }
);
```

## Best Practices

1. **TypeScript**: Type semua request/response
2. **Error Handling**: Wrap semua logic dalam try-catch
3. **Validation**: Validate input sebelum processing
4. **Status Codes**: Gunakan HTTP status codes yang tepat
5. **Consistent Response**: Gunakan format response yang konsisten
6. **Auth Check**: Validate token di protected routes
7. **Edge Runtime**: Gunakan `export const runtime = 'edge'` untuk performance jika tidak butuh Node.js APIs
