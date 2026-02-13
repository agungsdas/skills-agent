# Pages dengan App Router

Panduan membuat dan mengatur pages di Next.js App Router.

## Server Components vs Client Components

### Server Components (Default)

Server Components adalah default di App Router. Render di server, tidak mengirim JavaScript ke client.

```javascript
// src/app/users/page.js
// Server Component (default)
async function getUsers() {
  const res = await fetch('https://api.example.com/users', {
    cache: 'no-store' // atau 'force-cache'
  });
  return res.json();
}

export default async function UsersPage() {
  const users = await getUsers();
  
  return (
    <div>
      <h1>Users</h1>
      <ul>
        {users.map(user => (
          <li key={user.id}>{user.name}</li>
        ))}
      </ul>
    </div>
  );
}
```

**Keuntungan Server Components:**
- Tidak mengirim JavaScript ke client
- Akses langsung ke backend resources
- Lebih aman untuk sensitive data
- Better SEO

### Client Components

Gunakan `'use client'` untuk komponen yang perlu interactivity.

```javascript
// src/app/counter/page.js
'use client';

import { useState } from 'react';
import { Button } from 'antd';

export default function CounterPage() {
  const [count, setCount] = useState(0);
  
  return (
    <div>
      <h1>Count: {count}</h1>
      <Button onClick={() => setCount(count + 1)}>
        Increment
      </Button>
    </div>
  );
}
```

**Kapan menggunakan Client Components:**
- Event listeners (onClick, onChange, dll)
- State dan lifecycle (useState, useEffect)
- Browser APIs (localStorage, window)
- Custom hooks
- React Context

## Page Structure

### Basic Page

```javascript
// src/app/about/page.js
export default function AboutPage() {
  return (
    <div>
      <h1>About Us</h1>
      <p>Welcome to our application</p>
    </div>
  );
}
```

### Page dengan Ant Design

```javascript
// src/app/dashboard/page.js
import { Card, Row, Col, Statistic } from 'antd';
import { UserOutlined, ShoppingOutlined } from '@ant-design/icons';

export default function DashboardPage() {
  return (
    <div style={{ padding: 24 }}>
      <h1>Dashboard</h1>
      <Row gutter={16}>
        <Col span={8}>
          <Card>
            <Statistic
              title="Total Users"
              value={1128}
              prefix={<UserOutlined />}
            />
          </Card>
        </Col>
        <Col span={8}>
          <Card>
            <Statistic
              title="Total Orders"
              value={893}
              prefix={<ShoppingOutlined />}
            />
          </Card>
        </Col>
      </Row>
    </div>
  );
}
```

## Dynamic Routes

### Single Dynamic Segment

```javascript
// src/app/users/[id]/page.js
async function getUser(id) {
  const res = await fetch(`https://api.example.com/users/${id}`);
  return res.json();
}

export default async function UserDetailPage({ params }) {
  const user = await getUser(params.id);
  
  return (
    <div>
      <h1>{user.name}</h1>
      <p>Email: {user.email}</p>
    </div>
  );
}

// Generate static params untuk static generation
export async function generateStaticParams() {
  const users = await fetch('https://api.example.com/users').then(res => res.json());
  
  return users.map(user => ({
    id: user.id.toString(),
  }));
}
```

### Catch-all Routes

```javascript
// src/app/blog/[...slug]/page.js
export default function BlogPost({ params }) {
  // /blog/a/b/c -> params.slug = ['a', 'b', 'c']
  const slug = params.slug.join('/');
  
  return <div>Blog post: {slug}</div>;
}
```

## Data Fetching

### Fetch di Server Component

```javascript
// src/app/posts/page.js
async function getPosts() {
  const res = await fetch('https://api.example.com/posts', {
    next: { revalidate: 3600 } // Revalidate setiap 1 jam
  });
  
  if (!res.ok) {
    throw new Error('Failed to fetch posts');
  }
  
  return res.json();
}

export default async function PostsPage() {
  const posts = await getPosts();
  
  return (
    <div>
      <h1>Posts</h1>
      {posts.map(post => (
        <article key={post.id}>
          <h2>{post.title}</h2>
          <p>{post.excerpt}</p>
        </article>
      ))}
    </div>
  );
}
```

### Fetch di Client Component

```javascript
// src/app/products/page.js
'use client';

import { useState, useEffect } from 'react';
import { List, Spin } from 'antd';

export default function ProductsPage() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    fetch('/api/products')
      .then(res => res.json())
      .then(data => {
        setProducts(data);
        setLoading(false);
      });
  }, []);
  
  if (loading) return <Spin size="large" />;
  
  return (
    <List
      dataSource={products}
      renderItem={item => (
        <List.Item>
          <List.Item.Meta
            title={item.name}
            description={item.description}
          />
        </List.Item>
      )}
    />
  );
}
```

## Loading States

### loading.js

```javascript
// src/app/users/loading.js
import { Spin } from 'antd';

export default function Loading() {
  return (
    <div style={{ 
      display: 'flex', 
      justifyContent: 'center', 
      alignItems: 'center',
      minHeight: '400px'
    }}>
      <Spin size="large" tip="Loading..." />
    </div>
  );
}
```

### Skeleton dengan Ant Design

```javascript
// src/app/profile/loading.js
import { Skeleton, Card } from 'antd';

export default function Loading() {
  return (
    <Card>
      <Skeleton active avatar paragraph={{ rows: 4 }} />
    </Card>
  );
}
```

## Error Handling

### error.js

```javascript
// src/app/users/error.js
'use client';

import { Button, Result } from 'antd';

export default function Error({ error, reset }) {
  return (
    <Result
      status="error"
      title="Something went wrong"
      subTitle={error.message}
      extra={
        <Button type="primary" onClick={reset}>
          Try Again
        </Button>
      }
    />
  );
}
```

### not-found.js

```javascript
// src/app/not-found.js
import { Result, Button } from 'antd';
import Link from 'next/link';

export default function NotFound() {
  return (
    <Result
      status="404"
      title="404"
      subTitle="Sorry, the page you visited does not exist."
      extra={
        <Link href="/">
          <Button type="primary">Back Home</Button>
        </Link>
      }
    />
  );
}
```

## Metadata

### Static Metadata

```javascript
// src/app/about/page.js
export const metadata = {
  title: 'About Us',
  description: 'Learn more about our company',
};

export default function AboutPage() {
  return <div>About content</div>;
}
```

### Dynamic Metadata

```javascript
// src/app/users/[id]/page.js
export async function generateMetadata({ params }) {
  const user = await fetch(`https://api.example.com/users/${params.id}`)
    .then(res => res.json());
  
  return {
    title: user.name,
    description: `Profile of ${user.name}`,
  };
}

export default async function UserPage({ params }) {
  const user = await fetch(`https://api.example.com/users/${params.id}`)
    .then(res => res.json());
  
  return <div>{user.name}</div>;
}
```

## Search Params

```javascript
// src/app/search/page.js
import { Suspense } from 'react';

function SearchResults({ searchParams }) {
  const query = searchParams.q || '';
  
  return <div>Search results for: {query}</div>;
}

export default function SearchPage({ searchParams }) {
  return (
    <div>
      <h1>Search</h1>
      <Suspense fallback={<div>Loading...</div>}>
        <SearchResults searchParams={searchParams} />
      </Suspense>
    </div>
  );
}
```

## Parallel Routes

```javascript
// src/app/dashboard/@analytics/page.js
export default function Analytics() {
  return <div>Analytics</div>;
}

// src/app/dashboard/@team/page.js
export default function Team() {
  return <div>Team</div>;
}

// src/app/dashboard/layout.js
export default function DashboardLayout({ children, analytics, team }) {
  return (
    <div>
      {children}
      <div style={{ display: 'flex' }}>
        <div>{analytics}</div>
        <div>{team}</div>
      </div>
    </div>
  );
}
```

## Revalidation

### Time-based Revalidation

```javascript
// Revalidate setiap 60 detik
fetch('https://api.example.com/data', {
  next: { revalidate: 60 }
});
```

### On-demand Revalidation

```javascript
// src/app/api/revalidate/route.js
import { revalidatePath } from 'next/cache';

export async function POST(request) {
  const path = request.nextUrl.searchParams.get('path');
  
  if (path) {
    revalidatePath(path);
    return Response.json({ revalidated: true, now: Date.now() });
  }
  
  return Response.json({ revalidated: false, now: Date.now() });
}
```
