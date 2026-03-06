# CODEMAP - School Management SaaS

> Generated 2026-03-06 | v1.0.0+1
> Flutter 3.2+ / Dart / Supabase / Riverpod / GoRouter

---

## Table of Contents

1. [Project Structure Overview](#project-structure-overview)
2. [Feature Modules (48)](#feature-modules-48)
3. [Repositories (47)](#repositories-47)
4. [Providers (52)](#providers-52)
5. [Data Models (46)](#data-models-46)
6. [Core Services (9)](#core-services-9)
7. [Core Infrastructure](#core-infrastructure)
8. [Database Migrations (36)](#database-migrations-36)

---

## Project Structure Overview

```
lib/
  core/
    config/          # App config, Supabase config, environment
    providers/       # Global providers (supabase, AI, connectivity, payment)
    router/          # GoRouter with 75+ routes
    services/        # AI, sync, payment, storage services
    shell/           # Main shell (bottom nav)
    theme/           # Material 3 theme, colors
  data/
    models/          # 46 model files (some with Freezed codegen)
    repositories/    # 47 repositories extending BaseRepository
  features/          # 48 feature modules
    <module>/
      presentation/
        screens/     # Screen widgets
        widgets/     # Reusable feature widgets
      providers/     # Riverpod state management

supabase/
  migrations/        # 36 SQL migration files
```

---

## Feature Modules (48)

| # | Module | Path | Screens | Purpose |
|---|--------|------|---------|---------|
| 1 | **academic** | `lib/features/academic/` | 0 | Academic year/term/class configuration (provider-only) |
| 2 | **admin** | `lib/features/admin/` | 6 | Admin management screens: students, staff, academics, fees, exams, announcements |
| 3 | **admission** | `lib/features/admission/` | 8 | Admissions pipeline: inquiries, applications, interviews, settings |
| 4 | **ai_insights** | `lib/features/ai_insights/` | 13 | AI analytics: risk scores, attendance insights, trends, early warnings, study recs, report remarks, message composer, class intelligence |
| 5 | **ai_tutor** | `lib/features/ai_tutor/` | 0 | AI tutoring chat overlay (widget + provider only) |
| 6 | **alumni** | `lib/features/alumni/` | 9 | Alumni management: directory, profiles, events, donations, mentorship, success stories |
| 7 | **announcements** | `lib/features/announcements/` | 0 | Announcement state management (provider-only, screen in admin) |
| 8 | **assessments** | `lib/features/assessments/` | 3 | Quiz system: listing, taking quizzes, viewing results |
| 9 | **assignments** | `lib/features/assignments/` | 0 | Assignment state management (provider-only, screens in teacher/student) |
| 10 | **attendance** | `lib/features/attendance/` | 2 | Attendance overview and marking |
| 11 | **auth** | `lib/features/auth/` | 2 | Login and splash screens |
| 12 | **calendar** | `lib/features/calendar/` | 7 | Calendar & events: calendar view, event CRUD, academic calendar, holidays, attendees |
| 13 | **canteen** | `lib/features/canteen/` | 4 | Canteen ordering: menu, cart, wallet, order history |
| 14 | **certificate** | `lib/features/certificate/` | 6 | Certificate generation: templates, issuing, listing, preview, verification |
| 15 | **communication** | `lib/features/communication/` | 10 | Communication hub: campaigns, templates, SMS/email settings, auto rules, logs |
| 16 | **dashboard** | `lib/features/dashboard/` | 4 | Role-based dashboards: admin, teacher, student, parent |
| 17 | **discipline** | `lib/features/discipline/` | 9 | Behavior management: incidents, reporting, behavior plans, positive recognition, detentions, settings |
| 18 | **emergency** | `lib/features/emergency/` | 1 | Emergency alert dashboard |
| 19 | **exams** | `lib/features/exams/` | 2 | Exam management and marks entry |
| 20 | **fees** | `lib/features/fees/` | 1 | Fee overview (accountant view) |
| 21 | **gamification** | `lib/features/gamification/` | 2 | Achievements and leaderboard |
| 22 | **health** | `lib/features/health/` | 1 | Student health profiles |
| 23 | **hostel** | `lib/features/hostel/` | 3 | Hostel management: listing, detail, my room |
| 24 | **hr** | `lib/features/hr/` | 11 | HR & Payroll: departments, staff directory, contracts, payroll, salary slips, attendance, tax |
| 25 | **insights** | `lib/features/insights/` | 1 | Child insights for parents (charts, tips) |
| 26 | **inventory** | `lib/features/inventory/` | 12 | Inventory & assets: dashboard, lists, asset CRUD, assignments, scanning, maintenance, audits, purchases, categories |
| 27 | **leave** | `lib/features/leave/` | 1 | Leave management |
| 28 | **library** | `lib/features/library/` | 3 | Library: book catalog, book detail, my books |
| 29 | **lms** | `lib/features/lms/` | 8 | Learning Management: dashboard, catalog, course detail, builder, modules, progress, forums, certificates |
| 30 | **messaging** | `lib/features/messaging/` | 1 | In-app messaging (threads) |
| 31 | **notifications** | `lib/features/notifications/` | 1 | Notification center |
| 32 | **online_exam** | `lib/features/online_exam/` | 8 | Online exams: dashboard, builder, detail, take exam, results, analytics, grading, settings |
| 33 | **parent** | `lib/features/parent/` | 2 | Parent-specific: child results, fee payment |
| 34 | **ptm** | `lib/features/ptm/` | 2 | Parent-teacher meetings: scheduling, booking |
| 35 | **qr_scan** | `lib/features/qr_scan/` | 2 | QR scanning: scanner, student ID card |
| 36 | **question_paper** | `lib/features/question_paper/` | 3 | AI question paper generation: list, generator, detail |
| 37 | **report_card** | `lib/features/report_card/` | 10 | Report card system: dashboard, templates, grading scales, generation, listing, detail, preview, comments, skills |
| 38 | **reports** | `lib/features/reports/` | 2 | Legacy report card views |
| 39 | **resources** | `lib/features/resources/` | 1 | Study resource library |
| 40 | **student** | `lib/features/student/` | 5 | Student-role screens: assignments, attendance, results, fees, timetable |
| 41 | **students** | `lib/features/students/` | 2 | Student admin: list, detail |
| 42 | **substitution** | `lib/features/substitution/` | 2 | Teacher substitution: dashboard, report absence |
| 43 | **super_admin** | `lib/features/super_admin/` | 4 | Super admin: dashboard, tenant list, tenant detail, create tenant |
| 44 | **syllabus** | `lib/features/syllabus/` | 10 | Syllabus management: list, editor, topic CRUD, AI generation, coverage tracking, lesson plans, student view |
| 45 | **teacher** | `lib/features/teacher/` | 6 | Teacher-role screens: classes, students, analytics, assignments, timetable, class teacher dashboard |
| 46 | **timetable** | `lib/features/timetable/` | 0 | Timetable state management (provider-only, screens in teacher/student) |
| 47 | **transport** | `lib/features/transport/` | 3 | Transport: route listing, route detail, my transport |
| 48 | **visitor** | `lib/features/visitor/` | 6 | Visitor management: dashboard, check-in, check-out, log, pre-registration, detail |

**Total screens: 163**

---

## Repositories (47)

| Repository | File | Feature(s) Served | Key Tables |
|------------|------|-------------------|------------|
| `BaseRepository` | `base_repository.dart` | All | Provides Supabase client, tenant_id, realtime helpers |
| `AcademicRepository` | `academic_repository.dart` | academic, admin | academic_years, terms, classes, sections, subjects, class_subjects, teacher_assignments |
| `AdmissionRepository` | `admission_repository.dart` | admission | admission_inquiries_v2, admission_applications_v2, admission_interviews_v2, admission_documents_v2, admission_settings_v2 |
| `AlumniRepository` | `alumni_repository.dart` | alumni | alumni_profiles, alumni_events, alumni_event_registrations, alumni_donations, mentorship_programs, mentorship_requests, alumni_success_stories |
| `AnnouncementRepository` | `announcement_repository.dart` | announcements, admin | announcements |
| `AssessmentRepository` | `assessment_repository.dart` | assessments | quizzes, question_bank, quiz_questions, quiz_attempts |
| `AssignmentRepository` | `assignment_repository.dart` | assignments, teacher, student | assignments, submissions |
| `AttendanceRepository` | `attendance_repository.dart` | attendance | attendance, period_attendance |
| `AttendanceInsightsRepository` | `attendance_insights_repository.dart` | ai_insights | attendance (analytics queries) |
| `CalendarRepository` | `calendar_repository.dart` | calendar | school_events, event_attendees, event_reminders, academic_calendar_items, holiday_calendar |
| `CanteenRepository` | `canteen_repository.dart` | canteen | canteen_menu, canteen_orders, canteen_order_items, wallets, wallet_transactions |
| `CertificateRepository` | `certificate_repository.dart` | certificate | certificate_templates, issued_certificates, certificate_number_sequences |
| `CheckinRepository` | `checkin_repository.dart` | qr_scan | student_checkins |
| `ClassIntelligenceRepository` | `class_intelligence_repository.dart` | ai_insights | Multiple analytics tables |
| `CommunicationRepository` | `communication_repository.dart` | communication | communication_templates, communication_campaigns, campaign_recipients, communication_log, sms_gateway_config, email_config, auto_notification_rules |
| `DisciplineRepository` | `discipline_repository.dart` | discipline | behavior_categories, behavior_incidents, behavior_actions, behavior_plans, behavior_plan_reviews, positive_recognitions, detention_schedules, detention_assignments |
| `EarlyWarningRepository` | `early_warning_repository.dart` | ai_insights | early_warning_alerts, alert_rules |
| `EmergencyRepository` | `emergency_repository.dart` | emergency | emergency_alerts, emergency_responses, emergency_contacts |
| `ExamRepository` | `exam_repository.dart` | exams, admin | exams, exam_subjects, marks, grade_scales, grade_scale_items, exam_statistics |
| `FeeRepository` | `fee_repository.dart` | fees, admin, student, parent | fee_heads, fee_structures, invoices, invoice_items, payments, fee_reminder_log |
| `GamificationRepository` | `gamification_repository.dart` | gamification | achievements, student_achievements, student_points, point_transactions |
| `HealthRepository` | `health_repository.dart` | health | student_health_records, health_incidents |
| `HostelRepository` | `hostel_repository.dart` | hostel | hostels, hostel_rooms, room_allocations |
| `HrRepository` | `hr_repository.dart` | hr | departments, designations, staff_contracts, salary_structures, payroll_runs, payroll_items, salary_slips, staff_attendance_daily, tax_declarations, staff_documents |
| `InsightsRepository` | `insights_repository.dart` | insights | Multiple tables (aggregated student data) |
| `InventoryRepository` | `inventory_repository.dart` | inventory | inv_asset_categories, inv_assets, inv_asset_assignments, inv_asset_maintenance, inv_inventory_items, inv_inventory_transactions, inv_purchase_requests, inv_asset_audits |
| `LeaveRepository` | `leave_repository.dart` | leave | leave_applications, leave_balance |
| `LibraryRepository` | `library_repository.dart` | library | library_books, book_issues |
| `LmsRepository` | `lms_repository.dart` | lms | courses, course_modules, module_content, course_enrollments, content_progress, discussion_forums, forum_posts, course_certificates |
| `MessageRepository` | `message_repository.dart` | messaging | threads, thread_participants, messages |
| `NotificationRepository` | `notification_repository.dart` | notifications | notifications |
| `OnlineExamRepository` | `online_exam_repository.dart` | online_exam | online_exams, exam_sections, exam_questions, exam_attempts, exam_responses |
| `ParentDigestRepository` | `parent_digest_repository.dart` | ai_insights | parent_digests |
| `PtmRepository` | `ptm_repository.dart` | ptm | ptm_schedules, ptm_teacher_availability, ptm_appointments |
| `QuestionPaperRepository` | `question_paper_repository.dart` | question_paper | question_papers, question_paper_sections, question_paper_items |
| `ReportCardRepository` | `report_card_repository.dart` | reports | report_cards (legacy) |
| `ReportCardFullRepository` | `report_card_full_repository.dart` | report_card | grading_scales, report_card_templates, report_cards, report_card_comments, report_card_skills, report_card_activities |
| `ResourceRepository` | `resource_repository.dart` | resources | study_resources, resource_access |
| `RiskScoreRepository` | `risk_score_repository.dart` | ai_insights | student_risk_scores |
| `StudentRepository` | `student_repository.dart` | students, student | students, student_enrollments, student_parents, parents |
| `SubstitutionRepository` | `substitution_repository.dart` | substitution | teacher_absences, substitution_assignments |
| `SyllabusRepository` | `syllabus_repository.dart` | syllabus | syllabus_topics, topic_coverage, lesson_plans, topic_resource_links |
| `TenantRepository` | `tenant_repository.dart` | super_admin | tenants |
| `TimetableRepository` | `timetable_repository.dart` | timetable, teacher, student | timetable_slots, timetables |
| `TransportRepository` | `transport_repository.dart` | transport | transport_routes, transport_stops, student_transport |
| `TrendPredictionRepository` | `trend_prediction_repository.dart` | ai_insights | trend_predictions |
| `VisitorRepository` | `visitor_repository.dart` | visitor | visitors, visitor_logs, visitor_pre_registrations |

---

## Providers (52)

| Provider | File | Feature |
|----------|------|---------|
| `AuthProvider` | `auth/providers/auth_provider.dart` | auth |
| `AcademicProvider` | `academic/providers/academic_provider.dart` | academic |
| `AdmissionProvider` | `admission/providers/admission_provider.dart` | admission |
| `AlumniProvider` | `alumni/providers/alumni_provider.dart` | alumni |
| `AnnouncementProvider` | `announcements/providers/announcement_provider.dart` | announcements |
| `AssessmentProvider` | `assessments/providers/assessment_provider.dart` | assessments |
| `AssignmentsProvider` | `assignments/providers/assignments_provider.dart` | assignments |
| `AttendanceProvider` | `attendance/providers/attendance_provider.dart` | attendance |
| `AttendanceInsightsProvider` | `ai_insights/providers/attendance_insights_provider.dart` | ai_insights |
| `AiTutorProvider` | `ai_tutor/providers/ai_tutor_provider.dart` | ai_tutor |
| `CalendarProvider` | `calendar/providers/calendar_provider.dart` | calendar |
| `CanteenProvider` | `canteen/providers/canteen_provider.dart` | canteen |
| `CertificateProvider` | `certificate/providers/certificate_provider.dart` | certificate |
| `ClassIntelligenceProvider` | `ai_insights/providers/class_intelligence_provider.dart` | ai_insights |
| `CommunicationProvider` | `communication/providers/communication_provider.dart` | communication |
| `DisciplineProvider` | `discipline/providers/discipline_provider.dart` | discipline |
| `EarlyWarningProvider` | `ai_insights/providers/early_warning_provider.dart` | ai_insights |
| `EmergencyProvider` | `emergency/providers/emergency_provider.dart` | emergency |
| `ExamsProvider` | `exams/providers/exams_provider.dart` | exams |
| `FeesProvider` | `fees/providers/fees_provider.dart` | fees |
| `GamificationProvider` | `gamification/providers/gamification_provider.dart` | gamification |
| `HealthProvider` | `health/providers/health_provider.dart` | health |
| `HostelProvider` | `hostel/providers/hostel_provider.dart` | hostel |
| `HrProvider` | `hr/providers/hr_provider.dart` | hr |
| `InsightsProvider` | `insights/providers/insights_provider.dart` | insights |
| `InventoryProvider` | `inventory/providers/inventory_provider.dart` | inventory |
| `LeaveProvider` | `leave/providers/leave_provider.dart` | leave |
| `LibraryProvider` | `library/providers/library_provider.dart` | library |
| `LmsProvider` | `lms/providers/lms_provider.dart` | lms |
| `MessageDraftProvider` | `ai_insights/providers/message_draft_provider.dart` | ai_insights |
| `MessagesProvider` | `messaging/providers/messages_provider.dart` | messaging |
| `NotificationProvider` | `notifications/providers/notification_provider.dart` | notifications |
| `OnlineExamProvider` | `online_exam/providers/online_exam_provider.dart` | online_exam |
| `ParentDigestProvider` | `ai_insights/providers/parent_digest_provider.dart` | ai_insights |
| `PtmProvider` | `ptm/providers/ptm_provider.dart` | ptm |
| `QuestionPaperProvider` | `question_paper/providers/question_paper_provider.dart` | question_paper |
| `QrScanProvider` | `qr_scan/providers/qr_scan_provider.dart` | qr_scan |
| `ReportCardProvider` (legacy) | `reports/providers/report_card_provider.dart` | reports |
| `ReportCardProvider` (full) | `report_card/providers/report_card_provider.dart` | report_card |
| `ReportCommentaryProvider` | `ai_insights/providers/report_commentary_provider.dart` | ai_insights |
| `ResourceProvider` | `resources/providers/resource_provider.dart` | resources |
| `RiskScoreProvider` | `ai_insights/providers/risk_score_provider.dart` | ai_insights |
| `StudentsProvider` | `students/providers/students_provider.dart` | students |
| `StudyRecommendationProvider` | `ai_insights/providers/study_recommendation_provider.dart` | ai_insights |
| `SubstitutionProvider` | `substitution/providers/substitution_provider.dart` | substitution |
| `SyllabusProvider` | `syllabus/providers/syllabus_provider.dart` | syllabus |
| `SyllabusAiProvider` | `syllabus/providers/syllabus_ai_provider.dart` | syllabus |
| `TenantProvider` | `super_admin/providers/tenant_provider.dart` | super_admin |
| `TimetableProvider` | `timetable/providers/timetable_provider.dart` | timetable |
| `TransportProvider` | `transport/providers/transport_provider.dart` | transport |
| `TrendPredictionProvider` | `ai_insights/providers/trend_prediction_provider.dart` | ai_insights |
| `VisitorProvider` | `visitor/providers/visitor_provider.dart` | visitor |

**Core providers** (in `lib/core/providers/`):

| Provider | File | Purpose |
|----------|------|---------|
| `SupabaseProvider` | `supabase_provider.dart` | Supabase client singleton |
| `AiProviders` | `ai_providers.dart` | DeepSeek, OpenRouter, Claude Vision service providers |
| `ConnectivityProvider` | `connectivity_provider.dart` | Network connectivity state |
| `PaymentProviders` | `payment_providers.dart` | Payment gateway service |

---

## Data Models (46)

Models are in `lib/data/models/`. Some use Freezed code generation (marked with F).

| Model File | Classes | Freezed |
|------------|---------|---------|
| `academic.dart` | AcademicYear, Term, SchoolClass, Section, Subject, ClassSubject, TeacherAssignment | No |
| `achievement.dart` | Achievement, StudentAchievement, StudentPoints | No |
| `admission.dart` | AdmissionInquiry, AdmissionApplication, AdmissionInterview, AdmissionDocument, AdmissionSettings | No |
| `alumni.dart` | AlumniProfile, AlumniEvent, AlumniDonation, MentorshipProgram, MentorshipRequest, SuccessStory | No |
| `announcement.dart` | Announcement | Yes (F) |
| `assignment.dart` | Assignment, Submission | Yes (F) |
| `attendance.dart` | Attendance, PeriodAttendance | No |
| `attendance_insights.dart` | AttendanceInsights, DayPattern, ChronicAbsentee | No |
| `canteen.dart` | MenuItem, Wallet, WalletTransaction, CanteenOrder, OrderItem | No |
| `certificate.dart` | CertificateTemplate, IssuedCertificate | No |
| `class_intelligence.dart` | ClassIntelligence, SubjectComparison, ClassNarrative | No |
| `communication.dart` | CommunicationTemplate, CommunicationCampaign, CampaignRecipient, CommunicationLog, AutoNotificationRule | No |
| `discipline.dart` | BehaviorCategory, BehaviorIncident, BehaviorAction, BehaviorPlan, PositiveRecognition, DetentionSchedule | No |
| `early_warning_alert.dart` | EarlyWarningAlert, AlertRule | No |
| `emergency.dart` | EmergencyAlert, EmergencyResponse, EmergencyContact | No |
| `exam_statistics.dart` | ExamStatistics | Yes (F) |
| `fee_default_prediction.dart` | FeeDefaultPrediction | No |
| `health_record.dart` | HealthRecord, HealthIncident | No |
| `hostel.dart` | Hostel, HostelRoom, RoomAllocation | No |
| `hr_payroll.dart` | Department, Designation, StaffContract, SalaryStructure, PayrollRun, PayrollItem, SalarySlip, TaxDeclaration | No |
| `inventory.dart` | AssetCategory, Asset, AssetAssignment, AssetMaintenance, InventoryItem, InventoryTransaction, PurchaseRequest, AssetAudit | No |
| `invoice.dart` | Invoice, InvoiceItem, Payment, FeeHead, FeeStructure | Yes (F) |
| `leave.dart` | LeaveApplication, LeaveBalance | No |
| `lesson_plan.dart` | LessonPlan | No |
| `library.dart` | Book, BookIssue | No |
| `lms.dart` | Course, CourseModule, ModuleContent, CourseEnrollment, ContentProgress, DiscussionForum, ForumPost, CourseCertificate | No |
| `message.dart` | Message, Thread, ThreadParticipant | Yes (F) |
| `message_template.dart` | MessageTemplate | No |
| `notification.dart` | AppNotification | No |
| `online_exam.dart` | OnlineExam, ExamSection, ExamQuestion, ExamAttempt, ExamResponse | No |
| `parent_digest.dart` | ParentDigest | No |
| `ptm.dart` | PtmSchedule, PtmTeacherAvailability, PtmAppointment | No |
| `question_paper.dart` | QuestionPaper, QuestionPaperSection, QuestionPaperItem | No |
| `quiz.dart` | Quiz, QuizQuestion, QuizAttempt | No |
| `report_card.dart` | ReportCard (legacy) | No |
| `report_card_full.dart` | GradingScale, ReportCardTemplate, ReportCardFull, ReportCardComment, ReportCardSkill, ReportCardActivity | No |
| `report_commentary.dart` | ReportCommentary | No |
| `resource.dart` | StudyResource | No |
| `school_event.dart` | SchoolEvent, EventAttendee, EventReminder, AcademicCalendarItem, Holiday | No |
| `student.dart` | Student, StudentEnrollment, Parent, StudentParent | No |
| `student_checkin.dart` | StudentCheckin | No |
| `student_insights.dart` | StudentInsights | No |
| `student_risk_score.dart` | StudentRiskScore | No |
| `study_recommendation.dart` | StudyRecommendation | No |
| `substitution.dart` | TeacherAbsence, SubstitutionAssignment | No |
| `syllabus_topic.dart` | SyllabusTopic, TopicCoverage | No |
| `tenant.dart` | Tenant | No |
| `timetable.dart` | Timetable, TimetableSlot | Yes (F) |
| `transport.dart` | TransportRoute, TransportStop, StudentTransport | No |
| `trend_prediction.dart` | TrendPrediction | No |
| `user.dart` | AppUser, UserRole | No |
| `visitor.dart` | Visitor, VisitorLog, VisitorPreRegistration | No |

---

## Core Services (9)

| Service | File | Purpose |
|---------|------|---------|
| `AiTextGenerator` | `lib/core/services/ai_text_generator.dart` | Text generation via AI (remarks, recommendations, syllabi) |
| `AiImageGenerator` | `lib/core/services/ai_image_generator.dart` | AI-powered image generation |
| `ClaudeVisionService` | `lib/core/services/claude_vision_service.dart` | Claude API vision/multimodal capabilities |
| `DeepSeekService` | `lib/core/services/deepseek_service.dart` | DeepSeek LLM integration |
| `LocalStorageService` | `lib/core/services/local_storage_service.dart` | Isar/local storage for offline data |
| `OfflineSyncService` | `lib/core/services/offline_sync_service.dart` | Offline-first sync logic (incomplete) |
| `OpenRouterImageService` | `lib/core/services/openrouter_image_service.dart` | OpenRouter API for image models |
| `PaymentGatewayService` | `lib/core/services/payment_gateway_service.dart` | Payment processing (stub, no live gateway) |
| `ScreenCaptureService` | `lib/core/services/screen_capture_service.dart` | Screen capture/screenshot utility |

---

## Core Infrastructure

| Component | File | Purpose |
|-----------|------|---------|
| `AppConfig` | `lib/core/config/app_config.dart` | App-wide configuration constants |
| `AppEnvironment` | `lib/core/config/app_environment.dart` | Environment (dev/staging/prod) settings |
| `SupabaseConfig` | `lib/core/config/supabase_config.dart` | Supabase URL and anon key |
| `AppRouter` | `lib/core/router/app_router.dart` | GoRouter with 75+ routes, role-based redirect |
| `MainShell` | `lib/core/shell/main_shell.dart` | ShellRoute with persistent bottom navigation |
| `AppTheme` | `lib/core/theme/app_theme.dart` | Material 3 theme with Poppins font |
| `AppColors` | `lib/core/theme/app_colors.dart` | Color palette |
| Entry Point | `lib/main.dart` | App bootstrap, Supabase init, ProviderScope |

---

## Database Migrations (36)

Listed in execution order. All tables use `tenant_id` with RLS policies.

| # | File | Purpose | Tables Created |
|---|------|---------|----------------|
| 1 | `00001_initial_schema.sql` | Core schema, enums, base tables | `tenants`, `users`, `user_roles`, `academic_years`, `terms`, `classes`, `sections`, `subjects`, `class_subjects`, `teacher_assignments`, `students`, `student_enrollments`, `parents`, `student_parents`, `staff` |
| 2 | `00002_timetable_attendance.sql` | Timetable and attendance | `timetable_slots`, `timetables`, `attendance`, `period_attendance` |
| 3 | `00003_exams_assignments.sql` | Exams, grading, assignments | `exams`, `exam_subjects`, `marks`, `grade_scales`, `grade_scale_items`, `exam_statistics`, `assignments`, `submissions` |
| 4 | `00004_communication_fees.sql` | Messaging and fee billing | `threads`, `thread_participants`, `messages`, `announcements`, `fee_heads`, `fee_structures`, `invoices`, `invoice_items`, `payments` |
| 5 | `00005_canteen_library_transport_hostel.sql` | Campus services | `canteen_menu`, `wallets`, `wallet_transactions`, `canteen_orders`, `canteen_order_items`, `library_books`, `book_issues`, `transport_routes`, `transport_stops`, `student_transport`, `hostels`, `hostel_rooms`, `room_allocations`, `calendar_events` |
| 6 | `00006_rls_policies.sql` | Row Level Security policies | (policies only) |
| 7 | `00007_analytics_views.sql` | Analytics views and server-side functions | Functions: `promote_students`, `refresh_analytics`, `generate_class_invoices`, `get_student_current_enrollment`, `get_parent_children`, `get_teacher_classes`, `update_exam_statistics`, `update_invoice_on_payment`, `update_wallet_balance`, `update_book_availability` |
| 8 | `00008_new_features.sql` | Extended features batch | `notifications`, `student_health_records`, `health_incidents`, `achievements`, `student_achievements`, `student_points`, `point_transactions`, `quizzes`, `question_bank`, `quiz_questions`, `quiz_attempts`, `ptm_schedules`, `ptm_teacher_availability`, `ptm_appointments`, `emergency_alerts`, `emergency_responses`, `emergency_contacts`, `leave_applications`, `leave_balance`, `study_resources`, `resource_access` |
| 9 | `00009_qr_scan_checkin.sql` | QR check-in tracking | `student_checkins` |
| 10 | `00010_ai_phase1.sql` | AI analytics phase 1 | `student_risk_scores`, `parent_digests`, `trend_predictions` + `compute_student_risk_score()` function |
| 11 | `00011_syllabus_topics.sql` | Syllabus management | `syllabus_topics`, `topic_coverage`, `lesson_plans`, `topic_resource_links` |
| 12 | `00012_question_papers.sql` | Question paper generation | `question_papers`, `question_paper_sections`, `question_paper_items` |
| 13 | `00013_fee_default_prediction.sql` | Fee default prediction | `fee_reminder_log` |
| 14 | `00014_substitution_ai.sql` | Teacher substitution | `teacher_absences`, `substitution_assignments` |
| 15 | `00015_admissions.sql` | Admissions pipeline v2 | `admission_inquiries_v2`, `admission_applications_v2`, `admission_interviews_v2`, `admission_documents_v2`, `admission_settings_v2` |
| 16 | `00016_discipline.sql` | Behavior and discipline | `behavior_categories`, `behavior_incidents`, `behavior_actions`, `behavior_plans`, `behavior_plan_reviews`, `positive_recognitions`, `detention_schedules`, `detention_assignments` |
| 17 | `00017_communication_hub.sql` | Communication platform | `communication_templates`, `communication_campaigns`, `campaign_recipients`, `sms_gateway_config`, `email_config`, `communication_log`, `auto_notification_rules` |
| 18 | `00018_report_cards.sql` | Report card system | `grading_scales`, `report_card_templates`, `report_cards`, `report_card_comments`, `report_card_skills`, `report_card_activities` |
| 19 | `00019_hr_payroll.sql` | HR and payroll | `departments`, `designations`, `staff_contracts`, `salary_structures`, `payroll_runs`, `payroll_items`, `salary_slips`, `staff_attendance_daily`, `tax_declarations`, `staff_documents` |
| 20 | `00020_inventory_assets.sql` | Inventory and asset tracking | `inv_asset_categories`, `inv_assets`, `inv_asset_assignments`, `inv_asset_maintenance`, `inv_inventory_items`, `inv_inventory_transactions`, `inv_purchase_requests`, `inv_asset_audits` |
| 21 | `00021_lms.sql` | Learning management system | `courses`, `course_modules`, `module_content`, `course_enrollments`, `content_progress`, `discussion_forums`, `forum_posts`, `course_certificates` |
| 22 | `00022_online_exams.sql` | Online examination system | `online_exams`, `exam_sections`, `exam_questions`, `exam_attempts`, `exam_responses` |
| 23 | `00023_alumni.sql` | Alumni network | `alumni_profiles`, `alumni_events`, `alumni_event_registrations`, `alumni_donations`, `mentorship_programs`, `mentorship_requests`, `alumni_success_stories`, `alumni_directory_searches` |
| 24 | `00024_visitor_management.sql` | Visitor management | `visitors`, `visitor_logs`, `visitor_pre_registrations` |
| 25 | `00025_certificates.sql` | Certificate generation | `certificate_templates`, `issued_certificates`, `certificate_number_sequences` |
| 26 | `00026_calendar_events.sql` | Enhanced calendar | `school_events`, `event_attendees`, `event_reminders`, `academic_calendar_items`, `holiday_calendar` |
| 27 | `00027_ai_tutoring.sql` | AI tutoring system | `ai_tutor_sessions`, `ai_tutor_messages`, `ai_learning_paths`, `ai_practice_problems`, `student_concept_mastery`, `ai_tutor_feedback` |
| 28 | `20240101_update_students_schema.sql` | Student schema updates | (ALTER TABLE only) |
| 29 | `20260209112622_ai_predictive_analytics.sql` | AI predictive analytics | `ml_models`, `student_performance_predictions`, `student_feature_snapshots`, `student_interventions`, `early_warning_alerts`, `alert_rules` |
| 30 | `20260209112623_admissions_pipeline.sql` | Extended admissions | `admission_inquiries`, `admission_applications`, `admission_entrance_tests`, `admission_interviews`, `admission_campaigns` |
| 31 | `20260209112624_advanced_fee_management.sql` | Advanced fees | `fee_payment_plans`, `payment_installments`, `fee_dunning_workflows`, `dunning_actions`, `fee_concessions`, `concession_applications` |
| 32 | `20260209112625_asset_hr_alumni.sql` | Asset/HR/Alumni (legacy) | `asset_categories`, `assets`, `asset_maintenance`, `staff_attendance`, `staff_leave_applications`, `payroll`, `performance_reviews`, `alumni`, `alumni_events` (legacy), `alumni_event_registrations` (legacy), `alumni_donations` (legacy) |
| 33 | `20260209112626_audit_security.sql` | Audit and security | `audit_logs`, `data_access_logs`, `login_audit`, `data_retention_policies`, `encryption_keys`, `data_subject_requests` |
| 34 | `20260209112627_behavioral_tracking.sql` | Behavioral tracking (legacy) | `behavior_incidents`, `disciplinary_actions`, `counseling_sessions`, `student_conduct_grades`, `behavior_intervention_plans` |
| 35 | `20260209112628_integrations.sql` | External integrations | `payment_gateway_transactions`, `sms_logs`, `email_logs`, `push_notification_logs`, `webhook_logs`, `api_usage_logs` |
| 36 | `20260209112631_skills_competencies.sql` | Skills framework | `competency_frameworks`, `competencies`, `student_competency_assessments`, `learning_objectives`, `student_skills_portfolio` |

**Note:** `20260209112629_performance_optimization.sql` is disabled (`.disabled` extension) and contains partition tables and archival logic.

---

## Summary Counts

| Component | Count |
|-----------|-------|
| Feature modules | 48 |
| Screens | 163 |
| Repositories | 47 |
| Providers | 52 (+ 4 core) |
| Data models (files) | 46 (excluding .freezed/.g.dart) |
| Core services | 9 |
| DB migrations | 36 (+ 1 disabled) |
| DB tables | ~170 |
| Routes | 75+ |
| User roles | 12 |
