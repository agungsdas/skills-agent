# Next.js Web Development Skill

Skill untuk pengembangan aplikasi web menggunakan Next.js dengan Ant Design component library, JavaScript, dan App Router.

## Kapan Menggunakan Skill Ini

Gunakan skill ini ketika:
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

Lihat detail struktur project di [project-structure.md](references/project-structure.md)

```
src/
├── app/
│   ├── (auth)/              # Route group untuk authentication
│   │   ├── login/
│   │   └── register/
│   ├── (dashboard)/         # Route group untuk dashboard
│   │   ├── layout.js
│   │   └── page.js
│   ├── api/                 # API routes
│   ├── layout.js            # Root layout
│   └── page.js              # Home page
├── components/
│   ├── common/              # Komponen umum
│   ├── forms/               # Form components
│   ├── layouts/             # Layout components
│   └── providers/           # Context providers
├── lib/
│   ├── hooks/               # Custom React hooks
│   └── utils/               # Utility functions
├── services/                # API service calls per backend service
│   ├── account-service/     # Account service APIs
│   ├── user-service/        # User service APIs
│   └── product-service/     # Product service APIs
└── styles/                  # Global styles
public/                      # Static assets (outside src)
```

## Komponen Utama

### 1. Pages (App Router)
Lihat detail di [pages.md](references/pages.md)
- Server Components (default)
- Client Components (dengan 'use client')
- Loading states
- Error handling

### 2. Layouts
Lihat detail di [layouts.md](references/layouts.md)
- Root layout
- Nested layouts
- Route groups

### 3. Components
Lihat detail di [components.md](references/components.md)
- Ant Design components
- Custom reusable components
- Form components

### 4. API Routes
Lihat detail di [api-routes.md](references/api-routes.md)
- GET, POST, PUT, DELETE handlers
- Middleware
- Error handling

### 5. Services
Lihat detail di [services.md](references/services.md)
- API service calls per backend service
- Service-specific endpoints
- Request/response handling

### 6. Hooks & Utils
Lihat detail di [hooks-utils.md](references/hooks-utils.md)
- Custom hooks
- Helper functions
- Theme management

### 7. Theme System
Lihat detail di [theme.md](references/theme.md)
- Light & Dark mode (mandatory)
- Theme configuration
- Component styling for both themes

### 8. Middleware
Lihat detail di [middleware.md](references/middleware.md)
- Authentication & authorization
- Request/response modification
- Rate limiting & security

### 9. Security
Lihat detail di [security.md](references/security.md)
- Security headers & CSP
- Authentication best practices
- Input validation & sanitization
- CSRF & XSS protection

### 10. Monitoring & Error Tracking
Lihat detail di [monitoring.md](references/monitoring.md)
- Error tracking dengan Sentry
- Logging dengan Winston
- Performance monitoring
- Health checks & metrics

### 11. Deployment
Lihat detail di [deployment.md](references/deployment.md)
- Vercel deployment
- Docker & Docker Compose
- CI/CD pipelines
- Production best practices

### 12. Performance & Optimization
Lihat detail di [performance.md](references/performance.md)
- Image & font optimization
- Code splitting & lazy loading
- Caching strategies
- Bundle analysis & optimization
- Database & API optimization

### 13. Environment Variables & Configuration
Lihat detail di [environment.md](references/environment.md)
- Environment variables management
- Multi-environment setup
- Configuration validation
- Feature flags
- Secrets management

## Workflow Pengembangan

### Membuat Halaman Baru

1. Buat folder di `app/` sesuai route yang diinginkan
2. Buat file `page.js` untuk halaman utama
3. Buat file `loading.js` untuk loading state (optional)
4. Buat file `error.js` untuk error handling (optional)

### Membuat Komponen Baru

1. Tentukan apakah komponen perlu interaktif (Client Component)
2. Buat file di folder `components/` yang sesuai
3. Gunakan Ant Design components sebagai base
4. Export komponen untuk digunakan di pages

### Membuat API Route

1. Buat folder di `app/api/` sesuai endpoint
2. Buat file `route.js`
3. Export fungsi handler (GET, POST, dll)
4. Implementasikan logic dan error handling

## Best Practices

1. **Server Components First**: Gunakan Server Components secara default, hanya gunakan Client Components ketika perlu interactivity
2. **Theme Support**: WAJIB support light & dark mode untuk semua components dan pages
3. **Ant Design Theming**: Konfigurasikan theme di root layout untuk konsistensi
4. **Error Boundaries**: Implementasikan error.js di setiap route penting
5. **Loading States**: Gunakan loading.js atau Ant Design Skeleton
6. **Code Splitting**: Gunakan dynamic imports untuk komponen besar
7. **Service Layer**: Organize API calls per backend service di folder `services/`
8. **Custom Hooks**: Extract reusable logic ke custom hooks
9. **Responsive Design**: Gunakan Ant Design Grid system
10. **Security First**: Implement security headers, CSRF protection, input validation
11. **Performance**: Optimize images, fonts, dan bundle size
12. **Environment Variables**: Validate dan document semua environment variables
13. **Monitoring**: Setup error tracking dan performance monitoring
14. **Testing**: Test di semua environments sebelum deploy

## Naming Conventions

- **Files**: kebab-case (user-profile.js)
- **Components**: PascalCase (UserProfile)
- **Functions**: camelCase (getUserData)
- **Constants**: UPPER_SNAKE_CASE (API_BASE_URL)
- **CSS Modules**: camelCase (.userCard)

## References

Dokumentasi lengkap untuk setiap aspek:

- [Project Structure](references/project-structure.md) - Struktur folder dan file
- [Pages](references/pages.md) - Membuat dan mengatur pages
- [Layouts](references/layouts.md) - Layout patterns
- [Components](references/components.md) - Komponen dengan Ant Design
- [API Routes](references/api-routes.md) - Backend API endpoints
- [Services](references/services.md) - API service layer organization
- [Theme](references/theme.md) - Light & Dark mode implementation
- [Hooks & Utils](references/hooks-utils.md) - Custom hooks dan utilities
- [Middleware](references/middleware.md) - Authentication, authorization, security
- [Security](references/security.md) - Security best practices
- [Monitoring](references/monitoring.md) - Error tracking & monitoring
- [Deployment](references/deployment.md) - Production deployment
- [Performance](references/performance.md) - Performance & optimization
- [Environment](references/environment.md) - Environment variables & configuration

## Contoh Implementasi

Lihat contoh lengkap di masing-masing reference file untuk:
- Authentication flow
- CRUD operations
- Form handling dengan Ant Design
- Data fetching patterns
- State management
