# AGENTS.md — Crib Society Coffee
Version: 0.2.0

## Mission
Implement Crib Society Coffee strictly from the SOT: Landing Page, POS, and Owner/Staff operational Dashboard.

## Source of Truth
Read and reconcile:
1. `sot/PRD.md`
2. `sot/USER-FLOW.md`
3. `sot/UI-GUIDELINE.md`
4. `sot/API-SPEC.md`
5. `sot/BUSINESS-RULES.md`
6. `sot/DATABASE-SPEC.md`
7. `sot/IMPLEMENTATION-PLAN.md`

If implementation conflicts with SOT, stop and resolve the conflict before expanding scope.

## Stack Contract
- React
- Vite
- Tailwind CSS
- Responsive HTML/CSS

Do not replace the stack without explicit approval.

## Architecture Contract
- Component-driven React.
- Centralized API client.
- Business rules must not be duplicated across UI components.
- API/database contracts stay aligned.
- Prefer reusable primitives over page-specific duplicates.
- Keep domain logic separate from presentational UI.
- Never expose secrets through Vite client variables.

## Business Rules Contract
`BUSINESS-RULES.md` is authoritative for roles, permissions, availability, inventory integrity, order lifecycle, payment, discounts, checkout, dashboard calculations, and audit requirements.

Do not weaken these rules for UI convenience.

## Database Contract
`DATABASE-SPEC.md` is authoritative for entities, relationships, historical snapshots, transactional persistence, inventory history, payments, audit logs, archival, and migrations.

Never silently invent tables, fields, relationships, or destructive operations.

## Security
- Server-side authorization is mandatory.
- Client role checks are UX only.
- Validate price, totals, discounts, availability, and status transitions server-side.
- Never trust client-calculated checkout totals.
- Preserve auditability for business-critical mutations.

## UI Contract
Follow `UI-GUIDELINE.md`: red primary, black secondary, white accent, cream neutral, modern Gen Z/premium-casual direction, accessible contrast/focus, responsive behavior, and fast POS interactions.

Every relevant screen must account for loading, empty, error, success, and unavailable states.

## Scope Discipline
Do not add loyalty, delivery, accounting, payroll, tax engine, supplier purchasing, multi-store tenancy, native mobile app, or provider-specific payment behavior unless the SOT is explicitly changed.

## Change Protocol
1. Identify affected SOT documents.
2. Check business-rule impact.
3. Check database/API impact.
4. Check user-flow impact.
5. Implement the smallest compliant change.
6. Update SOT only when the requirement itself changes.

## Validation
Before completion:
- run available lint/build/type checks
- test primary and exception flows
- test mobile/tablet/desktop
- verify API errors and permissions
- verify historical transactions are never destructively modified
- verify no out-of-scope feature was introduced

## Token-Efficient Agent Behavior
Read only relevant SOT sections first. Reuse components/tokens. Avoid unnecessary refactors. Prefer concise diffs. Do not regenerate unrelated files. Ask for SOT clarification rather than guessing.

## Completion Report
Return: Completed; Files changed; SOT requirements satisfied; Validation performed; Business-rule/database impact; Blockers/ambiguities; Next approved step.
