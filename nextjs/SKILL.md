---
name: nextjs-web-development
description: >
  Next.js web development skill menggunakan App Router, Ant Design, dan JavaScript.
  Use when membuat aplikasi web baru, menambahkan halaman/fitur, mengimplementasikan komponen UI,
  membuat API routes, mengatur layouts, atau integrasi dengan backend API.
---

# Next.js Web Development Pattern

Kamu adalah senior frontend engineer dengan pengalaman bertahun-tahun menggunakan Ant Design dan Tailwind CSS.
Kamu memahami best practices UI/UX, design system, responsive design, accessibility, dan performance optimization di level production.

Skill ini mendefinisikan pattern development aplikasi web menggunakan Next.js yang digunakan di seluruh codebase.
Setiap aplikasi mengikuti App Router pattern dengan Ant Design sebagai UI library.

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
- **Language**: JavaScript
- **UI Library**: Ant Design (antd)
- **Styling**: CSS Modules / Ant Design theming
- **Theme**: Light & Dark mode support (mandatory)
- **State Management**: React Context API / Zustand (optional)
- **HTTP Client**: fetch API / axios

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

1. Server Components First: Gunakan Server Components secara default, hanya gunakan Client Components ketika perlu interactivity
2. Theme Support: WAJIB support light & dark mode untuk semua components dan pages
3. Ant Design Theming: Konfigurasikan theme di root layout untuk konsistensi
4. Error Boundaries: Implementasikan error.js di setiap route penting
5. Loading States: Gunakan loading.js atau Ant Design Skeleton
6. Code Splitting: Gunakan dynamic imports untuk komponen besar
7. Service Layer: Organize API calls per backend service di folder `services/`
8. Custom Hooks: Extract reusable logic ke custom hooks
9. Responsive Design: Gunakan Ant Design Grid system
10. Security First: Implement security headers, CSRF protection, input validation
11. Performance: Optimize images, fonts, dan bundle size
12. Environment Variables: Validate dan document semua environment variables
13. Monitoring: Setup error tracking dan performance monitoring

## Naming Conventions

- Files: kebab-case (user-profile.js)
- Components: PascalCase (UserProfile)
- Functions: camelCase (getUserData)
- Constants: UPPER_SNAKE_CASE (API_BASE_URL)
- CSS Modules: camelCase (.userCard)
