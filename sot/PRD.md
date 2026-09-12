# Crib Society Coffee — PRD
Version: 0.1.0
Status: Contract Draft
Scope: Landing Page + POS + Owner/Staff Operations Dashboard

## 1. Product Vision
Crib Society Coffee is a modern coffee-shop web application combining a conversion-focused public landing page, fast counter-service POS, and role-aware operational management.

Design direction: Gen Z, editorial, bold, warm, premium-casual.
Brand palette: Red primary, Black secondary, White accent, Cream neutral, supported by muted warm utility colors.

## 2. Goals
- Convert visitors into store visits/orders.
- Let staff complete a sale with minimal interaction.
- Give owner/staff a single operational view.
- Keep UI responsive from mobile to desktop.
- Keep architecture SOT-driven and implementation-ready without premature feature expansion.

## 3. Non-Goals
- Native mobile app.
- Accounting/tax platform.
- Delivery marketplace.
- Loyalty/membership system.
- Advanced BI/data warehouse.
- Kitchen Display System unless later added to scope.

## 4. Roles
### Owner
Full operational visibility and configuration.

### Staff
POS, order handling, basic inventory/status actions, and operational dashboard access permitted by policy.

### Guest
Public customer / counter visitor. Read-only access to live order queue display, live menu catalog availability, store status, and personal order status lookup by order number. Protected operational actions (financial KPIs, inventory adjustment, staff configuration) are strictly restricted.

## 5. Modules
### A. Landing Page
Sections:
1. Hero / brand statement / primary CTA
2. Featured menu
3. Brand story
4. Store information
5. Social proof / selected highlights
6. Footer

Primary CTA: View Menu / Order at Counter.
Secondary CTA: Visit Us.

### B. POS
Core flow:
- Start order
- Select category
- Select product
- Configure variants/add-ons
- Review cart
- Apply allowed discount
- Select payment method
- Confirm payment
- Issue receipt/order number
- Reset for next customer

Required states:
- Empty cart
- Active cart
- Product unavailable
- Payment pending
- Payment success
- Payment failed/cancelled
- Order completed

### C. Operations Dashboard
Owner:
- Overview KPIs
- Sales/orders
- Products/menu
- Inventory
- Staff
- Store settings
- Reports

Staff:
- Shift overview
- POS
- Active orders
- Basic product availability
- Limited inventory/status actions

Guest (Customer Board):
- Live queue status monitor ('Now Brewing', 'Ready for Pickup')
- Order status tracker by order number (#CSC-xxxx)
- Digital live menu & availability
- Store open/busy status

## 6. Functional Requirements
### FR-01 Authentication
Role-aware sign-in and session handling.

### FR-02 POS
Create, update, remove, and complete orders. Prevent checkout with unavailable products.

### FR-03 Menu
View product/category data and availability.

### FR-04 Inventory
Track stock quantity/status at product level. Low-stock and out-of-stock states must be visible.

### FR-05 Orders
Persist order status and payment status. Provide order number and timestamp.

### FR-06 Dashboard
Show revenue, order count, average order value, and operational alerts for the selected period.

### FR-07 Access Control
Owner-only actions must be hidden/blocked for staff.

### FR-08 Responsive UI
All public and operational screens must work at mobile, tablet, and desktop breakpoints.

## 7. UX Principles
- POS: speed first.
- Dashboard: hierarchy first.
- Landing: brand and conversion first.
- Use progressive disclosure for complex actions.
- Always expose clear success/error feedback.
- Avoid modal overload.

## 8. Acceptance Criteria
A feature is ready when:
- Its user flow exists in USER-FLOW.md.
- Its visual rules comply with UI-GUIDELINE.md.
- Its request/response contract exists in API-SPEC.md when backend data is involved.
- Its implementation sequence exists in IMPLEMENTATION-PLAN.md.
- Empty/loading/error/success states are defined.
- Responsive behavior is defined.

## 9. MVP Priority
P0: Landing core, auth, POS checkout, menu, orders, role access.
P1: Inventory, dashboard KPIs, product management, staff operational view.
P2: Reports, advanced configuration, polish/optimization.
