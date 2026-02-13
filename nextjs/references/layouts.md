# Layouts

Panduan membuat dan mengatur layouts di Next.js App Router.

## Root Layout (Required)

Root layout adalah layout utama yang wajib ada di `app/layout.js`. WAJIB include ThemeProvider untuk light/dark mode support.

```javascript
// src/app/layout.js
import { AntdRegistry } from '@ant-design/nextjs-registry';
import ThemeProvider from '@/components/providers/ThemeProvider';
import '@/styles/globals.css';

export const metadata = {
  title: 'My App',
  description: 'My Next.js Application',
};

export default function RootLayout({ children }) {
  return (
    <html lang="id" suppressHydrationWarning>
      <body>
        <AntdRegistry>
          <ThemeProvider>
            {children}
          </ThemeProvider>
        </AntdRegistry>
      </body>
    </html>
  );
}
```

## Nested Layouts

Layout bisa nested untuk apply layout ke specific routes.

```javascript
// src/app/(dashboard)/layout.js
import { Layout } from 'antd';
import Sidebar from '@/components/layouts/Sidebar';
import Header from '@/components/layouts/Header';

const { Content } = Layout;

export default function DashboardLayout({ children }) {
  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Sidebar />
      <Layout>
        <Header />
        <Content style={{ margin: '24px 16px', padding: 24 }}>
          {children}
        </Content>
      </Layout>
    </Layout>
  );
}
```

## Layout Components

### Header Component

```javascript
// src/components/layouts/Header.js
'use client';

import { Layout, Avatar, Dropdown, Space } from 'antd';
import { UserOutlined, LogoutOutlined, SettingOutlined } from '@ant-design/icons';
import { useRouter } from 'next/navigation';
import { useTheme } from '@/components/providers/ThemeProvider';
import ThemeToggle from '@/components/common/ThemeToggle';

const { Header: AntHeader } = Layout;

export default function Header() {
  const router = useRouter();
  const { theme } = useTheme();
  
  const headerStyle = {
    background: theme === 'dark' ? '#1f1f1f' : '#ffffff',
    borderBottom: `1px solid ${theme === 'dark' ? '#434343' : '#f0f0f0'}`,
    padding: '0 24px',
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
  };
  
  const menuItems = [
    {
      key: 'profile',
      icon: <UserOutlined />,
      label: 'Profile',
      onClick: () => router.push('/profile'),
    },
    {
      key: 'settings',
      icon: <SettingOutlined />,
      label: 'Settings',
      onClick: () => router.push('/settings'),
    },
    {
      type: 'divider',
    },
    {
      key: 'logout',
      icon: <LogoutOutlined />,
      label: 'Logout',
      onClick: () => {
        // Handle logout
        router.push('/login');
      },
    },
  ];
  
  return (
    <AntHeader style={headerStyle}>
      <div style={{ fontSize: 18, fontWeight: 'bold' }}>
        My Application
      </div>
      
      <Space size="large">
        <ThemeToggle />
        <Dropdown menu={{ items: menuItems }} placement="bottomRight">
          <Space style={{ cursor: 'pointer' }}>
            <Avatar icon={<UserOutlined />} />
            <span>John Doe</span>
          </Space>
        </Dropdown>
      </Space>
    </AntHeader>
  );
}
```

### Sidebar Component

```javascript
// src/components/layouts/Sidebar.js
'use client';

import { Layout, Menu } from 'antd';
import { 
  DashboardOutlined, 
  UserOutlined, 
  ShoppingOutlined,
  SettingOutlined 
} from '@ant-design/icons';
import { useRouter, usePathname } from 'next/navigation';

const { Sider } = Layout;

export default function Sidebar() {
  const router = useRouter();
  const pathname = usePathname();
  
  const menuItems = [
    {
      key: '/dashboard',
      icon: <DashboardOutlined />,
      label: 'Dashboard',
    },
    {
      key: '/users',
      icon: <UserOutlined />,
      label: 'Users',
    },
    {
      key: '/products',
      icon: <ShoppingOutlined />,
      label: 'Products',
    },
    {
      key: '/settings',
      icon: <SettingOutlined />,
      label: 'Settings',
    },
  ];
  
  const handleMenuClick = ({ key }) => {
    router.push(key);
  };
  
  return (
    <Sider
      breakpoint="lg"
      collapsedWidth="0"
      style={{
        overflow: 'auto',
        height: '100vh',
        position: 'sticky',
        top: 0,
        left: 0,
      }}
    >
      <div style={{ 
        height: 64, 
        margin: 16,
        background: 'rgba(255, 255, 255, 0.2)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: '#fff',
        fontSize: 18,
        fontWeight: 'bold'
      }}>
        LOGO
      </div>
      
      <Menu
        theme="dark"
        mode="inline"
        selectedKeys={[pathname]}
        items={menuItems}
        onClick={handleMenuClick}
      />
    </Sider>
  );
}
```

### Footer Component

```javascript
// src/components/layouts/Footer.js
import { Layout } from 'antd';

const { Footer: AntFooter } = Layout;

export default function Footer() {
  return (
    <AntFooter style={{ textAlign: 'center' }}>
      My App ©{new Date().getFullYear()} Created with Next.js & Ant Design
    </AntFooter>
  );
}
```

## Auth Layout

Layout khusus untuk halaman authentication.

```javascript
// src/app/(auth)/layout.js
import { Layout, Card } from 'antd';
import Image from 'next/image';

const { Content } = Layout;

export default function AuthLayout({ children }) {
  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Content style={{
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
      }}>
        <Card 
          style={{ 
            width: 400,
            boxShadow: '0 4px 12px rgba(0,0,0,0.15)'
          }}
        >
          <div style={{ 
            textAlign: 'center', 
            marginBottom: 24 
          }}>
            <Image 
              src="/images/logo.png" 
              alt="Logo" 
              width={80} 
              height={80}
            />
            <h2 style={{ marginTop: 16 }}>Welcome Back</h2>
          </div>
          {children}
        </Card>
      </Content>
    </Layout>
  );
}
```

## Route Groups

Route groups untuk organize layouts tanpa mempengaruhi URL.

```
app/
├── (auth)/
│   ├── layout.js          # Auth layout
│   ├── login/
│   │   └── page.js        # /login
│   └── register/
│       └── page.js        # /register
│
├── (dashboard)/
│   ├── layout.js          # Dashboard layout
│   ├── page.js            # /dashboard
│   └── users/
│       └── page.js        # /users
│
└── layout.js              # Root layout
```

## Layout dengan Context

```javascript
// src/app/(dashboard)/layout.js
'use client';

import { Layout } from 'antd';
import { useState, createContext, useContext } from 'react';
import Sidebar from '@/components/layouts/Sidebar';
import Header from '@/components/layouts/Header';

const { Content } = Layout;

const LayoutContext = createContext();

export const useLayout = () => useContext(LayoutContext);

export default function DashboardLayout({ children }) {
  const [collapsed, setCollapsed] = useState(false);
  
  return (
    <LayoutContext.Provider value={{ collapsed, setCollapsed }}>
      <Layout style={{ minHeight: '100vh' }}>
        <Sidebar collapsed={collapsed} />
        <Layout>
          <Header onToggle={() => setCollapsed(!collapsed)} />
          <Content style={{ margin: '24px 16px', padding: 24 }}>
            {children}
          </Content>
        </Layout>
      </Layout>
    </LayoutContext.Provider>
  );
}
```

## Responsive Layout

```javascript
// src/components/layouts/ResponsiveLayout.js
'use client';

import { Layout, Grid } from 'antd';
import { useState } from 'react';
import Sidebar from './Sidebar';
import Header from './Header';

const { Content } = Layout;
const { useBreakpoint } = Grid;

export default function ResponsiveLayout({ children }) {
  const [collapsed, setCollapsed] = useState(false);
  const screens = useBreakpoint();
  
  // Auto collapse pada mobile
  const isMobile = !screens.lg;
  
  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Sidebar 
        collapsed={isMobile ? true : collapsed}
        onCollapse={setCollapsed}
      />
      <Layout>
        <Header 
          collapsed={collapsed}
          onToggle={() => setCollapsed(!collapsed)}
        />
        <Content style={{ 
          margin: isMobile ? '16px 8px' : '24px 16px',
          padding: isMobile ? 16 : 24
        }}>
          {children}
        </Content>
      </Layout>
    </Layout>
  );
}
```

## Layout dengan Breadcrumb

```javascript
// src/components/layouts/LayoutWithBreadcrumb.js
'use client';

import { Layout, Breadcrumb } from 'antd';
import { HomeOutlined } from '@ant-design/icons';
import { usePathname } from 'next/navigation';
import Link from 'next/link';

const { Content } = Layout;

export default function LayoutWithBreadcrumb({ children }) {
  const pathname = usePathname();
  
  const pathSegments = pathname.split('/').filter(segment => segment);
  
  const breadcrumbItems = [
    {
      title: (
        <Link href="/">
          <HomeOutlined />
        </Link>
      ),
    },
    ...pathSegments.map((segment, index) => {
      const path = `/${pathSegments.slice(0, index + 1).join('/')}`;
      const isLast = index === pathSegments.length - 1;
      
      return {
        title: isLast ? (
          <span>{segment}</span>
        ) : (
          <Link href={path}>{segment}</Link>
        ),
      };
    }),
  ];
  
  return (
    <Content style={{ padding: '0 24px' }}>
      <Breadcrumb 
        items={breadcrumbItems}
        style={{ margin: '16px 0' }}
      />
      <div style={{ 
        background: '#fff', 
        padding: 24, 
        minHeight: 360 
      }}>
        {children}
      </div>
    </Content>
  );
}
```

## Template vs Layout

Template mirip dengan layout, tapi re-render pada navigation.

```javascript
// src/app/template.js
'use client';

import { motion } from 'framer-motion';

export default function Template({ children }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
    >
      {children}
    </motion.div>
  );
}
```

## Layout Best Practices

1. **Root Layout**: Selalu ada, setup global providers di sini
2. **Nested Layouts**: Gunakan untuk specific sections (dashboard, admin)
3. **Route Groups**: Organize routes dengan layout berbeda
4. **Client Components**: Gunakan 'use client' untuk interactive layouts
5. **Responsive**: Pertimbangkan mobile/tablet layouts
6. **Performance**: Avoid re-rendering dengan proper state management
7. **Ant Design**: Gunakan Layout components dari antd untuk consistency
