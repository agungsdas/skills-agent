# Custom Hooks & Utilities

Panduan membuat custom hooks dan utility functions.

## Custom Hooks

### useAuth Hook

```javascript
// src/lib/hooks/useAuth.js
'use client';

import { useState, useEffect, createContext, useContext } from 'react';
import { useRouter } from 'next/navigation';
import { login as loginService, logout as logoutService } from '@/services/account-service';

const AuthContext = createContext();

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();
  
  useEffect(() => {
    checkAuth();
  }, []);
  
  const checkAuth = async () => {
    try {
      const token = localStorage.getItem('token');
      if (token) {
        // Verify token or get user info
        const userData = JSON.parse(localStorage.getItem('user'));
        setUser(userData);
      }
    } catch (error) {
      console.error('Auth check failed:', error);
    } finally {
      setLoading(false);
    }
  };
  
  const login = async (credentials) => {
    const response = await loginService(credentials);
    
    localStorage.setItem('token', response.token);
    localStorage.setItem('user', JSON.stringify(response.user));
    setUser(response.user);
    router.push('/dashboard');
  };
  
  const logout = async () => {
    await logoutService();
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    setUser(null);
    router.push('/login');
  };
  
  return (
    <AuthContext.Provider value={{ user, loading, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
}
```

### useUsers Hook

```javascript
// src/lib/hooks/useUsers.js
'use client';

import { useState, useEffect } from 'react';
import { getUsers, createUser, updateUser, deleteUser } from '@/services/user-service';

export function useUsers() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  const fetchUsers = async () => {
    try {
      setLoading(true);
      const response = await getUsers();
      setUsers(response.data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };
  
  useEffect(() => {
    fetchUsers();
  }, []);
  
  const create = async (userData) => {
    const response = await createUser(userData);
    return response;
  };
  
  const update = async (id, userData) => {
    const response = await updateUser(id, userData);
    return response;
  };
  
  const remove = async (id) => {
    const response = await deleteUser(id);
    return response;
  };
  
  return {
    users,
    loading,
    error,
    refetch: fetchUsers,
    createUser: create,
    updateUser: update,
    deleteUser: remove,
  };
}
```

### useDebounce Hook

```javascript
// src/lib/hooks/useDebounce.js
'use client';

import { useState, useEffect } from 'react';

export function useDebounce(value, delay = 500) {
  const [debouncedValue, setDebouncedValue] = useState(value);
  
  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);
    
    return () => {
      clearTimeout(handler);
    };
  }, [value, delay]);
  
  return debouncedValue;
}

// Usage example
// const [searchTerm, setSearchTerm] = useState('');
// const debouncedSearch = useDebounce(searchTerm, 500);
// 
// useEffect(() => {
//   if (debouncedSearch) {
//     // Perform search
//   }
// }, [debouncedSearch]);
```

### useLocalStorage Hook

```javascript
// src/lib/hooks/useLocalStorage.js
'use client';

import { useState, useEffect } from 'react';

export function useLocalStorage(key, initialValue) {
  const [storedValue, setStoredValue] = useState(() => {
    if (typeof window === 'undefined') {
      return initialValue;
    }
    
    try {
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch (error) {
      console.error(error);
      return initialValue;
    }
  });
  
  const setValue = (value) => {
    try {
      const valueToStore = value instanceof Function ? value(storedValue) : value;
      setStoredValue(valueToStore);
      
      if (typeof window !== 'undefined') {
        window.localStorage.setItem(key, JSON.stringify(valueToStore));
      }
    } catch (error) {
      console.error(error);
    }
  };
  
  return [storedValue, setValue];
}
```

### usePagination Hook

```javascript
// src/lib/hooks/usePagination.js
'use client';

import { useState } from 'react';

export function usePagination(initialPage = 1, initialPageSize = 10) {
  const [page, setPage] = useState(initialPage);
  const [pageSize, setPageSize] = useState(initialPageSize);
  
  const handlePageChange = (newPage, newPageSize) => {
    setPage(newPage);
    if (newPageSize !== pageSize) {
      setPageSize(newPageSize);
    }
  };
  
  const reset = () => {
    setPage(initialPage);
    setPageSize(initialPageSize);
  };
  
  return {
    page,
    pageSize,
    onChange: handlePageChange,
    reset,
  };
}
```

### useModal Hook

```javascript
// src/lib/hooks/useModal.js
'use client';

import { useState } from 'react';

export function useModal(initialState = false) {
  const [isOpen, setIsOpen] = useState(initialState);
  const [data, setData] = useState(null);
  
  const open = (modalData = null) => {
    setData(modalData);
    setIsOpen(true);
  };
  
  const close = () => {
    setIsOpen(false);
    setData(null);
  };
  
  const toggle = () => {
    setIsOpen(!isOpen);
  };
  
  return {
    isOpen,
    data,
    open,
    close,
    toggle,
  };
}
```

## Utility Functions

### Format Utilities

```javascript
// src/lib/utils/format.js

export function formatDate(date, locale = 'id-ID') {
  return new Date(date).toLocaleDateString(locale, {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
}

export function formatDateTime(date, locale = 'id-ID') {
  return new Date(date).toLocaleString(locale, {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

export function formatCurrency(amount, currency = 'IDR', locale = 'id-ID') {
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency,
  }).format(amount);
}

export function formatNumber(number, locale = 'id-ID') {
  return new Intl.NumberFormat(locale).format(number);
}

export function truncateText(text, maxLength = 100) {
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength) + '...';
}

export function slugify(text) {
  return text
    .toLowerCase()
    .replace(/[^\w\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .trim();
}
```

### Validation Utilities

```javascript
// src/lib/utils/validation.js

export function isEmail(email) {
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return regex.test(email);
}

export function isPhone(phone) {
  const regex = /^(\+62|62|0)[0-9]{9,12}$/;
  return regex.test(phone);
}

export function isURL(url) {
  try {
    new URL(url);
    return true;
  } catch {
    return false;
  }
}

export function isStrongPassword(password) {
  // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
  const regex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$/;
  return regex.test(password);
}

export function validateRequired(value, fieldName) {
  if (!value || value.trim().length === 0) {
    return `${fieldName} is required`;
  }
  return null;
}

export function validateMinLength(value, minLength, fieldName) {
  if (value.length < minLength) {
    return `${fieldName} must be at least ${minLength} characters`;
  }
  return null;
}
```

### Storage Utilities

```javascript
// src/lib/utils/storage.js

export const storage = {
  get: (key) => {
    if (typeof window === 'undefined') return null;
    
    try {
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : null;
    } catch (error) {
      console.error('Error reading from localStorage:', error);
      return null;
    }
  },
  
  set: (key, value) => {
    if (typeof window === 'undefined') return;
    
    try {
      window.localStorage.setItem(key, JSON.stringify(value));
    } catch (error) {
      console.error('Error writing to localStorage:', error);
    }
  },
  
  remove: (key) => {
    if (typeof window === 'undefined') return;
    
    try {
      window.localStorage.removeItem(key);
    } catch (error) {
      console.error('Error removing from localStorage:', error);
    }
  },
  
  clear: () => {
    if (typeof window === 'undefined') return;
    
    try {
      window.localStorage.clear();
    } catch (error) {
      console.error('Error clearing localStorage:', error);
    }
  },
};
```

### Array Utilities

```javascript
// src/lib/utils/array.js

export function groupBy(array, key) {
  return array.reduce((result, item) => {
    const group = item[key];
    if (!result[group]) {
      result[group] = [];
    }
    result[group].push(item);
    return result;
  }, {});
}

export function sortBy(array, key, order = 'asc') {
  return [...array].sort((a, b) => {
    if (order === 'asc') {
      return a[key] > b[key] ? 1 : -1;
    }
    return a[key] < b[key] ? 1 : -1;
  });
}

export function unique(array) {
  return [...new Set(array)];
}

export function chunk(array, size) {
  const chunks = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
}
```

## Constants

```javascript
// src/lib/utils/constants.js

export const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || '/api';

export const ROUTES = {
  HOME: '/',
  LOGIN: '/login',
  REGISTER: '/register',
  DASHBOARD: '/dashboard',
  USERS: '/users',
  PROFILE: '/profile',
  SETTINGS: '/settings',
};

export const USER_ROLES = {
  ADMIN: 'admin',
  USER: 'user',
  MANAGER: 'manager',
};

export const STATUS = {
  ACTIVE: 'active',
  INACTIVE: 'inactive',
  PENDING: 'pending',
};

export const PAGINATION = {
  DEFAULT_PAGE: 1,
  DEFAULT_PAGE_SIZE: 10,
  PAGE_SIZE_OPTIONS: [10, 20, 50, 100],
};
```

## Best Practices

1. **Custom Hooks**: Extract reusable logic ke custom hooks
2. **Service Layer**: Use services layer untuk API calls (lihat services.md)
3. **Error Handling**: Handle errors gracefully di hooks dan utilities
4. **Type Safety**: Consider using JSDoc comments untuk better IDE support
5. **Testing**: Write tests untuk critical utilities
6. **Documentation**: Document complex functions dengan comments
7. **Performance**: Memoize expensive computations
8. **Reusability**: Buat utilities yang generic dan reusable
