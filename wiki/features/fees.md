---
feature: fees
last_tested: 2026-05-16
tester: product-tester
verdict: SHIP
persona: Mrs. Verma, accountant at a 1,200-student CBSE school in Indore
---

# Fees & Payments

## At a Glance
- **Verdict:** SHIP — 5 of 6 dead buttons wired (2026-05-16). Fee Structure CRUD intentionally deferred to Sprint 1.6 per architect. Core data layer solid + actions now functional.
- **Entry screen:** [[../../lib/features/fees/presentation/screens/fees_screen.dart]]
- **Roles with access:** admin, tenant_admin, principal, accountant (4-tab view); parent, student (2-tab view)

## Axis 1 — Works?

**Pass:**
- Real fee stats with retry + AppColors-aware error UI — `fees_screen.dart:91-110` (admin overview) and `:240-273` (recent payments).
- Real invoice list with client-side pagination — `:543-657`.
- Parent flow correctly redirects "Pay Now" to `paymentCheckout` route — `:1120-1124`.
- AI-generated reminder dialog wired to a real `aiTextGeneratorProvider` with graceful fallback string — `:1808-1842`.
- Reminder logging persists via `feeRepositoryProvider.logReminderSent` — `:1844-1854`.

**Pass (added 2026-05-16 — 5 wires):**
- `_QuickAction "Generate Invoices"` now routes to `AppRoutes.feeManagement` (`/admin/fees`).
- `_QuickAction "Send Reminders"` now bulk-fetches overdue invoices, shows confirmation dialog, calls `logReminderSent` for each, and reports success count.
- `_QuickAction "Export Report"` now builds a PDF via `FeesPdfBuilder` and calls `Printing.sharePdf`.
- `_CollectionTab` Export button now calls the same `FeesPdfBuilder.buildAndShare`.
- Invoice card `View` button now opens `_InvoiceDetailSheet` modal with full invoice fields + Record Payment shortcut.

**Deferred (Sprint 1.6 — per architect decision):**
- `_QuickAction "Fee Structure"` — CRUD for fee structure remains a snackbar placeholder. Wiring blocked on Sprint 1.6 ticket.

**Previously passing:**
- Real fee stats with retry + AppColors-aware error UI.
- Real invoice list with client-side pagination.
- Parent flow correctly redirects "Pay Now" to `paymentCheckout` route.
- AI-generated reminder dialog wired to a real `aiTextGeneratorProvider` with graceful fallback string.
- Reminder logging persists via `feeRepositoryProvider.logReminderSent`.

## Axis 2 — Good?

- **Taps to primary admin action:** N/A — the primary action doesn't exist. To create an invoice today, admin must go through `feeManagement` route in a separate flow.
- **Taps to primary parent action (Pay Now):** 2 taps (open Fees tab → Pay Now). Good.
- **Labels:** "Total Collection / Pending / Overdue / Today" — clean, no jargon. Currency is correctly formatted in lakhs (`₹4.2L`) — `:118-122`. This is the *only* screen I saw with proper Indian lakh formatting. Good.
- **Empty state:** "No invoices found" with icon — `:580-590`. Functional but flat. Should suggest the next action: "Generate this term's invoices" (which routes to the form that doesn't exist yet).
- **Reports tab dropdowns have `onChanged: (value) {}`** — `attendance_screen.dart:456, 474`. Same anti-pattern; flag also lives here.

## Axis 3 — Necessary?

YES — fees is the **single most important feature** for an Indian K-12 SaaS purchase decision. Schools typically already use Tally or Excel for fees; the SaaS has to clearly beat that baseline. The Risk-tab predictive default scoring (`feeDefaultPredictionsProvider`) is actually an excellent unique selling point — Tally cannot do that. But it's hidden behind a broken Overview tab.

No overlap with other modules. `payment_checkout_screen.dart`, `payment_history_screen.dart`, `payment_gateway_screen.dart` form a clean payment subsystem.

## Fixed 2026-05-16

Five of six dead quick-action snackbars replaced with real implementations:

1. **Generate Invoices** (`fees_screen.dart` — `_AdminOverviewState.build`) — `context.push(AppRoutes.feeManagement)`.
2. **Send Reminders** (`fees_screen.dart` — `_AdminOverviewState._sendBulkReminders`) — loads overdue invoices, confirmation dialog, bulk `logReminderSent`.
3. **Export Report** (`fees_screen.dart` — `_AdminOverviewState._exportReport`) — `FeesPdfBuilder.buildAndShare`.
4. **Collection Export** (`fees_screen.dart` — `_CollectionTabState._exportCollectionReport`) — same `FeesPdfBuilder.buildAndShare`.
5. **Invoice View** (`fees_screen.dart` — `_InvoiceCard.build`) — `showModalBottomSheet` with `_InvoiceDetailSheet`.

New files:
- `lib/features/fees/utils/fees_pdf_builder.dart` — shared PDF builder used by Fix 3 + Fix 4.
- `test/fees/fees_actions_test.dart` — 5 widget tests, all pass.

Fee Structure CRUD remains deferred to Sprint 1.6.

## Axis 4 — Improvable?

- [x] Wire 5 of 6 Quick Actions — done 2026-05-16.
- [ ] Wire **Fee Structure** CRUD — Sprint 1.6 ticket.
- [ ] Demote Risk tab to "Predictive" tab name and feature it prominently — it's the most unique thing in the module.
- [ ] Replace `attendance_screen.dart` dropdowns + this screen's Period/Class filters with state that actually filters the providers (currently `onChanged: (value) {}` — `attendance_screen.dart:456, 474`).
- [ ] Merge `fee_management_screen.dart` (in `lib/features/admin/`) into this module — it's the missing "Fee Structure" target. The fact that Admin → Fees and Fees → Quick Actions both lead to the same conceptual destination but route to different screens is a code-smell.
- [ ] Split: the AI reminder generation + risk-scoring substack deserves its own feature page (e.g. `features/fee_intelligence.md`) — it's productizable separately.

## Notes for the panel

- **Critic:** is the Risk tab worth the AI cost on a Tier-2 Indian school subscription? Need price/feature math.
- **Product-intel:** what do MyClassboard, Edsys, Teachmint charge for "predictive fee defaulter scoring"? If it's a $10/month uplift, this changes the whole product positioning.
- **Architect:** `_QuickAction "Fee Structure"` is the canonical case for whether we should keep `fee_management_screen.dart` in `features/admin/` or move it under `features/fees/`. Decide once, document in [[decisions/]].
- **UX-expert:** the AI badge in the reminder dialog (`fees_screen.dart:1882-1901`) is excellent micro-copy — the same pattern should appear on every AI-touched surface in the app.

## Backlinks

- [[../00 Index]]
- [[../_feature_inventory_2026-05-16]]
- [[../panels/feature-audit-2026-05-16]]
