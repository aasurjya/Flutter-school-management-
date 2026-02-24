# School Management SaaS - Comprehensive Codebase Analysis

> **Project:** `school_management` v1.0.0+1
> **Stack:** Flutter 3.2+ / Dart / Supabase / Riverpod / GoRouter / Isar (offline) / Firebase (push)
> **Architecture:** Multi-tenant SaaS with role-based access (12 roles)
> **Analysis Date:** 2026-02-24 (updated 2026-02-24 — Syllabus & Topics feature added)

**Note:** The prompt referenced a "rental platform" domain. This is actually a **multi-tenant school management system** (students, teachers, parents, fees, attendance, exams). All analysis below is based on the actual codebase.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Database Schema Summary](#2-database-schema-summary)
3. [ER Diagram](#3-er-diagram)
4. [User Flow Diagrams & Critical Checkpoints](#4-user-flow-diagrams--critical-checkpoints)
5. [UX & Usability Review](#5-ux--usability-review)
6. [API & Database Usage Risks](#6-api--database-usage-risks)
7. [Top Strengths](#7-top-strengths)
8. [Top Improvement Areas](#8-top-improvement-areas)
9. [Realistic Failure Scenarios](#9-realistic-failure-scenarios)
10. [Accessibility & Cognitive Load](#10-accessibility--cognitive-load)
11. [Concrete Action Items & Roadmap](#11-concrete-action-items--roadmap)

---

## 1. Project Overview

### What It Is

A **multi-tenant school management SaaS** application built with Flutter, targeting mobile platforms. Each tenant represents one school/institution. The system serves 6 primary user personas across 12 enumerated roles:

| Persona | Roles | Key Capabilities |
|---------|-------|-----------------|
| Super Admin | `super_admin` | Tenant creation, global oversight |
| School Admin | `tenant_admin`, `principal` | Full school management, config |
| Teacher | `teacher` | Attendance, marks, assignments, timetable |
| Student | `student` | View grades, timetable, library, canteen |
| Parent | `parent` | Child monitoring, fee payment, PTM booking |
| Staff | `accountant`, `librarian`, `transport_manager`, `hostel_warden`, `canteen_staff`, `receptionist` | Domain-specific operations |

### Tech Stack

| Layer | Technology | File Reference |
|-------|-----------|---------------|
| Frontend | Flutter 3.2+ with Material 3 | `pubspec.yaml:6` |
| State | Riverpod (flutter_riverpod 2.4.9) | `pubspec.yaml:14` |
| Backend | Supabase (supabase_flutter 2.3.2) | `pubspec.yaml:18` |
| Offline DB | Isar 3.1.0 | `pubspec.yaml:21` |
| Routing | GoRouter 13.1.0 | `pubspec.yaml:25` |
| Push | Firebase Messaging 14.7.15 | `pubspec.yaml:39` |
| Charts | fl_chart 0.66.0 | `pubspec.yaml:33` |
| PDF | pdf 3.10.7 + printing 5.12.0 | `pubspec.yaml:36-37` |
| QR | qr_flutter 4.1.0 + mobile_scanner 4.0.0 | `pubspec.yaml:60-61` |

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App (UI)                       │
│  ┌─────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │ Screens  │  │ Widgets  │  │  Shell   │  │  Router  │ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘ │
│       │              │             │              │       │
│  ┌────▼──────────────▼─────────────▼──────────────▼────┐ │
│  │              Riverpod Providers                      │ │
│  │  FutureProvider / StateNotifier / StateProvider      │ │
│  └─────────────────────┬───────────────────────────────┘ │
│                        │                                  │
│  ┌─────────────────────▼───────────────────────────────┐ │
│  │              Repository Layer (27 repos)             │ │
│  │         BaseRepository → SupabaseClient             │ │
│  └──────────┬──────────────────────┬───────────────────┘ │
└─────────────┼──────────────────────┼─────────────────────┘
              │                      │
   ┌──────────▼──────────┐  ┌───────▼───────────┐
   │   Supabase (Cloud)  │  │   Isar (Local DB)  │
   │  PostgreSQL + RLS   │  │   Offline cache    │
   │  Realtime channels  │  │   Sync queue       │
   │  Auth (JWT)         │  │                    │
   └─────────────────────┘  └────────────────────┘
```

### Codebase Scale

| Metric | Count |
|--------|-------|
| Feature modules | 32 |
| Screen files | 88 |
| Repository classes | 27 + 1 base |
| Provider files | 29 |
| Data model files | 40 + 3 local |
| SQL migrations | 19 |
| Database tables | ~104 |
| Database enums | 54+ |
| Named routes | 75+ |

---

## 2. Database Schema Summary

### 2.1 Core Domain Tables

#### Multi-Tenancy Foundation

| Table | Purpose | Key Fields | Indexes |
|-------|---------|-----------|---------|
| `tenants` | School/institution record | `name`, `slug`, `subscription_plan`, `is_active` | `idx_tenants_slug` |
| `users` | All user accounts (FK to `auth.users`) | `tenant_id`, `email`, `full_name`, `fcm_token` | `idx_users_tenant`, `idx_users_email` |
| `user_roles` | Role assignments (many-per-user) | `user_id`, `tenant_id`, `role`, `is_primary` | UNIQUE(`user_id`, `tenant_id`, `role`) |

**Source:** `supabase/migrations/00001_initial_schema.sql`

#### Academic Structure

| Table | Purpose | Key Constraint |
|-------|---------|---------------|
| `academic_years` | Year periods with `is_current` flag | `tenant_id` scoped |
| `terms` | Sub-periods within a year | FK to `academic_years` |
| `classes` | Grade levels (1-12, etc.) | `numeric_name` + `sequence_order` |
| `sections` | Divisions within a class | FK to `classes`, includes `class_teacher_id` |
| `subjects` | Subject catalog | `subject_type` enum (mandatory/elective) |
| `class_subjects` | Subject-to-class mapping | UNIQUE(`class_id`, `subject_id`, `academic_year_id`) |
| `teacher_assignments` | Teacher-to-section-subject links | UNIQUE(`teacher_id`, `section_id`, `subject_id`, `academic_year_id`) |

**Source:** `supabase/migrations/00001_initial_schema.sql`

#### Syllabus & Topics

| Table | Purpose | Key Constraint |
|-------|---------|---------------|
| `syllabus_topics` | Hierarchical topic tree (unit/chapter/topic/subtopic) | Self-referencing `parent_topic_id` FK, `level` enum, UNIQUE(`tenant_id, subject_id, class_id, academic_year_id, parent_topic_id, sequence_order`) |
| `topic_coverage` | Per-section coverage tracking | `status` enum (not_started/in_progress/completed/skipped), UNIQUE(`topic_id, section_id`) |
| `lesson_plans` | Lesson plans tied to topics | `status` enum, `is_ai_generated` BOOL, `ai_prompt_context` JSONB |
| `topic_resource_links` | Polymorphic M:N linking (topic ↔ assignment/quiz/resource/etc.) | `entity_type` enum, UNIQUE(`topic_id, entity_type, entity_id`) |

Cross-references: `assignments.topic_id`, `quizzes.topic_id`, `question_bank.topic_id`, `study_resources.topic_id` (nullable FK columns added to existing tables).

View: `v_syllabus_coverage_summary` — aggregates coverage counts and percentage per subject+class+section.

**Source:** `supabase/migrations/00011_syllabus_topics.sql`

#### People

| Table | Purpose | Key Fields |
|-------|---------|-----------|
| `students` | Student profiles | `admission_number`, `first_name`, `last_name`, `payment_status` |
| `student_enrollments` | Year-by-year section placement | UNIQUE(`student_id`, `academic_year_id`) |
| `parents` | Parent/guardian profiles | `relation`, `occupation`, `annual_income` |
| `student_parents` | Many-to-many student-parent link | `is_primary`, `can_pickup` |
| `staff` | Staff profiles | `employee_id`, `designation`, `salary` |

**Source:** `supabase/migrations/00001_initial_schema.sql`, `20240101_update_students_schema.sql`

### 2.2 Relationships Map

```
tenants
  ├── users ──── user_roles
  ├── academic_years ──── terms
  ├── classes ──── sections ──── student_enrollments
  │                   │               └── students ──── student_parents ──── parents
  │                   └── timetables
  ├── subjects ──── class_subjects
  │              └── teacher_assignments
  ├── exams ──── exam_subjects ──── marks
  ├── assignments ──── submissions
  ├── attendance (daily) / period_attendance (per-period)
  ├── fee_heads ──── fee_structures ──── invoices ──── invoice_items
  │                                         └── payments
  ├── threads ──── thread_participants
  │            └── messages
  ├── announcements
  ├── notifications
  ├── canteen_menu ──── canteen_orders ──── canteen_order_items
  │                         └── wallets ──── wallet_transactions
  ├── library_books ──── book_issues
  ├── transport_routes ──── transport_stops
  │                    └── student_transport
  ├── hostels ──── hostel_rooms ──── room_allocations
  ├── quizzes ──── quiz_questions ──── quiz_attempts
  │            └── question_bank
  ├── ptm_schedules ──── ptm_teacher_availability
  │                  └── ptm_appointments
  ├── emergency_alerts ──── emergency_responses
  ├── leave_applications / leave_balance
  ├── study_resources ──── resource_access
  ├── achievements ──── student_achievements
  │                └── student_points ──── point_transactions
  ├── student_health_records / health_incidents
  ├── student_checkins (QR)
  ├── syllabus_topics ──── topic_coverage (per-section)
  │                   ├── lesson_plans
  │                   └── topic_resource_links ──► assignments / quizzes / study_resources / question_bank
  └── [Advanced modules: admissions, AI analytics, behavioral, HR, audit, integrations, competencies]
```

### 2.3 Normalization Assessment

**Well-normalized areas:**
- Core academic hierarchy (tenants → classes → sections → enrollments) is 3NF
- Fee structures properly separated into heads, structures, invoices, items, payments
- Messaging uses proper thread-participant-message pattern (no denormalization)
- Attendance uses correct unique constraints (`student_id`, `date`)

**Denormalization issues found:**

| Issue | Location | Impact |
|-------|----------|--------|
| `students.payment_status` / `payment_amount` duplicates invoice data | `20240101_update_students_schema.sql` | Stale data risk; these fields can drift from actual invoice/payment state |
| `students.email` / `phone` duplicates `users.email` / `users.phone` | `20240101_update_students_schema.sql` | Two sources of truth for contact info |
| `hostel_rooms.occupied` (counter) vs actual allocations count | `00005_canteen_library_transport_hostel.sql` | Counter can desync from `room_allocations` rows |
| `library_books.available_copies` counter vs actual `book_issues` count | `00005_canteen_library_transport_hostel.sql` | Trigger maintains it but race conditions possible under load |
| `wallets.balance` counter maintained by trigger | `00005_canteen_library_transport_hostel.sql` | Same race-condition risk |

### 2.4 Indexing & Performance Notes

**Index coverage is generally good.** Key observations:

| Category | Assessment |
|----------|-----------|
| Tenant isolation | Every major table has `idx_*_tenant` on `tenant_id` -- good for RLS performance |
| Temporal queries | `attendance.date`, `messages.created_at` DESC, `notifications.created_at` DESC are indexed |
| Lookup patterns | Unique indexes on natural keys: `admission_number`, `invoice_number`, `order_number` |
| Composite indexes | `UNIQUE(student_id, date)` on attendance prevents duplicates and speeds lookups |

**Missing or weak indexes:**

| Table | Missing Index | Why It Matters |
|-------|--------------|---------------|
| `students` | No index on `first_name`/`last_name` | Search by name uses `ilike` -- needs GIN trigram index for performance |
| `messages` | No index on `sender_id` | Loading "my sent messages" is a full scan within tenant |
| `student_enrollments` | No index on `(section_id, academic_year_id)` | Teacher loading class roster requires scanning all enrollments |
| `marks` | No composite index on `(student_id, exam_subject_id)` beyond unique | Analytics queries joining marks with students are frequent |
| `attendance` | No partial index on `status = 'absent'` | Absence reports are common admin queries |
| `invoices` | No index on `due_date` | Overdue fee queries scan all invoices |
| `canteen_orders` | No index on `ordered_at` | Order history sorted by date is unindexed |

**RLS Performance Concern:**
All tables have RLS enabled (`00006_rls_policies.sql`). The `has_role()` function queries `user_roles` on every row check. For tables with thousands of rows (attendance, marks, messages), this could cause significant overhead. Consider caching role checks in JWT claims instead.

---

## 3. ER Diagram

### Core Academic ER (ASCII)

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   TENANTS    │     │    USERS     │     │  USER_ROLES  │
├──────────────┤     ├──────────────┤     ├──────────────┤
│ id (PK)      │◄───┤ tenant_id(FK)│◄───┤ user_id (FK) │
│ name         │     │ id (PK/FK)   │     │ tenant_id(FK)│
│ slug         │     │ email        │     │ role (enum)  │
│ is_active    │     │ full_name    │     │ is_primary   │
└──────────────┘     │ fcm_token    │     └──────────────┘
                     └──────┬───────┘
                            │
          ┌─────────────────┼─────────────────┐
          │                 │                  │
  ┌───────▼────────┐ ┌─────▼──────┐  ┌───────▼────────┐
  │   STUDENTS     │ │   STAFF    │  │   PARENTS      │
  ├────────────────┤ ├────────────┤  ├────────────────┤
  │ id (PK)        │ │ id (PK)    │  │ id (PK)        │
  │ user_id (FK)   │ │ user_id(FK)│  │ user_id (FK)   │
  │ admission_no   │ │ employee_id│  │ first_name     │
  │ first_name     │ │ designation│  │ relation       │
  │ last_name      │ │ salary     │  │ occupation     │
  │ is_active      │ └────────────┘  └───────┬────────┘
  └───────┬────────┘                          │
          │         ┌──────────────────┐      │
          │         │ STUDENT_PARENTS  │      │
          ├────────►│ student_id (FK)  │◄─────┘
          │         │ parent_id (FK)   │
          │         │ is_primary       │
          │         └──────────────────┘
          │
  ┌───────▼──────────────┐     ┌──────────────┐
  │ STUDENT_ENROLLMENTS  │     │  SECTIONS    │
  ├──────────────────────┤     ├──────────────┤
  │ student_id (FK)      │────►│ id (PK)      │
  │ section_id (FK)      │     │ class_id(FK) │──► CLASSES
  │ academic_year_id(FK) │     │ teacher_id   │
  │ roll_number          │     │ capacity     │
  └──────────────────────┘     └──────────────┘
```

### Assessment ER

```
  ┌──────────────┐        ┌────────────────┐        ┌──────────┐
  │    EXAMS     │        │ EXAM_SUBJECTS  │        │  MARKS   │
  ├──────────────┤        ├────────────────┤        ├──────────┤
  │ id (PK)      │───────►│ exam_id (FK)   │───────►│exam_sub_id│
  │ name         │        │ subject_id(FK) │        │student_id │
  │ exam_type    │        │ max_marks      │        │marks_obt  │
  │ start_date   │        │ passing_marks  │        │is_absent  │
  │ is_published │        │ weightage      │        │entered_by │
  └──────────────┘        └────────────────┘        └──────────┘

  ┌──────────────┐        ┌────────────────┐
  │ ASSIGNMENTS  │        │  SUBMISSIONS   │
  ├──────────────┤        ├────────────────┤
  │ section_id   │───────►│ assignment_id  │
  │ subject_id   │        │ student_id     │
  │ teacher_id   │        │ marks_obtained │
  │ due_date     │        │ status         │
  │ max_marks    │        │ graded_by      │
  └──────────────┘        └────────────────┘
```

### Financial ER

```
  ┌──────────────┐     ┌────────────────┐     ┌──────────────┐
  │  FEE_HEADS   │     │ FEE_STRUCTURES │     │   INVOICES   │
  ├──────────────┤     ├────────────────┤     ├──────────────┤
  │ name         │────►│ fee_head_id    │     │ student_id   │
  │ code         │     │ class_id       │     │ invoice_no   │
  │ is_recurring │     │ amount         │     │ total_amount │
  └──────────────┘     │ due_date       │     │ paid_amount  │
                       └────────────────┘     │ status       │
                                              └──────┬───────┘
                                                     │
                                    ┌────────────────┐│┌──────────────┐
                                    │ INVOICE_ITEMS  │││  PAYMENTS    │
                                    ├────────────────┤│├──────────────┤
                                    │ invoice_id(FK) │◄┤ invoice_id   │
                                    │ fee_head_id    │ │ amount       │
                                    │ amount         │ │ method       │
                                    │ discount       │ │ status       │
                                    └────────────────┘ └──────────────┘
```

### Syllabus & Topics ER

```
  ┌──────────────────┐     ┌──────────────────┐
  │ SYLLABUS_TOPICS  │     │ TOPIC_COVERAGE   │
  ├──────────────────┤     ├──────────────────┤
  │ id (PK)          │◄───┤ topic_id (FK)    │
  │ tenant_id        │     │ section_id (FK)  │
  │ subject_id (FK)  │     │ teacher_id (FK)  │
  │ class_id (FK)    │     │ status (enum)    │
  │ academic_year_id │     │ periods_spent    │
  │ parent_topic_id  │──┐  │ started_date     │
  │ level (enum)     │  │  │ completed_date   │
  │ sequence_order   │  │  └──────────────────┘
  │ title            │  │
  │ learning_obj[]   │  │  ┌──────────────────┐
  │ estimated_periods│  │  │  LESSON_PLANS    │
  └─────┬────────────┘  │  ├──────────────────┤
        │               │  │ topic_id (FK)    │──► SYLLABUS_TOPICS
        └───────────────┘  │ section_id (FK)  │
  (self-referencing tree)  │ teacher_id (FK)  │
                           │ title, objective │
  ┌─────────────────────┐  │ warm_up          │
  │ TOPIC_RESOURCE_LINKS│  │ main_activity    │
  ├─────────────────────┤  │ is_ai_generated  │
  │ topic_id (FK)       │  │ status (enum)    │
  │ entity_type (enum)  │  └──────────────────┘
  │ entity_id (UUID)    │
  └─────────────────────┘
    ↳ Polymorphic: assignment | quiz | question_bank | study_resource | exam_subject
```

---

## 4. User Flow Diagrams & Critical Checkpoints

### 4.1 Authentication Flow

```
App Launch
    │
    ▼
[Splash Screen]
    │ 2s animation
    ▼
Check Supabase session ──── No session ──► [Login Screen]
    │                                          │
    │ Valid session                    Email + Password
    │                                          │
    ▼                                          ▼
Load user profile & roles            Supabase auth.signIn()
    │                                          │
    ▼                                          ▼
Route by primaryRole:           ┌── Errors handled:
  super_admin → /super-admin    │   - Invalid credentials
  tenant_admin → /admin         │   - Email not confirmed
  teacher → /teacher            │   - User not found
  student → /student            │   - Too many attempts
  parent → /parent              │   - Network errors
  default → /login              └── SnackBar feedback
```

**Critical Checkpoint:** `lib/core/router/app_router.dart:233-261` — The redirect guard checks session validity on every navigation. If `currentUser` is null but session exists, the user gets stuck. The guard relies on both `session != null` OR `currentUser != null`, which is a safety net but can mask stale state.

**Source:** `lib/features/auth/presentation/screens/login_screen.dart`, `lib/features/auth/providers/auth_provider.dart`

### 4.2 Teacher: Mark Attendance Flow

```
[Teacher Dashboard]
    │ Tap "Mark Attendance" or class card
    ▼
[Attendance Screen] → Select date → Select section
    │
    ▼
[Mark Attendance Screen]
    │ Load students via studentsBySection provider
    ▼
┌─────────────────────────────────────────────┐
│ For each student:                            │
│  [Present] [Absent] [Late] toggle buttons   │
│  ↳ More options: Half Day, Excused, Remarks │
│                                              │
│ Quick actions: "All Present" / "All Absent"  │
│                                              │
│ Summary bar: P: 25 | A: 3 | L: 2 | Total: 30 │
└─────────────────────────────────────────────┘
    │ Tap "Submit Attendance"
    ▼
Upsert to `attendance` table
  onConflict: 'student_id,date'
    │
    ▼
Success SnackBar → Navigate back
```

**Critical Checkpoint:** The upsert uses `student_id,date` as conflict resolution, meaning re-submitting overwrites previous attendance for that date. No confirmation dialog warns about overwriting.

**Source:** `lib/features/attendance/presentation/screens/mark_attendance_screen.dart`

### 4.3 Parent: Fee Payment Flow

```
[Parent Dashboard]
    │ View fee summary → "Pay Now"
    ▼
[Fee Payment Screen]
    │ Load invoices for child
    ▼
┌─────────────────────────────────────┐
│ Invoice List:                        │
│  INV-2024-001  ₹15,000  [Pending]  │
│  INV-2024-002  ₹ 8,500  [Overdue]  │
│                                      │
│ Total Due: ₹23,500                  │
│                                      │
│ [Select Payment Method]              │
│   Cash | Card | UPI | Net Banking   │
│                                      │
│ [Pay Now] button                     │
└─────────────────────────────────────┘
    │
    ▼
Create payment record → Update invoice status
    │
    ▼
Trigger: update_invoice_on_payment()
  → Recalculates paid_amount, sets status
```

**Critical Checkpoint:** Payment processing happens client-side without a payment gateway integration in the current codebase. The `payment_gateway_transactions` table exists in migrations (`20260209112628_integrations.sql`) but no Flutter-side integration code was found. Payments are currently recorded manually.

### 4.4 Student: Take Quiz Flow

```
[Student Dashboard]
    │ Navigate to Assessments
    ▼
[Quizzes Screen]
    │ View available quizzes
    ▼
[Take Quiz Screen]
    │ Timer starts → Duration countdown
    ▼
┌─────────────────────────────────────────────┐
│ Question 3 of 20          Time: 14:32       │
│                                              │
│ Q: What is photosynthesis?                   │
│                                              │
│ ○ A) Cell division                          │
│ ● B) Converting light to chemical energy    │
│ ○ C) Protein synthesis                      │
│ ○ D) DNA replication                        │
│                                              │
│ [Previous]  Progress: ████░░░░  [Next]      │
│                                              │
│ [Submit Quiz]                                │
└─────────────────────────────────────────────┘
    │ Submit
    ▼
Calculate score → Create quiz_attempt record
    │
    ▼
[Quiz Result Screen]
  Score, percentage, pass/fail, answer review
```

**Critical Checkpoint:** Timer runs client-side only. A student could theoretically close the app and reopen to reset the timer. The `started_at` timestamp is recorded server-side, but `time_taken_seconds` is computed client-side.

**Source:** `lib/features/assessments/presentation/screens/take_quiz_screen.dart`, `lib/data/models/quiz.dart`

### 4.5 Admin: Generate Invoices Flow

```
[Admin Dashboard] → [Fee Management]
    │
    ▼
Select: Class + Academic Year + Term + Due Date
    │
    ▼
Call RPC: generate_class_invoices()
    │ Server-side function in 00007_analytics_views.sql
    ▼
For each student in class:
  - Lookup fee_structures for class/year/term
  - Create invoice record
  - Create invoice_items for each fee head
  - Set status = 'pending'
    │
    ▼
Return count of generated invoices
```

**Critical Checkpoint:** No duplicate check — calling `generate_class_invoices` twice creates duplicate invoices. The function should check for existing invoices before generating.

**Source:** `supabase/migrations/00007_analytics_views.sql`

### 4.6 Teacher: Syllabus & Topic Management Flow

```
[Teacher Dashboard]
    │ "Syllabus Progress" section or AI Tools → "Syllabus"
    ▼
[Syllabus List Screen]
    │ Shows teacher's subject assignments with coverage progress
    ▼
Tap subject card
    ▼
[Syllabus Editor Screen]
    │ Expandable tree: Units → Chapters → Topics → Subtopics
    │ Summary bar: coverage %, topic counts, period stats
    ▼
┌───────────────────────────────────────────────────┐
│ Actions:                                           │
│  + Add Unit (manual)                               │
│  + AI Generate (wizard: board → generate → preview │
│    → edit → save)                                   │
│  Toggle coverage status per topic (if section ctx) │
│  Tap topic → Detail screen (linked content, plans) │
│  "Generate Lesson Plan" per topic (AI-powered)     │
└───────────────────────────────────────────────────┘
    │ Coverage status changes
    ▼
Upsert to `topic_coverage` table
  onConflict: 'topic_id,section_id'
    │
    ▼
Dashboard progress bars update automatically
```

**Critical Checkpoint:** AI-generated syllabus uses DeepSeek API (`AITextGenerator.generateSyllabusStructure()`). If API key is missing or call fails, teachers can still create topics manually. The AI wizard shows a preview tree before saving, allowing edits. Bulk creation inserts units → chapters → topics sequentially (not transactional).

**Source:** `lib/features/syllabus/presentation/screens/syllabus_editor_screen.dart`, `lib/features/syllabus/presentation/screens/ai_syllabus_generator_screen.dart`

---

## 5. UX & Usability Review

### 5.1 Visual & Layout Assessment

**Strengths:**
- Consistent use of Material 3 with custom `AppColors` and `AppTheme` (`lib/core/theme/`)
- Poppins font family across all weight variants provides visual coherence
- `GlassCard` widget creates a distinctive frosted-glass aesthetic
- Color-coded status badges (green=paid, yellow=pending, red=overdue) are intuitive
- Dashboard stat cards use gradients effectively to draw attention

**Issues:**

| Issue | Location | Severity |
|-------|----------|----------|
| No responsive breakpoints — layout is phone-only | All screens | Medium |
| No tablet/landscape adaptations | All screens | Medium |
| Hardcoded `SizedBox` widths (e.g., `width: 120`) in dashboard cards | Dashboard screens | Low |
| No dark mode testing evident (theme exists but toggle unclear) | `app_theme.dart` | Low |
| Avatar fallback is initials-only — no default image asset | Student/user displays | Low |

### 5.2 Navigation Assessment

**Strengths:**
- Role-based dashboard routing is well-implemented (`app_router.dart:737-761`)
- `ShellRoute` with `MainShell` provides persistent bottom navigation
- Deep linking supported via GoRouter path parameters
- Named routes avoid magic strings

**Issues:**

| Issue | Impact |
|-------|--------|
| 75+ flat routes under a single `ShellRoute` — no nested grouping | Hard to maintain, route conflicts possible |
| No breadcrumb or "back to dashboard" affordance on deep screens | User can get lost 3-4 levels deep |
| Bottom navigation items not visible on the analyzed code; likely hardcoded per role | Unclear how many nav items exist per role |
| QR scanner mode passed as query parameter `?mode=lookup` — fragile | URL manipulation could bypass intended flow |

### 5.3 Form & Input Assessment

**Mark Attendance Screen** — Well designed:
- Summary bar updates in real-time
- "All Present" shortcut reduces repetitive tapping
- Three prominent status buttons per student (Present/Absent/Late)

**Login Screen** — Good error handling:
- Specific error messages for different failure types (not just "login failed")
- Password visibility toggle
- Demo credential buttons for development (should be removed in production)

**Marks Entry Screen** — Needs work:
- Numeric text input allows any text (relies on parsing, not keyboard restriction)
- No auto-advance to next student after entering marks
- 100 students × manual entry = high friction

### 5.4 Information Density

| Screen | Density Level | Assessment |
|--------|--------------|------------|
| Admin Dashboard | High | 4 stat cards + at-risk + early warnings + syllabus coverage card + quick actions + activity feed — appropriate for power users |
| Teacher Dashboard | High | Schedule + class teacher section + syllabus progress cards + my classes + quick stats + at-risk + early warnings + AI tools (4 cards) + pending tasks |
| Parent Dashboard | Medium-High | Child selector + stats + syllabus progress bars + attendance calendar + performance + fees — verging on overwhelming |
| Student Dashboard | Medium | Stats + today's classes + AI study tips + syllabus coverage bars + performance + upcoming |
| Mark Attendance | Low-Medium | Clean and focused — good for the task |
| Fee Payment | Medium | Clear breakdown but lacks payment confirmation step |
| Syllabus Editor | Medium | Tree view + summary bar + FAB actions — well-organized for hierarchical data |

---

## 6. API & Database Usage Risks

### 6.1 N+1 Query Patterns

| Location | Risk | File Reference |
|----------|------|---------------|
| Student list loading parents separately | Each student card triggers parent lookup | `lib/data/repositories/student_repository.dart` |
| Dashboard stat cards | 4-6 separate queries for stats, not batched | Dashboard screen providers |
| Class roster + attendance + marks | Three separate provider watches per student | Teacher class views |

**Recommendation:** Use Supabase's nested select joins (`select('*, parents(*)')`) consistently. Several repositories already do this well; others still make separate calls.

### 6.2 Missing Pagination

| Screen | Current Behavior | Risk |
|--------|-----------------|------|
| Students List | Loads all students for tenant | >500 students = slow/OOM |
| Messages | Loads all messages in thread | Threads with 1000+ messages |
| Attendance history | Full history load | Years of daily records |
| Notification center | All notifications | Unbounded growth |

Only `StudentsFilter`, `ResourceFilter`, and `SyllabusFilter` models include `limit`/`offset` or scoped filter fields. Most providers fetch unbounded result sets.

### 6.3 Real-Time Channel Risks

**Source:** `lib/data/repositories/base_repository.dart:17-64`

```
Concern: Each subscribeToTable() call creates a new Realtime channel.
Multiple screens open = multiple channels.
No cleanup lifecycle management visible in providers.
```

If a teacher opens attendance for 5 sections without navigating back, 5 channels remain subscribed. Supabase has a default limit of ~100 concurrent channels per connection.

### 6.4 Tenant Isolation Risk

**Source:** `lib/data/repositories/base_repository.dart:12-15`

```dart
String? get tenantId {
  final claims = _client.auth.currentUser?.appMetadata;
  return claims?['tenant_id'] as String?;
}
```

`tenantId` is extracted from JWT `appMetadata`. If `tenant_id` is null (e.g., super_admin without a tenant), queries that `.eq('tenant_id', tenantId!)` will throw a null assertion error. Several repositories force-unwrap with `tenantId!` without null checks.

### 6.5 Missing Transaction Guarantees

| Operation | Risk | File |
|-----------|------|------|
| PTM schedule deletion | Deletes appointments, availability, then schedule in 3 calls — partial failure leaves orphans | `ptm_repository.dart` |
| Invoice generation (client-side) | Creates invoice then items — failure after invoice leaves empty invoice | `fee_repository.dart` |
| Canteen order placement | Deducts wallet then creates order — failure after deduction loses money | `canteen_repository.dart` |

Supabase doesn't support client-side transactions. These multi-step operations should use server-side RPC functions (PostgreSQL stored procedures).

### 6.6 Offline Sync Gap

Isar (local database) is declared as a dependency with local models (`attendance_local.dart`, `student_local.dart`, `sync_queue.dart`), but:
- No sync logic implementation found in repositories
- No conflict resolution strategy documented
- `LocalStorageService` exists but minimal implementation
- The `synced_at` field on `attendance` suggests offline-first was planned but not completed

---

## 7. Top Strengths

### 7.1 Comprehensive Multi-Tenant Architecture
Every table includes `tenant_id` with RLS policies enforcing isolation. The `has_role()` helper function provides a clean authorization abstraction. This is production-grade multi-tenant design.

### 7.2 Extensive Schema Design
150+ tables covering 20+ functional modules (now including a full syllabus/topics hierarchy) is unusually thorough. The schema handles edge cases like:
- Period-level attendance (not just daily)
- Multi-attempt quizzes with shuffled questions
- Payment plans with installment tracking and dunning workflows
- Behavioral tracking with intervention plans
- GDPR compliance with data subject requests

### 7.3 Clean Separation of Concerns
The Repository → Provider → UI layering is consistent across all 27 repositories and 29 providers. `BaseRepository` provides a foundation with real-time subscription support. Models use `fromJson`/`toJson` with proper snake_case conversion.

### 7.4 Role-Based Experience Design
Each role (admin, teacher, student, parent) gets a purpose-built dashboard with relevant stats and actions. Navigation guards redirect users to their appropriate dashboard. This is superior to a one-size-fits-all approach.

### 7.5 Real-Time Data Foundation
The `BaseRepository.subscribeToTable()` method provides a reusable pattern for real-time updates. Attendance marking, messaging, and notifications can update live without polling.

### 7.6 Analytics Infrastructure
Materialized views (`mv_student_performance`), computed views (`v_class_exam_stats`, `v_student_ranks`, `v_fee_summary`), and PostgreSQL functions (`promote_students`, `generate_class_invoices`) push computation to the database where it's most efficient.

### 7.7 Gamification Layer
Points, achievements, and leaderboards are well-structured with automatic achievement checks and point transaction history. This adds engagement beyond basic school management.

### 7.8 Syllabus & Topics Ecosystem
Full hierarchical topic management (unit → chapter → topic → subtopic) with:
- AI-powered syllabus generation via DeepSeek (with manual fallback)
- AI-powered lesson plan generation with structured output (objective, warm-up, main activity, assessment, homework)
- Per-section coverage tracking with segmented progress bars
- Cross-cutting topic linking to assignments, quizzes, question bank, and study resources
- Multi-role views: teacher (edit + track), student/parent (read-only progress), admin (cross-section comparison)
- Dashboard integration on all 4 role dashboards

**Source:** `lib/features/syllabus/` (10 screens, 8 widgets, 2 providers, 1 repository)

---

## 8. Top Improvement Areas

### 8.1 Critical: Missing Error Recovery

**Current state:** Most errors surface as generic `Exception` messages. No custom exception hierarchy. No retry logic for transient network failures.

**Recommendation:**
```
Create:
  lib/core/errors/app_exception.dart
    - NetworkException (timeout, no connection)
    - AuthException (expired token, unauthorized)
    - ValidationException (invalid input)
    - ConflictException (duplicate entry)
    - NotFoundExcepion

Add retry wrapper in BaseRepository for transient failures.
Add connectivity_plus listener to show offline banner.
```

### 8.2 Critical: Unbounded Query Results

**Current state:** Most providers fetch all records. A school with 2000 students loading all at once will cause UI jank and memory pressure.

**Recommendation:** Implement cursor-based or offset pagination in all list providers. Use `ScrollController` listeners to trigger "load more" calls.

### 8.3 High: No Payment Gateway Integration

The `payment_gateway_transactions` table and integration schema exist (`20260209112628_integrations.sql`), but no Flutter-side implementation connects to Razorpay, Stripe, or any gateway. Parents currently cannot pay fees electronically.

### 8.4 High: Offline-First Is Incomplete

Isar dependency and local models exist but sync logic is absent. For a school app used in areas with unreliable connectivity (common in Indian schools), offline attendance marking is essential.

### 8.5 Medium: No Automated Testing

No test files found beyond the default `flutter_test` dependency. Zero unit tests, widget tests, or integration tests. Given the 78-screen surface area, this is a significant risk for regression.

### 8.6 Medium: Demo Credentials in Production Code

`LoginScreen` contains hardcoded demo credential buttons. These should be behind an environment flag (`AppEnvironment`) and stripped from release builds.

**Source:** `lib/features/auth/presentation/screens/login_screen.dart`

### 8.7 Medium: Inconsistent Model Patterns

Some models use Freezed (immutable, code-generated): `Timetable`, `Announcement`, `Assignment`, `Invoice`, `Message`, `ExamStatistics`.
Most models use plain Dart classes with manual `fromJson`/`toJson` (including newer additions: `SyllabusTopic`, `LessonPlan`, `TopicCoverage`).

This inconsistency increases maintenance burden. Pick one approach and apply it uniformly.

### 8.8 Low: Feature Bloat vs. Feature Depth

The codebase has 32 feature modules but many are shallow (notable exception: `syllabus` is fully deep with CRUD, AI, tracking, linking, and multi-role views). For example:
- `Canteen` has full CRUD but no kitchen-staff order management screen
- `Transport` shows routes but no GPS tracking
- `Hostel` manages rooms but no complaint system
- `Emergency` alerts exist but no drill automation

Consider deepening core features (attendance, exams, fees) before expanding breadth.

---

## 9. Realistic Failure Scenarios

### 9.1 Long Student Names

**Scenario:** A student named "Mohammed Abdul Rahman Al-Farouq Ibn Khalid" (47 characters) with admission number "2024-KV-CENTRAL-DELHI-00123" (27 characters).

**Impact:**
- Student list cards will truncate or overflow (`Text` widgets with hardcoded `maxLines: 1`)
- Attendance marking screen shows name + roll number — very long names push status buttons off screen
- PDF report cards with fixed column widths will clip names
- QR code data encoding may exceed scanner read distance

**Fix:** Use `TextOverflow.ellipsis` consistently, test with 50-character names, consider `FittedBox` for critical labels.

### 9.2 Class with 80+ Students

**Scenario:** A government school section with 80 students (common in India).

**Impact:**
- Mark Attendance screen loads 80 student cards — excessive scrolling
- Marks Entry screen with 80 rows of input fields — form becomes unwieldy
- Section capacity is `DEFAULT 40` — no validation prevents exceeding it
- Summary bar counts become hard to read at 3 digits

**Fix:** Add virtual scrolling (`ListView.builder` — likely already used), implement batch operations, add capacity warnings.

### 9.3 Missing or Null Data

**Scenario:** A student created with only `admission_number` and `first_name` (all other fields null).

**Impact:**
- `student.fullName` returns "FirstName null" if `lastName` is null (depends on implementation)
- `student.age` throws if `dateOfBirth` is null (`.difference()` on null DateTime)
- Student Detail screen shows "null" text in contact/guardian sections
- Insights calculations divide by zero if no attendance/marks data exists

**Fix:** Null-check all display values. Use `??` fallbacks like `"Not provided"`. Guard computed properties.

### 9.4 Concurrent Attendance Marking

**Scenario:** Two teachers mark attendance for the same section on the same date simultaneously.

**Impact:**
- Both see the initial state (no attendance marked)
- Both submit — second submission overwrites first via upsert
- No merge or conflict detection — last write wins silently
- Neither teacher is notified of the conflict

**Fix:** Add `updated_at` optimistic locking check. Show warning if attendance was modified since initial load.

### 9.5 Large File Uploads

**Scenario:** A teacher uploads a 50MB assignment PDF as attachment.

**Impact:**
- No file size validation visible in upload code
- Supabase storage has configurable limits but no client-side check
- Mobile data users would face lengthy uploads with no progress indicator
- The `attachments` JSONB field stores URLs, but no cleanup if upload fails mid-way

**Fix:** Validate file size client-side (suggest 10MB limit), show upload progress, implement resumable uploads.

### 9.6 Academic Year Transition

**Scenario:** End of academic year — promote 500 students from Class 9 to Class 10.

**Impact:**
- `promote_students()` RPC exists but no UI found to trigger it
- If promotion fails halfway, some students are promoted and others aren't
- Old enrollments need to be closed, new ones created — atomicity required
- Report cards, fee invoices, and attendance data reference old year IDs

**Fix:** Build a dedicated promotion wizard with preview, confirmation, and rollback capability.

### 9.7 Subscription Expiry

**Scenario:** A tenant's `subscription_expires_at` passes without renewal.

**Impact:**
- No middleware or guard checks subscription status on API calls
- `is_active` on tenant exists but no enforcement code found
- Users continue accessing all features indefinitely
- No downgrade path to restrict features

**Fix:** Add subscription check middleware. Implement feature gating based on `subscription_plan`.

---

## 10. Accessibility & Cognitive Load

### 10.1 Accessibility Gaps

| Category | Current State | Recommendation |
|----------|--------------|----------------|
| Semantic labels | No `Semantics` widgets found in screen code | Add semantic labels to all interactive elements |
| Color contrast | Status badges (yellow on white) may fail WCAG AA | Test with contrast checker; ensure 4.5:1 ratio |
| Touch targets | Some icon buttons (filter, more options) are < 48dp | Ensure minimum 48x48dp touch targets |
| Screen reader | No `ExcludeSemantics` / `MergeSemantics` usage | Add semantic grouping for card widgets |
| Font scaling | No `textScaleFactor` bounds set | Test at 2x text scale; add `MediaQuery` bounds |
| RTL support | No RTL-aware padding/margins | Use `EdgeInsetsDirectional` for Urdu/Arabic locales |

### 10.2 Cognitive Load Assessment

**Admin Dashboard:** HIGH cognitive load
- 4 stat cards + 7 quick action buttons + activity feed + today's summary = ~15 distinct information groups on one screen
- Recommendation: Collapse quick actions into a FAB menu or drawer. Show only top 3 stats, expand on tap.

**Parent Dashboard:** MEDIUM-HIGH cognitive load
- Child selector + stats + weekly calendar + performance chart + fee summary
- For parents with 3+ children, the horizontal child selector pushes content below fold
- Recommendation: Dedicate full screen to selected child. Add child switcher to app bar, not inline.

**Mark Attendance Screen:** LOW cognitive load (well-designed)
- Single task focus: one student at a time, clear Present/Absent/Late buttons
- Summary bar provides running total
- This is a model screen for the app.

**Student Dashboard:** MEDIUM cognitive load (appropriate)
- Three stats + today's schedule + upcoming items
- No unnecessary decoration or feature promotion
- Clear hierarchy of information

### 10.3 Localization Status

- `intl: ^0.20.2` is included but no `.arb` files or `AppLocalizations` setup found
- All strings are hardcoded in English
- Currency is hardcoded as `₹` in fee display code
- Date formats use `intl.DateFormat` in some places, hardcoded in others

---

## 11. Concrete Action Items & Roadmap

### Month 1: Stability & Core Quality

| Priority | Action | Effort | Impact |
|----------|--------|--------|--------|
| P0 | Add pagination to all list screens (students, messages, attendance, notifications) | Medium | Prevents crashes with real data volumes |
| P0 | Null-safety audit: fix all `!` force-unwraps in repositories and models | Medium | Prevents null crashes in production |
| P0 | Remove demo credentials from LoginScreen in release builds | Low | Security fix |
| P0 | Add file size validation for all upload inputs | Low | Prevents upload failures |
| P1 | Create custom exception hierarchy and error handling wrapper | Medium | Better error messages for users |
| P1 | Add missing database indexes (student name search, message sender, invoice due date) | Low | Query performance improvement |
| P1 | Add confirmation dialog before attendance overwrite | Low | Prevents accidental data loss |
| P1 | Fix `tenantId` null-safety in BaseRepository for super_admin role | Low | Prevents crashes for super admin |
| P2 | Add unit tests for all repository methods | High | Regression prevention foundation |
| P2 | Standardize model pattern: migrate all to Freezed or all to plain classes | Medium | Reduce maintenance burden |

### Month 2: Feature Completion & UX Polish

| Priority | Action | Effort | Impact |
|----------|--------|--------|--------|
| P0 | Implement payment gateway integration (Razorpay recommended for India) | High | Core monetization feature |
| P0 | Complete offline-first sync for attendance marking | High | Essential for field usage |
| P1 | Add academic year promotion wizard UI | Medium | Critical for annual operations |
| P1 | Implement subscription enforcement and feature gating | Medium | Monetization protection |
| P1 | Add tablet/landscape responsive layouts | High | Enables admin use on tablets |
| P1 | Add breadcrumb navigation for deep screens | Medium | Reduces user disorientation |
| P2 | Implement real-time channel cleanup in provider dispose | Low | Prevents channel leaks |
| P2 | Add search indexing (GIN trigram) for student name search | Low | Fast search for large schools |
| P2 | Add loading skeletons (shimmer already in deps) | Medium | Perceived performance improvement |

### Month 3: Scale & Polish

| Priority | Action | Effort | Impact |
|----------|--------|--------|--------|
| P0 | Widget and integration test coverage for core flows (auth, attendance, fees) | High | Quality gate |
| P1 | Localization setup with ARB files (Hindi, Tamil, Telugu minimum) | High | Market reach |
| P1 | Accessibility audit and Semantics implementation | Medium | Inclusive design |
| P1 | Server-side transaction functions for multi-step operations (invoicing, orders, PTM) | Medium | Data integrity |
| P2 | Push notification implementation (FCM token already stored) | Medium | Engagement feature |
| P2 | Add data export (CSV/PDF) for reports, attendance, fee collection | Medium | Admin productivity |
| P2 | Performance profiling — RLS query overhead measurement | Medium | Scalability validation |
| P2 | Add rate limiting awareness and exponential backoff | Low | Resilience under load |

### Architectural Debt Items (Ongoing)

- [ ] Consolidate `student` and `students` feature folders (both exist, causing confusion)
- [ ] Move demo/development utilities behind build flavor flags
- [ ] Create shared form validation library (currently duplicated per screen)
- [ ] Implement proper state invalidation strategy (currently manual `ref.invalidate()`)
- [ ] Add API response caching layer with TTL (Riverpod caches indefinitely or not at all)
- [ ] Document all RPC functions with input/output contracts
- [ ] Add database migration versioning strategy (mix of `0000x` and `2026MMDD` naming)

---

## Appendix: Key File References

| Component | Path |
|-----------|------|
| Entry point | `lib/main.dart` |
| Router | `lib/core/router/app_router.dart` |
| Theme | `lib/core/theme/app_theme.dart`, `lib/core/theme/app_colors.dart` |
| Base repository | `lib/data/repositories/base_repository.dart` |
| Supabase config | `lib/core/config/supabase_config.dart` |
| Auth provider | `lib/features/auth/providers/auth_provider.dart` |
| Core migrations | `supabase/migrations/00001_initial_schema.sql` through `00011_syllabus_topics.sql` |
| Advanced migrations | `supabase/migrations/20260209112622_*.sql` through `20260209112631_*.sql` |
| Shell (bottom nav) | `lib/core/shell/main_shell.dart` |
| Glass card widget | `lib/shared/widgets/glass_card.dart` |
| AI text generator | `lib/core/services/ai_text_generator.dart` |
| Syllabus models | `lib/data/models/syllabus_topic.dart`, `lib/data/models/lesson_plan.dart` |
| Syllabus repository | `lib/data/repositories/syllabus_repository.dart` |
| Syllabus providers | `lib/features/syllabus/providers/syllabus_provider.dart`, `syllabus_ai_provider.dart` |
| Syllabus screens | `lib/features/syllabus/presentation/screens/` (10 screens) |
| Syllabus widgets | `lib/features/syllabus/presentation/widgets/` (8 widgets) |
| Syllabus migration | `supabase/migrations/00011_syllabus_topics.sql` |

---

## Appendix: Questions Requiring Clarification

These items could not be determined from code analysis alone:

1. **Deployment target:** Is this currently deployed? What Supabase instance/plan is in use?
2. **User scale:** What is the target number of students per tenant? This affects pagination priority.
3. **Offline requirement:** Is offline attendance marking a hard requirement? The Isar setup suggests yes, but implementation is missing.
4. **Payment gateway:** Has a payment gateway been selected? Razorpay is most common for Indian schools.
5. **FCM setup:** Firebase is in dependencies — is the Firebase project configured? Are push notifications working?
6. **Migration strategy:** The mix of `0000x_` and `20260209_` migration naming suggests two development phases. Is there a migration runner in place?
7. **Feature priority:** With 31 modules at varying completion levels, which 5 are must-have for MVP launch?
8. **Test data:** Is there seed data or a test tenant? The demo credentials on login suggest a dev environment exists.
