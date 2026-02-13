# Components dengan Ant Design

Panduan membuat komponen reusable dengan Ant Design.

## Component Structure

### Basic Component

```javascript
// src/components/common/PageHeader.js
import { Typography } from 'antd';

const { Title } = Typography;

export default function PageHeader({ title, subtitle }) {
  return (
    <div style={{ marginBottom: 24 }}>
      <Title level={2}>{title}</Title>
      {subtitle && <p style={{ color: '#666' }}>{subtitle}</p>}
    </div>
  );
}
```

### Client Component dengan State

```javascript
// src/components/common/SearchBar.js
'use client';

import { Input } from 'antd';
import { SearchOutlined } from '@ant-design/icons';
import { useState } from 'react';

export default function SearchBar({ onSearch, placeholder = 'Search...' }) {
  const [value, setValue] = useState('');
  
  const handleSearch = (searchValue) => {
    onSearch?.(searchValue);
  };
  
  return (
    <Input
      placeholder={placeholder}
      prefix={<SearchOutlined />}
      value={value}
      onChange={(e) => setValue(e.target.value)}
      onPressEnter={(e) => handleSearch(e.target.value)}
      allowClear
      style={{ width: 300 }}
    />
  );
}
```

## Form Components

### Login Form

```javascript
// src/components/forms/LoginForm.js
'use client';

import { Form, Input, Button, Checkbox } from 'antd';
import { UserOutlined, LockOutlined } from '@ant-design/icons';

export default function LoginForm({ onSubmit, loading = false }) {
  const [form] = Form.useForm();
  
  const handleFinish = (values) => {
    onSubmit?.(values);
  };
  
  return (
    <Form
      form={form}
      name="login"
      onFinish={handleFinish}
      autoComplete="off"
      layout="vertical"
    >
      <Form.Item
        name="email"
        rules={[
          { required: true, message: 'Please input your email!' },
          { type: 'email', message: 'Please enter a valid email!' }
        ]}
      >
        <Input 
          prefix={<UserOutlined />} 
          placeholder="Email"
          size="large"
        />
      </Form.Item>
      
      <Form.Item
        name="password"
        rules={[
          { required: true, message: 'Please input your password!' },
          { min: 6, message: 'Password must be at least 6 characters!' }
        ]}
      >
        <Input.Password
          prefix={<LockOutlined />}
          placeholder="Password"
          size="large"
        />
      </Form.Item>
      
      <Form.Item name="remember" valuePropName="checked">
        <Checkbox>Remember me</Checkbox>
      </Form.Item>
      
      <Form.Item>
        <Button 
          type="primary" 
          htmlType="submit" 
          loading={loading}
          block
          size="large"
        >
          Log in
        </Button>
      </Form.Item>
    </Form>
  );
}
```

### User Form

```javascript
// src/components/forms/UserForm.js
'use client';

import { Form, Input, Select, DatePicker, Button, Space } from 'antd';

const { Option } = Select;

export default function UserForm({ initialValues, onSubmit, onCancel, loading = false }) {
  const [form] = Form.useForm();
  
  const handleFinish = (values) => {
    onSubmit?.({
      ...values,
      birthDate: values.birthDate?.format('YYYY-MM-DD'),
    });
  };
  
  return (
    <Form
      form={form}
      layout="vertical"
      initialValues={initialValues}
      onFinish={handleFinish}
    >
      <Form.Item
        label="Name"
        name="name"
        rules={[{ required: true, message: 'Please input name!' }]}
      >
        <Input placeholder="Enter name" />
      </Form.Item>
      
      <Form.Item
        label="Email"
        name="email"
        rules={[
          { required: true, message: 'Please input email!' },
          { type: 'email', message: 'Please enter valid email!' }
        ]}
      >
        <Input placeholder="Enter email" />
      </Form.Item>
      
      <Form.Item
        label="Phone"
        name="phone"
        rules={[{ required: true, message: 'Please input phone!' }]}
      >
        <Input placeholder="Enter phone number" />
      </Form.Item>
      
      <Form.Item
        label="Role"
        name="role"
        rules={[{ required: true, message: 'Please select role!' }]}
      >
        <Select placeholder="Select role">
          <Option value="admin">Admin</Option>
          <Option value="user">User</Option>
          <Option value="manager">Manager</Option>
        </Select>
      </Form.Item>
      
      <Form.Item
        label="Birth Date"
        name="birthDate"
      >
        <DatePicker style={{ width: '100%' }} />
      </Form.Item>
      
      <Form.Item>
        <Space>
          <Button type="primary" htmlType="submit" loading={loading}>
            Submit
          </Button>
          <Button onClick={onCancel}>
            Cancel
          </Button>
        </Space>
      </Form.Item>
    </Form>
  );
}
```

## Data Display Components

### Data Table

```javascript
// src/components/ui/DataTable.js
'use client';

import { Table, Button, Space, Popconfirm } from 'antd';
import { EditOutlined, DeleteOutlined } from '@ant-design/icons';

export default function DataTable({ 
  data, 
  loading = false,
  onEdit,
  onDelete,
  pagination = true
}) {
  const columns = [
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
      sorter: (a, b) => a.name.localeCompare(b.name),
    },
    {
      title: 'Email',
      dataIndex: 'email',
      key: 'email',
    },
    {
      title: 'Role',
      dataIndex: 'role',
      key: 'role',
      filters: [
        { text: 'Admin', value: 'admin' },
        { text: 'User', value: 'user' },
        { text: 'Manager', value: 'manager' },
      ],
      onFilter: (value, record) => record.role === value,
    },
    {
      title: 'Action',
      key: 'action',
      render: (_, record) => (
        <Space size="middle">
          <Button 
            type="link" 
            icon={<EditOutlined />}
            onClick={() => onEdit?.(record)}
          >
            Edit
          </Button>
          <Popconfirm
            title="Are you sure to delete this user?"
            onConfirm={() => onDelete?.(record.id)}
            okText="Yes"
            cancelText="No"
          >
            <Button 
              type="link" 
              danger
              icon={<DeleteOutlined />}
            >
              Delete
            </Button>
          </Popconfirm>
        </Space>
      ),
    },
  ];
  
  return (
    <Table
      columns={columns}
      dataSource={data}
      loading={loading}
      pagination={pagination}
      rowKey="id"
    />
  );
}
```

### Stat Card

```javascript
// src/components/ui/StatCard.js
import { Card, Statistic } from 'antd';
import { ArrowUpOutlined, ArrowDownOutlined } from '@ant-design/icons';

export default function StatCard({ 
  title, 
  value, 
  prefix, 
  suffix,
  trend,
  trendValue 
}) {
  const trendColor = trend === 'up' ? '#3f8600' : '#cf1322';
  const TrendIcon = trend === 'up' ? ArrowUpOutlined : ArrowDownOutlined;
  
  return (
    <Card>
      <Statistic
        title={title}
        value={value}
        prefix={prefix}
        suffix={suffix}
        valueStyle={{ color: trendColor }}
      />
      {trend && (
        <div style={{ marginTop: 8 }}>
          <TrendIcon style={{ color: trendColor, marginRight: 4 }} />
          <span style={{ color: trendColor }}>{trendValue}%</span>
          <span style={{ marginLeft: 8, color: '#666' }}>vs last month</span>
        </div>
      )}
    </Card>
  );
}
```

## Modal Components

### Confirmation Modal

```javascript
// src/components/common/ConfirmModal.js
'use client';

import { Modal } from 'antd';
import { ExclamationCircleOutlined } from '@ant-design/icons';

const { confirm } = Modal;

export function showConfirm({ title, content, onOk, onCancel }) {
  confirm({
    title,
    icon: <ExclamationCircleOutlined />,
    content,
    onOk,
    onCancel,
  });
}

export function showDeleteConfirm({ itemName, onOk }) {
  confirm({
    title: 'Are you sure delete this item?',
    icon: <ExclamationCircleOutlined />,
    content: `This will permanently delete "${itemName}". This action cannot be undone.`,
    okText: 'Yes, Delete',
    okType: 'danger',
    cancelText: 'Cancel',
    onOk,
  });
}
```

### Form Modal

```javascript
// src/components/common/FormModal.js
'use client';

import { Modal } from 'antd';

export default function FormModal({ 
  open, 
  title, 
  onCancel, 
  onOk,
  children,
  loading = false,
  width = 600
}) {
  return (
    <Modal
      open={open}
      title={title}
      onCancel={onCancel}
      onOk={onOk}
      confirmLoading={loading}
      width={width}
      destroyOnClose
    >
      {children}
    </Modal>
  );
}
```

## Upload Components

### Image Upload

```javascript
// src/components/common/ImageUpload.js
'use client';

import { Upload, message } from 'antd';
import { PlusOutlined } from '@ant-design/icons';
import { useState } from 'react';

export default function ImageUpload({ value, onChange, maxCount = 1 }) {
  const [fileList, setFileList] = useState(value || []);
  
  const handleChange = ({ fileList: newFileList }) => {
    setFileList(newFileList);
    onChange?.(newFileList);
  };
  
  const beforeUpload = (file) => {
    const isImage = file.type.startsWith('image/');
    if (!isImage) {
      message.error('You can only upload image files!');
    }
    const isLt2M = file.size / 1024 / 1024 < 2;
    if (!isLt2M) {
      message.error('Image must smaller than 2MB!');
    }
    return isImage && isLt2M;
  };
  
  const uploadButton = (
    <div>
      <PlusOutlined />
      <div style={{ marginTop: 8 }}>Upload</div>
    </div>
  );
  
  return (
    <Upload
      listType="picture-card"
      fileList={fileList}
      onChange={handleChange}
      beforeUpload={beforeUpload}
      maxCount={maxCount}
    >
      {fileList.length >= maxCount ? null : uploadButton}
    </Upload>
  );
}
```

## Custom Hooks Integration

### Component dengan Custom Hook

```javascript
// src/components/users/UserList.js
'use client';

import { Table, Button, Space, message } from 'antd';
import { PlusOutlined } from '@ant-design/icons';
import { useUsers } from '@/lib/hooks/useUsers';
import { useState } from 'react';

export default function UserList() {
  const { users, loading, deleteUser, refetch } = useUsers();
  const [selectedUser, setSelectedUser] = useState(null);
  
  const handleDelete = async (id) => {
    try {
      await deleteUser(id);
      message.success('User deleted successfully');
      refetch();
    } catch (error) {
      message.error('Failed to delete user');
    }
  };
  
  const columns = [
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
    },
    {
      title: 'Email',
      dataIndex: 'email',
      key: 'email',
    },
    {
      title: 'Action',
      key: 'action',
      render: (_, record) => (
        <Space>
          <Button onClick={() => setSelectedUser(record)}>
            Edit
          </Button>
          <Button danger onClick={() => handleDelete(record.id)}>
            Delete
          </Button>
        </Space>
      ),
    },
  ];
  
  return (
    <div>
      <div style={{ marginBottom: 16 }}>
        <Button type="primary" icon={<PlusOutlined />}>
          Add User
        </Button>
      </div>
      <Table
        columns={columns}
        dataSource={users}
        loading={loading}
        rowKey="id"
      />
    </div>
  );
}
```

## Responsive Components

```javascript
// src/components/common/ResponsiveCard.js
'use client';

import { Card, Grid } from 'antd';

const { useBreakpoint } = Grid;

export default function ResponsiveCard({ children, ...props }) {
  const screens = useBreakpoint();
  
  const cardStyle = {
    margin: screens.xs ? 8 : 16,
    padding: screens.xs ? 12 : 24,
  };
  
  return (
    <Card style={cardStyle} {...props}>
      {children}
    </Card>
  );
}
```

## Component Best Practices

1. **Client vs Server**: Default ke Server Component, gunakan 'use client' hanya jika perlu
2. **Theme Support**: WAJIB support light & dark mode untuk semua components
3. **Props Validation**: Gunakan PropTypes atau TypeScript untuk type safety
4. **Reusability**: Buat komponen generic dengan props yang flexible
5. **Ant Design**: Leverage Ant Design components, jangan reinvent the wheel
6. **Loading States**: Selalu handle loading states dengan Spin atau Skeleton
7. **Error Handling**: Implement error boundaries dan user feedback
8. **Accessibility**: Gunakan semantic HTML dan ARIA attributes
9. **Performance**: Memoize expensive computations dengan useMemo/useCallback
