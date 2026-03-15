# School Management SaaS

> **Project:** `school_management` v1.0.0+1
> **Stack:** Flutter 3.2+ / Dart / Supabase / Riverpod / GoRouter / Isar (offline) / Firebase (push)
> **Architecture:** Multi-tenant SaaS with role-based access (12 roles)

## Low-Token Startup Rules

Read these files first before broad exploration:

1. `AGENTS.md`
2. `docs/context-map.json`

Then:

- read only the files mapped to the current task
- avoid broad repo scans for role, routing, auth, and super-admin tasks
- do not web search unless explicitly asked
- ignore `agents/everything-claude-code/` unless the task is explicitly about that embedded plugin
- prefer minimal, targeted reads over parallel deep exploration for small and medium tasks

## Quick Reference

**Roles:** `super_admin`, `tenant_admin`, `principal`, `teacher`, `student`, `parent`, `accountant`, `librarian`, `transport_manager`, `hostel_warden`, `canteen_staff`, `receptionist`

**Scale:** 32 feature modules, 88 screens, 27 repositories, 29 providers, 40 models, ~104 DB tables, 75+ routes

## Architecture

```
UI (Screens/Widgets) → Riverpod Providers → Repository Layer (BaseRepository) → Supabase (cloud) + Isar (local)
```

- Multi-tenant: every table has `tenant_id` with RLS policies
- `tenantId` from JWT `appMetadata` — force-unwrap (`tenantId!`) in repos can crash for super_admin
- Role-based dashboards via GoRouter redirect (`app_router.dart:233-261`)

## Key File Paths

| Component | Path |
|-----------|------|
| Entry point | `lib/main.dart` |
| Router | `lib/core/router/app_router.dart` |
| Theme | `lib/core/theme/app_theme.dart`, `app_colors.dart` |
| Base repository | `lib/data/repositories/base_repository.dart` |
| Supabase config | `lib/core/config/supabase_config.dart` |
| Auth provider | `lib/features/auth/providers/auth_provider.dart` |
| Shell (bottom nav) | `lib/core/shell/main_shell.dart` |
| AI text generator | `lib/core/services/ai_text_generator.dart` |
| Migrations | `supabase/migrations/00001_*.sql` through `00011_*.sql` + `20260209_*.sql` |

## Known Issues & Risks

**Critical:**
- No pagination on most list screens — will crash with large datasets
- `tenantId!` null-safety issue in BaseRepository for super_admin
- Demo credentials hardcoded in LoginScreen (remove for production)
- No payment gateway integration (table exists, no Flutter code)
- Offline sync (Isar) is incomplete — models exist but no sync logic

**High:**
- N+1 queries in student list (parents loaded separately)
- No transaction guarantees for multi-step ops (PTM deletion, invoice generation, canteen orders) — use server-side RPCs
- Real-time channels not cleaned up on dispose — can leak
- `generate_class_invoices()` RPC has no duplicate check
- Attendance overwrite has no confirmation dialog
- Quiz timer runs client-side only (exploitable)

**Medium:**
- Mixed model patterns (some Freezed, most plain Dart classes)
- No automated tests
- No localization setup (strings hardcoded in English)
- No subscription enforcement code
- Missing DB indexes: student name search, message sender, invoice due_date

## DB Schema Highlights

**Core tables:** `tenants`, `users`, `user_roles`, `academic_years`, `terms`, `classes`, `sections`, `subjects`, `class_subjects`, `teacher_assignments`, `students`, `student_enrollments`, `parents`, `student_parents`, `staff`

**Denormalization risks:** `students.payment_status` duplicates invoice data, `hostel_rooms.occupied` counter can desync, `wallets.balance` trigger has race conditions

**Key relationships:**
```
tenants → users → user_roles
tenants → academic_years → terms
tenants → classes → sections → student_enrollments → students → student_parents → parents
sections → timetables
subjects → class_subjects, teacher_assignments
exams → exam_subjects → marks
assignments → submissions
syllabus_topics (self-referencing tree) → topic_coverage, lesson_plans, topic_resource_links
fee_heads → fee_structures → invoices → invoice_items/payments
threads → messages, thread_participants
```

## Conventions

- Repositories extend `BaseRepository` with Supabase client access
- Models use `fromJson`/`toJson` with snake_case conversion
- Providers: `FutureProvider` / `StateNotifier` / `StateProvider` (Riverpod)
- Routing: GoRouter with named routes, `ShellRoute` for persistent bottom nav
- UI: Material 3, Poppins font, `GlassCard` widget for frosted-glass aesthetic
- Feature structure: `lib/features/<name>/presentation/screens/` + `providers/` + `widgets/`
