# Theme System - Light & Dark Mode

Panduan implementasi light & dark mode di Next.js dengan Ant Design. **WAJIB** support kedua mode untuk semua development.

## Setup Theme Provider

### Root Layout dengan Theme

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

### Theme Provider Component

```javascript
// src/components/providers/ThemeProvider.js
'use client';

import { ConfigProvider, theme as antdTheme } from 'antd';
import { createContext, useContext, useEffect, useState } from 'react';

const ThemeContext = createContext();

export function useTheme() {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within ThemeProvider');
  }
  return context;
}

export default function ThemeProvider({ children }) {
  const [theme, setTheme] = useState('light');
  const [mounted, setMounted] = useState(false);
  
  // Load theme dari localStorage
  useEffect(() => {
    const savedTheme = localStorage.getItem('theme') || 'light';
    setTheme(savedTheme);
    setMounted(true);
  }, []);
  
  // Save theme ke localStorage
  useEffect(() => {
    if (mounted) {
      localStorage.setItem('theme', theme);
      document.documentElement.setAttribute('data-theme', theme);
    }
  }, [theme, mounted]);
  
  const toggleTheme = () => {
    setTheme(prev => prev === 'light' ? 'dark' : 'light');
  };
  
  // Ant Design theme configuration
  const antdConfig = {
    algorithm: theme === 'dark' ? antdTheme.darkAlgorithm : antdTheme.defaultAlgorithm,
    token: {
      colorPrimary: '#1890ff',
      borderRadius: 6,
      // Light mode colors
      ...(theme === 'light' && {
        colorBgContainer: '#ffffff',
        colorText: '#000000',
        colorTextSecondary: '#666666',
        colorBorder: '#d9d9d9',
      }),
      // Dark mode colors
      ...(theme === 'dark' && {
        colorBgContainer: '#1f1f1f',
        colorText: '#ffffff',
        colorTextSecondary: '#a0a0a0',
        colorBorder: '#434343',
      }),
    },
  };
  
  // Prevent flash of unstyled content
  if (!mounted) {
    return null;
  }
  
  return (
    <ThemeContext.Provider value={{ theme, toggleTheme }}>
      <ConfigProvider theme={antdConfig}>
        {children}
      </ConfigProvider>
    </ThemeContext.Provider>
  );
}
```

## Theme Toggle Component

```javascript
// src/components/common/ThemeToggle.js
'use client';

import { Switch } from 'antd';
import { MoonOutlined, SunOutlined } from '@ant-design/icons';
import { useTheme } from '@/components/providers/ThemeProvider';

export default function ThemeToggle() {
  const { theme, toggleTheme } = useTheme();
  
  return (
    <Switch
      checked={theme === 'dark'}
      onChange={toggleTheme}
      checkedChildren={<MoonOutlined />}
      unCheckedChildren={<SunOutlined />}
    />
  );
}
```

## Global Styles dengan Theme

```css
/* src/styles/globals.css */

:root {
  /* Light mode variables */
  --bg-primary: #ffffff;
  --bg-secondary: #f5f5f5;
  --text-primary: #000000;
  --text-secondary: #666666;
  --border-color: #d9d9d9;
  --shadow: rgba(0, 0, 0, 0.1);
}

[data-theme='dark'] {
  /* Dark mode variables */
  --bg-primary: #1f1f1f;
  --bg-secondary: #2a2a2a;
  --text-primary: #ffffff;
  --text-secondary: #a0a0a0;
  --border-color: #434343;
  --shadow: rgba(0, 0, 0, 0.3);
}

body {
  background-color: var(--bg-primary);
  color: var(--text-primary);
  transition: background-color 0.3s ease, color 0.3s ease;
}

.card {
  background-color: var(--bg-primary);
  border: 1px solid var(--border-color);
  box-shadow: 0 2px 8px var(--shadow);
}

.text-secondary {
  color: var(--text-secondary);
}
```

## Component dengan Theme Support

### Card Component

```javascript
// src/components/common/ThemedCard.js
'use client';

import { Card } from 'antd';
import { useTheme } from '@/components/providers/ThemeProvider';

export default function ThemedCard({ children, ...props }) {
  const { theme } = useTheme();
  
  const cardStyle = {
    backgroundColor: theme === 'dark' ? '#1f1f1f' : '#ffffff',
    borderColor: theme === 'dark' ? '#434343' : '#d9d9d9',
  };
  
  return (
    <Card style={cardStyle} {...props}>
      {children}
    </Card>
  );
}
```

### Page dengan Theme

```javascript
// src/app/dashboard/page.js
'use client';

import { Card, Row, Col, Statistic } from 'antd';
import { UserOutlined, ShoppingOutlined } from '@ant-design/icons';
import { useTheme } from '@/components/providers/ThemeProvider';
import ThemeToggle from '@/components/common/ThemeToggle';

export default function DashboardPage() {
  const { theme } = useTheme();
  
  const containerStyle = {
    padding: 24,
    minHeight: '100vh',
    backgroundColor: theme === 'dark' ? '#141414' : '#f0f2f5',
  };
  
  return (
    <div style={containerStyle}>
      <div style={{ 
        display: 'flex', 
        justifyContent: 'space-between',
        marginBottom: 24 
      }}>
        <h1>Dashboard</h1>
        <ThemeToggle />
      </div>
      
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

## CSS Modules dengan Theme

```javascript
// src/components/ui/ProductCard.js
'use client';

import { Card } from 'antd';
import { useTheme } from '@/components/providers/ThemeProvider';
import styles from './ProductCard.module.css';

export default function ProductCard({ product }) {
  const { theme } = useTheme();
  
  return (
    <Card 
      className={`${styles.card} ${theme === 'dark' ? styles.dark : styles.light}`}
      cover={<img alt={product.name} src={product.image} />}
    >
      <h3 className={styles.title}>{product.name}</h3>
      <p className={styles.price}>${product.price}</p>
    </Card>
  );
}
```

```css
/* src/components/ui/ProductCard.module.css */

.card {
  transition: all 0.3s ease;
}

.card.light {
  background-color: #ffffff;
  border-color: #d9d9d9;
}

.card.dark {
  background-color: #1f1f1f;
  border-color: #434343;
}

.title {
  color: var(--text-primary);
  margin-bottom: 8px;
}

.price {
  color: var(--text-secondary);
  font-size: 18px;
  font-weight: bold;
}
```

## Layout dengan Theme

```javascript
// src/components/layouts/Header.js
'use client';

import { Layout, Avatar, Dropdown, Space } from 'antd';
import { UserOutlined, LogoutOutlined } from '@ant-design/icons';
import { useTheme } from '@/components/providers/ThemeProvider';
import ThemeToggle from '@/components/common/ThemeToggle';

const { Header: AntHeader } = Layout;

export default function Header() {
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
    },
    {
      type: 'divider',
    },
    {
      key: 'logout',
      icon: <LogoutOutlined />,
      label: 'Logout',
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

## useTheme Hook

```javascript
// src/lib/hooks/useTheme.js
'use client';

import { useContext } from 'react';
import { ThemeContext } from '@/components/providers/ThemeProvider';

export function useTheme() {
  const context = useContext(ThemeContext);
  
  if (!context) {
    throw new Error('useTheme must be used within ThemeProvider');
  }
  
  return context;
}

// Usage:
// const { theme, toggleTheme } = useTheme();
```

## Theme-aware Utilities

```javascript
// src/lib/utils/theme.js

export function getThemeColor(theme, lightColor, darkColor) {
  return theme === 'dark' ? darkColor : lightColor;
}

export function getThemeStyles(theme) {
  return {
    background: theme === 'dark' ? '#1f1f1f' : '#ffffff',
    color: theme === 'dark' ? '#ffffff' : '#000000',
    borderColor: theme === 'dark' ? '#434343' : '#d9d9d9',
  };
}

export function getCardStyles(theme) {
  return {
    backgroundColor: theme === 'dark' ? '#1f1f1f' : '#ffffff',
    borderColor: theme === 'dark' ? '#434343' : '#d9d9d9',
    boxShadow: theme === 'dark' 
      ? '0 2px 8px rgba(0, 0, 0, 0.3)' 
      : '0 2px 8px rgba(0, 0, 0, 0.1)',
  };
}

// Usage:
// import { getThemeStyles } from '@/lib/utils/theme';
// const styles = getThemeStyles(theme);
```

## Ant Design Component Customization

```javascript
// src/components/ui/CustomButton.js
'use client';

import { Button } from 'antd';
import { useTheme } from '@/components/providers/ThemeProvider';

export default function CustomButton({ children, variant = 'primary', ...props }) {
  const { theme } = useTheme();
  
  const buttonStyle = {
    ...(variant === 'ghost' && {
      borderColor: theme === 'dark' ? '#434343' : '#d9d9d9',
      color: theme === 'dark' ? '#ffffff' : '#000000',
    }),
  };
  
  return (
    <Button 
      type={variant}
      style={buttonStyle}
      {...props}
    >
      {children}
    </Button>
  );
}
```

## Best Practices

1. **Mandatory Support**: Semua components dan pages WAJIB support light & dark mode
2. **CSS Variables**: Gunakan CSS variables untuk consistency
3. **Ant Design Theme**: Leverage Ant Design's theme system
4. **Smooth Transitions**: Tambahkan transition untuk smooth theme switching
5. **Persist Theme**: Save user preference di localStorage
6. **SSR Handling**: Handle hydration dengan suppressHydrationWarning
7. **Test Both Modes**: Selalu test di kedua mode sebelum deploy
8. **Accessibility**: Pastikan contrast ratio memenuhi WCAG standards
9. **Performance**: Avoid re-renders dengan proper memoization
10. **Consistent Colors**: Gunakan theme-aware utilities untuk consistency

## Color Palette

### Light Mode
- Background Primary: `#ffffff`
- Background Secondary: `#f5f5f5`
- Text Primary: `#000000`
- Text Secondary: `#666666`
- Border: `#d9d9d9`
- Primary: `#1890ff`

### Dark Mode
- Background Primary: `#1f1f1f`
- Background Secondary: `#2a2a2a`
- Text Primary: `#ffffff`
- Text Secondary: `#a0a0a0`
- Border: `#434343`
- Primary: `#1890ff`

## Testing Checklist

Sebelum deploy, pastikan:
- [ ] Semua pages berfungsi di light mode
- [ ] Semua pages berfungsi di dark mode
- [ ] Theme toggle berfungsi dengan baik
- [ ] Theme preference tersimpan di localStorage
- [ ] Tidak ada flash of unstyled content
- [ ] Semua text readable di kedua mode
- [ ] Semua borders visible di kedua mode
- [ ] Ant Design components styled correctly
- [ ] Custom components styled correctly
- [ ] Images/icons visible di kedua mode
