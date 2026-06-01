# Layouts (TypeScript)

Panduan membuat dan mengatur layouts di Next.js App Router dengan TypeScript.

## Root Layout (Required)

Root layout adalah layout utama yang wajib ada di `app/layout.tsx`. WAJIB include ThemeProvider dan ReduxProvider.

```tsx
// src/app/layout.tsx
import type { Metadata } from 'next';
import { AntdRegistry } from '@ant-design/nextjs-registry';
import ThemeProvider from '@/components/providers/ThemeProvider';
import ReduxProvider from '@/components/providers/ReduxProvider';
import '@/styles/globals.css';

export const metadata: Metadata = {
  title: 'My App',
  description: 'My Next.js Application',
};

interface RootLayoutProps {
  children: React.ReactNode;
}

export default function RootLayout({ children }: RootLayoutProps) {
  return (
    <html lang="id" suppressHydrationWarning>
      <body>
        <AntdRegistry>
          <ReduxProvider>
            <ThemeProvider>
              {children}
            </ThemeProvider>
          </ReduxProvider>
        </AntdRegistry>
      </body>
    </html>
  );
}
```

## Nested Layouts

Layout bisa nested untuk apply layout ke specific routes.

```tsx
// src/app/(main)/layout.tsx
import Header from '@/components/layouts/Header';
import Footer from '@/components/layouts/Footer';

interface MainLayoutProps {
  children: React.ReactNode;
}

export default function MainLayout({ children }: MainLayoutProps) {
  return (
    <div className="min-h-screen flex flex-col">
      <Header />
      <main className="flex-1">
        {children}
      </main>
      <Footer />
    </div>
  );
}
```

## Dashboard Layout (Ant Design + Tailwind)

```tsx
// src/app/(dashboard)/layout.tsx
'use client';

import { Layout, Menu } from 'antd';
import { DashboardOutlined, UserOutlined, SettingOutlined } from '@ant-design/icons';
import { useRouter, usePathname } from 'next/navigation';
import type { ReactNode } from 'react';

const { Sider, Content } = Layout;

interface DashboardLayoutProps {
  children: ReactNode;
}

export default function DashboardLayout({ children }: DashboardLayoutProps) {
  const router = useRouter();
  const pathname = usePathname();
  
  const menuItems = [
    { key: '/dashboard', icon: <DashboardOutlined />, label: 'Dashboard' },
    { key: '/users', icon: <UserOutlined />, label: 'Users' },
    { key: '/settings', icon: <SettingOutlined />, label: 'Settings' },
  ];
  
  return (
    <Layout className="min-h-screen">
      <Sider
        breakpoint="lg"
        collapsedWidth="0"
        className="shadow-md"
      >
        <div className="h-16 flex items-center justify-center">
          <h1 className="text-white text-lg font-bold">Admin</h1>
        </div>
        <Menu
          theme="dark"
          mode="inline"
          selectedKeys={[pathname]}
          items={menuItems}
          onClick={({ key }) => router.push(key)}
        />
      </Sider>
      <Layout>
        <Content className="p-6 bg-gray-50 dark:bg-gray-900">
          {children}
        </Content>
      </Layout>
    </Layout>
  );
}
```

## Route Groups

Route groups menggunakan `(folder)` untuk organize routes tanpa mempengaruhi URL.

```
src/app/
├── (public)/              # Halaman publik (tanpa auth)
│   ├── layout.tsx         # Layout tanpa sidebar
│   ├── login/page.tsx
│   └── daftar/page.tsx
│
├── (main)/                # Halaman utama (dengan header/footer)
│   ├── layout.tsx         # Layout dengan header + footer
│   ├── page.tsx           # Home /
│   ├── cabang/page.tsx
│   └── janji-temu/page.tsx
│
└── (dashboard)/           # Admin area
    ├── layout.tsx         # Layout dengan sidebar
    └── pengaturan/page.tsx
```

## Auth Layout (Public Pages)

```tsx
// src/app/(public)/layout.tsx
interface AuthLayoutProps {
  children: React.ReactNode;
}

export default function AuthLayout({ children }: AuthLayoutProps) {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100 dark:bg-gray-900">
      <div className="w-full max-w-md p-8 bg-white dark:bg-gray-800 rounded-xl shadow-lg">
        {children}
      </div>
    </div>
  );
}
```

## Best Practices

1. **TypeScript**: Selalu type children props dengan `React.ReactNode`
2. **Root Layout**: WAJIB include AntdRegistry, ReduxProvider, ThemeProvider
3. **Route Groups**: Gunakan `(folder)` untuk organize tanpa affect URL
4. **Server vs Client**: Layout default Server Component, tambah 'use client' jika perlu interactivity
5. **Responsive**: Gunakan Tailwind responsive utilities untuk layout
6. **Dark Mode**: Pastikan layout support dark mode via Tailwind `dark:` prefix
7. **Metadata**: Definisikan metadata di layout untuk SEO
