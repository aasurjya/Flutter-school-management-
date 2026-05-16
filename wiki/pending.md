---
type: kanban
last_updated: 2026-05-16
---

# Pending — School Management Kanban

> **How to use:** any agent (or the user) can move items between columns. Keep entries short — one line + a [[wikilink]] to the detail file.

---

## ⏳ Needs Human

- 🔴 **Rotate DeepSeek API key** (the one in local `.env`) at platform.deepseek.com — see [[panels/sprint-1-closure-2026-05-16]]
- 🔴 **Rotate OpenRouter API key** (the one in local `.env`) at openrouter.ai/keys
- 🔴 **History scan** — `git log --all -p -- .env .env.* | grep -E "sk-[a-zA-Z0-9]{20,}"` — should return nothing; BFG-purge if anything surfaces
- 🟠 **Provide production deploy URL** for `ALLOWED_ORIGINS` env var in Supabase Functions secrets
- ✅ ~~**PDF rupee symbol (₹) renders as box in fees exports**~~ — DONE 2026-05-16 (PdfGoogleFonts.notoSansRegular/Bold via bundled TTF asset; `rootBundle` primary, CDN fallback)
- ✅ ~~Decide on `ai_tutor` KILL~~ — DONE 2026-05-16 (panel verdict 4-1; 813 LOC deleted)
- ✅ ~~Decide on admin dashboard mock-data ship-block~~ — DONE 2026-05-16 (5 mock surfaces wired, fake feed hidden, dead tiles fixed)
- ✅ ~~Promote Sprint 3 fees-snackbars to Sprint 1.5?~~ — DONE 2026-05-16 (5 of 6 wired; Fee Structure CRUD deferred to 1.6)

---

## 🚧 In Progress

- **Sprint 1.5** — Customer-trust ship-blockers (KILL `ai_tutor`, dashboard mock-data, fees 5 wires). Panel decision: [[panels/feature-audit-decision-2026-05-16]]
- Sprint 1 — Security CLOSURE (Phase α + α-verify + Phase β + β-verify all complete)
- product-tester + panel-moderator pass 1 — DONE — see [[panels/feature-audit-decision-2026-05-16]]

## ⚠️ DEPLOY GATE

**No production deploy until Sprint 1.5 ships.** Per CEO + critic + product-intel + head-of-product unanimous panel verdict 2026-05-16.

---

## 📋 Backlog

### Sprint 2 — Tenant Isolation (1 week, after deploy)
- [ ] `BaseRepository.scoped(table)` query builder wrapping all tenant-filtered queries
- [ ] Migrate top 5 repos: `academic`, `communication`, `fees`, `attendance`, `messaging`
- [ ] Refactor 17 screens that call `SupabaseClient.from()` directly (profile_setup, admin, super_admin, id_card, academic) to go through repos
- [ ] Move `super_admin` promotion to edge function or `BEFORE INSERT` trigger

### Sprint 3 — Conversion / Product fixes
- [ ] Fees `invoice generation` snackbar → real PDF via existing `pdf` package — `fees_screen.dart:193`
- [ ] Fees `send reminders` snackbar → wire to `communication` provider — `fees_screen.dart:204`
- [ ] Fees `fee structure setup` snackbar → admin form — `fees_screen.dart:215`
- [ ] Fees `export report` snackbar → CSV via `share_plus` — `fees_screen.dart:226`
- [ ] AI remarks: replace hardcoded `_sections` / `_exams` with real providers — `generate_remarks_screen.dart:24-34`
- [ ] PTM create flow — implement `ptm_scheduler_screen.dart` FAB

### Architectural decisions (post-Sprint 3)
- [ ] Isar — commit to offline-first on top 5 features OR rip Isar from `pubspec.yaml`
- [ ] **Merge `homework` + `assignments`** into one module (product-tester audit 2026-05-16)
- [ ] **Merge `transport` + `bus_tracking`** into one transport hub with role variants (product-tester audit 2026-05-16)
- [ ] **Move teacher/student `timetable` screens** into `features/timetable/presentation/screens/` (currently scattered) — see [[features/timetable]]
- [ ] **Move `ai_insights/parent_digest_*`** under `features/communication` as a campaign type
- [ ] **Move `ai_insights/study_recommendations_screen`** under `features/homework`
- [ ] Lint rule: enforce `context.push(AppRoutes.x)` and ban `Navigator.pushNamed` (8 sites in `communication_dashboard_screen.dart`)
- [ ] Extract `core/theme/role_colors.dart` — `_RoleBadge._roleColors` duplicated across modules

### Backlog from 2026-05-16 feature audit
- [ ] Fix admin dashboard 5 mock-data surfaces (`admin_dashboard_screen.dart:354, 463, 469, 475, 481, 494-511, 944, 977`) — see [[features/dashboard]]
- [ ] Fix attendance fake weekly calendar (`attendance_screen.dart:366-367`) — see [[features/attendance]]
- [ ] Fix attendance Period/Class dropdowns to actually filter (`attendance_screen.dart:456, 474`) — see [[features/attendance]]
- [ ] Fix duplicate "Avg Attendance %" `_ReportCard` math (`attendance_screen.dart:524-531`)
- [ ] Wire students list Add Student CTA — both AppBar `+` and FAB (`students_list_screen.dart:85-93, 151-160`)
- [ ] Wire students filter-sheet chips (`students_list_screen.dart:255-275`)
- [ ] Replace `generate_remarks_screen.dart` hardcoded `_sections` / `_exams` with real providers (`:24-34`)
- [ ] Implement PTM creation form (replace `ptm_scheduler_screen.dart:53-59` snackbar)

---

## ✅ Done (this week)

- 🔴 CRIT-1 plaintext-passwords-in-DB — `00051_drop_initial_password.sql` (atomic with RPC recreation)
- 🔴 CRIT-2 exception leakage in edge functions — `create-user/index.ts`, `compute-exam-stats/index.ts`
- 🔴 CRIT-3 auth bypass via ghost session — `app_router.dart:674`
- 🟠 HIGH `has_role()` tenant-scoping — `00052_scope_has_role.sql` + `is_super_admin()` extracted
- 🟠 HIGH avatars bucket MIME/size + magic-byte check — `00053_avatars_bucket_policy.sql` + `profile_photo_picker.dart`
- 🟠 HIGH StateProvider stale auth reads — `auth_provider.dart` + 7 regression tests
- 🟠 HIGH client-side super_admin email-match removed — `auth_provider.dart`
- 🟠 HIGH developer.log unguarded in prod redirect — `app_router.dart:680, 711, 2261, 2291`
- 🟠 HIGH CORS `*` on `create-user` → `ALLOWED_ORIGINS` allowlist
- `CredentialService` refactored to audit-log only; `UserCredentialAudit` is the new shape
- All 4 caller screens migrated off `_credential!.initialPassword`

---

## Backlinks
- [[00 Index]]
