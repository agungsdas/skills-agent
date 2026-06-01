# Services Layer (TypeScript)

Panduan organizing API calls per backend service. Services layer memisahkan API calls berdasarkan backend service yang berbeda.

## Structure

```
src/services/
├── Auth/                  # Authentication service
│   ├── index.ts
│   ├── login.ts
│   └── types.ts
├── Appointment/           # Appointment service
│   ├── index.ts
│   ├── booking.ts
│   └── types.ts
├── Clinics/               # Clinic service
│   ├── index.ts
│   ├── list.ts
│   └── types.ts
├── Patient/               # Patient service
│   ├── index.ts
│   └── types.ts
└── readme.md
```

## Base Fetcher

```typescript
// src/helpers/fetcher.ts
import Cookies from 'js-cookie';

interface FetcherOptions extends RequestInit {
  params?: Record<string, string | number | undefined>;
}

interface ApiResponse<T = unknown> {
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

const BASE_URL = process.env.NEXT_PUBLIC_API_URL;

export async function fetcher<T>(
  endpoint: string,
  options: FetcherOptions = {}
): Promise<ApiResponse<T>> {
  const { params, ...fetchOptions } = options;
  
  let url = `${BASE_URL}${endpoint}`;
  
  if (params) {
    const searchParams = new URLSearchParams();
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined) {
        searchParams.append(key, String(value));
      }
    });
    url += `?${searchParams.toString()}`;
  }
  
  const token = Cookies.get('token');
  
  const config: RequestInit = {
    ...fetchOptions,
    headers: {
      'Content-Type': 'application/json',
      ...(token && { Authorization: `Bearer ${token}` }),
      ...fetchOptions.headers,
    },
  };
  
  const response = await fetch(url, config);
  const data = await response.json();
  
  if (!response.ok) {
    if (response.status === 401) {
      // Handle token expired
      Cookies.remove('token');
      window.location.href = '/login';
    }
    throw new Error(data.message || 'Request failed');
  }
  
  return data;
}
```

## Service Types

```typescript
// src/services/Auth/types.ts
export interface LoginPayload {
  email: string;
  password: string;
}

export interface LoginResponse {
  token: string;
  refreshToken: string;
  user: {
    id: string;
    name: string;
    email: string;
    userType: string;
  };
}

export interface RegisterPayload {
  name: string;
  email: string;
  password: string;
  phone: string;
}
```

```typescript
// src/services/Clinics/types.ts
export interface Clinic {
  refId: string;
  name: string;
  address: string;
  phone: string;
  latitude: number;
  longitude: number;
  imageUrl?: string;
}

export interface ClinicListParams {
  page?: number;
  per_page?: number;
  keyword?: string;
  area_ref_id?: string;
}
```

## Service Implementation

```typescript
// src/services/Auth/login.ts
import { fetcher } from '@/helpers/fetcher';
import type { LoginPayload, LoginResponse } from './types';

export async function login(payload: LoginPayload) {
  return fetcher<LoginResponse>('/auth/login', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export async function refreshToken(token: string) {
  return fetcher<{ token: string }>('/auth/refresh', {
    method: 'POST',
    body: JSON.stringify({ refreshToken: token }),
  });
}

export async function logout() {
  return fetcher('/auth/logout', { method: 'POST' });
}
```

```typescript
// src/services/Clinics/list.ts
import { fetcher } from '@/helpers/fetcher';
import type { Clinic, ClinicListParams } from './types';

export async function getClinics(params?: ClinicListParams) {
  return fetcher<Clinic[]>('/clinics', { params: params as Record<string, string> });
}

export async function getClinicBySlug(slug: string) {
  return fetcher<Clinic>(`/clinics/${slug}`);
}

export async function getClinicDoctors(clinicRefId: string) {
  return fetcher<Doctor[]>(`/clinics/${clinicRefId}/doctors`);
}
```

## Index Export

```typescript
// src/services/Auth/index.ts
export * from './login';
export * from './types';
```

```typescript
// src/services/Clinics/index.ts
export * from './list';
export * from './types';
```

## Usage in Components

```tsx
// src/app/cabang/page.tsx
'use client';

import { useState, useEffect } from 'react';
import { List, Spin, Input } from 'antd';
import { getClinics } from '@/services/Clinics';
import type { Clinic } from '@/services/Clinics/types';
import ClinicCard from '@/components/cards/ClinicCard';

export default function ClinicsPage() {
  const [clinics, setClinics] = useState<Clinic[]>([]);
  const [loading, setLoading] = useState(true);
  const [keyword, setKeyword] = useState('');
  
  useEffect(() => {
    fetchClinics();
  }, [keyword]);
  
  const fetchClinics = async () => {
    try {
      setLoading(true);
      const response = await getClinics({ keyword, page: 1, per_page: 20 });
      setClinics(response.data);
    } catch (error) {
      console.error('Failed to fetch clinics:', error);
    } finally {
      setLoading(false);
    }
  };
  
  return (
    <div className="p-6">
      <Input.Search
        placeholder="Cari cabang..."
        onSearch={setKeyword}
        className="mb-6 max-w-md"
      />
      
      {loading ? (
        <div className="flex justify-center py-8">
          <Spin size="large" />
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {clinics.map((clinic) => (
            <ClinicCard key={clinic.refId} clinic={clinic} />
          ))}
        </div>
      )}
    </div>
  );
}
```

## Token Refresh Manager

```typescript
// src/helpers/tokenRefreshManager.ts
import Cookies from 'js-cookie';
import { refreshToken } from '@/services/Auth';

let isRefreshing = false;
let refreshSubscribers: ((token: string) => void)[] = [];

function subscribeTokenRefresh(cb: (token: string) => void) {
  refreshSubscribers.push(cb);
}

function onRefreshed(token: string) {
  refreshSubscribers.forEach((cb) => cb(token));
  refreshSubscribers = [];
}

export async function handleTokenRefresh(): Promise<string> {
  if (isRefreshing) {
    return new Promise((resolve) => {
      subscribeTokenRefresh(resolve);
    });
  }
  
  isRefreshing = true;
  
  try {
    const currentRefreshToken = Cookies.get('refreshToken');
    if (!currentRefreshToken) throw new Error('No refresh token');
    
    const response = await refreshToken(currentRefreshToken);
    const newToken = response.data.token;
    
    Cookies.set('token', newToken);
    onRefreshed(newToken);
    
    return newToken;
  } catch (error) {
    Cookies.remove('token');
    Cookies.remove('refreshToken');
    window.location.href = '/login';
    throw error;
  } finally {
    isRefreshing = false;
  }
}
```

## Best Practices

1. **Service Separation**: Pisahkan API calls berdasarkan backend service (PascalCase folder)
2. **Type Safety**: Definisikan types untuk semua request/response di `types.ts`
3. **Base Fetcher**: Gunakan shared fetcher untuk consistency (auth, error handling)
4. **Token Management**: Handle token refresh secara otomatis
5. **Error Handling**: Implement proper error handling dengan typed errors
6. **Cookie-based Auth**: Gunakan `js-cookie` untuk token storage (bukan localStorage)
7. **Environment Variables**: Store service URLs di environment variables
8. **Index Exports**: Export semua functions dari `index.ts` untuk clean imports
