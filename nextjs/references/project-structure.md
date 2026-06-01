# Project Structure

Struktur project Next.js dengan App Router, TypeScript, Ant Design, dan Tailwind CSS.

## Root Structure

```
my-nextjs-app/
├── src/                    # Source directory
│   ├── app/               # App Router directory
│   ├── components/        # React components
│   ├── constants/         # Constants & enums
│   ├── helpers/           # Helper functions & utilities
│   ├── hooks/             # Custom React hooks
│   ├── services/          # API service calls (per backend service)
│   ├── store/             # Redux store & slices
│   ├── styles/            # Global styles & CSS
│   └── middleware.ts      # Next.js middleware (auth, etc)
├── public/                # Static files (images, icons)
├── .env.local             # Environment variables (local)
├── .eslintrc.json         # ESLint config
├── .gitignore             # Git ignore
├── next.config.js         # Next.js config
├── package.json           # Dependencies
├── postcss.config.js      # PostCSS config (for Tailwind)
├── tailwind.config.ts     # Tailwind CSS config
├── tsconfig.json          # TypeScript config
└── README.md              # Documentation
```

## App Directory (App Router)

```
src/app/
├── (public)/              # Route group — halaman publik
│   ├── login/
│   │   └── page.tsx       # /login
│   ├── daftar/
│   │   └── page.tsx       # /daftar
│   └── lupa-password/
│       └── page.tsx       # /lupa-password
│
├── (main)/                # Route group — halaman utama
│   ├── layout.tsx         # Layout untuk main pages
│   ├── cabang/
│   │   ├── page.tsx       # /cabang
│   │   └── [slug]/
│   │       └── page.tsx   # /cabang/[slug]
│   ├── janji-temu/
│   │   └── page.tsx       # /janji-temu
│   └── pengaturan/
│       └── page.tsx       # /pengaturan
│
├── api/                   # API Routes (optional)
│   └── auth/
│       └── route.ts       # /api/auth
│
├── layout.tsx             # Root layout (required)
├── page.tsx               # Home page /
├── loading.tsx            # Loading UI
├── error.tsx              # Error UI
├── not-found.tsx          # 404 page
├── robots.ts              # robots.txt generation
└── sitemap.ts             # sitemap.xml generation
```

## Components Directory

```
src/components/
├── banners/               # Banner components
│   ├── HeroBanner.tsx
│   └── PromoBanner.tsx
│
├── cards/                 # Card components
│   ├── DoctorCard.tsx
│   ├── ClinicCard.tsx
│   └── PromoCard.tsx
│
├── commons/               # Common/shared components
│   ├── Button.tsx
│   ├── SearchBar.tsx
│   └── ThemeToggle.tsx
│
├── floating/              # Floating components (FAB, chat widget)
│   └── FloatingButton.tsx
│
├── layouts/               # Layout components
│   ├── Header.tsx
│   ├── Footer.tsx
│   ├── Sidebar.tsx
│   └── Navbar.tsx
│
├── modals/                # Modal components
│   ├── ConfirmModal.tsx
│   └── FormModal.tsx
│
├── page/                  # Page-specific components
│   ├── home/
│   └── appointment/
│
└── sections/              # Section components (reusable page sections)
    ├── DoctorSection.tsx
    └── TestimonialSection.tsx
```

## Services Directory

```
src/services/
├── Auth/                  # Authentication service
│   ├── index.ts
│   ├── login.ts
│   └── types.ts
│
├── Appointment/           # Appointment service
│   ├── index.ts
│   ├── booking.ts
│   └── types.ts
│
├── Clinics/               # Clinic service
│   ├── index.ts
│   ├── list.ts
│   └── types.ts
│
├── Patient/               # Patient service
│   ├── index.ts
│   ├── profile.ts
│   └── types.ts
│
└── readme.md              # Service documentation
```

## Hooks Directory

```
src/hooks/
├── components/            # Hooks untuk specific components
│   ├── useSearchBar.ts
│   └── useInfiniteScroll.ts
│
├── pages/                 # Hooks untuk specific pages
│   ├── useHomePage.ts
│   └── useAppointmentPage.ts
│
├── sections/              # Hooks untuk sections
│   └── useDoctorSection.ts
│
└── usePageTracking.ts     # Global page tracking hook
```

## Store Directory (Redux)

```
src/store/
├── slices/                # Redux slices
│   ├── authSlice.ts
│   ├── appointmentSlice.ts
│   └── clinicSlice.ts
│
├── combinedReducers.ts    # Combined reducers
└── index.ts               # Store configuration
```

## Helpers Directory

```
src/helpers/
├── appointment/           # Domain-specific helpers
│   └── formatSchedule.ts
├── booking/
│   └── calculatePrice.ts
├── cookie/
│   └── cookieManager.ts
├── formatter/
│   ├── dateFormatter.ts
│   └── currencyFormatter.ts
├── mixpanel/
│   └── trackEvent.ts
├── fetcher.ts             # Base HTTP fetcher
├── cryptoUtils.ts         # Encryption utilities
├── compressImage.ts       # Image compression
├── tokenRefreshManager.ts # Token refresh logic
└── redirectToAuth.ts      # Auth redirect helper
```

## Constants Directory

```
src/constants/
├── appointments/
│   └── statusEnum.ts
├── payment/
│   └── methodEnum.ts
├── bookingEnum.ts
├── genderType.ts
├── daysEnum.ts
└── seoMeta.ts
```

## Styles Directory

```
src/styles/
├── globals.css            # Global styles + Tailwind directives
├── calendar-full.css      # Custom calendar styles
├── modal.css              # Custom modal styles
└── content.css            # Content/rich-text styles
```

## File Naming Conventions

### Pages (App Router)
- `page.tsx` - Halaman route
- `layout.tsx` - Layout untuk route
- `loading.tsx` - Loading UI
- `error.tsx` - Error UI
- `not-found.tsx` - 404 UI
- `route.ts` - API route handler

### Components
- PascalCase: `UserProfile.tsx`, `DataTable.tsx`
- Gunakan index.ts untuk export multiple components

### Utilities, Hooks, Services
- camelCase: `formatDate.ts`, `useAuth.ts`
- Prefix hooks dengan "use": `useDebounce.ts`

## Configuration Files

### tsconfig.json
```json
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

### tailwind.config.ts
```typescript
import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      // Custom theme extensions
    },
  },
  plugins: [],
  // PENTING: corePlugins preflight false agar tidak conflict dengan Ant Design
  corePlugins: {
    preflight: false,
  },
};

export default config;
```

### globals.css (Tailwind directives)
```css
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Custom global styles */
```

### next.config.js
```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    domains: ['example.com'],
  },
};

module.exports = nextConfig;
```

## Path Aliases

Dengan `@/*` alias di tsconfig, import menjadi:
```typescript
import { DoctorCard } from '@/components/cards/DoctorCard';
import { useAuth } from '@/hooks/useAuth';
import { AuthService } from '@/services/Auth';
import { formatDate } from '@/helpers/formatter/dateFormatter';
import { BOOKING_STATUS } from '@/constants/bookingEnum';
```
