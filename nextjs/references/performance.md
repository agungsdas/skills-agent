# Performance & Optimization

Panduan optimasi performa Next.js untuk aplikasi yang cepat dan efisien.

## Image Optimization

### Next.js Image Component

```javascript
// src/components/common/OptimizedImage.js
import Image from 'next/image';

export default function OptimizedImage({ src, alt, width, height, priority = false }) {
  return (
    <Image
      src={src}
      alt={alt}
      width={width}
      height={height}
      priority={priority}
      placeholder="blur"
      blurDataURL="data:image/jpeg;base64,/9j/4AAQSkZJRg..."
      quality={85}
      sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
    />
  );
}
```

### Image Configuration

```javascript
// next.config.js
const nextConfig = {
  images: {
    formats: ['image/avif', 'image/webp'],
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
    minimumCacheTTL: 60,
    domains: ['example.com', 'cdn.example.com'],
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**.example.com',
        port: '',
        pathname: '/images/**',
      },
    ],
  },
};

module.exports = nextConfig;
```

### Responsive Images

```javascript
// src/components/ui/ResponsiveImage.js
'use client';

import Image from 'next/image';
import { useTheme } from '@/components/providers/ThemeProvider';

export default function ResponsiveImage({ src, alt, ...props }) {
  const { theme } = useTheme();
  
  return (
    <div style={{ position: 'relative', width: '100%', height: 'auto' }}>
      <Image
        src={src}
        alt={alt}
        fill
        style={{ objectFit: 'cover' }}
        sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
        {...props}
      />
    </div>
  );
}
```

## Font Optimization

### Next.js Font Optimization

```javascript
// src/app/layout.js
import { Inter, Roboto_Mono } from 'next/font/google';

const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-inter',
});

const robotoMono = Roboto_Mono({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-roboto-mono',
});

export default function RootLayout({ children }) {
  return (
    <html lang="id" className={`${inter.variable} ${robotoMono.variable}`}>
      <body className={inter.className}>
        {children}
      </body>
    </html>
  );
}
```

### Local Fonts

```javascript
// src/app/layout.js
import localFont from 'next/font/local';

const myFont = localFont({
  src: [
    {
      path: '../fonts/MyFont-Regular.woff2',
      weight: '400',
      style: 'normal',
    },
    {
      path: '../fonts/MyFont-Bold.woff2',
      weight: '700',
      style: 'normal',
    },
  ],
  variable: '--font-my-font',
  display: 'swap',
});

export default function RootLayout({ children }) {
  return (
    <html lang="id" className={myFont.variable}>
      <body className={myFont.className}>
        {children}
      </body>
    </html>
  );
}
```

## Code Splitting & Lazy Loading

### Dynamic Imports

```javascript
// src/app/dashboard/page.js
'use client';

import { useState } from 'react';
import dynamic from 'next/dynamic';
import { Spin } from 'antd';

// Lazy load heavy components
const HeavyChart = dynamic(() => import('@/components/ui/HeavyChart'), {
  loading: () => <Spin size="large" />,
  ssr: false, // Disable SSR for this component
});

const DataTable = dynamic(() => import('@/components/ui/DataTable'), {
  loading: () => <Spin />,
});

export default function DashboardPage() {
  const [showChart, setShowChart] = useState(false);
  
  return (
    <div>
      <h1>Dashboard</h1>
      
      <button onClick={() => setShowChart(true)}>
        Show Chart
      </button>
      
      {showChart && <HeavyChart />}
      
      <DataTable />
    </div>
  );
}
```

### Route-based Code Splitting

```javascript
// Automatic dengan App Router
// Setiap page.js otomatis code-split

// Manual dynamic import untuk conditional routes
// src/components/layouts/ConditionalLayout.js
'use client';

import dynamic from 'next/dynamic';

const AdminLayout = dynamic(() => import('./AdminLayout'));
const UserLayout = dynamic(() => import('./UserLayout'));

export default function ConditionalLayout({ userRole, children }) {
  const Layout = userRole === 'admin' ? AdminLayout : UserLayout;
  
  return <Layout>{children}</Layout>;
}
```

## Bundle Analysis

### Setup Bundle Analyzer

```bash
npm install @next/bundle-analyzer
```

```javascript
// next.config.js
const withBundleAnalyzer = require('@next/bundle-analyzer')({
  enabled: process.env.ANALYZE === 'true',
});

const nextConfig = {
  // your config
};

module.exports = withBundleAnalyzer(nextConfig);
```

```json
// package.json
{
  "scripts": {
    "analyze": "ANALYZE=true npm run build"
  }
}
```

### Tree Shaking

```javascript
// WRONG - imports entire library
import _ from 'lodash';

// CORRECT - imports only what you need
import debounce from 'lodash/debounce';
import throttle from 'lodash/throttle';

// WRONG - imports all icons
import * as Icons from '@ant-design/icons';

// CORRECT - imports specific icons
import { UserOutlined, SettingOutlined } from '@ant-design/icons';
```

## Caching Strategies

### Static Generation (SSG)

```javascript
// src/app/blog/[slug]/page.js
// Generate static pages at build time
export async function generateStaticParams() {
  const posts = await getPosts();
  
  return posts.map((post) => ({
    slug: post.slug,
  }));
}

export default async function BlogPost({ params }) {
  const post = await getPost(params.slug);
  
  return (
    <article>
      <h1>{post.title}</h1>
      <div>{post.content}</div>
    </article>
  );
}
```

### Incremental Static Regeneration (ISR)

```javascript
// src/app/products/page.js
// Revalidate every 60 seconds
export const revalidate = 60;

export default async function ProductsPage() {
  const products = await fetch('https://api.example.com/products', {
    next: { revalidate: 60 }
  }).then(res => res.json());
  
  return (
    <div>
      {products.map(product => (
        <div key={product.id}>{product.name}</div>
      ))}
    </div>
  );
}
```

### Client-side Caching

```javascript
// src/lib/utils/cache.js
class Cache {
  constructor(ttl = 5 * 60 * 1000) { // 5 minutes default
    this.cache = new Map();
    this.ttl = ttl;
  }
  
  set(key, value) {
    this.cache.set(key, {
      value,
      timestamp: Date.now(),
    });
  }
  
  get(key) {
    const item = this.cache.get(key);
    
    if (!item) return null;
    
    // Check if expired
    if (Date.now() - item.timestamp > this.ttl) {
      this.cache.delete(key);
      return null;
    }
    
    return item.value;
  }
  
  clear() {
    this.cache.clear();
  }
}

export const apiCache = new Cache();

// Usage
import { apiCache } from '@/lib/utils/cache';

export async function getUsers() {
  const cached = apiCache.get('users');
  if (cached) return cached;
  
  const users = await fetch('/api/users').then(res => res.json());
  apiCache.set('users', users);
  
  return users;
}
```

## React Performance

### Memoization

```javascript
// src/components/ui/ExpensiveComponent.js
'use client';

import { memo, useMemo, useCallback } from 'react';

const ExpensiveComponent = memo(function ExpensiveComponent({ data, onUpdate }) {
  // Memoize expensive calculations
  const processedData = useMemo(() => {
    return data.map(item => ({
      ...item,
      computed: expensiveCalculation(item),
    }));
  }, [data]);
  
  // Memoize callbacks
  const handleUpdate = useCallback((id) => {
    onUpdate(id);
  }, [onUpdate]);
  
  return (
    <div>
      {processedData.map(item => (
        <div key={item.id} onClick={() => handleUpdate(item.id)}>
          {item.computed}
        </div>
      ))}
    </div>
  );
});

export default ExpensiveComponent;
```

### Virtual Scrolling

```javascript
// src/components/ui/VirtualList.js
'use client';

import { FixedSizeList } from 'react-window';

export default function VirtualList({ items }) {
  const Row = ({ index, style }) => (
    <div style={style}>
      {items[index].name}
    </div>
  );
  
  return (
    <FixedSizeList
      height={600}
      itemCount={items.length}
      itemSize={50}
      width="100%"
    >
      {Row}
    </FixedSizeList>
  );
}
```

## Database Optimization

### Query Optimization

```javascript
// WRONG - N+1 query problem
const users = await prisma.user.findMany();
for (const user of users) {
  const posts = await prisma.post.findMany({
    where: { userId: user.id }
  });
}

// CORRECT - Use include/select
const users = await prisma.user.findMany({
  include: {
    posts: true,
  },
});

// CORRECT - Select only needed fields
const users = await prisma.user.findMany({
  select: {
    id: true,
    name: true,
    email: true,
  },
});
```

### Connection Pooling

```javascript
// src/lib/db/prisma.js
import { PrismaClient } from '@prisma/client';

const globalForPrisma = global;

export const prisma = globalForPrisma.prisma || new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
});

if (process.env.NODE_ENV !== 'production') {
  globalForPrisma.prisma = prisma;
}
```

## API Optimization

### Response Compression

```javascript
// next.config.js
const nextConfig = {
  compress: true, // Enable gzip compression
};

module.exports = nextConfig;
```

### Pagination

```javascript
// src/app/api/users/route.js
export async function GET(request) {
  const { searchParams } = new URL(request.url);
  const page = parseInt(searchParams.get('page') || '1');
  const limit = parseInt(searchParams.get('limit') || '10');
  const skip = (page - 1) * limit;
  
  const [users, total] = await Promise.all([
    prisma.user.findMany({
      skip,
      take: limit,
      select: {
        id: true,
        name: true,
        email: true,
      },
    }),
    prisma.user.count(),
  ]);
  
  return Response.json({
    data: users,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    },
  });
}
```

### Response Caching

```javascript
// src/app/api/products/route.js
export async function GET() {
  const products = await getProducts();
  
  return Response.json(products, {
    headers: {
      'Cache-Control': 'public, s-maxage=60, stale-while-revalidate=30',
    },
  });
}
```

## Build Optimization

### Next.js Config Optimization

```javascript
// next.config.js
const nextConfig = {
  // Enable SWC minification
  swcMinify: true,
  
  // Remove console logs in production
  compiler: {
    removeConsole: process.env.NODE_ENV === 'production' ? {
      exclude: ['error', 'warn'],
    } : false,
  },
  
  // Optimize CSS
  experimental: {
    optimizeCss: true,
  },
  
  // Reduce bundle size
  modularizeImports: {
    '@ant-design/icons': {
      transform: '@ant-design/icons/{{member}}',
    },
    'lodash': {
      transform: 'lodash/{{member}}',
    },
  },
  
  // Production source maps (optional)
  productionBrowserSourceMaps: false,
};

module.exports = nextConfig;
```

### Webpack Optimization

```javascript
// next.config.js
const nextConfig = {
  webpack: (config, { isServer }) => {
    // Optimize bundle
    if (!isServer) {
      config.optimization.splitChunks = {
        chunks: 'all',
        cacheGroups: {
          default: false,
          vendors: false,
          // Vendor chunk
          vendor: {
            name: 'vendor',
            chunks: 'all',
            test: /node_modules/,
            priority: 20,
          },
          // Common chunk
          common: {
            name: 'common',
            minChunks: 2,
            chunks: 'all',
            priority: 10,
            reuseExistingChunk: true,
            enforce: true,
          },
        },
      };
    }
    
    return config;
  },
};

module.exports = nextConfig;
```

## Runtime Performance

### Debouncing & Throttling

```javascript
// src/lib/hooks/useDebounce.js
'use client';

import { useState, useEffect } from 'react';

export function useDebounce(value, delay = 500) {
  const [debouncedValue, setDebouncedValue] = useState(value);
  
  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);
    
    return () => clearTimeout(handler);
  }, [value, delay]);
  
  return debouncedValue;
}

// Usage
import { useDebounce } from '@/lib/hooks/useDebounce';

function SearchComponent() {
  const [search, setSearch] = useState('');
  const debouncedSearch = useDebounce(search, 500);
  
  useEffect(() => {
    if (debouncedSearch) {
      // Perform search
      searchAPI(debouncedSearch);
    }
  }, [debouncedSearch]);
  
  return <input value={search} onChange={(e) => setSearch(e.target.value)} />;
}
```

### Request Deduplication

```javascript
// src/lib/utils/request-dedup.js
const pendingRequests = new Map();

export async function dedupedFetch(url, options = {}) {
  const key = `${url}-${JSON.stringify(options)}`;
  
  // Return existing promise if request is pending
  if (pendingRequests.has(key)) {
    return pendingRequests.get(key);
  }
  
  // Create new request
  const promise = fetch(url, options)
    .then(res => res.json())
    .finally(() => {
      pendingRequests.delete(key);
    });
  
  pendingRequests.set(key, promise);
  
  return promise;
}
```

## Monitoring Performance

### Performance Metrics

```javascript
// src/lib/utils/performance-monitor.js
export function measurePerformance(name, fn) {
  const start = performance.now();
  
  const result = fn();
  
  if (result instanceof Promise) {
    return result.finally(() => {
      const duration = performance.now() - start;
      console.log(`${name}: ${duration.toFixed(2)}ms`);
    });
  }
  
  const duration = performance.now() - start;
  console.log(`${name}: ${duration.toFixed(2)}ms`);
  
  return result;
}

// Usage
const users = await measurePerformance('Fetch Users', () => 
  fetch('/api/users').then(res => res.json())
);
```

### Lighthouse CI

```yaml
# .github/workflows/lighthouse.yml
name: Lighthouse CI

on:
  pull_request:
    branches: [main]

jobs:
  lighthouse:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build
        run: npm run build
      
      - name: Run Lighthouse CI
        uses: treosh/lighthouse-ci-action@v9
        with:
          urls: |
            http://localhost:3000
            http://localhost:3000/dashboard
          uploadArtifacts: true
```

## Performance Checklist

### Development
- [ ] Use Next.js Image component
- [ ] Optimize fonts with next/font
- [ ] Implement code splitting
- [ ] Use dynamic imports for heavy components
- [ ] Memoize expensive calculations
- [ ] Debounce/throttle frequent operations
- [ ] Implement virtual scrolling for long lists

### Build
- [ ] Enable SWC minification
- [ ] Remove console logs in production
- [ ] Analyze bundle size
- [ ] Optimize images (AVIF/WebP)
- [ ] Tree shake unused code
- [ ] Configure proper caching headers

### Runtime
- [ ] Use ISR for dynamic content
- [ ] Implement client-side caching
- [ ] Optimize database queries
- [ ] Use connection pooling
- [ ] Implement pagination
- [ ] Compress API responses

### Monitoring
- [ ] Track Web Vitals
- [ ] Monitor bundle size
- [ ] Set performance budgets
- [ ] Run Lighthouse audits
- [ ] Monitor API response times
- [ ] Track error rates

## Performance Targets

### Core Web Vitals
- **LCP (Largest Contentful Paint)**: < 2.5s
- **FID (First Input Delay)**: < 100ms
- **CLS (Cumulative Layout Shift)**: < 0.1

### Other Metrics
- **TTFB (Time to First Byte)**: < 600ms
- **FCP (First Contentful Paint)**: < 1.8s
- **TTI (Time to Interactive)**: < 3.8s
- **Bundle Size**: < 200KB (gzipped)

## Best Practices

1. **Measure First**: Always measure before optimizing
2. **Prioritize**: Focus on biggest impact optimizations
3. **Progressive Enhancement**: Start with basics, enhance progressively
4. **Lazy Load**: Load resources only when needed
5. **Cache Aggressively**: Cache at multiple levels
6. **Optimize Images**: Use modern formats and proper sizing
7. **Minimize JavaScript**: Reduce bundle size
8. **Server-side Rendering**: Use SSR/SSG when appropriate
9. **Monitor Continuously**: Track performance metrics
10. **Test Regularly**: Run performance tests in CI/CD
