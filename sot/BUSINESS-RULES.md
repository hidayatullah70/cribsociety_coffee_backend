# Crib Society Coffee — BUSINESS RULES
Version: 0.2.0

## 1. Purpose
Operational rules governing Landing Page, POS, Owner/Staff Dashboard, API, and database behavior.

## 2. Roles & Permissions
### Owner
- Full operational access.
- Manage products, inventory, staff, orders, reports, and permitted store settings.
- Access owner-only configuration and destructive operations.

### Staff
- Operate POS.
- View/process permitted orders.
- Perform explicitly permitted inventory/status actions.
- Cannot manage staff or owner-only configuration.

Server-side authorization is mandatory; UI restrictions are not security controls.

## 3. Product Rules
- Every product belongs to one category.
- Product name is required; price must be >= 0.
- Unavailable products cannot be added to a new order.
- Completed orders retain product name and price snapshots.
- Products referenced by transactions should be archived rather than hard-deleted.
- Variants/add-ons must reference valid active records.

## 4. Inventory Rules
- Quantity cannot become negative.
- `available=false` prevents new sales.
- Low-stock state uses the configured threshold.
- Inventory mutations record actor, previous quantity, adjustment, resulting quantity, reason, and timestamp.
- Inventory history is append-only.

## 5. Order Rules
- An order must contain at least one item.
- Quantity must be a positive integer.
- Server is authoritative for subtotal, discount, and total.
- Client totals are display-only.
- Order number must be unique within its numbering scope.
- Paid/completed orders cannot be silently edited.
- Cancelled orders are excluded from completed sales.
- Historical order items preserve snapshots.

## 6. Payment Rules
- Payment must cover the final order total.
- Successful payment => `PAID`.
- Failed/cancelled payment cannot complete an order.
- Payment retries must be idempotent.
- Duplicate successful payment for the same order is prohibited.
- Successful payment records are immutable except through a future explicit reconciliation workflow.

## 7. Discount Rules
- Discounts are optional.
- Final total cannot become negative.
- Only authorized roles may apply discounts.
- Discount calculations are server-validated.
- Applied discount details are preserved on completed orders.

## 8. Order Status
Recommended lifecycle: `PENDING → PAID → PREPARING → READY → COMPLETED`.
Permitted pre-completion states may transition to `CANCELLED` according to policy. Invalid transitions are rejected.

## 9. Checkout
Validate availability → validate quantities → calculate authoritative totals → persist order → process/register payment → confirm payment → update order → return order number/receipt.

Payment failure must leave the transaction recoverable and never appear as paid.

## 10. Dashboard
- Revenue uses qualifying sales only.
- Cancelled orders are excluded.
- Average order value = qualifying revenue / qualifying order count.
- Date filters use store-local time.
- Staff sees only authorized operational data.

## 11. Audit
Business-critical mutations should record actor, action, entity, entity ID, timestamp, and relevant metadata. At minimum: inventory, product, staff, discounts, and order-status changes.

## 12. Data Integrity
- Never hard-delete historical transactional records.
- Money uses exact integer/numeric representation, never floating point.
- Server/database is authoritative for permissions, prices, totals, and state.
- Concurrent conflicts fail safely rather than overwrite newer data.

## 13. Scope Guard
Do not introduce loyalty, delivery, accounting, payroll, tax engine, supplier purchasing, multi-store tenancy, or advanced promotions without an explicit SOT change.
