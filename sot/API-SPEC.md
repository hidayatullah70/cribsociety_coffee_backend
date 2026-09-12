# Crib Society Coffee — API Spec
Version: 0.1.0
Style: REST JSON
Base path: /api/v1

## 1. Conventions
JSON request/response.
ISO-8601 timestamps.
IDs are opaque strings.
Errors use a consistent envelope.

### Error Envelope
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Human-readable message",
    "details": {}
  }
}

## 2. Auth
POST /auth/login
Request: { "email": "...", "password": "..." }
Response: { "user": { "id": "...", "role": "owner|staff" }, "session": { "expiresAt": "..." } }

POST /auth/logout
GET /auth/me

## 3. Menu
GET /menu/categories
GET /menu/products?categoryId=&available=
GET /menu/products/:id

Owner:
POST /menu/products
PATCH /menu/products/:id
DELETE /menu/products/:id

Product shape:
{
  "id": "prod_...",
  "categoryId": "cat_...",
  "name": "Iced Latte",
  "description": "...",
  "price": 28000,
  "available": true,
  "variants": [],
  "addons": []
}

## 4. Orders
POST /orders
GET /orders?status=&from=&to=&page=
GET /orders/:id
PATCH /orders/:id/status

Create order:
{
  "items": [
    {
      "productId": "prod_...",
      "quantity": 1,
      "variantId": null,
      "addonIds": []
    }
  ],
  "discount": null
}

Response includes:
id, orderNumber, items, subtotal, discount, total, paymentStatus, orderStatus, createdAt.

## 5. Payments
POST /orders/:id/payment
Request:
{ "method": "cash|qris|card|other", "amount": 28000 }
Response:
{ "paymentId": "pay_...", "status": "paid|failed|cancelled", "paidAt": "..." }

Payment provider integration details are intentionally deferred.

## 6. Inventory
GET /inventory
GET /inventory/:productId
PATCH /inventory/:productId
Request:
{ "quantity": 12, "available": true }

## 7. Dashboard
GET /dashboard/summary?from=&to=
Response:
{
  "revenue": 0,
  "orders": 0,
  "averageOrderValue": 0,
  "lowStockCount": 0
}

## 8. Staff
GET /staff
POST /staff
PATCH /staff/:id
Owner-only unless policy says otherwise.

## 9. Front-end API Rules
- Centralize API client.
- Never call fetch directly from deeply nested UI components.
- Model loading/error/success states.
- Normalize API errors into UI-safe messages.
- Never expose secrets in Vite client variables.
