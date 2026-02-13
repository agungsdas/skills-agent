# Services Layer

Panduan organizing API calls per backend service. Services layer memisahkan API calls berdasarkan backend service yang berbeda.

## Structure

```
services/
├── account-service/       # Account/Auth service
│   ├── auth.js
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

## Base Service Client

```javascript
// src/services/base-client.js

class ServiceClient {
  constructor(baseURL) {
    this.baseURL = baseURL;
  }
  
  async request(endpoint, options = {}) {
    const url = `${this.baseURL}${endpoint}`;
    
    const config = {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
    };
    
    // Add auth token if available
    if (typeof window !== 'undefined') {
      const token = localStorage.getItem('token');
      if (token) {
        config.headers['Authorization'] = `Bearer ${token}`;
      }
    }
    
    try {
      const response = await fetch(url, config);
      const data = await response.json();
      
      if (!response.ok) {
        throw new Error(data.message || 'Request failed');
      }
      
      return data;
    } catch (error) {
      console.error(`API Error [${endpoint}]:`, error);
      throw error;
    }
  }
  
  get(endpoint, options = {}) {
    return this.request(endpoint, {
      ...options,
      method: 'GET',
    });
  }
  
  post(endpoint, data, options = {}) {
    return this.request(endpoint, {
      ...options,
      method: 'POST',
      body: JSON.stringify(data),
    });
  }
  
  put(endpoint, data, options = {}) {
    return this.request(endpoint, {
      ...options,
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }
  
  patch(endpoint, data, options = {}) {
    return this.request(endpoint, {
      ...options,
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }
  
  delete(endpoint, options = {}) {
    return this.request(endpoint, {
      ...options,
      method: 'DELETE',
    });
  }
}

export default ServiceClient;
```

## Account Service

### Login API

```javascript
// src/services/account-service/login.js
import ServiceClient from '../base-client';

const ACCOUNT_SERVICE_URL = process.env.NEXT_PUBLIC_ACCOUNT_SERVICE_URL || 'https://api.example.com/account';
const client = new ServiceClient(ACCOUNT_SERVICE_URL);

export async function login(credentials) {
  return client.post('/auth/login', credentials);
}

export async function loginWithGoogle(token) {
  return client.post('/auth/google', { token });
}

export async function logout() {
  return client.post('/auth/logout');
}

export async function refreshToken() {
  return client.post('/auth/refresh');
}
```

### Profile API

```javascript
// src/services/account-service/profile.js
import ServiceClient from '../base-client';

const ACCOUNT_SERVICE_URL = process.env.NEXT_PUBLIC_ACCOUNT_SERVICE_URL || 'https://api.example.com/account';
const client = new ServiceClient(ACCOUNT_SERVICE_URL);

export async function getProfile() {
  return client.get('/profile');
}

export async function updateProfile(data) {
  return client.put('/profile', data);
}

export async function changePassword(data) {
  return client.post('/profile/change-password', data);
}

export async function uploadAvatar(file) {
  const formData = new FormData();
  formData.append('avatar', file);
  
  return client.post('/profile/avatar', formData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  });
}
```

### Index Export

```javascript
// src/services/account-service/index.js
export * from './login';
export * from './profile';
```

## User Service

### Users API

```javascript
// src/services/user-service/users.js
import ServiceClient from '../base-client';

const USER_SERVICE_URL = process.env.NEXT_PUBLIC_USER_SERVICE_URL || 'https://api.example.com/users';
const client = new ServiceClient(USER_SERVICE_URL);

export async function getUsers(params = {}) {
  const query = new URLSearchParams(params).toString();
  return client.get(`/users?${query}`);
}

export async function getUserById(id) {
  return client.get(`/users/${id}`);
}

export async function createUser(data) {
  return client.post('/users', data);
}

export async function updateUser(id, data) {
  return client.put(`/users/${id}`, data);
}

export async function deleteUser(id) {
  return client.delete(`/users/${id}`);
}

export async function searchUsers(query) {
  return client.get(`/users/search?q=${encodeURIComponent(query)}`);
}
```

### Roles API

```javascript
// src/services/user-service/roles.js
import ServiceClient from '../base-client';

const USER_SERVICE_URL = process.env.NEXT_PUBLIC_USER_SERVICE_URL || 'https://api.example.com/users';
const client = new ServiceClient(USER_SERVICE_URL);

export async function getRoles() {
  return client.get('/roles');
}

export async function assignRole(userId, roleId) {
  return client.post(`/users/${userId}/roles`, { roleId });
}

export async function removeRole(userId, roleId) {
  return client.delete(`/users/${userId}/roles/${roleId}`);
}
```

### Index Export

```javascript
// src/services/user-service/index.js
export * from './users';
export * from './roles';
```

## Product Service

### Products API

```javascript
// src/services/product-service/products.js
import ServiceClient from '../base-client';

const PRODUCT_SERVICE_URL = process.env.NEXT_PUBLIC_PRODUCT_SERVICE_URL || 'https://api.example.com/products';
const client = new ServiceClient(PRODUCT_SERVICE_URL);

export async function getProducts(params = {}) {
  const query = new URLSearchParams(params).toString();
  return client.get(`/products?${query}`);
}

export async function getProductById(id) {
  return client.get(`/products/${id}`);
}

export async function createProduct(data) {
  return client.post('/products', data);
}

export async function updateProduct(id, data) {
  return client.put(`/products/${id}`, data);
}

export async function deleteProduct(id) {
  return client.delete(`/products/${id}`);
}

export async function getProductsByCategory(categoryId, params = {}) {
  const query = new URLSearchParams(params).toString();
  return client.get(`/categories/${categoryId}/products?${query}`);
}
```

### Categories API

```javascript
// src/services/product-service/categories.js
import ServiceClient from '../base-client';

const PRODUCT_SERVICE_URL = process.env.NEXT_PUBLIC_PRODUCT_SERVICE_URL || 'https://api.example.com/products';
const client = new ServiceClient(PRODUCT_SERVICE_URL);

export async function getCategories() {
  return client.get('/categories');
}

export async function getCategoryById(id) {
  return client.get(`/categories/${id}`);
}

export async function createCategory(data) {
  return client.post('/categories', data);
}

export async function updateCategory(id, data) {
  return client.put(`/categories/${id}`, data);
}

export async function deleteCategory(id) {
  return client.delete(`/categories/${id}`);
}
```

### Index Export

```javascript
// src/services/product-service/index.js
export * from './products';
export * from './categories';
```

## Order Service

### Orders API

```javascript
// src/services/order-service/orders.js
import ServiceClient from '../base-client';

const ORDER_SERVICE_URL = process.env.NEXT_PUBLIC_ORDER_SERVICE_URL || 'https://api.example.com/orders';
const client = new ServiceClient(ORDER_SERVICE_URL);

export async function getOrders(params = {}) {
  const query = new URLSearchParams(params).toString();
  return client.get(`/orders?${query}`);
}

export async function getOrderById(id) {
  return client.get(`/orders/${id}`);
}

export async function createOrder(data) {
  return client.post('/orders', data);
}

export async function updateOrderStatus(id, status) {
  return client.patch(`/orders/${id}/status`, { status });
}

export async function cancelOrder(id) {
  return client.post(`/orders/${id}/cancel`);
}

export async function getOrderHistory(userId) {
  return client.get(`/users/${userId}/orders`);
}
```

### Payments API

```javascript
// src/services/order-service/payments.js
import ServiceClient from '../base-client';

const ORDER_SERVICE_URL = process.env.NEXT_PUBLIC_ORDER_SERVICE_URL || 'https://api.example.com/orders';
const client = new ServiceClient(ORDER_SERVICE_URL);

export async function createPayment(orderId, data) {
  return client.post(`/orders/${orderId}/payments`, data);
}

export async function getPaymentStatus(paymentId) {
  return client.get(`/payments/${paymentId}`);
}

export async function confirmPayment(paymentId) {
  return client.post(`/payments/${paymentId}/confirm`);
}

export async function refundPayment(paymentId, amount) {
  return client.post(`/payments/${paymentId}/refund`, { amount });
}
```

### Index Export

```javascript
// src/services/order-service/index.js
export * from './orders';
export * from './payments';
```

## Usage in Components

### Login Page

```javascript
// src/app/(auth)/login/page.js
'use client';

import { useState } from 'react';
import { Form, Input, Button, message } from 'antd';
import { useRouter } from 'next/navigation';
import { login } from '@/services/account-service';

export default function LoginPage() {
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  
  const handleSubmit = async (values) => {
    try {
      setLoading(true);
      const response = await login(values);
      
      // Save token
      localStorage.setItem('token', response.token);
      
      message.success('Login successful');
      router.push('/dashboard');
    } catch (error) {
      message.error(error.message || 'Login failed');
    } finally {
      setLoading(false);
    }
  };
  
  return (
    <Form onFinish={handleSubmit}>
      <Form.Item name="email" rules={[{ required: true, type: 'email' }]}>
        <Input placeholder="Email" />
      </Form.Item>
      <Form.Item name="password" rules={[{ required: true }]}>
        <Input.Password placeholder="Password" />
      </Form.Item>
      <Form.Item>
        <Button type="primary" htmlType="submit" loading={loading} block>
          Login
        </Button>
      </Form.Item>
    </Form>
  );
}
```

### Users Page

```javascript
// src/app/users/page.js
'use client';

import { useState, useEffect } from 'react';
import { Table, Button, message } from 'antd';
import { getUsers, deleteUser } from '@/services/user-service';

export default function UsersPage() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    fetchUsers();
  }, []);
  
  const fetchUsers = async () => {
    try {
      setLoading(true);
      const response = await getUsers({ page: 1, limit: 10 });
      setUsers(response.data);
    } catch (error) {
      message.error('Failed to fetch users');
    } finally {
      setLoading(false);
    }
  };
  
  const handleDelete = async (id) => {
    try {
      await deleteUser(id);
      message.success('User deleted');
      fetchUsers();
    } catch (error) {
      message.error('Failed to delete user');
    }
  };
  
  const columns = [
    { title: 'Name', dataIndex: 'name', key: 'name' },
    { title: 'Email', dataIndex: 'email', key: 'email' },
    {
      title: 'Action',
      key: 'action',
      render: (_, record) => (
        <Button danger onClick={() => handleDelete(record.id)}>
          Delete
        </Button>
      ),
    },
  ];
  
  return <Table columns={columns} dataSource={users} loading={loading} />;
}
```

## Environment Variables

```bash
# .env.local

# Account Service
NEXT_PUBLIC_ACCOUNT_SERVICE_URL=https://api.example.com/account

# User Service
NEXT_PUBLIC_USER_SERVICE_URL=https://api.example.com/users

# Product Service
NEXT_PUBLIC_PRODUCT_SERVICE_URL=https://api.example.com/products

# Order Service
NEXT_PUBLIC_ORDER_SERVICE_URL=https://api.example.com/orders
```

## Error Handling

```javascript
// src/services/error-handler.js

export class ServiceError extends Error {
  constructor(message, status, data) {
    super(message);
    this.status = status;
    this.data = data;
  }
}

export function handleServiceError(error) {
  if (error instanceof ServiceError) {
    switch (error.status) {
      case 401:
        // Redirect to login
        window.location.href = '/login';
        break;
      case 403:
        return 'You do not have permission to perform this action';
      case 404:
        return 'Resource not found';
      case 500:
        return 'Server error. Please try again later';
      default:
        return error.message;
    }
  }
  
  return 'An unexpected error occurred';
}
```

## Best Practices

1. **Service Separation**: Pisahkan API calls berdasarkan backend service
2. **Base Client**: Gunakan base client untuk consistency
3. **Environment Variables**: Store service URLs di environment variables
4. **Error Handling**: Implement proper error handling di setiap service
5. **Authentication**: Handle auth tokens di base client
6. **Type Safety**: Consider using JSDoc untuk better IDE support
7. **Retry Logic**: Implement retry untuk failed requests
8. **Caching**: Consider caching untuk frequently accessed data
9. **Loading States**: Always handle loading states di components
10. **Index Exports**: Export semua functions dari index.js untuk easy imports

## Testing

```javascript
// src/services/account-service/__tests__/login.test.js

import { login } from '../login';

// Mock fetch
global.fetch = jest.fn();

describe('Account Service - Login', () => {
  beforeEach(() => {
    fetch.mockClear();
  });
  
  it('should login successfully', async () => {
    const mockResponse = {
      token: 'mock-token',
      user: { id: 1, email: 'test@example.com' },
    };
    
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => mockResponse,
    });
    
    const result = await login({
      email: 'test@example.com',
      password: 'password',
    });
    
    expect(result).toEqual(mockResponse);
    expect(fetch).toHaveBeenCalledTimes(1);
  });
  
  it('should handle login error', async () => {
    fetch.mockResolvedValueOnce({
      ok: false,
      json: async () => ({ message: 'Invalid credentials' }),
    });
    
    await expect(
      login({ email: 'test@example.com', password: 'wrong' })
    ).rejects.toThrow('Invalid credentials');
  });
});
```
