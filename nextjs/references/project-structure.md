# Project Structure

Struktur project Next.js dengan App Router dan Ant Design.

## Root Structure

```
my-nextjs-app/
├── src/                    # Source directory
│   ├── app/               # App Router directory
│   ├── components/        # React components
│   ├── lib/               # Libraries dan utilities
│   ├── services/          # API service calls
│   ├── styles/            # Global styles
│   └── middleware.js      # Middleware (auth, security, etc)
├── public/                # Static files
├── .env.local             # Environment variables
├── .eslintrc.json         # ESLint config
├── .gitignore             # Git ignore
├── jsconfig.json          # JavaScript config
├── next.config.js         # Next.js config
├── package.json           # Dependencies
└── README.md              # Documentation
```

## App Directory (App Router)

```
src/app/
├── (auth)/                # Route group - tidak muncul di URL
│   ├── login/
│   │   └── page.js       # /login
│   └── register/
│       └── page.js       # /register
│
├── (dashboard)/           # Route group dengan layout
│   ├── layout.js         # Layout untuk dashboard
│   ├── page.js           # /dashboard
│   ├── users/
│   │   ├── page.js       # /users
│   │   ├── [id]/
│   │   │   └── page.js   # /users/[id]
│   │   └── create/
│   │       └── page.js   # /users/create
│   └── settings/
│       └── page.js       # /settings
│
├── api/                   # API Routes
│   ├── auth/
│   │   └── route.js      # /api/auth
│   └── users/
│       ├── route.js      # /api/users
│       └── [id]/
│           └── route.js  # /api/users/[id]
│
├── layout.js              # Root layout (required)
├── page.js                # Home page /
├── loading.js             # Loading UI
├── error.js               # Error UI
└── not-found.js           # 404 page
```

## Components Directory

```
src/components/
├── common/                # Komponen umum
│   ├── Button.js
│   ├── Card.js
│   ├── Modal.js
│   └── ThemeToggle.js
│
├── forms/                 # Form components
│   ├── LoginForm.js
│   ├── UserForm.js
│   └── SearchForm.js
│
├── layouts/               # Layout components
│   ├── Header.js
│   ├── Sidebar.js
│   ├── Footer.js
│   └── DashboardLayout.js
│
├── providers/             # Context providers
│   ├── ThemeProvider.js
│   └── AuthProvider.js
│
└── ui/                    # UI components
    ├── DataTable.js
    ├── StatCard.js
    └── Chart.js
```

## Lib Directory

```
src/lib/
├── hooks/                 # Custom React hooks
│   ├── useAuth.js
│   ├── useUsers.js
│   ├── useDebounce.js
│   └── useTheme.js
│
└── utils/                 # Utility functions
    ├── format.js         # Formatting helpers
    ├── validation.js     # Validation helpers
    ├── theme.js          # Theme utilities
    └── constants.js      # Constants
```

## Services Directory

```
src/services/
├── base-client.js         # Base service client
├── account-service/       # Account/Auth service
│   ├── login.js
│   ├── profile.js
│   └── index.js
├── user-service/          # User management service
│   ├── users.js
│   ├── roles.js
│   └── index.js
├── product-service/       # Product service
│   ├── products.js
│   ├── categories.js
│   └── index.js
└── order-service/         # Order service
    ├── orders.js
    ├── payments.js
    └── index.js
```

## Public Directory

```
public/
├── images/
│   ├── logo.png
│   └── avatar-default.png
├── icons/
│   └── favicon.ico
└── fonts/
    └── custom-font.woff2
```

## Styles Directory

```
src/styles/
├── globals.css           # Global styles
├── variables.css         # CSS variables
└── antd-custom.css       # Ant Design overrides
```

## File Naming Conventions

### Pages (App Router)
- `page.js` - Halaman route
- `layout.js` - Layout untuk route
- `loading.js` - Loading UI
- `error.js` - Error UI
- `not-found.js` - 404 UI
- `route.js` - API route handler

### Components
- PascalCase: `UserProfile.js`, `DataTable.js`
- Gunakan index.js untuk export multiple components

### Utilities & Hooks
- camelCase: `formatDate.js`, `useAuth.js`
- Prefix hooks dengan "use": `useDebounce.js`

## Route Groups

Route groups menggunakan `(folder)` untuk:
- Organize routes tanpa mempengaruhi URL
- Apply layout ke specific routes
- Separate concerns (auth, dashboard, admin)

```javascript
// src/app/(auth)/layout.js
export default function AuthLayout({ children }) {
  return (
    <div className="auth-container">
      {children}
    </div>
  );
}
```

## Dynamic Routes

```
src/app/
├── users/
│   └── [id]/
│       └── page.js       # /users/123
├── blog/
│   └── [...slug]/
│       └── page.js       # /blog/a/b/c (catch-all)
└── shop/
    └── [[...slug]]/
        └── page.js       # /shop atau /shop/a/b (optional catch-all)
```

## Environment Variables

```bash
# .env.local
NEXT_PUBLIC_API_URL=http://localhost:3000/api
NEXT_PUBLIC_APP_NAME=My App
API_SECRET_KEY=your-secret-key
```

- `NEXT_PUBLIC_*` - Exposed ke browser
- Tanpa prefix - Server-side only

## Configuration Files

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

### jsconfig.json
```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@/components/*": ["./src/components/*"],
      "@/lib/*": ["./src/lib/*"],
      "@/services/*": ["./src/services/*"],
      "@/styles/*": ["./src/styles/*"]
    }
  }
}
```

Dengan path aliases, import menjadi:
```javascript
import Button from '@/components/common/Button';
import { getUsers } from '@/services/user-service';
import { formatDate } from '@/lib/utils/format';
```
