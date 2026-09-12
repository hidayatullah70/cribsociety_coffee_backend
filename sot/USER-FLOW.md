# Crib Society Coffee — User Flow
Version: 0.1.0

## 1. Visitor Flow
Landing → Hero CTA → Menu → Product detail → Store info → Visit/order decision.

## 2. Staff Sign-in Flow
Sign-in → Role validation → Staff dashboard/POS → Active shift context.

## 3. POS Main Flow
New Order
→ Select category
→ Select item
→ Configure item
→ Add to cart
→ Review cart
→ Payment method
→ Confirm
→ Payment result
→ Order completed
→ Receipt/order number
→ New Order

### POS Exception Flows
- Item unavailable → disable add-to-cart + explain reason.
- Invalid quantity → inline validation.
- Payment failed → preserve cart + retry/change payment.
- Checkout cancelled → return to cart without losing order.
- Network/API error → show recoverable state; do not silently clear cart.

## 4. Order Management Flow
Dashboard → Orders → Filter/status → Order detail → Update permitted status → Confirmation.

Suggested status:
PENDING → PAID → PREPARING → READY → COMPLETED
Exception: CANCELLED.

## 5. Inventory Flow
Dashboard → Inventory → Search/filter → Product → Adjust stock/status → Confirm → Updated state.

Staff permissions should be narrower than owner permissions.

## 6. Product Management Flow
Owner dashboard → Products → Create/edit product → Price/category/availability → Save → Success feedback.

## 7. Staff Flow
Staff dashboard → Shift snapshot → POS / Active orders / Allowed inventory actions → End-of-shift summary.

## 7B. Guest Flow
Guest dashboard / Order tracker:
Guest / Board View → Track order by number OR view live queue board → Real-time status update ('PREPARING' / 'READY') → Pickup decision.

## 8. Owner Flow
Owner dashboard → KPI overview → Sales/orders → Inventory → Products → Staff → Settings/Reports.

## 9. Global UI States
Every data screen:
Loading → Content
Loading → Empty
Loading → Error → Retry
Action → Success/Error feedback

Destructive action:
Intent → Confirmation → Execute → Result.
