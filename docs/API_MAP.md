# API MAP - School Management SaaS

> Generated 2026-03-06 | v1.0.0+1
> All Supabase table references, RPC calls, and realtime subscriptions found in Flutter code

---

## Table of Contents

1. [Supabase Tables Referenced in Code](#supabase-tables-referenced-in-code)
2. [RPC (Remote Procedure Call) Functions](#rpc-remote-procedure-call-functions)
3. [Realtime Subscriptions](#realtime-subscriptions)
4. [Server-Side Functions and Triggers](#server-side-functions-and-triggers)
5. [Tables Defined in Migrations but Not Referenced in Flutter](#tables-defined-in-migrations-but-not-referenced-in-flutter)

---

## Supabase Tables Referenced in Code

Tables accessed via `client.from('table_name')` in repository files.

### Core / Identity

| Table | Repository | Operations |
|-------|-----------|------------|
| `tenants` | TenantRepository | SELECT, INSERT, UPDATE, DELETE |
| `users` | StudentRepository, multiple | SELECT, UPDATE |
| `user_roles` | AuthProvider, multiple | SELECT |
| `staff` | LibraryRepository, HrRepository | SELECT |

### Academics

| Table | Repository | Operations |
|-------|-----------|------------|
| `academic_years` | AcademicRepository | SELECT, INSERT, UPDATE, DELETE |
| `terms` | AcademicRepository | SELECT, INSERT, UPDATE, DELETE |
| `classes` | AcademicRepository | SELECT, INSERT, UPDATE, DELETE |
| `sections` | AcademicRepository | SELECT, INSERT, UPDATE, DELETE |
| `subjects` | AcademicRepository | SELECT, INSERT, UPDATE, DELETE |
| `class_subjects` | AcademicRepository | SELECT, INSERT, DELETE |
| `teacher_assignments` | AcademicRepository | SELECT, INSERT, UPDATE, DELETE |

### Students & Parents

| Table | Repository | Operations |
|-------|-----------|------------|
| `students` | StudentRepository, multiple | SELECT, INSERT, UPDATE, DELETE |
| `student_enrollments` | StudentRepository | SELECT, INSERT, UPDATE |
| `parents` | StudentRepository | SELECT, INSERT, UPDATE |
| `student_parents` | StudentRepository | SELECT, INSERT |

### Timetable & Attendance

| Table | Repository | Operations |
|-------|-----------|------------|
| `timetable_slots` | TimetableRepository | SELECT, INSERT, UPDATE, DELETE |
| `timetables` | TimetableRepository | SELECT, INSERT, UPDATE, DELETE |
| `attendance` | AttendanceRepository | SELECT, INSERT, UPDATE, UPSERT |
| `period_attendance` | AttendanceRepository | SELECT, INSERT |

### Exams & Grading

| Table | Repository | Operations |
|-------|-----------|------------|
| `exams` | ExamRepository | SELECT, INSERT, UPDATE, DELETE |
| `exam_subjects` | ExamRepository | SELECT, INSERT, UPDATE, DELETE |
| `marks` | ExamRepository | SELECT, INSERT, UPDATE, UPSERT |
| `grade_scales` | ExamRepository | SELECT |
| `grade_scale_items` | ExamRepository | SELECT |
| `exam_statistics` | ExamRepository | SELECT |

### Assignments & Submissions

| Table | Repository | Operations |
|-------|-----------|------------|
| `assignments` | AssignmentRepository | SELECT, INSERT, UPDATE, DELETE |
| `submissions` | AssignmentRepository | SELECT, INSERT, UPDATE |

### Communication & Messaging

| Table | Repository | Operations |
|-------|-----------|------------|
| `threads` | MessageRepository | SELECT, INSERT, UPDATE |
| `thread_participants` | MessageRepository | SELECT, INSERT |
| `messages` | MessageRepository | SELECT, INSERT |
| `announcements` | AnnouncementRepository, MessageRepository | SELECT, INSERT, UPDATE, DELETE |
| `notifications` | NotificationRepository | SELECT, INSERT, UPDATE, DELETE |

### Fees & Payments

| Table | Repository | Operations |
|-------|-----------|------------|
| `fee_heads` | FeeRepository | SELECT, INSERT, UPDATE, DELETE |
| `fee_structures` | FeeRepository | SELECT, INSERT, UPDATE, DELETE |
| `invoices` | FeeRepository | SELECT, INSERT, UPDATE |
| `invoice_items` | FeeRepository | SELECT, INSERT |
| `payments` | FeeRepository | SELECT, INSERT |
| `fee_reminder_log` | FeeRepository | SELECT, INSERT |

### Canteen

| Table | Repository | Operations |
|-------|-----------|------------|
| `canteen_menu` | CanteenRepository | SELECT, INSERT, UPDATE, DELETE |
| `canteen_orders` | CanteenRepository | SELECT, INSERT, UPDATE |
| `canteen_order_items` | CanteenRepository | SELECT, INSERT |
| `wallets` | CanteenRepository | SELECT, UPDATE |
| `wallet_transactions` | CanteenRepository | SELECT, INSERT |

### Library

| Table | Repository | Operations |
|-------|-----------|------------|
| `library_books` | LibraryRepository | SELECT, INSERT, UPDATE, DELETE |
| `book_issues` | LibraryRepository | SELECT, INSERT, UPDATE |

### Transport

| Table | Repository | Operations |
|-------|-----------|------------|
| `transport_routes` | TransportRepository | SELECT, INSERT, UPDATE, DELETE |
| `transport_stops` | TransportRepository | SELECT, INSERT, UPDATE, DELETE |
| `student_transport` | TransportRepository | SELECT, INSERT, UPDATE, DELETE |

### Hostel

| Table | Repository | Operations |
|-------|-----------|------------|
| `hostels` | HostelRepository | SELECT, INSERT, UPDATE, DELETE |
| `hostel_rooms` | HostelRepository | SELECT, INSERT, UPDATE, DELETE |
| `room_allocations` | HostelRepository | SELECT, INSERT, UPDATE, DELETE |

### Health & Safety

| Table | Repository | Operations |
|-------|-----------|------------|
| `student_health_records` | HealthRepository | SELECT, INSERT, UPDATE |
| `health_incidents` | HealthRepository | SELECT, INSERT, UPDATE |
| `emergency_alerts` | EmergencyRepository | SELECT, INSERT, UPDATE |
| `emergency_responses` | EmergencyRepository | SELECT, INSERT |
| `emergency_contacts` | EmergencyRepository | SELECT, INSERT, UPDATE, DELETE |

### Gamification

| Table | Repository | Operations |
|-------|-----------|------------|
| `achievements` | GamificationRepository | SELECT, INSERT, UPDATE |
| `student_achievements` | GamificationRepository | SELECT, INSERT |
| `student_points` | GamificationRepository | SELECT, UPDATE |
| `point_transactions` | GamificationRepository | SELECT, INSERT |

### Assessments & Quizzes

| Table | Repository | Operations |
|-------|-----------|------------|
| `quizzes` | AssessmentRepository | SELECT, INSERT, UPDATE, DELETE |
| `question_bank` | AssessmentRepository | SELECT, INSERT, UPDATE |
| `quiz_questions` | AssessmentRepository | SELECT, INSERT, DELETE |
| `quiz_attempts` | AssessmentRepository | SELECT, INSERT, UPDATE |

### PTM (Parent-Teacher Meeting)

| Table | Repository | Operations |
|-------|-----------|------------|
| `ptm_schedules` | PtmRepository | SELECT, INSERT, UPDATE, DELETE |
| `ptm_teacher_availability` | PtmRepository | SELECT, INSERT, UPDATE |
| `ptm_appointments` | PtmRepository | SELECT, INSERT, UPDATE, DELETE |

### Leave Management

| Table | Repository | Operations |
|-------|-----------|------------|
| `leave_applications` | LeaveRepository | SELECT, INSERT, UPDATE |
| `leave_balance` | LeaveRepository | SELECT, UPDATE |

### Study Resources

| Table | Repository | Operations |
|-------|-----------|------------|
| `study_resources` | ResourceRepository | SELECT, INSERT, UPDATE, DELETE |
| `resource_access` | ResourceRepository | SELECT, INSERT |

### QR / Check-in

| Table | Repository | Operations |
|-------|-----------|------------|
| `student_checkins` | CheckinRepository | SELECT, INSERT |

### AI Analytics

| Table | Repository | Operations |
|-------|-----------|------------|
| `student_risk_scores` | RiskScoreRepository | SELECT, INSERT, UPDATE |
| `parent_digests` | ParentDigestRepository | SELECT, INSERT |
| `trend_predictions` | TrendPredictionRepository | SELECT, INSERT |
| `early_warning_alerts` | EarlyWarningRepository | SELECT, INSERT, UPDATE |
| `alert_rules` | EarlyWarningRepository | SELECT, INSERT, UPDATE, DELETE |

### Syllabus & Lesson Plans

| Table | Repository | Operations |
|-------|-----------|------------|
| `syllabus_topics` | SyllabusRepository | SELECT, INSERT, UPDATE, DELETE |
| `topic_coverage` | SyllabusRepository | SELECT, INSERT, UPDATE |
| `lesson_plans` | SyllabusRepository | SELECT, INSERT, UPDATE, DELETE |
| `topic_resource_links` | SyllabusRepository | SELECT, INSERT, DELETE |

### Question Papers

| Table | Repository | Operations |
|-------|-----------|------------|
| `question_papers` | QuestionPaperRepository | SELECT, INSERT, UPDATE, DELETE |
| `question_paper_sections` | QuestionPaperRepository | SELECT, INSERT, UPDATE, DELETE |
| `question_paper_items` | QuestionPaperRepository | SELECT, INSERT, UPDATE, DELETE |

### Substitution

| Table | Repository | Operations |
|-------|-----------|------------|
| `teacher_absences` | SubstitutionRepository | SELECT, INSERT, UPDATE |
| `substitution_assignments` | SubstitutionRepository | SELECT, INSERT, UPDATE |

### Discipline

| Table | Repository | Operations |
|-------|-----------|------------|
| `behavior_categories` | DisciplineRepository | SELECT, INSERT, UPDATE |
| `behavior_incidents` | DisciplineRepository | SELECT, INSERT, UPDATE |
| `behavior_actions` | DisciplineRepository | SELECT, INSERT |
| `behavior_plans` | DisciplineRepository | SELECT, INSERT, UPDATE |
| `behavior_plan_reviews` | DisciplineRepository | SELECT, INSERT |
| `positive_recognitions` | DisciplineRepository | SELECT, INSERT |
| `detention_schedules` | DisciplineRepository | SELECT, INSERT, UPDATE |
| `detention_assignments` | DisciplineRepository | SELECT, INSERT, UPDATE |

### Admission

| Table | Repository | Operations |
|-------|-----------|------------|
| `admission_inquiries_v2` | AdmissionRepository | SELECT, INSERT, UPDATE |
| `admission_applications_v2` | AdmissionRepository | SELECT, INSERT, UPDATE |
| `admission_interviews_v2` | AdmissionRepository | SELECT, INSERT, UPDATE |
| `admission_documents_v2` | AdmissionRepository | SELECT, INSERT |
| `admission_settings_v2` | AdmissionRepository | SELECT, INSERT, UPDATE |

### Communication Hub

| Table | Repository | Operations |
|-------|-----------|------------|
| `communication_templates` | CommunicationRepository | SELECT, INSERT, UPDATE, DELETE |
| `communication_campaigns` | CommunicationRepository | SELECT, INSERT, UPDATE |
| `campaign_recipients` | CommunicationRepository | SELECT, INSERT |
| `communication_log` | CommunicationRepository | SELECT |
| `sms_gateway_config` | CommunicationRepository | SELECT, INSERT, UPDATE |
| `email_config` | CommunicationRepository | SELECT, INSERT, UPDATE |
| `auto_notification_rules` | CommunicationRepository | SELECT, INSERT, UPDATE, DELETE |

### Report Cards (full module)

| Table | Repository | Operations |
|-------|-----------|------------|
| `grading_scales` | ReportCardFullRepository | SELECT, INSERT, UPDATE |
| `report_card_templates` | ReportCardFullRepository | SELECT, INSERT, UPDATE |
| `report_cards` | ReportCardFullRepository | SELECT, INSERT, UPDATE |
| `report_card_comments` | ReportCardFullRepository | SELECT, INSERT, UPDATE |
| `report_card_skills` | ReportCardFullRepository | SELECT, INSERT, UPDATE |
| `report_card_activities` | ReportCardFullRepository | SELECT, INSERT |

### HR & Payroll

| Table | Repository | Operations |
|-------|-----------|------------|
| `departments` | HrRepository | SELECT, INSERT, UPDATE, DELETE |
| `designations` | HrRepository | SELECT, INSERT, UPDATE |
| `staff_contracts` | HrRepository | SELECT, INSERT, UPDATE |
| `salary_structures` | HrRepository | SELECT, INSERT, UPDATE |
| `payroll_runs` | HrRepository | SELECT, INSERT, UPDATE |
| `payroll_items` | HrRepository | SELECT, INSERT |
| `salary_slips` | HrRepository | SELECT |
| `staff_attendance_daily` | HrRepository | SELECT, INSERT, UPDATE |
| `tax_declarations` | HrRepository | SELECT, INSERT, UPDATE |
| `staff_documents` | HrRepository | SELECT, INSERT, DELETE |

### Inventory & Assets

| Table | Repository | Operations |
|-------|-----------|------------|
| `inv_asset_categories` | InventoryRepository | SELECT, INSERT, UPDATE, DELETE |
| `inv_assets` | InventoryRepository | SELECT, INSERT, UPDATE, DELETE |
| `inv_asset_assignments` | InventoryRepository | SELECT, INSERT, UPDATE |
| `inv_asset_maintenance` | InventoryRepository | SELECT, INSERT, UPDATE |
| `inv_inventory_items` | InventoryRepository | SELECT, INSERT, UPDATE |
| `inv_inventory_transactions` | InventoryRepository | SELECT, INSERT |
| `inv_purchase_requests` | InventoryRepository | SELECT, INSERT, UPDATE |
| `inv_asset_audits` | InventoryRepository | SELECT, INSERT, UPDATE |

### LMS

| Table | Repository | Operations |
|-------|-----------|------------|
| `courses` | LmsRepository | SELECT, INSERT, UPDATE, DELETE |
| `course_modules` | LmsRepository | SELECT, INSERT, UPDATE, DELETE |
| `module_content` | LmsRepository | SELECT, INSERT, UPDATE, DELETE |
| `course_enrollments` | LmsRepository | SELECT, INSERT, UPDATE |
| `content_progress` | LmsRepository | SELECT, INSERT, UPDATE |
| `discussion_forums` | LmsRepository | SELECT, INSERT |
| `forum_posts` | LmsRepository | SELECT, INSERT |
| `course_certificates` | LmsRepository | SELECT, INSERT |

### Online Exams

| Table | Repository | Operations |
|-------|-----------|------------|
| `online_exams` | OnlineExamRepository | SELECT, INSERT, UPDATE, DELETE |
| `exam_sections` | OnlineExamRepository | SELECT, INSERT, UPDATE, DELETE |
| `exam_questions` | OnlineExamRepository | SELECT, INSERT, UPDATE, DELETE |
| `exam_attempts` | OnlineExamRepository | SELECT, INSERT, UPDATE |
| `exam_responses` | OnlineExamRepository | SELECT, INSERT, UPDATE |

### Alumni

| Table | Repository | Operations |
|-------|-----------|------------|
| `alumni_profiles` | AlumniRepository | SELECT, INSERT, UPDATE |
| `alumni_events` | AlumniRepository | SELECT, INSERT, UPDATE |
| `alumni_event_registrations` | AlumniRepository | SELECT, INSERT, DELETE |
| `alumni_donations` | AlumniRepository | SELECT, INSERT |
| `mentorship_programs` | AlumniRepository | SELECT, INSERT, UPDATE |
| `mentorship_requests` | AlumniRepository | SELECT, INSERT, UPDATE |
| `alumni_success_stories` | AlumniRepository | SELECT, INSERT, UPDATE |

### Visitor Management

| Table | Repository | Operations |
|-------|-----------|------------|
| `visitors` | VisitorRepository | SELECT, INSERT, UPDATE |
| `visitor_logs` | VisitorRepository | SELECT, INSERT, UPDATE |
| `visitor_pre_registrations` | VisitorRepository | SELECT, INSERT, UPDATE |

### Certificates

| Table | Repository | Operations |
|-------|-----------|------------|
| `certificate_templates` | CertificateRepository | SELECT, INSERT, UPDATE, DELETE |
| `issued_certificates` | CertificateRepository | SELECT, INSERT, UPDATE |
| `certificate_number_sequences` | CertificateRepository | SELECT |

### Calendar & Events

| Table | Repository | Operations |
|-------|-----------|------------|
| `school_events` | CalendarRepository | SELECT, INSERT, UPDATE, DELETE |
| `event_attendees` | CalendarRepository | SELECT, INSERT, UPDATE, DELETE |
| `event_reminders` | CalendarRepository | SELECT, INSERT, DELETE |
| `academic_calendar_items` | CalendarRepository | SELECT, INSERT, UPDATE, DELETE |
| `holiday_calendar` | CalendarRepository | SELECT, INSERT, UPDATE, DELETE |

---

## RPC (Remote Procedure Call) Functions

All server-side functions called from Flutter via `client.rpc()`.

| RPC Function | Repository | Parameters | Purpose |
|-------------|-----------|------------|---------|
| `refresh_analytics` | ExamRepository | none | Refreshes materialized analytics views after marks update |
| `compute_student_risk_score` | RiskScoreRepository | `p_student_id`, `p_academic_year_id`, `p_tenant_id` | Computes composite risk score for a student |
| `increment_resource_view` | ResourceRepository | `resource_id` | Increments view counter on study resource |
| `increment_resource_download` | ResourceRepository | `resource_id` | Increments download counter on study resource |
| `suggest_substitutes` | SubstitutionRepository | `p_tenant_id`, `p_subject_id`, `p_date`, `p_slot_id` | AI-assisted substitute teacher suggestions |
| `generate_payroll` | HrRepository | `p_tenant_id`, `p_payroll_run_id` | Generates payroll items for a payroll run |
| `award_points` | GamificationRepository | `p_student_id`, `p_points`, `p_reason`, `p_category` | Awards gamification points with transaction log |
| `create_tenant_admin` | TenantRepository | `p_tenant_id`, `p_email`, `p_password`, `p_name` | Creates admin user for a new tenant |
| `get_parent_children` | StudentRepository | `p_user_id` | Returns all children for a parent user |
| `get_student_current_enrollment` | StudentRepository | `p_student_id` | Returns current enrollment (class, section) for a student |
| `generate_class_invoices` | FeeRepository | `p_tenant_id`, `p_class_id`, `p_fee_structure_id`, `p_academic_year_id` | Bulk-generates invoices for all students in a class |
| `predict_fee_defaults` | FeeRepository | `p_tenant_id` | Returns fee default predictions for students |
| `generate_certificate_number` | CertificateRepository | `p_tenant_id`, `p_template_id` | Generates unique sequential certificate number |

---

## Realtime Subscriptions

Active WebSocket channels using Supabase Realtime (Postgres CDC).

| Subscription | Repository | Channel Pattern | Events | Scope |
|-------------|-----------|-----------------|--------|-------|
| Section Attendance | AttendanceRepository | `public:attendance` | INSERT, UPDATE | Filtered by section_id |
| User Notifications | NotificationRepository | `public:notifications` | INSERT | Filtered by user_id |
| Thread Messages | MessageRepository | `public:messages` | INSERT | Filtered by thread_id |
| Announcements | MessageRepository, AnnouncementRepository | `announcements-{tenantId}` | INSERT, UPDATE, DELETE | Filtered by tenant_id |
| Assignments | AssignmentRepository | `public:assignments` | INSERT, UPDATE | Tenant-scoped |
| Communication Campaigns | CommunicationRepository | (campaigns channel) | INSERT, UPDATE | Tenant-scoped |

### Realtime via BaseRepository

`BaseRepository.subscribeToTable()` provides a generic subscription helper:

```dart
RealtimeChannel subscribeToTable(
  String table, {
  PostgresChangeEvent event = PostgresChangeEvent.all,
  String? filter,
  required void Function(PostgresChangePayload) callback,
})
```

Any repository can use this to subscribe to any table with optional filters.

**Known issue:** Channels are not consistently unsubscribed on widget dispose, leading to potential memory leaks and stale listeners.

---

## Server-Side Functions and Triggers

Defined in migrations (primarily `00007_analytics_views.sql`) but called indirectly via triggers, not RPCs.

| Function | Migration | Trigger/Usage |
|----------|-----------|---------------|
| `promote_students()` | 00007 | Manual invocation for year-end promotion |
| `refresh_analytics()` | 00007 | Called via RPC after marks changes |
| `generate_class_invoices()` | 00007 | Called via RPC from fee management |
| `get_student_current_enrollment()` | 00007 | Called via RPC from student views |
| `get_parent_children()` | 00007 | Called via RPC from parent dashboard |
| `get_teacher_classes()` | 00007 | Called via RPC from teacher views |
| `update_exam_statistics()` | 00007 | Trigger: AFTER INSERT/UPDATE on marks |
| `update_invoice_on_payment()` | 00007 | Trigger: AFTER INSERT on payments |
| `update_wallet_balance()` | 00007 | Trigger: AFTER INSERT on wallet_transactions |
| `update_book_availability()` | 00007 | Trigger: AFTER INSERT/UPDATE on book_issues |
| `compute_student_risk_score()` | 00010 | Called via RPC from AI insights |

---

## Tables Defined in Migrations but Not Referenced in Flutter

These tables exist in the database but have no corresponding `client.from()` call in the Flutter codebase. They may be used only by server-side functions, are planned for future use, or are from legacy/disabled migrations.

### From active migrations:

| Table | Migration | Likely Reason |
|-------|-----------|---------------|
| `calendar_events` (legacy) | 00005 | Superseded by `school_events` in 00026 |
| `alumni_directory_searches` | 00023 | Analytics table, possibly server-side only |

### From `20260209*` series (advanced features, partially implemented):

| Table | Migration |
|-------|-----------|
| `fee_payment_plans` | 20260209112624 |
| `payment_installments` | 20260209112624 |
| `fee_dunning_workflows` | 20260209112624 |
| `dunning_actions` | 20260209112624 |
| `fee_concessions` | 20260209112624 |
| `concession_applications` | 20260209112624 |
| `asset_categories` (legacy) | 20260209112625 |
| `assets` (legacy) | 20260209112625 |
| `asset_maintenance` (legacy) | 20260209112625 |
| `staff_attendance` (legacy) | 20260209112625 |
| `staff_leave_applications` | 20260209112625 |
| `payroll` (legacy) | 20260209112625 |
| `performance_reviews` | 20260209112625 |
| `alumni` (legacy) | 20260209112625 |
| `audit_logs` | 20260209112626 |
| `data_access_logs` | 20260209112626 |
| `login_audit` | 20260209112626 |
| `data_retention_policies` | 20260209112626 |
| `encryption_keys` | 20260209112626 |
| `data_subject_requests` | 20260209112626 |
| `behavior_incidents` (legacy dup) | 20260209112627 |
| `disciplinary_actions` | 20260209112627 |
| `counseling_sessions` | 20260209112627 |
| `student_conduct_grades` | 20260209112627 |
| `behavior_intervention_plans` | 20260209112627 |
| `payment_gateway_transactions` | 20260209112628 |
| `sms_logs` | 20260209112628 |
| `email_logs` | 20260209112628 |
| `push_notification_logs` | 20260209112628 |
| `webhook_logs` | 20260209112628 |
| `api_usage_logs` | 20260209112628 |
| `competency_frameworks` | 20260209112631 |
| `competencies` | 20260209112631 |
| `student_competency_assessments` | 20260209112631 |
| `learning_objectives` | 20260209112631 |
| `student_skills_portfolio` | 20260209112631 |
| `ml_models` | 20260209112622 |
| `student_performance_predictions` | 20260209112622 |
| `student_feature_snapshots` | 20260209112622 |
| `student_interventions` | 20260209112622 |
| `admission_inquiries` (legacy) | 20260209112623 |
| `admission_applications` (legacy) | 20260209112623 |
| `admission_entrance_tests` | 20260209112623 |
| `admission_interviews` (legacy) | 20260209112623 |
| `admission_campaigns` | 20260209112623 |

### From AI Tutoring (00027, provider exists but no direct table access yet):

| Table | Migration |
|-------|-----------|
| `ai_tutor_sessions` | 00027 |
| `ai_tutor_messages` | 00027 |
| `ai_learning_paths` | 00027 |
| `ai_practice_problems` | 00027 |
| `student_concept_mastery` | 00027 |
| `ai_tutor_feedback` | 00027 |

---

## Summary

| Metric | Count |
|--------|-------|
| Tables referenced in Flutter code | ~130 |
| Tables in migrations (total) | ~170 |
| Tables not yet referenced in Flutter | ~45 |
| RPC functions called | 13 |
| Realtime subscriptions | 6 active channels |
| Server-side trigger functions | 4 |
| Server-side utility functions | 7 |
