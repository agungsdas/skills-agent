# Custom Hooks & Utilities (TypeScript)

Panduan membuat custom hooks dan utility functions dengan TypeScript.

## Custom Hooks

### useDebounce Hook

```typescript
// src/helpers/useDebounce.ts
'use client';

import { useState, useEffect } from 'react';

export function useDebounce<T>(value: T, delay: number = 500): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);
  
  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);
    
    return () => clearTimeout(handler);
  }, [value, delay]);
  
  return debouncedValue;
}
```

### useWindowSize Hook

```typescript
// src/helpers/useWindowSize.ts
'use client';

import { useState, useEffect } from 'react';

interface WindowSize {
  width: number;
  height: number;
}

export function useWindowSize(): WindowSize {
  const [windowSize, setWindowSize] = useState<WindowSize>({
    width: 0,
    height: 0,
  });
  
  useEffect(() => {
    function handleResize() {
      setWindowSize({
        width: window.innerWidth,
        height: window.innerHeight,
      });
    }
    
    handleResize();
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);
  
  return windowSize;
}
```

### useClickOutside Hook

```typescript
// src/helpers/useClickOutside.ts
'use client';

import { useEffect, useRef, type RefObject } from 'react';

export function useClickOutside<T extends HTMLElement>(
  handler: () => void
): RefObject<T> {
  const ref = useRef<T>(null);
  
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (ref.current && !ref.current.contains(event.target as Node)) {
        handler();
      }
    }
    
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [handler]);
  
  return ref;
}
```

### Page-specific Hooks

```typescript
// src/hooks/pages/useHomePage.ts
'use client';

import { useState, useEffect } from 'react';
import { getClinics } from '@/services/Clinics';
import type { Clinic } from '@/services/Clinics/types';

interface UseHomePageReturn {
  clinics: Clinic[];
  loading: boolean;
  error: string | null;
}

export function useHomePage(): UseHomePageReturn {
  const [clinics, setClinics] = useState<Clinic[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await getClinics({ per_page: 6 });
        setClinics(response.data);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to fetch');
      } finally {
        setLoading(false);
      }
    };
    
    fetchData();
  }, []);
  
  return { clinics, loading, error };
}
```

### usePageTracking Hook

```typescript
// src/hooks/usePageTracking.ts
'use client';

import { useEffect } from 'react';
import { usePathname } from 'next/navigation';
import mixpanel from 'mixpanel-browser';

export function usePageTracking() {
  const pathname = usePathname();
  
  useEffect(() => {
    mixpanel.track('Page View', {
      path: pathname,
      timestamp: new Date().toISOString(),
    });
  }, [pathname]);
}
```

## Redux Store (Redux Toolkit + Redux Persist)

### Store Configuration

```typescript
// src/store/index.ts
import { configureStore } from '@reduxjs/toolkit';
import { persistStore, persistReducer } from 'redux-persist';
import storage from 'redux-persist/lib/storage';
import combinedReducers from './combinedReducers';

const persistConfig = {
  key: 'root',
  storage,
  whitelist: ['auth'], // hanya persist auth slice
};

const persistedReducer = persistReducer(persistConfig, combinedReducers);

export const store = configureStore({
  reducer: persistedReducer,
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware({
      serializableCheck: {
        ignoredActions: ['persist/PERSIST', 'persist/REHYDRATE'],
      },
    }),
});

export const persistor = persistStore(store);

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
```

### Combined Reducers

```typescript
// src/store/combinedReducers.ts
import { combineReducers } from '@reduxjs/toolkit';
import authSlice from './slices/authSlice';
import appointmentSlice from './slices/appointmentSlice';

const combinedReducers = combineReducers({
  auth: authSlice,
  appointment: appointmentSlice,
});

export default combinedReducers;
```

### Auth Slice

```typescript
// src/store/slices/authSlice.ts
import { createSlice, type PayloadAction } from '@reduxjs/toolkit';

interface User {
  id: string;
  name: string;
  email: string;
  phone: string;
  userType: string;
}

interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
}

const initialState: AuthState = {
  user: null,
  token: null,
  isAuthenticated: false,
};

const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    setCredentials: (state, action: PayloadAction<{ user: User; token: string }>) => {
      state.user = action.payload.user;
      state.token = action.payload.token;
      state.isAuthenticated = true;
    },
    logout: (state) => {
      state.user = null;
      state.token = null;
      state.isAuthenticated = false;
    },
    updateUser: (state, action: PayloadAction<Partial<User>>) => {
      if (state.user) {
        state.user = { ...state.user, ...action.payload };
      }
    },
  },
});

export const { setCredentials, logout, updateUser } = authSlice.actions;
export default authSlice.reducer;
```

### Redux Provider

```tsx
// src/components/providers/ReduxProvider.tsx
'use client';

import { Provider } from 'react-redux';
import { PersistGate } from 'redux-persist/integration/react';
import { store, persistor } from '@/store';
import type { ReactNode } from 'react';

interface ReduxProviderProps {
  children: ReactNode;
}

export default function ReduxProvider({ children }: ReduxProviderProps) {
  return (
    <Provider store={store}>
      <PersistGate loading={null} persistor={persistor}>
        {children}
      </PersistGate>
    </Provider>
  );
}
```

## Utility Functions

### Date Formatter

```typescript
// src/helpers/formatter/dateFormatter.ts

export function formatDate(date: string | Date, locale: string = 'id-ID'): string {
  return new Date(date).toLocaleDateString(locale, {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
}

export function formatDateTime(date: string | Date, locale: string = 'id-ID'): string {
  return new Date(date).toLocaleString(locale, {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

export function formatTime(date: string | Date): string {
  return new Date(date).toLocaleTimeString('id-ID', {
    hour: '2-digit',
    minute: '2-digit',
  });
}
```

### Currency Formatter

```typescript
// src/helpers/formatter/currencyFormatter.ts

export function formatCurrency(
  amount: number,
  currency: string = 'IDR',
  locale: string = 'id-ID'
): string {
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency,
    minimumFractionDigits: 0,
  }).format(amount);
}
```

### Cookie Manager

```typescript
// src/helpers/cookie/cookieManager.ts
import Cookies from 'js-cookie';

export const cookieManager = {
  get: (key: string): string | undefined => {
    return Cookies.get(key);
  },
  
  set: (key: string, value: string, options?: Cookies.CookieAttributes): void => {
    Cookies.set(key, value, { ...options, secure: true, sameSite: 'strict' });
  },
  
  remove: (key: string): void => {
    Cookies.remove(key);
  },
};
```

### Image Compression

```typescript
// src/helpers/compressImage.ts
import imageConversion from 'image-conversion';

export async function compressImage(file: File, maxSizeKB: number = 500): Promise<File> {
  const compressedBlob = await imageConversion.compressAccurately(file, maxSizeKB);
  return new File([compressedBlob], file.name, { type: file.type });
}
```

## Best Practices

1. **TypeScript**: Selalu definisikan types untuk hook return values dan utility params
2. **Hooks Organization**: Pisahkan hooks berdasarkan scope (pages, components, sections)
3. **Redux Toolkit**: Gunakan createSlice untuk state management, persist hanya yang perlu
4. **Custom Hooks**: Extract reusable logic, prefix dengan "use"
5. **Helpers vs Hooks**: Helpers = pure functions, Hooks = React-specific logic
6. **Error Handling**: Handle errors gracefully, return typed error states
7. **Performance**: Memoize expensive computations dengan useMemo/useCallback
