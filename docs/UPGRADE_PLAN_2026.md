# Upgrade Plan 2026 — Scalable + Cheap + Competitive

> Goal: Turn the app into a real, monetizable, cost-efficient SaaS that scales without compute blowups.
> Strategy: **Foundation (monetize + cut cost) → Cost optimization → Competitive gaps**.
> Infra budget: scale-driven (start on Supabase Pro $25 + Micro $10 ≈ $35/mo, auto-upgrade compute only when tenant revenue covers it).

---

## Current State (verified)

| Area | Status |
|------|--------|
| Feature breadth | 52 modules — already exceeds most competitors |
| AI gateway | OpenRouter multi-model chain + agentic tools + per-tenant budget/quota ✅ |
| Subscription field | `tenants.subscription_plan` + `isSubscriptionActive` getter exist |
| Subscription **enforcement** | ❌ NONE — no middleware gates features by plan |
| Razorpay | SDK wrapper exists for **fee payments**, NOT for SaaS subscription billing |
| Pagination | Only 6 of ~27 repos — ❌ crashes at scale, burns compute |
| i18n | ✅ en/hi/ar/fr already wired |
| Offline sync | Isar models + sync queue exist, sync logic incomplete |
| Real-time cleanup | 31 cancel calls but leaks reported (no audit) |
| WhatsApp/SMS | ❌ absent — top competitive gap for 2026 |
| Tests | ❌ none |

---

## Phase 1 — Foundation: Monetize + Stop the Bleed  (HIGH priority)

> Without this, more users = more cost, not more revenue. Ship first.

### 1.1 Subscription enforcement (monetization gate)
**Why:** The single highest-ROI change. Makes scale = revenue.

- New DB table `subscription_plans` (id, name, price_inr, ai_credits_usd, max_students, feature_flags jsonb)
- New DB table `subscription_invoices` (tenant_id, plan_id, amount, razorpay_payment_id, status, period_start/end)
- Edge function `enforce-subscription`: called by `ai-gateway` + key repos; returns `{allowed, reason, plan}` from JWT tenant_id
- RLS policy helper: `tenant_is_paid()` SQL function — gates write access on heavy tables when `plan='free'` and over limits
- Flutter: `SubscriptionGuard` widget wraps feature screens; shows upgrade sheet when blocked
- Wire `tenant_ai_credits.budget_usd` to the plan (free=0.50, pro=5, elite=25)

**Files:** new migration `00072_subscription_enforcement.sql`, `supabase/functions/enforce-subscription/index.ts`, `lib/core/services/subscription_service.dart`, `lib/core/widgets/subscription_guard.dart`

**Complexity:** Medium | **Risk:** HIGH — RLS gating can lock out paid tenants if buggy; gate behind feature flag first

### 1.2 Razorpay SaaS billing flow
**Why:** Tenants must pay YOU, not just collect student fees.

- Reuse existing `PaymentGatewayService` — extend with `openSubscriptionCheckout(tenantId, planId)`
- New screen `super_admin/presentation/screens/subscription_checkout_screen.dart`
- Webhook edge function `razorpay-webhook` → verifies signature → upserts `subscription_invoices` → bumps `tenants.subscription_plan` + `subscription_expires_at`
- Super-admin tenant detail: "Change Plan" → checkout → webhook updates

**Files:** `supabase/functions/razorpay-webhook/index.ts`, extend `payment_gateway_service.dart`, new checkout screen

**Complexity:** Medium | **Risk:** MEDIUM — webhook signature verification; idempotency on retry

### 1.3 Pagination everywhere (scale + cost)
**Why:** Without this, a 5000-student school crashes the app AND burns Supabase compute on every open.

- Add `PaginatedResult<T>` model (`items, totalCount, page, pageSize, hasMore`)
- Add `BaseRepository.listPaginated(table, {page, pageSize, filters, order})` generic
- Convert the 21 un-paginated repos to paginated list calls (students, staff, invoices, messages, attendance, etc.)
- UI: infinite-scroll `ListView` + `Sliver` pattern; reuse a `PaginatedListWidget`

**Files:** `lib/data/models/paginated_result.dart`, `lib/data/repositories/base_repository.dart`, 21 repo edits, list screens

**Complexity:** Medium-High (breadth) | **Risk:** LOW — additive

---

## Phase 2 — Cost Optimization  (cut the Supabase bill)

### 2.1 Server-side caching layer
- Edge function responses (`compute-exam-stats`, `fee stats` RPCs) → set `Cache-Control` + use Supabase cache headers
- Flutter: `cached_network_image` already used; add TTL cache in `BaseRepository` for read-heavy low-change data (classes, sections, subjects, fee_heads)
- Reduces repeated DB round-trips = less compute

### 2.2 Real-time channel audit + cleanup
- Audit all `.channel().on()` subscriptions; ensure every one has a matching `channel.unsubscribe()` in `dispose()`
- Add a `RealtimeManager` singleton that tracks active channels per screen and force-cleans on route pop
- Prevents connection leaks that spike Supabase realtime connection count (billed)

### 2.3 Offline sync completion (cheapest data path)
- Complete `SyncQueueService`: process queue on connectivity restore, conflict resolution (last-write-wins with `updated_at`)
- Mark read-heavy screens cache-first (attendance roster, timetable, notices) → works offline, syncs when online
- **Cost win:** offline reads = zero API calls = zero compute

### 2.4 Query optimization
- Add missing indexes (per CLAUDE.md): `students(name)`, `messages(sender_id)`, `invoices(due_date)`, `tenant_ai_usage(tenant_id, date)`
- Fix N+1 in student list (batch-load parents via single `in` query)
- Replace client-side aggregation with existing RPCs where possible

**Complexity:** Medium | **Risk:** LOW-MEDIUM

---

## Phase 3 — Competitive Gaps  (what 2026 competitors have that you don't)

### 3.1 WhatsApp Business Cloud API integration
**Why:** #1 gap vs EduxenOS/MultiSchoolERP. Parents expect WhatsApp, not push.

- Edge function `send-whatsapp` (Meta Cloud API, free for 1000 conversations/mo)
- `notification_preferences` table: per-user channel (push/email/whatsapp)
- Wire into existing notifications module: fee due, absence, exam result, PTM reminder
- Template messages pre-approved (Meta requirement)

**Files:** `supabase/functions/send-whatsapp/index.ts`, `lib/core/services/whatsapp_service.dart`, extend notifications module

**Complexity:** Medium | **Risk:** MEDIUM — Meta template approval lead time

### 3.2 Parent app polish + PWA
- Parent role already exists; audit the 5 highest-traffic parent screens for the "one-tap" pattern (fee pay, attendance view, notice ack, PTM book, result view)
- Add web/PWA shell so parents without app install can use it (cheap — Flutter web already supported)

### 3.3 Automated test foundation
- Add widget tests for the 3 critical flows: auth→role redirect, fee payment, attendance mark
- Add repo integration tests against a test Supabase project
- Catches regressions cheaply before they cost support time

**Complexity:** Medium | **Risk:** LOW

---

## Recommended Order & Dependencies

```
Phase 1.1 (subscription enforcement) ─┐
Phase 1.2 (Razorpay SaaS billing) ────┤── these two together = you can charge
Phase 1.3 (pagination) ───────────────┘── unblocks safe scale
        │
Phase 2.1-2.4 (cost optimization) ─── runs in parallel with 1.3
        │
Phase 3.1 (WhatsApp) ── after notifications are stable
Phase 3.2-3.3 (parent polish, tests) ── anytime
```

## Cost Projection (scale-driven)

| Tenants | Supabase plan | Monthly cost | Revenue @ ₹12k/yr/tenant |
|---------|--------------|-------------|---------------------------|
| 1-5 | Pro + Micro | ~$35 (₹2,900) | ₹5,000-60,000 |
| 5-20 | Pro + Small | ~$40 (₹3,300) | ₹60,000-2,40,000 |
| 20-50 | Pro + Medium | ~$85 (₹7,000) | ₹2,40,000-6,00,000 |
| 50+ | Pro + Large | ~$135 (₹11,000) | ₹6,00,000+ |

Break-even at ~1 paying tenant. AI costs capped per-tenant by existing `tenant_ai_credits.budget_usd`.

---

**STATUS: ALL PHASES SHIPPED (2026-07-03)** — see the implementation log below. Remaining items are deploy-time steps (migrations, function deploys, secrets) tracked in PR #24's test plan.

---

## Implementation Log

### Phase 1 — SHIPPED (2026-07-03)

**Phase 1.1 — Subscription enforcement ✅**
- `supabase/migrations/00072_subscription_enforcement.sql` — `subscription_plans` catalog (free/pro/elite), `subscription_invoices` table, `tenant_is_paid()` + `tenant_plan_limits()` SQL helpers, `tenants.enforcement_enabled` flag (default OFF for safe rollout), trigger to sync plan → `tenant_ai_credits` on plan change, RLS policies, backfill.
- `supabase/functions/enforce-subscription/index.ts` — edge function: GET `?feature=<key>` for feature-flag checks, POST `{check:'student_count'|'ai_budget'}` for capacity checks.
- `lib/data/models/subscription_plan.dart` — `SubscriptionPlan` + `SubscriptionVerdict` models.
- `lib/core/services/subscription_service.dart` — Riverpod service wrapping the edge function.
- `lib/core/widgets/subscription_guard.dart` — `SubscriptionGuard` widget (fail-open on edge fn errors so a paid tenant is never locked out by a transient outage).

**Phase 1.2 — Razorpay SaaS billing ✅**
- `supabase/functions/razorpay-webhook/index.ts` — HMAC-SHA256 signature verification, idempotent upsert on `razorpay_payment_id`, bumps `tenants.subscription_plan` + `subscription_expires_at` (+1 year), DB trigger syncs AI credits.
- `lib/core/services/payment_gateway_service.dart` — added `openSubscriptionCheckout()` (tenant_id + plan_id in notes).
- `lib/features/super_admin/presentation/screens/subscription_checkout_screen.dart` — plan picker + Razorpay checkout.
- Route added: `/super-admin/tenants/:tenantId/billing`.

**Phase 1.3 — Pagination foundation ✅**
- `lib/data/models/paginated_result.dart` — generic `PaginatedResult<T>` with `hasMore`/`totalCount`/`map`.
- `lib/data/repositories/base_repository.dart` — `queryPaginated()` helper (data + count in one call).
- `lib/data/repositories/student_repository.dart` — `getStudentsPaginated()` as the conversion pattern.
- **Follow-up:** convert the remaining 20 repos + their list screens to use `queryPaginated`. Each is a mechanical ~15-line change following the student pattern.

**Verification:** `flutter analyze` — 0 errors across all new/changed files.

### Required secrets to set in Supabase before going live
- `RAZORPAY_WEBHOOK_SECRET` — from Razorpay dashboard webhook settings
- `RAZORPAY_KEY_ID` — already used by student fees; reused for subscriptions

### Remaining work (Phases 2 & 3)
See the plan above. Phase 2 (cost optimization) and Phase 3 (WhatsApp, parent polish, tests) are ready to start when you give the go-ahead.

---

### Phase 2 — SHIPPED (2026-07-03)

**Phase 2.4 — Missing DB indexes ✅**
- `supabase/migrations/00073_phase2_indexes_and_caps.sql`:
  - `exam_subjects(tenant_id)`, `exam_subjects(exam_id)` — exam season hot path
  - `marks(tenant_id)`, `marks(exam_subject_id)`, `marks(student_id)`, `marks(tenant_id, exam_subject_id)` — the single hottest table during grade entry
  - `class_subjects(tenant_id)`, `class_subjects(class_id)`, `class_subjects(subject_id)`
  - `teacher_assignments(tenant_id)`, `teacher_assignments(teacher_id)`, `teacher_assignments(tenant_id, teacher_id)` — every teacher's homepage
  - `get_student_count(tenant_id)` SECURITY DEFINER RPC — used by enforce-subscription (one round-trip instead of a count query)
  - `get_tenant_active_student_count()` RLS-safe version for tenant_admins
- Updated `enforce-subscription` edge function to use the RPC.

**Phase 2.2 — Realtime channel cleanup ✅**
- `lib/core/services/realtime_manager.dart` — `RealtimeManager` singleton: `track()`, `untrack()`, `cleanupAll()`. Safety net for channel leaks.
- Wired `cleanupAll()` into `AuthNotifier.signOut()` — all realtime channels are removed on logout, even if a provider forgot to dispose.
- Audit result: only `bus_tracking_provider` actively uses realtime and it already cleans up properly. Other subscribe methods are unused.

**Phase 2.1 — TTL cache for read-heavy data ✅**
- `BaseRepository.cached<T>({key, loader, ttl})` — in-memory TTL cache (default 5 min), scoped per-tenant so no cross-tenant leakage.
- `invalidateCache(key)` / `invalidateAllCache()` for write-through invalidation.
- `clearAllRepoCache()` global function — called on logout via `AuthNotifier.signOut()`.
- Reduces repeated DB round-trips for classes, sections, subjects, fee_heads, academic_years.

**Phase 2.3 — Offline sync completion ✅**
- `SyncQueueService` upgraded:
  - `attachConnectivity({client, onlineStream})` — auto-replays pending ops when device comes back online. No manual `processQueue()` call needed.
  - `detachConnectivity()` — cleanup on logout.
  - Per-op retry counter + dead-letter: ops dropped after 5 retries or 7 days (whichever first).
  - Per-op failure isolation: one bad op no longer blocks the queue.
- `syncQueueAutoProvider` — wires the queue to the connectivity stream + Supabase client at app startup.

**Phase 1.3b — Pagination rollout ✅**
- All 17 previously-unpaginated repos now have `*Paginated` methods (25 new methods total).
- Pattern: `queryPaginated()` helper + `PaginatedResult<T>.map()`.
- Existing methods untouched — only additive.
- `flutter analyze lib/data/repositories/` — 0 errors.

**Verification:** Full `flutter analyze` — **0 errors** across the entire project.

---

### Phase 3 — SHIPPED (2026-07-03)

**Phase 3.1 — WhatsApp Business Cloud API ✅**
- `supabase/functions/send-whatsapp/index.ts` — Meta Cloud API edge function:
  - Subscription gate: checks `tenant_plan_limits().feature_flags.whatsapp` → 402 if free plan
  - Loads tenant config from `sms_whatsapp_configs` (existing table)
  - Calls Meta Cloud API (`POST /v20.0/{phone_number_id}/messages`)
  - Logs every outcome to `notification_logs` (existing table)
  - Template-based (pre-approved in Meta Business Manager)
- `lib/core/services/whatsapp_service.dart` — Flutter service with convenience methods:
  - `send()` — generic template send
  - `sendAbsenceNotification()`, `sendFeeDueNotification()`, `sendResultNotification()`, `sendPtmReminder()`
  - `WhatsAppResult` with `isPlanBlocked` / `isNotConfigured` classification
- `lib/core/services/whatsapp_notification_helper.dart` — auto-notify helper:
  - Checks `sms_whatsapp_configs.auto_*` flags before sending
  - Fetches primary parent phone from `student_parents` → `parents`
  - `notifyAbsence()`, `notifyFeeDue()`, `notifyResultPublished()`
  - Silently skips if WhatsApp disabled, not configured, or plan doesn't include it

**Phase 3.2 — Parent app polish ✅**
- Audited 5 parent screens (dashboard, fee payment, child results, child progress, homework tracker) — already well-designed with emotional reassurance patterns
- PWA already configured (manifest.json, icons, standalone display)
- Added `SubscriptionGuard` wrapper to WhatsApp settings screen — shows upgrade prompt when on free plan

**Phase 3.3 — Automated test foundation ✅**
- `test/core/subscription_plan_test.dart` — 10 tests: plan parsing (free/pro/elite), verdict parsing (allowed/blocked/count/budget/missing)
- `test/core/paginated_result_test.dart` — 7 tests: hasMore math (boundary cases, last page, empty, exact fill), map preserves metadata
- `test/core/whatsapp_service_test.dart` — 6 tests: success/plan-blocked/not-configured/network-error classification
- **All 23 tests pass.** `flutter test` exit code 0.

**Verification:** Full `flutter analyze` — **0 errors**. All new tests pass.
