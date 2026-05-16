# Sprint Plan: School-Management-Flutter — 2026-05-16

## Overview
Three time-boxed sprints eliminating all 12 security/auth issues before any product work, followed by conversion-critical product fixes. Sprint 1 tasks are designed for parallel agent dispatch.

---

## USER ACTIONS REQUIRED BEFORE SPRINT 1 STARTS

| # | Action | Blocking |
|---|--------|----------|
| U1 | Rotate the DeepSeek key found in local `.env` (see [[wiki/decisions/2026-05-16-key-rotation]]) at platform.deepseek.com | Sprint 1 |
| U2 | Rotate the OpenRouter key found in local `.env` at openrouter.ai/keys | Sprint 1 |
| U3 | Run a history scan locally for the key prefix and BFG-purge if any historical commit surfaces it (do NOT include the literal key in any committed file) | Sprint 1 |
| U4 | Provide production deploy URL so CORS `ALLOWED_ORIGIN` env var can be set in Supabase dashboard | Sprint 2 |

---

## Sprint 1 — Security Hardening (1 week)
**Gate:** No production traffic until this sprint passes CI + security-reviewer sign-off.

### Parallel Group A — pure Dart fixes (dispatch simultaneously)

**Task 1.A1** — Auth bypass fix
- File: `lib/core/router/app_router.dart:673`
- Change: `final isLoggedIn = session != null;` (remove `|| currentUser != null`)
- Effort: S | Risk: Critical | Agent: security-reviewer

**Task 1.A2** — Remove guarded developer logs
- Files: `lib/core/router/app_router.dart:682,2258,2286`
- Change: wrap each `developer.log(...)` in `if (kDebugMode) { ... }`
- Effort: S | Risk: Low | Agent: refactor-cleaner

**Task 1.A3** — Fix stale auth state (StateProvider)
- File: `lib/features/auth/providers/auth_provider.dart:18,21,147-148`
- Changes: derive `currentUserProvider` from `authNotifierProvider.valueOrNull`; remove manual `.state =` assignments; remove client-side super_admin email-match promotion (item 11 — move logic flag comment for edge function in Sprint 2)
- Effort: M | Risk: High | Agent: tdd-guide (write regression test first)

### Parallel Group B — Supabase / edge function fixes (dispatch simultaneously with Group A)

**Task 1.B1** — Drop plaintext password column
- Files: `supabase/migrations/00043_user_credentials.sql:8`, `supabase/functions/create-user/index.ts:232`
- Changes: new migration `00051_drop_initial_password.sql` — `ALTER TABLE user_credentials DROP COLUMN IF EXISTS initial_password;`; update edge function to return OTP in response body only, never insert it
- Effort: M | Risk: Critical | Agent: security-reviewer

**Task 1.B2** — Redact exception leaks
- Files: `supabase/functions/create-user/index.ts:244-249`, `supabase/functions/compute-exam-stats/index.ts:217-219`
- Change: replace `error.message` in JSON response with `"An internal error occurred."`; retain `console.error(error)` for server logs
- Effort: S | Risk: High | Agent: security-reviewer

**Task 1.B3** — Tenant-scope `has_role()` DB function
- File: `supabase/migrations/00041_fix_has_role_db_lookup.sql:11-24`
- Change: new migration `00052_scope_has_role.sql` — add `AND tenant_id = public.tenant_id()` branch for non-super_admin; extract `is_super_admin()` helper function
- Effort: M | Risk: High | Agent: database-reviewer

**Task 1.B4** — CORS restriction on create-user function
- File: `supabase/functions/create-user/index.ts:5`
- Change: read `Deno.env.get('ALLOWED_ORIGIN')` and return 403 for unlisted origins; **blocked on U4** for prod value
- Effort: S | Risk: Med | Agent: security-reviewer
- Note: implement the guard now with `localhost:3000` as default; prod URL set via U4 before deploy

**Task 1.B5** — Avatars bucket MIME/size policy
- Files: new migration `00053_avatars_bucket_policy.sql` (mirror `00049_school_assets_storage.sql`); `lib/features/profile_setup/widgets/profile_photo_picker.dart`
- Change: migration sets `allowed_mime_types = ['image/jpeg','image/png','image/webp']`, `max_file_size = 5242880`; widget adds magic-byte check before upload
- Effort: M | Risk: Med | Agent: security-reviewer

**Sprint 1 Acceptance Criteria:**
- `session != null` is the sole auth truth in router
- `git grep initial_password` returns zero Dart/SQL hits after migration
- No raw exception `.message` in any edge function response body
- `has_role()` tested with cross-tenant user — returns false
- All `developer.log` calls in router are debug-gated
- `auth_provider` unit tests pass with no `.state =` mutations

---

## Sprint 2 — Tenant Isolation Hardening (1 week)
**Depends on:** Sprint 1 merged and deployed.

**Task 2.1** — `BaseRepository.scoped()` wrapper (M, High risk)
- File: `lib/data/repositories/base_repository.dart`
- Add `scoped(String table)` method that auto-applies `.eq('tenant_id', requireTenantId())`
- Agent: tdd-guide (write unit test against mock Supabase client first)

**Task 2.2** — Migrate top 5 repos to `scoped()` (M each, can run in parallel per repo)
- `lib/data/repositories/academic_repository.dart`
- `lib/data/repositories/communication_repository.dart`
- `lib/data/repositories/fees_repository.dart`
- `lib/data/repositories/attendance_repository.dart`
- `lib/data/repositories/messaging_repository.dart` (or nearest equivalent)
- Agent: refactor-cleaner (one agent per repo, parallel dispatch)

**Task 2.3** — Route 17 direct `SupabaseClient.from()` callers through repos (L, Med risk)
- Files: `lib/features/profile_setup/screens/` (5 files), `lib/features/admin/presentation/` (4 files), `lib/features/super_admin/`, `lib/features/id_card/`, `lib/features/academic/presentation/`
- Agent: refactor-cleaner

**Task 2.4** — Super_admin promotion to edge function (M, High risk)
- Depends on 1.A3 (auth_provider cleanup done)
- Move email-match check to new Supabase edge function `promote-super-admin/index.ts` or `BEFORE INSERT` trigger keyed off `app_config.super_admin_emails` table column
- Agent: security-reviewer

**Sprint 2 Acceptance Criteria:**
- `git grep "SupabaseClient.from(" lib/features/` returns zero results outside repository files
- All 5 migrated repos pass integration tests with cross-tenant fixture
- `has_role()` + `scoped()` combination verified by database-reviewer

---

## Sprint 3 — Product Conversion Fixes (1 week)
**Depends on:** Sprint 2 merged. These are revenue-blocking product bugs.

**Task 3.1** — Invoice PDF (L, Med risk) — HIGHEST PRIORITY
- File: `lib/features/fees/presentation/screens/fees_screen.dart:193`
- Use `pdf:^3.10.7` (already in pubspec). Wire invoice generation action to a new `InvoiceService` that calls existing fees repo data; replace snackbar with PDF preview screen
- Agent: tdd-guide

**Task 3.2** — Fee reminder (M, Low risk)
- File: `lib/features/fees/presentation/screens/fees_screen.dart:204`
- Wire to existing `communication` provider's notification dispatch; replace snackbar with confirmation dialog
- Agent: tdd-guide

**Task 3.3** — Fee structure setup (M, Med risk)
- File: `lib/features/fees/presentation/screens/fees_screen.dart:215` + `lib/features/admin/presentation/screens/fee_management_screen.dart`
- Implement fee structure form using existing Riverpod patterns; persist via fees repo
- Agent: tdd-guide

**Task 3.4** — Collection export (M, Low risk)
- File: `lib/features/fees/presentation/screens/fees_screen.dart:226`
- CSV export using `dart:convert`; share via `share_plus` if already in pubspec; replace snackbar
- Agent: tdd-guide

**Task 3.5** — AI Insights hardcoded arrays (S, Low risk)
- File: `lib/features/ai_insights/presentation/screens/generate_remarks_screen.dart:24-34`
- Replace `_sections` and `_exams` literals with `ref.watch(sectionsProvider)` + `ref.watch(examsProvider)`
- Agent: refactor-cleaner (can run in PARALLEL with 3.1–3.4)

**Task 3.6** — PTM create form (M, Med risk)
- File: `lib/features/ptm/presentation/screens/ptm_scheduler_screen.dart`
- Implement FAB → modal form following `book_appointment_screen.dart` pattern; dispatch via `ptm_provider.dart`
- Agent: tdd-guide (can run in PARALLEL with 3.1–3.4)

**Sprint 3 Acceptance Criteria:**
- Invoice PDF renders with correct student/fee data and is downloadable
- Reminder dispatches via communication provider (verified in integration test)
- Fee structure persists and reloads correctly
- No `_sections` or `_exams` hardcoded literals in generate_remarks_screen
- PTM creation round-trips through ptm_provider without errors

---

## Architectural Decision (post-Sprint 3)
**Isar:** 55/56 features bypass it. This is a decide-before-code item. Options:

| Option | Effort | When |
|--------|--------|------|
| Offline-first: enable Isar for top 5 (attendance, messaging, homework, notice_board, fees) | L | Sprint 4+ |
| Rip out Isar entirely, remove from pubspec | M | Sprint 4 |

Hold decision until Sprint 3 retrospective.

---

## Risk Table

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Migration 00051 drops column with live data | Med | Critical | Run on staging first; backup snapshot before apply |
| `has_role()` change breaks existing RBAC | Med | High | Test with all 5 role types in staging before prod deploy |
| scoped() wrapper misses async repo calls | Med | High | tdd-guide writes cross-tenant test fixture before migration |
| BFG history rewrite breaks team clone refs | Low | High | Coordinate with all contributors; force-push only after team ack |
| PDF lib version conflict in pubspec | Low | Med | Pin `pdf: ^3.10.7` explicitly; run `flutter pub upgrade --major-versions` on branch |
