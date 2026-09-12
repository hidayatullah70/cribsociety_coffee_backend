# Crib Society Coffee — API Integration Documentation
Version: 1.0.0  
Base URL: `http://localhost:5000/api/v1`  
Protocol: REST JSON  

---

## Table of Contents
1. [Conventions & Authentication](#1-conventions--authentication)
2. [Standard Error Envelope](#2-standard-error-envelope)
3. [Seed Accounts](#3-seed-accounts)
4. [System Endpoints](#4-system-endpoints)
5. [Authentication Endpoints](#5-authentication-endpoints)
6. [Menu & Catalog Endpoints](#6-menu--catalog-endpoints)
7. [Orders & POS Endpoints](#7-orders--pos-endpoints)
8. [Payment Endpoints](#8-payment-endpoints)
9. [Inventory Endpoints](#9-inventory-endpoints)
10. [Dashboard Metrics Endpoints](#10-dashboard-metrics-endpoints)
11. [Staff Management Endpoints](#11-staff-management-endpoints)
12. [Guest / Public Endpoints](#12-guest--public-endpoints)

---

## 1. Conventions & Authentication

- **Request Format**: All mutation requests (`POST`, `PATCH`, `PUT`) must include `Content-Type: application/json`.
- **Response Format**: All responses return formatted JSON.
- **Timestamps**: All timestamps follow ISO-8601 (`YYYY-MM-DDTHH:mm:ss.sssZ`).
- **Monetary Values**: Returned as numbers in Indonesian Rupiah (IDR).
- **Protected Routes**: Require HTTP Authorization Header:
  ```http
  Authorization: Bearer <JWT_TOKEN>
  ```

---

## 2. Standard Error Envelope

When a request fails, the server responds with a standardized error structure:

```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Product with ID prod_xyz not found",
    "details": {}
  }
}
```

### Common Error Codes:
| HTTP Status | Error Code | Description |
|---|---|---|
| `400` | `VALIDATION_ERROR` / `BAD_REQUEST` | Missing or invalid body parameters |
| `401` | `UNAUTHORIZED` | Missing, invalid, or expired JWT Bearer token |
| `403` | `FORBIDDEN` | Insufficient role permission (e.g. Staff accessing Owner endpoint) |
| `404` | `RESOURCE_NOT_FOUND` | Target entity does not exist |
| `409` | `CONFLICT` | Unique key collision (e.g. email exists) or duplicate payment attempt |
| `400` | `INVALID_STATE_TRANSITION` | Disallowed order status transition |
| `500` | `INTERNAL_SERVER_ERROR` | Unhandled server exception |

---

## 3. Seed Accounts

| Role | Email | Password | Allowed Access |
|---|---|---|---|
| **Owner** | `owner@cribsociety.coffee` | `password123` | Full Access: Menu CRUD, Staff, Inventory Override, Dashboard KPI |
| **Staff** | `sarah@cribsociety.coffee` | `password123` | Operational: POS Checkout, Order Status Updates, Inventory Adjustments |
| **Staff** | `dimas@cribsociety.coffee` | `password123` | Operational: POS Checkout, Order Status Updates, Inventory Adjustments |

---

## 4. System Endpoints

### 4.1 Root Ping
- **Endpoint**: `GET /`
- **Auth**: None
- **Response `200 OK`**:
```json
{
  "name": "Crib Society Coffee REST API",
  "status": "online",
  "documentation": "/api/v1/health"
}
```

### 4.2 Health Check
- **Endpoint**: `GET /api/v1/health`
- **Auth**: None
- **Response `200 OK`**:
```json
{
  "status": "UP",
  "name": "Crib Society Coffee API",
  "version": "1.0.0",
  "timestamp": "2026-09-12T15:00:00.000Z"
}
```

---

## 5. Authentication Endpoints

### 5.1 User Login
- **Endpoint**: `POST /api/v1/auth/login`
- **Auth**: None
- **Request Body**:
```json
{
  "email": "owner@cribsociety.coffee",
  "password": "password123"
}
```
- **Response `200 OK`**:
```json
{
  "user": {
    "id": "usr_owner_01",
    "name": "Admin Owner",
    "email": "owner@cribsociety.coffee",
    "role": "owner"
  },
  "session": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresAt": "2026-09-13T15:00:00.000Z"
  }
}
```
- **Error Response `401 Unauthorized`**:
```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Invalid email or password",
    "details": {}
  }
}
```

---

### 5.2 Get Current Profile
- **Endpoint**: `GET /api/v1/auth/me`
- **Auth**: `Bearer <token>`
- **Response `200 OK`**:
```json
{
  "user": {
    "id": "usr_owner_01",
    "name": "Admin Owner",
    "email": "owner@cribsociety.coffee",
    "role": "owner",
    "is_active": 1,
    "created_at": "2026-09-11T13:16:53.000Z",
    "updated_at": "2026-09-11T13:16:53.000Z"
  }
}
```

---

### 5.3 User Logout
- **Endpoint**: `POST /api/v1/auth/logout`
- **Auth**: None
- **Response `200 OK`**:
```json
{
  "message": "Logged out successfully"
}
```

---

## 6. Menu & Catalog Endpoints

### 6.1 Get Categories
- **Endpoint**: `GET /api/v1/menu/categories`
- **Query Params**: `all=true|false` (Optional, default `false`)
- **Auth**: Optional
- **Response `200 OK`**:
```json
{
  "categories": [
    {
      "id": "cat_signature",
      "name": "Signature Coffee",
      "sort_order": 1,
      "is_active": 1,
      "created_at": "2026-09-11T13:16:53.000Z",
      "updated_at": "2026-09-11T13:16:53.000Z"
    },
    {
      "id": "cat_espresso",
      "name": "Espresso & Classic",
      "sort_order": 2,
      "is_active": 1,
      "created_at": "2026-09-11T13:16:53.000Z",
      "updated_at": "2026-09-11T13:16:53.000Z"
    }
  ]
}
```

---

### 6.2 Create Category
- **Endpoint**: `POST /api/v1/menu/categories`
- **Auth**: `Bearer <token>` (Owner Only)
- **Request Body**:
```json
{
  "name": "Seasonal Specials",
  "sortOrder": 5
}
```
- **Response `201 Created`**:
```json
{
  "category": {
    "id": "cat_a1b2c3d4e5f6",
    "name": "Seasonal Specials",
    "sort_order": 5,
    "is_active": 1,
    "created_at": "2026-09-12T15:10:00.000Z",
    "updated_at": "2026-09-12T15:10:00.000Z"
  }
}
```

---

### 6.3 Update Category
- **Endpoint**: `PATCH /api/v1/menu/categories/:id`
- **Auth**: `Bearer <token>` (Owner Only)
- **Request Body**:
```json
{
  "name": "Signature Artisanal Coffee",
  "sortOrder": 1,
  "isActive": true
}
```
- **Response `200 OK`**:
```json
{
  "category": {
    "id": "cat_signature",
    "name": "Signature Artisanal Coffee",
    "sort_order": 1,
    "is_active": 1,
    "created_at": "2026-09-11T13:16:53.000Z",
    "updated_at": "2026-09-12T15:15:00.000Z"
  }
}
```

---

### 6.4 Get Addons
- **Endpoint**: `GET /api/v1/menu/addons`
- **Auth**: Optional
- **Response `200 OK`**:
```json
{
  "addons": [
    {
      "id": "add_extra_espresso",
      "name": "Extra Espresso Shot",
      "price": 6000,
      "is_active": 1
    },
    {
      "id": "add_oat_milk",
      "name": "Swap to Oat Milk",
      "price": 7000,
      "is_active": 1
    }
  ]
}
```

---

### 6.5 Create Addon
- **Endpoint**: `POST /api/v1/menu/addons`
- **Auth**: `Bearer <token>` (Owner Only)
- **Request Body**:
```json
{
  "name": "Vanilla Syrup Pump",
  "price": 4000
}
```
- **Response `201 Created`**:
```json
{
  "addon": {
    "id": "add_f8e7d6c5",
    "name": "Vanilla Syrup Pump",
    "price": 4000,
    "isActive": true
  }
}
```

---

### 6.6 Get Products Catalog
- **Endpoint**: `GET /api/v1/menu/products`
- **Query Params**:
  - `categoryId`: Filter by category ID
  - `available`: `true` | `false`
  - `includeArchived`: `true` | `false` (default `false`)
- **Auth**: Optional
- **Response `200 OK`**:
```json
{
  "products": [
    {
      "id": "prod_crib_aren",
      "categoryId": "cat_signature",
      "categoryName": "Signature Coffee",
      "name": "Crib Aren Latte",
      "description": "Signature espresso, fresh milk, and organic aren palm sugar.",
      "price": 28000,
      "available": true,
      "lowStockThreshold": 10,
      "stockQuantity": 45,
      "isArchived": false,
      "variants": [
        {
          "id": "var_aren_reg",
          "name": "Regular (12oz)",
          "priceDelta": 0
        },
        {
          "id": "var_aren_large",
          "name": "Large (16oz)",
          "priceDelta": 6000
        }
      ],
      "addons": [
        {
          "id": "add_extra_espresso",
          "name": "Extra Espresso Shot",
          "price": 6000
        },
        {
          "id": "add_oat_milk",
          "name": "Swap to Oat Milk",
          "price": 7000
        }
      ],
      "createdAt": "2026-09-11T13:16:53.000Z",
      "updatedAt": "2026-09-11T13:16:53.000Z"
    }
  ]
}
```

---

### 6.7 Get Product By ID
- **Endpoint**: `GET /api/v1/menu/products/:id`
- **Auth**: Optional
- **Response `200 OK`**:
```json
{
  "product": {
    "id": "prod_crib_aren",
    "categoryId": "cat_signature",
    "categoryName": "Signature Coffee",
    "name": "Crib Aren Latte",
    "description": "Signature espresso, fresh milk, and organic aren palm sugar.",
    "price": 28000,
    "available": true,
    "lowStockThreshold": 10,
    "stockQuantity": 45,
    "isArchived": false,
    "variants": [
      {
        "id": "var_aren_reg",
        "name": "Regular (12oz)",
        "priceDelta": 0
      },
      {
        "id": "var_aren_large",
        "name": "Large (16oz)",
        "priceDelta": 6000
      }
    ],
    "addons": [
      {
        "id": "add_extra_espresso",
        "name": "Extra Espresso Shot",
        "price": 6000
      }
    ],
    "createdAt": "2026-09-11T13:16:53.000Z",
    "updatedAt": "2026-09-11T13:16:53.000Z"
  }
}
```

---

### 6.8 Create Product
- **Endpoint**: `POST /api/v1/menu/products`
- **Auth**: `Bearer <token>` (Owner Only)
- **Request Body**:
```json
{
  "categoryId": "cat_signature",
  "name": "Pistachio Velvet Latte",
  "description": "Single origin espresso with roasted pistachio paste and velvety oat milk.",
  "price": 38000,
  "available": true,
  "lowStockThreshold": 8,
  "initialStock": 25,
  "variants": [
    {
      "name": "Regular (12oz)",
      "priceDelta": 0
    },
    {
      "name": "Large (16oz)",
      "priceDelta": 6000
    }
  ],
  "addonIds": [
    "add_extra_espresso",
    "add_oat_milk"
  ]
}
```
- **Response `201 Created`**:
```json
{
  "product": {
    "id": "prod_8c9d0e1f2a3b",
    "categoryId": "cat_signature",
    "categoryName": "Signature Coffee",
    "name": "Pistachio Velvet Latte",
    "description": "Single origin espresso with roasted pistachio paste and velvety oat milk.",
    "price": 38000,
    "available": true,
    "lowStockThreshold": 8,
    "stockQuantity": 25,
    "isArchived": false,
    "variants": [
      {
        "id": "var_11223344",
        "name": "Regular (12oz)",
        "priceDelta": 0
      },
      {
        "id": "var_55667788",
        "name": "Large (16oz)",
        "priceDelta": 6000
      }
    ],
    "addons": [
      {
        "id": "add_extra_espresso",
        "name": "Extra Espresso Shot",
        "price": 6000
      }
    ],
    "createdAt": "2026-09-12T15:20:00.000Z",
    "updatedAt": "2026-09-12T15:20:00.000Z"
  }
}
```

---

### 6.9 Update Product
- **Endpoint**: `PATCH /api/v1/menu/products/:id`
- **Auth**: `Bearer <token>` (Owner Only)
- **Request Body**:
```json
{
  "price": 30000,
  "available": true,
  "lowStockThreshold": 12
}
```
- **Response `200 OK`**:
```json
{
  "product": {
    "id": "prod_crib_aren",
    "price": 30000,
    "available": true,
    "lowStockThreshold": 12,
    "stockQuantity": 45,
    "isArchived": false,
    "updatedAt": "2026-09-12T15:25:00.000Z"
  }
}
```

---

### 6.10 Soft Archive Product
- **Endpoint**: `DELETE /api/v1/menu/products/:id`
- **Auth**: `Bearer <token>` (Owner Only)
- **Response `200 OK`**:
```json
{
  "message": "Product successfully archived",
  "id": "prod_coco_cappuccino"
}
```

---

## 7. Orders & POS Endpoints

### 7.1 Create Order (POS Checkout)
- **Endpoint**: `POST /api/v1/orders`
- **Auth**: `Bearer <token>` (Staff or Owner)
- **Request Body**:
```json
{
  "items": [
    {
      "productId": "prod_crib_aren",
      "quantity": 2,
      "variantId": "var_aren_large",
      "addonIds": [
        "add_extra_espresso"
      ]
    },
    {
      "productId": "prod_croissant",
      "quantity": 1,
      "variantId": null,
      "addonIds": [
        "add_caramel_drizzle"
      ]
    }
  ],
  "discount": {
    "type": "fixed",
    "value": 5000,
    "label": "Store Launch Promo"
  }
}
```
- **Calculation Details**:
  - `Item 1`: Base 28,000 + Variant 6,000 + Addon 6,000 = 40,000 x 2 = 80,000
  - `Item 2`: Base 25,000 + Addon 5,000 = 30,000 x 1 = 30,000
  - `Subtotal`: 110,000
  - `Discount`: 5,000
  - `Total`: 105,000
- **Response `201 Created`**:
```json
{
  "order": {
    "id": "ord_a7b8c9d0e1f2",
    "orderNumber": "#CSC-4821",
    "status": "pending",
    "paymentStatus": "unpaid",
    "subtotal": 110000,
    "discountTotal": 5000,
    "total": 105000,
    "createdBy": {
      "id": "usr_staff_01",
      "name": "Barista Sarah"
    },
    "items": [
      {
        "id": "item_112233",
        "productId": "prod_crib_aren",
        "name": "Crib Aren Latte",
        "unitPrice": 40000,
        "quantity": 2,
        "lineTotal": 80000,
        "variantName": "Large (16oz)",
        "addons": ["Extra Espresso Shot"]
      },
      {
        "id": "item_445566",
        "productId": "prod_croissant",
        "name": "Artisan Butter Croissant",
        "unitPrice": 30000,
        "quantity": 1,
        "lineTotal": 30000,
        "variantName": null,
        "addons": ["Salted Caramel Drizzle"]
      }
    ],
    "discount": {
      "id": "disc_998877",
      "type": "fixed",
      "value": 5000,
      "amountApplied": 5000,
      "label": "Store Launch Promo"
    },
    "payments": [],
    "createdAt": "2026-09-12T15:30:00.000Z",
    "updatedAt": "2026-09-12T15:30:00.000Z"
  }
}
```

---

### 7.2 Get Orders List
- **Endpoint**: `GET /api/v1/orders`
- **Query Params**:
  - `status`: `pending` | `paid` | `preparing` | `ready` | `completed` | `cancelled`
  - `orderNumber`: Keyword search (e.g. `1001`)
  - `from`: ISO start date (e.g. `2026-09-01`)
  - `to`: ISO end date (e.g. `2026-09-30`)
  - `page`: Page number (default `1`)
  - `limit`: Items per page (default `20`)
- **Auth**: `Bearer <token>` (Staff or Owner)
- **Response `200 OK`**:
```json
{
  "orders": [
    {
      "id": "ord_sample_01",
      "orderNumber": "#CSC-1001",
      "status": "completed",
      "paymentStatus": "paid",
      "subtotal": 62000,
      "discountTotal": 5000,
      "total": 57000,
      "createdBy": {
        "id": "usr_staff_01",
        "name": "Barista Sarah"
      },
      "items": [
        {
          "id": "item_01_1",
          "name": "Crib Aren Latte",
          "unitPrice": 34000,
          "quantity": 1,
          "lineTotal": 34000,
          "variantName": "Large (16oz)",
          "addons": ["Extra Espresso Shot"]
        }
      ],
      "payments": [
        {
          "id": "pay_01",
          "method": "qris",
          "amount": 57000,
          "status": "paid",
          "externalReference": "QRIS-GOPAY-992817231",
          "paidAt": "2026-09-12T13:16:53.000Z"
        }
      ],
      "createdAt": "2026-09-12T13:16:53.000Z",
      "updatedAt": "2026-09-12T13:16:53.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "totalCount": 1,
    "totalPages": 1
  }
}
```

---

### 7.3 Get Order By ID
- **Endpoint**: `GET /api/v1/orders/:id`
- **Auth**: `Bearer <token>` (Staff or Owner)
- **Response `200 OK`**:
```json
{
  "order": {
    "id": "ord_sample_01",
    "orderNumber": "#CSC-1001",
    "status": "completed",
    "paymentStatus": "paid",
    "subtotal": 62000,
    "discountTotal": 5000,
    "total": 57000,
    "createdBy": {
      "id": "usr_staff_01",
      "name": "Barista Sarah"
    },
    "items": [...],
    "payments": [...],
    "discount": {
      "id": "disc_01",
      "type": "fixed",
      "value": 5000,
      "amountApplied": 5000,
      "label": "Opening Promo Voucher"
    },
    "createdAt": "2026-09-12T13:16:53.000Z",
    "updatedAt": "2026-09-12T13:16:53.000Z"
  }
}
```

---

### 7.4 Update Order Status
- **Endpoint**: `PATCH /api/v1/orders/:id/status`
- **Auth**: `Bearer <token>` (Staff or Owner)
- **Request Body**:
```json
{
  "status": "ready"
}
```
- **Allowed Transitions**:
  - `pending` -> `paid`, `cancelled`
  - `paid` -> `preparing`, `cancelled`
  - `preparing` -> `ready`, `cancelled`
  - `ready` -> `completed`, `cancelled`
- **Response `200 OK`**:
```json
{
  "order": {
    "id": "ord_sample_02",
    "orderNumber": "#CSC-1002",
    "status": "ready",
    "updatedAt": "2026-09-12T15:35:00.000Z"
  }
}
```

---

### 7.5 Track Order by Number
- **Endpoint**: `GET /api/v1/orders/track/:orderNumber`
- **Example**: `GET /api/v1/orders/track/%23CSC-1001`
- **Auth**: None
- **Response `200 OK`**:
```json
{
  "order": {
    "id": "ord_sample_01",
    "orderNumber": "#CSC-1001",
    "status": "completed",
    "paymentStatus": "paid",
    "subtotal": 62000,
    "discountTotal": 5000,
    "total": 57000,
    "items": [
      {
        "name": "Crib Aren Latte",
        "variantName": "Large (16oz)",
        "addons": ["Extra Espresso Shot"],
        "quantity": 1
      }
    ],
    "createdAt": "2026-09-12T13:16:53.000Z"
  }
}
```

---

### 7.6 Get Live Queue Board
- **Endpoint**: `GET /api/v1/orders/queue`
- **Auth**: None
- **Response `200 OK`**:
```json
{
  "queue": {
    "preparing": [
      {
        "id": "ord_sample_02",
        "orderNumber": "#CSC-1002",
        "status": "preparing",
        "createdAt": "2026-09-12T15:00:00.000Z"
      }
    ],
    "ready": [
      {
        "id": "ord_sample_03",
        "orderNumber": "#CSC-1003",
        "status": "ready",
        "createdAt": "2026-09-12T15:10:00.000Z"
      }
    ]
  }
}
```

---

## 8. Payment Endpoints

### 8.1 Process Payment for Order
- **Endpoint**: `POST /api/v1/orders/:id/payment` *(or `POST /api/v1/payments/:id/payment`)*
- **Auth**: `Bearer <token>` (Staff or Owner)
- **Request Body**:
```json
{
  "method": "qris",
  "amount": 75000,
  "externalReference": "QRIS-BCA-981726354"
}
```
- **Allowed Methods**: `cash`, `qris`, `card`, `other`
- **Side Effects**:
  - Validates `amount >= order.total`.
  - Automatically decrements product inventory.
  - If inventory drops to 0, automatically toggles `available = false`.
  - Appends inventory adjustment history.
  - Updates order `payment_status = 'paid'` and `status = 'preparing'`.
- **Response `200 OK`**:
```json
{
  "paymentId": "pay_9f8e7d6c5b4a",
  "orderId": "ord_a7b8c9d0e1f2",
  "orderNumber": "#CSC-4821",
  "method": "qris",
  "amount": 75000,
  "status": "paid",
  "paidAt": "2026-09-12T15:40:00.000Z"
}
```
- **Error Response `409 Conflict` (Idempotency Guard)**:
```json
{
  "error": {
    "code": "CONFLICT",
    "message": "Order has already been paid",
    "details": {}
  }
}
```

---

## 9. Inventory Endpoints

### 9.1 Get Inventory Stock Overview
- **Endpoint**: `GET /api/v1/inventory`
- **Auth**: `Bearer <token>` (Staff or Owner)
- **Response `200 OK`**:
```json
{
  "inventory": [
    {
      "productId": "prod_fudge_brownie",
      "productName": "Sea Salt Fudge Brownie",
      "categoryName": "Pastry & Bites",
      "price": 22000,
      "available": true,
      "lowStockThreshold": 5,
      "quantity": 8,
      "isLowStock": false,
      "lastUpdated": "2026-09-11T13:16:53.000Z"
    },
    {
      "productId": "prod_croissant",
      "productName": "Artisan Butter Croissant",
      "categoryName": "Pastry & Bites",
      "price": 25000,
      "available": true,
      "lowStockThreshold": 15,
      "quantity": 12,
      "isLowStock": true,
      "lastUpdated": "2026-09-11T13:16:53.000Z"
    }
  ]
}
```

---

### 9.2 Get Product Stock by ID
- **Endpoint**: `GET /api/v1/inventory/:productId`
- **Auth**: `Bearer <token>` (Staff or Owner)
- **Response `200 OK`**:
```json
{
  "inventory": {
    "productId": "prod_crib_aren",
    "productName": "Crib Aren Latte",
    "categoryName": "Signature Coffee",
    "price": 28000,
    "available": true,
    "lowStockThreshold": 10,
    "quantity": 45,
    "isLowStock": false,
    "lastUpdated": "2026-09-11T13:16:53.000Z"
  }
}
```

---

### 9.3 Adjust Stock Quantity
- **Endpoint**: `PATCH /api/v1/inventory/:productId`
- **Auth**: `Bearer <token>` (Staff or Owner)
- **Request Body**:
```json
{
  "quantity": 50,
  "available": true,
  "reason": "Weekly fresh bean delivery arrival"
}
```
*Note: You can also pass `"adjustmentQuantity": 5` instead of absolute `"quantity"`.*
- **Response `200 OK`**:
```json
{
  "inventory": {
    "productId": "prod_crib_aren",
    "productName": "Crib Aren Latte",
    "categoryName": "Signature Coffee",
    "price": 28000,
    "available": true,
    "lowStockThreshold": 10,
    "quantity": 50,
    "isLowStock": false,
    "lastUpdated": "2026-09-12T15:45:00.000Z"
  }
}
```

---

### 9.4 Get Stock Adjustment History (Audit Trail)
- **Endpoint**: `GET /api/v1/inventory/adjustments`
- **Query Params**:
  - `productId`: Optional filter
  - `page`: Page number (default `1`)
  - `limit`: Records per page (default `20`)
- **Auth**: `Bearer <token>` (Staff or Owner)
- **Response `200 OK`**:
```json
{
  "adjustments": [
    {
      "id": "adj_init_01",
      "productId": "prod_crib_aren",
      "productName": "Crib Aren Latte",
      "actor": {
        "id": "usr_owner_01",
        "name": "Admin Owner"
      },
      "previousQuantity": 0,
      "adjustmentQuantity": 45,
      "resultingQuantity": 45,
      "reason": "Initial stock inbound for opening",
      "createdAt": "2026-09-11T13:16:53.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "totalCount": 1,
    "totalPages": 1
  }
}
```

---

## 10. Dashboard Metrics Endpoints

### 10.1 Get Dashboard Summary KPIs
- **Endpoint**: `GET /api/v1/dashboard/summary`
- **Query Params**:
  - `from`: ISO start date (e.g. `2026-09-01`)
  - `to`: ISO end date (e.g. `2026-09-30`)
- **Auth**: `Bearer <token>` (Staff or Owner)
- **Response `200 OK`**:
```json
{
  "revenue": 145000,
  "orders": 3,
  "averageOrderValue": 48333.33,
  "lowStockCount": 1,
  "topSellingProducts": [
    {
      "name": "Crib Aren Latte",
      "totalQuantitySold": 4,
      "totalRevenue": 114000
    },
    {
      "name": "Artisan Butter Croissant",
      "totalQuantitySold": 1,
      "totalRevenue": 28000
    }
  ],
  "paymentBreakdown": [
    {
      "method": "qris",
      "transactionCount": 1,
      "totalAmount": 57000
    },
    {
      "method": "cash",
      "transactionCount": 1,
      "totalAmount": 34000
    },
    {
      "method": "card",
      "transactionCount": 1,
      "totalAmount": 54000
    }
  ]
}
```

---

## 11. Staff Management Endpoints

> **Role Guard**: All endpoints under `/api/v1/staff` are strictly restricted to **Owner** role. Staff accounts attempting access will receive `403 FORBIDDEN`.

### 11.1 Get All Staff Accounts
- **Endpoint**: `GET /api/v1/staff`
- **Auth**: `Bearer <token>` (Owner Only)
- **Response `200 OK`**:
```json
{
  "staff": [
    {
      "id": "usr_owner_01",
      "name": "Admin Owner",
      "email": "owner@cribsociety.coffee",
      "role": "owner",
      "isActive": true,
      "createdAt": "2026-09-11T13:16:53.000Z",
      "updatedAt": "2026-09-11T13:16:53.000Z"
    },
    {
      "id": "usr_staff_01",
      "name": "Barista Sarah",
      "email": "sarah@cribsociety.coffee",
      "role": "staff",
      "isActive": true,
      "createdAt": "2026-09-11T13:16:53.000Z",
      "updatedAt": "2026-09-11T13:16:53.000Z"
    }
  ]
}
```

---

### 11.2 Create New Staff User
- **Endpoint**: `POST /api/v1/staff`
- **Auth**: `Bearer <token>` (Owner Only)
- **Request Body**:
```json
{
  "name": "Rian Barista",
  "email": "rian@cribsociety.coffee",
  "password": "password123",
  "role": "staff"
}
```
- **Response `201 Created`**:
```json
{
  "staff": {
    "id": "usr_1a2b3c4d5e6f",
    "name": "Rian Barista",
    "email": "rian@cribsociety.coffee",
    "role": "staff",
    "isActive": true,
    "createdAt": "2026-09-12T15:50:00.000Z",
    "updatedAt": "2026-09-12T15:50:00.000Z"
  }
}
```

---

### 11.3 Get Staff Account By ID
- **Endpoint**: `GET /api/v1/staff/:id`
- **Auth**: `Bearer <token>` (Owner Only)
- **Response `200 OK`**:
```json
{
  "staff": {
    "id": "usr_staff_01",
    "name": "Barista Sarah",
    "email": "sarah@cribsociety.coffee",
    "role": "staff",
    "isActive": true,
    "createdAt": "2026-09-11T13:16:53.000Z",
    "updatedAt": "2026-09-11T13:16:53.000Z"
  }
}
```

---

### 11.4 Update Staff Account
- **Endpoint**: `PATCH /api/v1/staff/:id`
- **Auth**: `Bearer <token>` (Owner Only)
- **Request Body**:
```json
{
  "name": "Sarah Head Barista",
  "isActive": true
}
```
- **Response `200 OK`**:
```json
{
  "staff": {
    "id": "usr_staff_01",
    "name": "Sarah Head Barista",
    "email": "sarah@cribsociety.coffee",
    "role": "staff",
    "isActive": true,
    "createdAt": "2026-09-11T13:16:53.000Z",
    "updatedAt": "2026-09-12T15:55:00.000Z"
  }
}
```

---

## 12. Guest / Public Endpoints

### 12.1 Public Menu
- **Endpoint**: `GET /api/v1/guest/menu`
- **Query Params**: `categoryId` (Optional)
- **Auth**: None
- **Response `200 OK`**:
```json
{
  "categories": [
    {
      "id": "cat_signature",
      "name": "Signature Coffee",
      "sort_order": 1
    }
  ],
  "products": [
    {
      "id": "prod_crib_aren",
      "name": "Crib Aren Latte",
      "description": "Signature espresso, fresh milk, and organic aren palm sugar.",
      "price": 28000,
      "available": true,
      "variants": [
        {
          "id": "var_aren_reg",
          "name": "Regular (12oz)",
          "priceDelta": 0
        }
      ],
      "addons": [
        {
          "id": "add_extra_espresso",
          "name": "Extra Espresso Shot",
          "price": 6000
        }
      ]
    }
  ]
}
```

---

### 12.2 Public Queue Board
- **Endpoint**: `GET /api/v1/guest/queue`
- **Auth**: None
- **Response `200 OK`**:
```json
{
  "queue": {
    "preparing": [
      {
        "id": "ord_sample_02",
        "orderNumber": "#CSC-1002",
        "status": "preparing"
      }
    ],
    "ready": [
      {
        "id": "ord_sample_03",
        "orderNumber": "#CSC-1003",
        "status": "ready"
      }
    ]
  }
}
```

---

### 12.3 Public Order Tracking
- **Endpoint**: `GET /api/v1/guest/track/:orderNumber`
- **Auth**: None
- **Response `200 OK`**:
```json
{
  "order": {
    "orderNumber": "#CSC-1001",
    "status": "completed",
    "paymentStatus": "paid",
    "subtotal": 62000,
    "discountTotal": 5000,
    "total": 57000,
    "items": [
      {
        "name": "Crib Aren Latte",
        "variantName": "Large (16oz)",
        "addons": ["Extra Espresso Shot"],
        "quantity": 1
      }
    ],
    "createdAt": "2026-09-11T13:16:53.000Z"
  }
}
```
