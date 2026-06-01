# Theme System - Light & Dark Mode (TypeScript + Ant Design + Tailwind)

Panduan implementasi light & dark mode di Next.js dengan Ant Design + Tailwind CSS.
**WAJIB** support kedua mode untuk semua development.

## Setup Theme Provider

### Root Layout dengan Theme

```tsx
// src/app/layout.tsx
import { AntdRegistry } from '@ant-design/nextjs-registry';
import ThemeProvider from '@/components/providers/ThemeProvider';
import '@/styles/globals.css';

export const metadata = {
  title: 'My App',
  description: 'My Next.js Application',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
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

```tsx
// src/components/providers/ThemeProvider.tsx
'use client';

import { ConfigProvider, theme as antdTheme } from 'antd';
import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';

type ThemeMode = 'light' | 'dark';

interface ThemeContextType {
  theme: ThemeMode;
  toggleTheme: () => void;
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

export function useTheme(): ThemeContextType {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within ThemeProvider');
  }
  return context;
}

interface ThemeProviderProps {
  children: ReactNode;
}

export default function ThemeProvider({ children }: ThemeProviderProps) {
  const [theme, setTheme] = useState<ThemeMode>('light');
  const [mounted, setMounted] = useState(false);
  
  useEffect(() => {
    const savedTheme = (localStorage.getItem('theme') as ThemeMode) || 'light';
    setTheme(savedTheme);
    setMounted(true);
  }, []);
  
  useEffect(() => {
    if (mounted) {
      localStorage.setItem('theme', theme);
      document.documentElement.setAttribute('data-theme', theme);
      // Untuk Tailwind dark mode
      if (theme === 'dark') {
        document.documentElement.classList.add('dark');
      } else {
        document.documentElement.classList.remove('dark');
      }
    }
  }, [theme, mounted]);
  
  const toggleTheme = () => {
    setTheme(prev => prev === 'light' ? 'dark' : 'light');
  };
  
  const antdConfig = {
    algorithm: theme === 'dark' ? antdTheme.darkAlgorithm : antdTheme.defaultAlgorithm,
    token: {
      colorPrimary: '#1890ff',
      borderRadius: 6,
    },
  };
  
  if (!mounted) return null;
  
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

```tsx
// src/components/commons/ThemeToggle.tsx
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

## Tailwind Dark Mode Config

```typescript
// tailwind.config.ts
import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./src/**/*.{js,ts,jsx,tsx,mdx}'],
  darkMode: 'class', // PENTING: gunakan class-based dark mode
  theme: {
    extend: {},
  },
  plugins: [],
  corePlugins: {
    preflight: false, // Disable agar tidak conflict dengan Ant Design
  },
};

export default config;
```

## Global Styles

```css
/* src/styles/globals.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --bg-primary: #ffffff;
  --bg-secondary: #f5f5f5;
  --text-primary: #000000;
  --text-secondary: #666666;
}

.dark {
  --bg-primary: #1f1f1f;
  --bg-secondary: #2a2a2a;
  --text-primary: #ffffff;
  --text-secondary: #a0a0a0;
}

body {
  background-color: var(--bg-primary);
  color: var(--text-primary);
  transition: background-color 0.3s ease, color 0.3s ease;
}
```

## Component dengan Dark Mode (Tailwind)

```tsx
// Gunakan dark: prefix untuk dark mode styling
<div className="bg-white dark:bg-gray-900 text-black dark:text-white p-6 rounded-lg">
  <h2 className="text-xl font-bold text-gray-800 dark:text-gray-100">Title</h2>
  <p className="text-gray-600 dark:text-gray-400">Description</p>
</div>
```

## Ant Design + Tailwind Dark Mode Strategy

1. **Ant Design components** — otomatis handle dark mode via `ConfigProvider` + `darkAlgorithm`
2. **Custom styling** — gunakan Tailwind `dark:` prefix
3. **CSS Variables** — untuk warna yang perlu konsisten di kedua mode

```tsx
// Contoh: Ant Design Card + Tailwind dark mode wrapper
import { Card, Statistic } from 'antd';

export default function StatsCard() {
  return (
    <div className="p-4 bg-gray-50 dark:bg-gray-800 rounded-xl">
      <Card className="shadow-sm">
        <Statistic title="Total Pasien" value={1128} />
      </Card>
    </div>
  );
}
```

## Best Practices

1. **Mandatory Support**: Semua components dan pages WAJIB support light & dark mode
2. **Tailwind dark: prefix**: Gunakan untuk custom styling
3. **Ant Design ConfigProvider**: Handle dark mode untuk semua Ant Design components
4. **class-based dark mode**: Tailwind `darkMode: 'class'` agar sinkron dengan ThemeProvider
5. **Smooth Transitions**: Tambahkan transition untuk smooth theme switching
6. **Persist Theme**: Save user preference di localStorage
7. **SSR Handling**: Handle hydration dengan `suppressHydrationWarning` dan mounted check
8. **Disable Preflight**: `corePlugins: { preflight: false }` agar Tailwind tidak override Ant Design base styles
