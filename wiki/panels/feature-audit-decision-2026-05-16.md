---
panel: feature-audit-decision
date: 2026-05-16
moderator: panel-moderator (synthesized by jarvis orchestrator)
panelists: [critic, architect, product-intel, ceo-founder, head-of-product]
decision: KILL ai_tutor + Sprint 1.5 ship-blocker on dashboard mock data + fees actions
status: DECIDED
deploy_gate: SPRINT 1 + 1.5 (no production deploy until 1.5 ships)
---

# Panel Decision — Feature Audit 2026-05-16

## The Questions
1. Should `ai_tutor` be killed?
2. Are admin dashboard mock surfaces a Sprint 1.5 ship-blocker?
3. Should fees snackbars promote from Sprint 3 to Sprint 1.5?

## Panelists & Verdicts

| Panelist | Finding 1 (ai_tutor) | Finding 2 (dashboard) | Finding 3 (fees) | Key argument |
|---|---|---|---|---|
| **critic** | KILL | BLOCKER, 1.5 | PROMOTE, 1.5 | "Team is decorating screens instead of completing modules — pick ONE module (fees) and ship it end-to-end" |
| **ceo-founder** | KILL | BLOCKER, 1.5 | PROMOTE, 1.5 | "Security without sellability is engineering theater. Deploy gate = SPRINT 1+1.5" |
| **product-intel** | SCOPE-DOWN (future paid SKU) | BLOCKER (hide activity feed, no competitor has it) | PROMOTE (MyClassboard ships invoice-gen 1-click) | "No Indian K-12 SaaS bundles AI tutoring at this price band. Bus tracking + WhatsApp arrival alerts is the real differentiator (already built)" |
| **head-of-product** | KILL (Western fake names = trust rupture; no Sales line) | BLOCKER (half-day fix; first screen lies = product is theater) | PROMOTE (sales coach around once, accountant kills deal silent at trial) | "Mrs. Verma the accountant runs invoicing on day 1 of the term. If 'Generate Invoices' returns snackbar, evaluation ends" |
| **architect** | (out of scope) | APPROVE-AND-EXECUTE; ~4 hrs; 4/5 are one-line provider swaps | APPROVE 5 of 6 in 1.5; DEFER Fee Structure CRUD (~1.5 day) to Sprint 1.6 | "All deps in pubspec. Reuse `notification_repository` for activity feed — don't scaffold an `audit_logs` table" |

## Where they agreed (4-of-5 or 5-of-5 consensus)

- 🔴 **`ai_tutor` KILL** — 4 of 5 say KILL outright. product-intel's SCOPE-DOWN add: keep the *idea* for a future paid SKU, but delete the folder *now*. No engineering investment until unit economics support it (parent app subscription tier? not the school ERP).
- 🔴 **Dashboard mock data is a SHIP-BLOCKER** — 5 of 5. Half-day to one-day fix per architect's mapping.
- 🔴 **Fees snackbars promote to Sprint 1.5** — 5 of 5. Architect carves Fee Structure CRUD out as a separate Sprint 1.6 ticket.
- 🟢 **Deploy gate = SPRINT 1 + Sprint 1.5** — CEO explicit. Sprint 2 (tenant-isolation hardening) follows.

## Where they disagreed (logged but not deciding)

- **product-intel vs the other 3 on ai_tutor:** "SCOPE-DOWN to future paid SKU" vs "KILL clean." Resolution: KILL the folder now, file a 1-pager idea in `wiki/decisions/2026-05-16-ai-tutor-future-sku.md` so the SKU thought survives the deletion. We are not scoping down code that has no entry screen — that's the team negotiating with sunk cost (critic's framing).
- **head-of-product vs product-intel on dashboard feed:** product-intel: "Hide the activity feed entirely; no competitor has it." HoP: "Hide it OR seed with realistic Indian names + connect to provider." Resolution: HIDE for now (architect path is cleanest; building a real activity feed is Sprint 1.6 if customers ask).

## Moderator's call (final decision)

**Sprint 1.5 — 1 week — between current Sprint 1 closure and Sprint 2 tenant-isolation work. Deploy gate: NO production deploy until 1.5 ships.**

The unanimous customer-side voice (CEO + HoP + product-intel + critic) is louder than architect's "this is fine, just APPROVE." Architect's analysis is *how* to fix; the verdict is *whether* to fix now. All 4 customer-facing voices say now.

The deeper signal — critic's "the team is decorating screens instead of completing modules" — is the long-term structural finding. The Sprint 1.5 fixes are tactical; the strategic correction is the CEO's new rule: **no new feature folder without a 1-pager naming (a) the paying buyer, (b) the KPI it moves, (c) the unit economics, signed off by architect before `flutter create` runs.** This is the prevention rule that keeps another `ai_tutor` from sneaking in.

## Action items (handed off to executor agents)

### Sprint 1.5 — Week of 2026-05-19

**A. KILL `ai_tutor`** (owner: `refactor-cleaner`)
- [ ] Delete `lib/features/ai_tutor/`
- [ ] Grep callers of `tutor_chat_overlay.dart` and `ai_tutor_provider.dart`; remove mounts
- [ ] Remove `ai_tutor` from `pubspec.yaml` assets if listed
- [ ] If any route registered → remove from `app_router.dart`
- [ ] Run `flutter analyze lib/` — expect 0 new errors

**B. Admin dashboard mock-data fixes** (owner: `refactor-cleaner` + arch's provider map)
- [ ] `:354` 94.2% → `todayAttendancePercentageProvider` (`attendance_provider.dart:50`)
- [ ] `:463` Students present → `attendanceSummaryProvider(today)` (`attendance_provider.dart:33`)
- [ ] `:469` Teachers present → new `staffAttendanceTodayProvider` thin wrapper
- [ ] `:477` Outstanding Invoices → `feeCollectionStatsProvider(null).outstanding`
- [ ] `:485` Scheduled Events → DEFER (no events provider yet; Sprint 1.6)
- [ ] `:494-511` Recent Activity → HIDE the section (no competitor has it; product-intel + architect agreement)
- [ ] `:944` Profile tile dead onTap → route to `AppRoutes.profile`
- [ ] `:977` Settings tile dead onTap → hide or route

**C. Fees snackbars → real wires** (owner: `tdd-guide`)
- [ ] `:192` Generate Invoices → push `FeeManagementScreen` + add `generateForPeriod()` to `feesNotifierProvider`
- [ ] `:203` Send Reminders → bulk-wrap `_sendReminder()` at `:1844` over overdue invoices
- [ ] `:214` Export Report → `Printing.sharePdf()` (use existing `printing:^5.12.0`)
- [ ] `:721` Collection Export → same util
- [ ] `:1108` View Invoice → push existing `payment_history_screen.dart` or detail sheet
- [ ] DEFER `:225` Fee Structure CRUD → Sprint 1.6 (~1.5 days; needs schema review)

### Sprint 1.6 — Backlog (deferred to next 1-pager)
- [ ] Fee Structure CRUD form
- [ ] Real `eventsProvider` for scheduled events tile
- [ ] (Optional) Real `activityFeedProvider` only if pilot schools ask for it

### Strategic / org change
- [ ] **New rule** — every new `lib/features/<name>/` folder requires a 1-pager (Buyer / KPI / Unit-economics) signed off by architect before scaffolding. CEO-decided 2026-05-16.

## Backlinks
- [[../00 Index]]
- [[feature-audit-2026-05-16]]
- [[../pending]]
- [[../features/ai_tutor]]
- [[../features/dashboard]]
- [[../features/fees]]
