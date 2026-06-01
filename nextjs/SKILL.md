---
name: nextjs-web-development
description: >
  Next.js web development skill menggunakan App Router, Ant Design, Tailwind CSS, dan TypeScript.
  Use when membuat aplikasi web baru, menambahkan halaman/fitur, mengimplementasikan komponen UI,
  membuat API routes, mengatur layouts, atau integrasi dengan backend API.
---

# Next.js Web Development Pattern

Kamu adalah senior frontend engineer dengan pengalaman bertahun-tahun menggunakan Ant Design dan Tailwind CSS.
Kamu memahami best practices UI/UX, design system, responsive design, accessibility, dan performance optimization di level production.

Skill ini mendefinisikan pattern development aplikasi web menggunakan Next.js yang digunakan di seluruh codebase.
Setiap aplikasi mengikuti App Router pattern dengan Ant Design sebagai UI component library dan Tailwind CSS untuk utility styling.

## When to use this skill

- Membuat aplikasi web baru dengan Next.js
- Menambahkan halaman atau fitur baru
- Mengimplementasikan komponen UI dengan Ant Design
- Mengatur routing dengan App Router
- Membuat API routes
- Mengimplementasikan layouts dan templates
- Menangani state management
- Integrasi dengan backend API

## Tech Stack

- **Framework**: Next.js 14+ (App Router)
- **Language**: TypeScript
- **UI Library**: Ant Design (antd) — untuk komponen UI (Form, Table, Modal, Button, dll)
- **Styling**: Tailwind CSS + Ant Design theming (berjalan berdampingan)
- **Theme**: Light & Dark mode support (mandatory)
- **State Management**: Redux Toolkit + Redux Persist
- **HTTP Client**: fetch API / custom fetcher
- **Animation**: Framer Motion
- **Slider**: Keen Slider
- **Analytics**: Mixpanel
- **SEO**: next-seo

## Ant Design + Tailwind CSS Strategy

Kedua library berjalan berdampingan:
- **Ant Design** → untuk UI components (Form, Table, Modal, Button, Select, DatePicker, dll)
- **Tailwind CSS** → untuk layout, spacing, custom styling, responsive utilities

```tsx
// Contoh: Ant Design component + Tailwind layout
import { Button, Card } from 'antd';

export default function MyComponent() {
  return (
    <div className="flex flex-col gap-4 p-6 max-w-4xl mx-auto">
      <Card className="shadow-md rounded-lg">
        <h2 className="text-xl font-semibold mb-4">Title</h2>
        <Button type="primary" className="mt-2">
          Submit
        </Button>
      </Card>
    </div>
  );
}
```

### Kapan pakai Ant Design vs Tailwind:
- **Ant Design**: Form controls, Table, Modal, Notification, Drawer, Tabs, Menu, Pagination
- **Tailwind**: Layout (flex, grid), spacing (p-4, m-2), typography, colors, responsive breakpoints, custom animations

## Project Structure

Refer to: `references/project-structure.md`

## Component Guide

### 1. Pages (App Router)

Server Components, Client Components, loading states, dan error handling.

Refer to: `references/pages.md`

### 2. Layouts

Root layout, nested layouts, dan route groups.

Refer to: `references/layouts.md`

### 3. Components

Ant Design components, custom reusable components, dan form components.

Refer to: `references/components.md`

### 4. API Routes

GET, POST, PUT, DELETE handlers, middleware, dan error handling.

Refer to: `references/api-routes.md`

### 5. Services

API service calls per backend service, service-specific endpoints, dan request/response handling.

Refer to: `references/services.md`

### 6. Hooks & Utils

Custom hooks, helper functions, dan theme management.

Refer to: `references/hooks-utils.md`

### 7. Theme System

Light & Dark mode (mandatory), theme configuration, dan component styling.

Refer to: `references/theme.md`

### 8. Middleware

Authentication & authorization, request/response modification, dan rate limiting.

Refer to: `references/middleware.md`

### 9. Security

Security headers, CSP, authentication best practices, input validation, CSRF & XSS protection.

Refer to: `references/security.md`

### 10. Monitoring & Error Tracking

Error tracking dengan Sentry, logging dengan Winston, performance monitoring, health checks.

Refer to: `references/monitoring.md`

### 11. Deployment

Vercel deployment, Docker & Docker Compose, CI/CD pipelines, production best practices.

Refer to: `references/deployment.md`

### 12. Performance & Optimization

Image & font optimization, code splitting, caching strategies, bundle analysis.

Refer to: `references/performance.md`

### 13. Environment Variables & Configuration

Environment variables management, multi-environment setup, configuration validation, feature flags.

Refer to: `references/environment.md`

## Critical Rules

1. **TypeScript**: Semua file menggunakan `.tsx` / `.ts` — BUKAN `.js` / `.jsx`
2. **Server Components First**: Gunakan Server Components secara default, hanya gunakan Client Components ketika perlu interactivity
3. **Theme Support**: WAJIB support light & dark mode untuk semua components dan pages
4. **Ant Design + Tailwind**: Gunakan Ant Design untuk UI components, Tailwind untuk layout & utility styling
5. **Error Boundaries**: Implementasikan error.tsx di setiap route penting
6. **Loading States**: Gunakan loading.tsx atau Ant Design Skeleton
7. **Code Splitting**: Gunakan dynamic imports untuk komponen besar
8. **Service Layer**: Organize API calls per backend service di folder `services/`
9. **Custom Hooks**: Extract reusable logic ke custom hooks
10. **Responsive Design**: Gunakan Tailwind responsive utilities (sm:, md:, lg:) + Ant Design Grid
11. **Security First**: Implement security headers, CSRF protection, input validation
12. **Performance**: Optimize images, fonts, dan bundle size
13. **Environment Variables**: Validate dan document semua environment variables
14. **State Management**: Gunakan Redux Toolkit + Redux Persist untuk global state
15. **Type Safety**: Definisikan interfaces/types untuk semua props, API responses, dan state

## Naming Conventions

- Files: kebab-case (`user-profile.tsx`, `auth-service.ts`)
- Components: PascalCase (`UserProfile`)
- Functions/hooks: camelCase (`getUserData`, `useAuth`)
- Constants: UPPER_SNAKE_CASE (`API_BASE_URL`)
- Types/Interfaces: PascalCase (`UserProfile`, `IAuthService`)
- CSS/Tailwind: kebab-case for custom classes

## TypeScript Conventions

```typescript
// Interface untuk props
interface UserCardProps {
  name: string;
  email: string;
  avatar?: string;
  onEdit?: (id: string) => void;
}

// Interface untuk API response
interface ApiResponse<T> {
  status: boolean;
  message: string;
  data: T;
  meta?: {
    page: number;
    per_page: number;
    total: number;
    total_page: number;
  };
}

// Type untuk state
type AuthState = {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
};
```
