# Refactor v1 — Summary of Changes

**Date:** 2026-02-11
**Scope:** 68K-line Flutter codebase (Riverpod + GoRouter + Supabase)
**Verification:** `flutter analyze` — 0 errors (308 pre-existing info/warning lints, 6 fewer than before)

---

## Phase 1: Clean Up Dependencies & Router Constants

### 1a. Removed unused packages from `pubspec.yaml`
- `reactive_forms: ^17.0.1` — never imported
- `glass_kit: ^3.0.0` — never imported (GlassCard uses built-in BackdropFilter)
- `blur: ^3.1.0` — never imported

### 1b. Replaced 16 hardcoded route paths in `app_router.dart`
All hardcoded path strings like `'/library/book/:bookId'` replaced with their corresponding `AppRoutes` constants (e.g. `AppRoutes.libraryBookDetail`). Affected routes: libraryBookDetail, transportRouteDetail, hostelMyRoom, hostelDetail, healthProfile, achievements, childInsights, takeQuiz, quizResult, ptmBook, reportDetail, classAnalytics, childResults, classStudents, feePayment, tenantDetail.

---

## Phase 2: Consistent Dependency Injection

### 2a. Centralized Supabase client access via `supabaseProvider`
- **New file:** `lib/core/providers/supabase_provider.dart` — single source of truth
- Moved `supabaseProvider` definition out of `auth_provider.dart`
- Updated **26 provider files** + **2 widget files** from `Supabase.instance.client` → `ref.watch(supabaseProvider)`
- All features now get their Supabase client through Riverpod DI, making testing and overriding trivial

**Files updated:**
`attendance_provider`, `assignments_provider`, `fees_provider`, `ptm_provider`, `assessment_provider`, `insights_provider`, `gamification_provider`, `health_provider`, `notification_provider`, `hostel_provider`, `transport_provider`, `library_provider`, `canteen_provider`, `academic_provider`, `announcement_provider`, `timetable_provider`, `tenant_provider`, `messages_provider`, `exams_provider`, `students_provider`, `report_card_provider`, `resource_provider`, `leave_provider`, `emergency_provider`, `child_switcher.dart`, `my_classes_screen.dart`

### 2b. Fixed fragile filter parsing in `base_repository.dart`
- Replaced `String? filter` with Dart record type `({String column, String value})? filter`
- Eliminated `filter.split('=')` parsing — now uses structured `.column` and `.value` access
- Updated 4 callers: `assignment_repository`, `attendance_repository`, `message_repository`, `notification_repository`

---

## Phase 3: Type Safety Fixes

### 3a. Replaced `dynamic` with `Student` in `student_management_screen.dart`
- Added `import '../../../../data/models/student.dart'`
- Changed 7 locations: 4 method parameters (`_showEditStudentDialog`, `_showStudentDetail`, `_showChangeSectionDialog`, `_confirmDeactivate`) + 3 widget fields (`_StudentCard`, `_StudentDetailSheet`, `_EditStudentSheet`)
- Fixed 5 null-safety errors surfaced by the stronger types (`photoUrl!`, `currentEnrollment!.className`, `medicalConditions!`)

### 3b. Replaced `dynamic` with `Assignment` in assignment screens
- `student_assignments_screen.dart` — 3 occurrences (method param + 2 widget fields)
- `assignments_management_screen.dart` — 3 occurrences (method param + 2 widget fields)
- Added `import '../../../../data/models/assignment.dart'` to both files

---

## Phase 4: Extract Shared UI Utilities

### 4a. Created SnackBar helper extension
- **New file:** `lib/shared/extensions/context_extensions.dart`
  ```dart
  extension ContextExtensions on BuildContext {
    void showSuccessSnackBar(String message) { ... }
    void showErrorSnackBar(String message) { ... }
  }
  ```
- **35 SnackBar replacements** across **12 files** (15 success + 20 error patterns)
- Plain SnackBars and `AppColors.warning`/`AppColors.info` variants left untouched
- Files modified: `student_management_screen`, `staff_management_screen`, `exam_management_screen`, `fee_management_screen`, `announcements_screen`, `mark_attendance_screen`, `assignments_management_screen`, `student_assignments_screen`, `tenants_list_screen`, `create_tenant_screen`, `tenant_detail_screen`, `marks_entry_screen`

### 4b. Deduplicated navigation items in `main_shell.dart`
- Extracted shared constants: `_dashboardItem`, `_attendanceItem`, `_studentsItem`, `_feesItem`, `_examsItem`, `_resultsItem`
- Extracted `_commonTrailingItems` list (Library, Transport, Hostel, Canteen, Messages)
- Extracted `_commonTrailingRoutes` for route matching
- Role-specific lists now compose from shared pieces via spread (`...`)
- **Eliminated ~150 lines** of duplicate `const _NavItemData` definitions
- 4 separate 9-item lists → 6 shared items + 1 trailing list + inline composition

---

## Phase 5: Deprecated API Migration

### 5a. Migrated `withOpacity()` → `withValues(alpha:)`
- **303 replacements** across **56 files**
- Mechanical search-and-replace: `.withOpacity(X)` → `.withValues(alpha: X)`
- Eliminates all `deprecated_member_use` warnings for this API

### 5b. Replaced `Colors.grey[xxx]` with theme references (top 4 files)
- `announcements_screen.dart` (17 occurrences → 0)
- `fee_payment_screen.dart` (11 → 0)
- `student_timetable_screen.dart` (10 → 0)
- `student_management_screen.dart` (10 → 0)

**Mapping used:**
| Before | After |
|--------|-------|
| `Colors.grey[300]` / `[400]` | `Theme.of(context).colorScheme.outlineVariant` |
| `Colors.grey[500]` | `Theme.of(context).colorScheme.outline` |
| `Colors.grey[600]` | `Theme.of(context).colorScheme.onSurfaceVariant` |
| `Colors.grey[700]` | `Theme.of(context).colorScheme.onSurface` |

This makes these screens fully theme-aware (light/dark mode compatible).

---

## Files Created (2)
| File | Purpose |
|------|---------|
| `lib/core/providers/supabase_provider.dart` | Centralized Supabase client DI |
| `lib/shared/extensions/context_extensions.dart` | SnackBar helper extension |

## Files Removed (0)
No files were deleted.

## Packages Removed (3)
| Package | Reason |
|---------|--------|
| `reactive_forms` | Never imported anywhere |
| `glass_kit` | Never imported; GlassCard uses Flutter's BackdropFilter |
| `blur` | Never imported |

## By the Numbers
| Metric | Count |
|--------|-------|
| Files modified | ~90 |
| Hardcoded routes replaced | 16 |
| Providers migrated to DI | 28 |
| `dynamic` → concrete type | 13 occurrences |
| SnackBar boilerplate eliminated | 35 |
| Nav item duplicates removed | ~150 lines |
| `withOpacity` calls migrated | 303 |
| `Colors.grey[xxx]` → theme refs | 48 |
| New analyzer errors introduced | 0 |

---

## Out of Scope (Future Work)
- Migrating all manual models to freezed (invasive, requires build_runner)
- Replacing hardcoded sample data with real API calls (feature work)
- Extracting reusable bottom sheet header widget (low impact)
- Splitting large 1000+ line screens into smaller widgets (needs per-screen analysis)
- Replacing remaining `Colors.grey[xxx]` in the other ~25 files
- Replacing remaining plain SnackBars that don't use AppColors.success/error
