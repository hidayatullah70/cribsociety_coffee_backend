# Crib Society Coffee — DATABASE SPECIFICATION
Version: 0.2.0

## 1. Principles
- Relational database is recommended.
- Use opaque UUID/string IDs.
- Use exact integer/numeric representation for money.
- Use consistent server timestamps.
- Enforce relationships with foreign keys.
- Preserve transactional history.
- Every schema change uses a migration.

## 2. Core Tables
### users
`id PK`, `name`, `email UNIQUE`, `password_hash`, `role(owner|staff)`, `is_active`, `created_at`, `updated_at`

### categories
`id PK`, `name`, `sort_order`, `is_active`, `created_at`, `updated_at`

### products
`id PK`, `category_id FK`, `name`, `description NULL`, `price`, `available`, `low_stock_threshold NULL`, `is_archived`, `created_at`, `updated_at`

Indexes: `category_id`, `available`, `is_archived`, `(category_id, available)`.

### product_variants
`id PK`, `product_id FK`, `name`, `price_delta`, `is_active`, `created_at`, `updated_at`

### addons
`id PK`, `name`, `price`, `is_active`, `created_at`, `updated_at`

### product_addons
`product_id FK`, `addon_id FK`, composite PK.

## 3. Orders
### orders
`id PK`, `order_number`, `status`, `payment_status`, `subtotal`, `discount_total`, `total`, `created_by FK users`, `created_at`, `updated_at`

Constraints: subtotal/discount_total/total >= 0; order number unique within configured scope.

Indexes: `status`, `payment_status`, `created_at`, `created_by`.

### order_items
`id PK`, `order_id FK`, `product_id FK NULL`, `product_name_snapshot`, `unit_price`, `quantity`, `line_total`, `variant_name_snapshot NULL`, `addon_snapshot JSON/TEXT NULL`, `created_at`

Constraints: quantity > 0; unit_price/line_total >= 0. Historical snapshots are mandatory.

## 4. Payments
### payments
`id PK`, `order_id FK`, `method(cash|qris|card|other)`, `amount`, `status(pending|paid|failed|cancelled)`, `external_reference NULL`, `paid_at NULL`, `created_at`, `updated_at`

Indexes: `order_id`, `status`, `external_reference`.
A future idempotency mechanism must prevent duplicate successful payment processing.

## 5. Inventory
### inventory
`product_id PK/FK`, `quantity`, `updated_at`; constraint `quantity >= 0`.

### inventory_adjustments
`id PK`, `product_id FK`, `actor_user_id FK`, `previous_quantity`, `adjustment_quantity`, `resulting_quantity`, `reason`, `created_at`

Append-only history.

## 6. Discounts
### discounts
`id PK`, `order_id FK`, `type(fixed|percentage)`, `value`, `amount_applied`, `label NULL`, `created_at`

Completed order discount data must remain reproducible.

## 7. Audit
### audit_logs
`id PK`, `actor_user_id FK NULL`, `action`, `entity_type`, `entity_id`, `metadata JSON/TEXT NULL`, `created_at`

Indexes: `actor_user_id`, `(entity_type, entity_id)`, `created_at`.

## 8. Relationships
- users 1:N orders
- users 1:N inventory_adjustments
- users 1:N audit_logs
- categories 1:N products
- products 1:N product_variants
- products N:N addons
- products 1:1 inventory
- products 1:N inventory_adjustments
- products 1:N order_items
- orders 1:N order_items
- orders 1:N payments
- orders 1:N discounts

## 9. Transaction Boundaries
Checkout should use an atomic transaction where supported: validate → persist order → payment state → final order state.
Inventory adjustment: read → validate non-negative → update → append adjustment history.

## 10. Archival
Prefer `is_archived` / `is_active` for products, categories, and staff accounts when historical references exist.
Never hard-delete completed orders, order items, successful payments, inventory adjustments, or audit logs.

## 11. Reporting
Dashboard summary derives from transactional data unless a later approved performance design introduces aggregates: revenue, order count, average order value, low-stock count. Reporting boundaries use store-local time.

## 12. Migration Rules
Every schema change requires a migration. Destructive changes require explicit SOT approval. Seed data is separated from production migration logic.

## 13. Deferred Decisions
Do not prematurely lock database vendor, ORM/query builder, session persistence, payment-provider schema, multi-store tenancy, tax configuration, receipt printer integration, supplier/purchasing, or advanced reporting aggregates.
