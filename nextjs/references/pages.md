# Pages dengan App Router (TypeScript)

Panduan membuat dan mengatur pages di Next.js App Router dengan TypeScript.

## Server Components vs Client Components

### Server Components (Default)

Server Components adalah default di App Router. Render di server, tidak mengirim JavaScript ke client.

```tsx
// src/app/users/page.tsx
interface User {
  id: string;
  name: string;
  email: string;
}

async function getUsers(): Promise<User[]> {
  const res = await fetch('https://api.example.com/users', {
    cache: 'no-store',
  });
  return res.json();
}

export default async function UsersPage() {
  const users = await getUsers();
  
  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-4">Users</h1>
      <ul className="space-y-2">
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

```tsx
// src/app/counter/page.tsx
'use client';

import { useState } from 'react';
import { Button } from 'antd';

export default function CounterPage() {
  const [count, setCount] = useState(0);
  
  return (
    <div className="flex flex-col items-center gap-4 p-6">
      <h1 className="text-2xl">Count: {count}</h1>
      <Button type="primary" onClick={() => setCount(count + 1)}>
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

## Page dengan Ant Design + Tailwind

```tsx
// src/app/dashboard/page.tsx
import { Card, Statistic, Row, Col } from 'antd';
import { UserOutlined, CalendarOutlined } from '@ant-design/icons';

export default function DashboardPage() {
  return (
    <div className="p-6 min-h-screen bg-gray-50 dark:bg-gray-900">
      <h1 className="text-2xl font-bold mb-6">Dashboard</h1>
      <Row gutter={[16, 16]}>
        <Col xs={24} sm={12} lg={8}>
          <Card className="shadow-sm">
            <Statistic
              title="Total Pasien"
              value={1128}
              prefix={<UserOutlined />}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={8}>
          <Card className="shadow-sm">
            <Statistic
              title="Janji Temu Hari Ini"
              value={42}
              prefix={<CalendarOutlined />}
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

```tsx
// src/app/cabang/[slug]/page.tsx
interface ClinicPageProps {
  params: { slug: string };
}

interface Clinic {
  name: string;
  address: string;
  phone: string;
}

async function getClinic(slug: string): Promise<Clinic> {
  const res = await fetch(`${process.env.API_URL}/clinics/${slug}`);
  return res.json();
}

export default async function ClinicDetailPage({ params }: ClinicPageProps) {
  const clinic = await getClinic(params.slug);
  
  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold">{clinic.name}</h1>
      <p className="text-gray-600 dark:text-gray-400">{clinic.address}</p>
    </div>
  );
}

export async function generateMetadata({ params }: ClinicPageProps) {
  const clinic = await getClinic(params.slug);
  return {
    title: clinic.name,
    description: `Informasi ${clinic.name}`,
  };
}
```

## Data Fetching di Client Component

```tsx
// src/app/pencarian/page.tsx
'use client';

import { useState, useEffect } from 'react';
import { Input, List, Spin, Empty } from 'antd';
import { SearchOutlined } from '@ant-design/icons';
import { useDebounce } from '@/helpers/useDebounce';

interface SearchResult {
  id: string;
  name: string;
  type: string;
}

export default function SearchPage() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<SearchResult[]>([]);
  const [loading, setLoading] = useState(false);
  const debouncedQuery = useDebounce(query, 300);
  
  useEffect(() => {
    if (!debouncedQuery) {
      setResults([]);
      return;
    }
    
    setLoading(true);
    fetch(`/api/search?q=${encodeURIComponent(debouncedQuery)}`)
      .then(res => res.json())
      .then(data => {
        setResults(data);
        setLoading(false);
      });
  }, [debouncedQuery]);
  
  return (
    <div className="max-w-2xl mx-auto p-6">
      <Input
        size="large"
        placeholder="Cari dokter, klinik, atau layanan..."
        prefix={<SearchOutlined />}
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        allowClear
        className="mb-6"
      />
      
      {loading ? (
        <div className="flex justify-center py-8">
          <Spin size="large" />
        </div>
      ) : results.length > 0 ? (
        <List
          dataSource={results}
          renderItem={(item) => (
            <List.Item>
              <List.Item.Meta title={item.name} description={item.type} />
            </List.Item>
          )}
        />
      ) : query ? (
        <Empty description="Tidak ada hasil" />
      ) : null}
    </div>
  );
}
```

## Loading States

```tsx
// src/app/users/loading.tsx
import { Skeleton, Card } from 'antd';

export default function Loading() {
  return (
    <div className="p-6 space-y-4">
      {[1, 2, 3].map((i) => (
        <Card key={i}>
          <Skeleton active avatar paragraph={{ rows: 2 }} />
        </Card>
      ))}
    </div>
  );
}
```

## Error Handling

```tsx
// src/app/users/error.tsx
'use client';

import { Button, Result } from 'antd';

interface ErrorProps {
  error: Error & { digest?: string };
  reset: () => void;
}

export default function Error({ error, reset }: ErrorProps) {
  return (
    <Result
      status="error"
      title="Terjadi Kesalahan"
      subTitle={error.message}
      extra={
        <Button type="primary" onClick={reset}>
          Coba Lagi
        </Button>
      }
    />
  );
}
```

## Not Found

```tsx
// src/app/not-found.tsx
import { Result, Button } from 'antd';
import Link from 'next/link';

export default function NotFound() {
  return (
    <Result
      status="404"
      title="404"
      subTitle="Halaman yang Anda cari tidak ditemukan."
      extra={
        <Link href="/">
          <Button type="primary">Kembali ke Beranda</Button>
        </Link>
      }
    />
  );
}
```

## Metadata

### Static Metadata

```tsx
// src/app/tentang-kami/page.tsx
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Tentang Kami',
  description: 'Informasi tentang perusahaan kami',
};

export default function AboutPage() {
  return <div>About content</div>;
}
```

### Dynamic Metadata

```tsx
// src/app/artikel/[slug]/page.tsx
import type { Metadata } from 'next';

interface PageProps {
  params: { slug: string };
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const article = await fetch(`${process.env.API_URL}/articles/${params.slug}`)
    .then(res => res.json());
  
  return {
    title: article.title,
    description: article.excerpt,
    openGraph: {
      title: article.title,
      images: [article.thumbnail],
    },
  };
}

export default async function ArticlePage({ params }: PageProps) {
  // ...
}
```

## SEO (robots.ts & sitemap.ts)

```tsx
// src/app/robots.ts
import type { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: '*',
      allow: '/',
      disallow: '/api/',
    },
    sitemap: 'https://example.com/sitemap.xml',
  };
}
```

```tsx
// src/app/sitemap.ts
import type { MetadataRoute } from 'next';

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    { url: 'https://example.com', lastModified: new Date() },
    { url: 'https://example.com/tentang-kami', lastModified: new Date() },
  ];
}
```
