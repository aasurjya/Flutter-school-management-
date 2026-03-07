import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../providers/supabase_provider.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/parent_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/student_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/teacher_dashboard_screen.dart';
import '../../features/students/presentation/screens/students_list_screen.dart';
import '../../features/students/presentation/screens/student_detail_screen.dart';
import '../../features/attendance/presentation/screens/attendance_screen.dart';
import '../../features/attendance/presentation/screens/mark_attendance_screen.dart';
import '../../features/exams/presentation/screens/exams_screen.dart';
import '../../features/exams/presentation/screens/marks_entry_screen.dart';
import '../../features/fees/presentation/screens/fees_screen.dart';
import '../../features/messaging/presentation/screens/messages_screen.dart';
import '../../features/student/presentation/screens/student_results_screen.dart';
import '../../features/student/presentation/screens/student_assignments_screen.dart';
import '../../features/teacher/presentation/screens/class_analytics_screen.dart';
import '../../features/admin/presentation/screens/student_management_screen.dart';
import '../../features/admin/presentation/screens/staff_management_screen.dart';
import '../../features/admin/presentation/screens/academic_config_screen.dart';
import '../../features/student/presentation/screens/student_timetable_screen.dart';
import '../../features/student/presentation/screens/student_attendance_screen.dart';
import '../../features/student/presentation/screens/student_fees_screen.dart';
import '../../features/parent/presentation/screens/child_results_screen.dart';
import '../../features/teacher/presentation/screens/assignments_management_screen.dart';
import '../../features/teacher/presentation/screens/my_classes_screen.dart';
import '../../features/teacher/presentation/screens/class_students_screen.dart';
import '../../features/parent/presentation/screens/fee_payment_screen.dart';
import '../../features/admin/presentation/screens/exam_management_screen.dart';
import '../../features/admin/presentation/screens/fee_management_screen.dart';
import '../../features/admin/presentation/screens/announcements_screen.dart';
import '../../features/teacher/presentation/screens/teacher_timetable_screen.dart';
import '../../features/super_admin/presentation/screens/super_admin_dashboard_screen.dart';
import '../../features/super_admin/presentation/screens/tenants_list_screen.dart';
import '../../features/super_admin/presentation/screens/create_tenant_screen.dart';
import '../../features/super_admin/presentation/screens/tenant_detail_screen.dart';
import '../../features/qr_scan/presentation/screens/qr_scanner_screen.dart';
import '../../features/qr_scan/presentation/screens/student_id_card_screen.dart';
import '../../features/teacher/presentation/screens/class_teacher_dashboard_screen.dart';

// New feature imports
import '../../features/canteen/presentation/screens/canteen_menu_screen.dart';
import '../../features/canteen/presentation/screens/cart_screen.dart';
import '../../features/canteen/presentation/screens/wallet_screen.dart';
import '../../features/canteen/presentation/screens/order_history_screen.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/library/presentation/screens/book_detail_screen.dart';
import '../../features/library/presentation/screens/my_books_screen.dart';
import '../../features/transport/presentation/screens/transport_screen.dart';
import '../../features/transport/presentation/screens/route_detail_screen.dart';
import '../../features/transport/presentation/screens/my_transport_screen.dart';
import '../../features/hostel/presentation/screens/hostel_screen.dart';
import '../../features/hostel/presentation/screens/hostel_detail_screen.dart';
import '../../features/hostel/presentation/screens/my_hostel_screen.dart';
import '../../features/notifications/presentation/screens/notification_center_screen.dart';
import '../../features/health/presentation/screens/student_health_profile_screen.dart';
import '../../features/gamification/presentation/screens/achievements_screen.dart';
import '../../features/gamification/presentation/screens/leaderboard_screen.dart';
import '../../features/insights/presentation/screens/child_insights_screen.dart';
import '../../features/assessments/presentation/screens/quizzes_screen.dart';
import '../../features/assessments/presentation/screens/take_quiz_screen.dart';
import '../../features/assessments/presentation/screens/quiz_result_screen.dart';
import '../../features/ptm/presentation/screens/ptm_scheduler_screen.dart';
import '../../features/ptm/presentation/screens/book_appointment_screen.dart';
import '../../features/emergency/presentation/screens/emergency_dashboard_screen.dart';
import '../../features/leave/presentation/screens/leave_management_screen.dart';
import '../../features/resources/presentation/screens/resource_library_screen.dart';
import '../../features/reports/presentation/screens/report_cards_screen.dart';
import '../../features/reports/presentation/screens/report_card_view_screen.dart';

// Report Card Generator (full module)
import '../../features/report_card/presentation/screens/report_card_dashboard_screen.dart';
import '../../features/report_card/presentation/screens/template_list_screen.dart';
import '../../features/report_card/presentation/screens/template_editor_screen.dart';
import '../../features/report_card/presentation/screens/grading_scale_screen.dart';
import '../../features/report_card/presentation/screens/generate_report_cards_screen.dart';
import '../../features/report_card/presentation/screens/report_card_list_screen.dart';
import '../../features/report_card/presentation/screens/report_card_detail_screen.dart';
import '../../features/report_card/presentation/screens/report_card_preview_screen.dart';
import '../../features/report_card/presentation/screens/add_comments_screen.dart';
import '../../features/report_card/presentation/screens/skills_rating_screen.dart';
import '../../features/ai_insights/presentation/screens/risk_dashboard_screen.dart';
import '../../features/ai_insights/presentation/screens/student_risk_detail_screen.dart';
import '../../features/ai_insights/presentation/screens/attendance_insights_screen.dart';
import '../../features/ai_insights/presentation/screens/trend_dashboard_screen.dart';
import '../../features/ai_insights/presentation/screens/parent_digest_list_screen.dart';
import '../../features/ai_insights/presentation/screens/parent_digest_detail_screen.dart';
import '../../features/ai_insights/presentation/screens/early_warning_dashboard_screen.dart';
import '../../features/ai_insights/presentation/screens/alert_detail_screen.dart';
import '../../features/ai_insights/presentation/screens/alert_rules_config_screen.dart';
import '../../features/ai_insights/presentation/screens/study_recommendations_screen.dart';
import '../../features/ai_insights/presentation/screens/generate_remarks_screen.dart';
import '../../features/ai_insights/presentation/screens/ai_message_composer_screen.dart';
import '../../features/ai_insights/presentation/screens/class_intelligence_screen.dart';
import '../../features/syllabus/presentation/screens/syllabus_list_screen.dart';
import '../../features/syllabus/presentation/screens/syllabus_editor_screen.dart';
import '../../features/syllabus/presentation/screens/topic_detail_screen.dart';
import '../../features/syllabus/presentation/screens/topic_form_screen.dart';
import '../../features/syllabus/presentation/screens/ai_syllabus_generator_screen.dart';
import '../../features/syllabus/presentation/screens/coverage_dashboard_screen.dart';
import '../../features/syllabus/presentation/screens/section_coverage_screen.dart';
import '../../features/syllabus/presentation/screens/lesson_plan_screen.dart';
import '../../features/syllabus/presentation/screens/lesson_plan_form_screen.dart';
import '../../features/syllabus/presentation/screens/student_syllabus_screen.dart';
import '../../features/question_paper/presentation/screens/question_paper_list_screen.dart';
import '../../features/question_paper/presentation/screens/question_paper_generator_screen.dart';
import '../../features/question_paper/presentation/screens/question_paper_detail_screen.dart';
import '../../features/substitution/presentation/screens/substitution_dashboard_screen.dart';
import '../../features/substitution/presentation/screens/report_absence_screen.dart';
import '../../features/admission/presentation/screens/admission_dashboard_screen.dart';
import '../../features/admission/presentation/screens/inquiry_list_screen.dart';
import '../../features/admission/presentation/screens/inquiry_form_screen.dart';
import '../../features/admission/presentation/screens/application_list_screen.dart';
import '../../features/admission/presentation/screens/application_detail_screen.dart';
import '../../features/admission/presentation/screens/application_form_screen.dart';
import '../../features/admission/presentation/screens/interview_schedule_screen.dart';
import '../../features/admission/presentation/screens/admission_settings_screen.dart';
import '../../features/discipline/presentation/screens/discipline_dashboard_screen.dart';
import '../../features/discipline/presentation/screens/incident_list_screen.dart';
import '../../features/discipline/presentation/screens/report_incident_screen.dart';
import '../../features/discipline/presentation/screens/incident_detail_screen.dart';
import '../../features/discipline/presentation/screens/behavior_plan_screen.dart';
import '../../features/discipline/presentation/screens/positive_recognition_screen.dart';
import '../../features/discipline/presentation/screens/student_behavior_profile_screen.dart';
import '../../features/discipline/presentation/screens/detention_management_screen.dart';
import '../../features/discipline/presentation/screens/behavior_settings_screen.dart';
import '../../features/hr/presentation/screens/hr_dashboard_screen.dart';
import '../../features/hr/presentation/screens/department_list_screen.dart';
import '../../features/hr/presentation/screens/department_detail_screen.dart';
import '../../features/hr/presentation/screens/staff_directory_screen.dart';
import '../../features/hr/presentation/screens/staff_profile_screen.dart';
import '../../features/hr/presentation/screens/contract_management_screen.dart';
import '../../features/hr/presentation/screens/payroll_dashboard_screen.dart';
import '../../features/hr/presentation/screens/payroll_run_screen.dart';
import '../../features/hr/presentation/screens/salary_slip_screen.dart';
import '../../features/hr/presentation/screens/staff_attendance_screen.dart';
import '../../features/hr/presentation/screens/tax_declaration_screen.dart';
import '../../features/lms/presentation/screens/lms_dashboard_screen.dart';
import '../../features/lms/presentation/screens/course_catalog_screen.dart';
import '../../features/lms/presentation/screens/course_detail_screen.dart';
import '../../features/lms/presentation/screens/course_builder_screen.dart';
import '../../features/lms/presentation/screens/module_content_screen.dart';
import '../../features/lms/presentation/screens/course_progress_screen.dart';
import '../../features/lms/presentation/screens/discussion_forum_screen.dart';
import '../../features/lms/presentation/screens/certificate_screen.dart';
// Calendar & Events
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/calendar/presentation/screens/event_list_screen.dart';
import '../../features/calendar/presentation/screens/event_detail_screen.dart' as cal;
import '../../features/calendar/presentation/screens/create_event_screen.dart';
import '../../features/calendar/presentation/screens/academic_calendar_screen.dart';
import '../../features/calendar/presentation/screens/holiday_list_screen.dart';
import '../../features/calendar/presentation/screens/event_attendees_screen.dart';
import '../../data/models/school_event.dart';
import '../../data/models/communication.dart';

import '../../features/alumni/presentation/screens/alumni_dashboard_screen.dart';
import '../../features/alumni/presentation/screens/alumni_directory_screen.dart';
import '../../features/alumni/presentation/screens/alumni_profile_screen.dart';
import '../../features/alumni/presentation/screens/alumni_events_screen.dart';
import '../../features/alumni/presentation/screens/event_detail_screen.dart';
import '../../features/alumni/presentation/screens/donations_screen.dart';
import '../../features/alumni/presentation/screens/mentorship_screen.dart';
import '../../features/alumni/presentation/screens/success_stories_screen.dart';
import '../../features/alumni/presentation/screens/alumni_registration_screen.dart';
// Visitor Management
import '../../features/visitor/presentation/screens/visitor_dashboard_screen.dart';
import '../../features/visitor/presentation/screens/visitor_check_in_screen.dart';
import '../../features/visitor/presentation/screens/visitor_check_out_screen.dart';
import '../../features/visitor/presentation/screens/visitor_log_screen.dart';
import '../../features/visitor/presentation/screens/pre_registration_screen.dart';
import '../../features/visitor/presentation/screens/visitor_detail_screen.dart';
// Certificate Generator
import '../../features/certificate/presentation/screens/certificate_dashboard_screen.dart';
import '../../features/certificate/presentation/screens/certificate_template_screen.dart';
import '../../features/certificate/presentation/screens/issue_certificate_screen.dart';
import '../../features/certificate/presentation/screens/certificate_list_screen.dart';
import '../../features/certificate/presentation/screens/certificate_preview_screen.dart';
import '../../features/certificate/presentation/screens/verify_certificate_screen.dart';
// Online Exam
import '../../features/online_exam/presentation/screens/exam_dashboard_screen.dart';
import '../../features/online_exam/presentation/screens/exam_builder_screen.dart';
import '../../features/online_exam/presentation/screens/exam_detail_screen.dart';
import '../../features/online_exam/presentation/screens/take_exam_screen.dart';
import '../../features/online_exam/presentation/screens/exam_result_screen.dart';
import '../../features/online_exam/presentation/screens/exam_analytics_screen.dart';
import '../../features/online_exam/presentation/screens/grade_exam_screen.dart';
import '../../features/online_exam/presentation/screens/exam_settings_screen.dart';
import '../../features/bus_tracking/presentation/screens/bus_tracking_dashboard_screen.dart';
import '../../features/bus_tracking/presentation/screens/live_map_screen.dart';
import '../../features/bus_tracking/presentation/screens/vehicle_detail_screen.dart';
import '../../features/bus_tracking/presentation/screens/vehicle_form_screen.dart';
import '../../features/bus_tracking/presentation/screens/geofence_list_screen.dart';
import '../../features/bus_tracking/presentation/screens/geofence_alerts_screen.dart';
import '../../features/bus_tracking/presentation/screens/driver_panel_screen.dart';
import '../../features/bus_tracking/presentation/screens/trip_history_screen.dart';
// Communication Hub
import '../../features/communication/presentation/screens/communication_dashboard_screen.dart';
import '../../features/communication/presentation/screens/template_list_screen.dart' as comm;
import '../../features/communication/presentation/screens/template_editor_screen.dart' as comm_editor;
import '../../features/communication/presentation/screens/campaign_create_screen.dart';
import '../../features/communication/presentation/screens/campaign_list_screen.dart';
import '../../features/communication/presentation/screens/campaign_detail_screen.dart';
import '../../features/communication/presentation/screens/auto_rules_screen.dart';
import '../../features/communication/presentation/screens/sms_settings_screen.dart';
import '../../features/communication/presentation/screens/email_settings_screen.dart';
import '../../features/communication/presentation/screens/communication_log_screen.dart';
// Inventory & Assets
import '../../features/inventory/presentation/screens/inventory_dashboard_screen.dart';
import '../../features/inventory/presentation/screens/asset_list_screen.dart';
import '../../features/inventory/presentation/screens/asset_detail_screen.dart';
import '../../features/inventory/presentation/screens/asset_form_screen.dart';
import '../../features/inventory/presentation/screens/asset_scan_screen.dart';
import '../../features/inventory/presentation/screens/asset_assignment_screen.dart';
import '../../features/inventory/presentation/screens/inventory_list_screen.dart';
import '../../features/inventory/presentation/screens/inventory_transaction_screen.dart';
import '../../features/inventory/presentation/screens/purchase_request_screen.dart';
import '../../features/inventory/presentation/screens/maintenance_screen.dart';
import '../../features/inventory/presentation/screens/audit_screen.dart';
import '../../features/inventory/presentation/screens/category_management_screen.dart';
// Homework Tracker
import '../../features/homework/presentation/screens/homework_dashboard_screen.dart';
// Notice Board
import '../../features/notice_board/presentation/screens/notice_board_screen.dart';
import '../../features/notice_board/presentation/screens/notice_detail_screen.dart';
import '../../features/notice_board/presentation/screens/notice_form_screen.dart';
import '../../data/models/notice_board.dart' as notice;
// Student Portfolio
import '../../features/portfolio/presentation/screens/student_portfolio_screen.dart';
import '../../features/portfolio/presentation/screens/portfolio_work_screen.dart';
import '../../features/student_portfolio/presentation/screens/digital_id_screen.dart';
import '../../features/homework/presentation/screens/homework_create_screen.dart';
import '../../features/homework/presentation/screens/homework_detail_screen.dart';
import '../../features/homework/presentation/screens/homework_submit_screen.dart';
import '../../features/homework/presentation/screens/homework_submissions_screen.dart';
import '../../features/homework/presentation/screens/homework_calendar_screen.dart';
import '../shell/main_shell.dart';

/// Route names
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String selectTenant = '/select-tenant';

  // Dashboard routes by role
  static const String adminDashboard = '/admin';
  static const String teacherDashboard = '/teacher';
  static const String studentDashboard = '/student';
  static const String parentDashboard = '/parent';

  // Feature routes
  static const String students = '/students';
  static const String studentDetail = '/students/:id';
  static const String attendance = '/attendance';
  static const String markAttendance = '/attendance/mark/:sectionId';
  static const String exams = '/exams';
  static const String marksEntry = '/exams/:examId/marks';
  static const String fees = '/fees';
  static const String messages = '/messages';
  static const String assignments = '/assignments';
  static const String timetable = '/timetable';
  static const String calendar = '/calendar';
  static const String calendarEvents = '/calendar/events';
  static const String calendarEventDetail = '/calendar/event/:eventId';
  static const String calendarCreateEvent = '/calendar/create';
  static const String calendarAcademic = '/calendar/academic';
  static const String calendarHolidays = '/calendar/holidays';
  static const String calendarEventAttendees = '/calendar/event/:eventId/attendees';
  static const String settings = '/settings';
  static const String profile = '/profile';

  // Canteen routes
  static const String canteen = '/canteen';
  static const String canteenCart = '/canteen/cart';
  static const String canteenWallet = '/canteen/wallet';
  static const String canteenOrders = '/canteen/orders';

  // Library routes
  static const String library = '/library';
  static const String libraryBookDetail = '/library/book/:bookId';
  static const String libraryMyBooks = '/library/my-books';

  // Transport routes
  static const String transport = '/transport';
  static const String transportRouteDetail = '/transport/route/:routeId';
  static const String transportMyRoute = '/transport/my-route';

  // Hostel routes
  static const String hostel = '/hostel';
  static const String hostelDetail = '/hostel/:hostelId';
  static const String hostelMyRoom = '/hostel/my-room';

  // Notifications
  static const String notifications = '/notifications';

  // Health routes
  static const String healthProfile = '/health/:studentId';
  static const String healthEdit = '/health/edit/:studentId';
  static const String healthIncidents = '/health/incidents/:studentId';

  // Gamification routes
  static const String achievements = '/gamification/achievements/:studentId';
  static const String leaderboard = '/gamification/leaderboard';

  // Insights routes
  static const String childInsights = '/insights/:studentId';

  // Assessment routes
  static const String assessments = '/assessments';
  static const String assessmentDetail = '/assessments/:quizId';
  static const String createAssessment = '/assessments/create';
  static const String takeQuiz = '/assessments/take/:quizId';
  static const String quizResult = '/assessments/result/:attemptId';
  static const String quizReview = '/assessments/review/:attemptId';

  // PTM routes
  static const String ptm = '/ptm';
  static const String ptmDetail = '/ptm/:scheduleId';
  static const String ptmBook = '/ptm/:scheduleId/book';

  // Emergency routes
  static const String emergency = '/emergency';

  // Leave routes
  static const String leave = '/leave';

  // Resource Library routes
  static const String resources = '/resources';
  static const String resourceDetail = '/resources/:resourceId';

  // Report Card routes (legacy)
  static const String reports = '/reports';
  static const String reportDetail = '/reports/:reportId';

  // Report Card Generator (full module)
  static const String reportCardDashboard = '/report-cards';
  static const String reportCardTemplates = '/report-cards/templates';
  static const String reportCardTemplateNew = '/report-cards/templates/new';
  static const String reportCardTemplateEdit = '/report-cards/templates/:templateId';
  static const String reportCardGradingScales = '/report-cards/grading-scales';
  static const String reportCardGenerate = '/report-cards/generate';
  static const String reportCardList = '/report-cards/list';
  static const String reportCardDetail = '/report-cards/detail/:id';
  static const String reportCardPreview = '/report-cards/preview/:id';
  static const String reportCardComments = '/report-cards/comments/:id';
  static const String reportCardSkills = '/report-cards/skills/:id';

  // Student portal routes
  static const String studentResults = '/student/results';
  static const String studentAssignments = '/student/assignments';

  // Teacher portal routes
  static const String classAnalytics = '/teacher/class-analytics/:sectionId';

  // Admin routes
  static const String studentManagement = '/admin/students';
  static const String staffManagement = '/admin/staff';
  static const String academicConfig = '/admin/academic-config';

  // Student portal routes (additional)
  static const String studentTimetable = '/student/timetable';
  static const String studentAttendance = '/student/attendance';
  static const String studentFees = '/student/fees';

  // Parent portal routes
  static const String childResults = '/parent/child/:childId/results';

  // Teacher portal routes (additional)
  static const String teacherAssignments = '/teacher/assignments';
  static const String teacherClasses = '/teacher/classes';
  static const String classStudents = '/teacher/class/:sectionId/students';

  // Parent portal routes (additional)
  static const String feePayment = '/parent/child/:childId/fees';

  // Admin routes (additional)
  static const String examManagement = '/admin/exams';
  static const String feeManagement = '/admin/fees';
  static const String announcements = '/admin/announcements';

  // Teacher routes (additional)
  static const String teacherTimetable = '/teacher/timetable';

  // QR Scan & ID Card routes
  static const String qrScanner = '/qr-scanner';
  static const String studentIdCard = '/student-id-card/:studentId';
  static const String classTeacherDashboard = '/class-teacher/:sectionId';

  // Super Admin routes
  static const String superAdminDashboard = '/super-admin';
  static const String tenantsList = '/super-admin/tenants';
  static const String createTenant = '/super-admin/tenants/create';
  static const String tenantDetail = '/super-admin/tenants/:tenantId';

  // AI Insights routes
  static const String riskDashboard = '/ai/risk-dashboard';
  static const String studentRiskDetail = '/ai/risk-dashboard/:studentId';
  static const String attendanceInsights = '/ai/attendance-insights/:sectionId';
  static const String trendDashboard = '/ai/trends';
  static const String parentDigests = '/ai/parent-digests';
  static const String parentDigestDetail = '/ai/parent-digests/:digestId';

  // Early Warning Alerts routes
  static const String earlyWarningAlerts = '/ai/alerts';
  static const String alertDetail = '/ai/alerts/:alertId';
  static const String alertRulesConfig = '/ai/alert-rules';

  // AI Features routes (additional)
  static const String studyRecommendations = '/ai/study-tips';
  static const String generateRemarks = '/ai/report-remarks';
  static const String aiMessageComposer = '/ai/compose-message';
  static const String classIntelligence = '/ai/class-intelligence/:sectionId';

  // Syllabus & Topics routes
  static const String syllabusList = '/syllabus';
  static const String syllabusEditor = '/syllabus/editor';
  static const String topicDetail = '/syllabus/topic/:topicId';
  static const String topicForm = '/syllabus/topic-form';
  static const String syllabusAIGenerator = '/syllabus/ai-generate';
  static const String coverageDashboard = '/syllabus/coverage';
  static const String sectionCoverage = '/syllabus/coverage/compare';
  static const String lessonPlan = '/syllabus/lesson-plan/:planId';
  static const String lessonPlanForm = '/syllabus/topic/:topicId/lesson-plan';
  static const String studentSyllabus = '/student/syllabus';

  // Question Paper routes
  static const String questionPaperList = '/question-papers';
  static const String questionPaperCreate = '/question-papers/create';
  static const String questionPaperDetail = '/question-papers/:paperId';

  // Substitution routes
  static const String substitutionDashboard = '/substitutions';
  static const String reportAbsence = '/substitutions/report-absence';

  // Admission routes
  static const String admissionDashboard = '/admissions';
  static const String admissionInquiries = '/admissions/inquiries';
  static const String admissionInquiryForm = '/admissions/inquiries/form';
  static const String admissionApplications = '/admissions/applications';
  static const String admissionApplicationDetail = '/admissions/applications/:applicationId';
  static const String admissionApplicationForm = '/admissions/applications/form';
  static const String admissionInterviews = '/admissions/interviews';
  static const String admissionSettings = '/admissions/settings';

  // Discipline / Behavior Management routes
  static const String disciplineDashboard = '/discipline';
  static const String disciplineIncidents = '/discipline/incidents';
  static const String disciplineReportIncident = '/discipline/report';
  static const String disciplineIncidentDetail = '/discipline/incidents/:incidentId';
  static const String disciplinePlans = '/discipline/plans';
  static const String disciplineRecognitions = '/discipline/recognitions';
  static const String disciplineStudentProfile = '/discipline/student/:studentId';
  static const String disciplineDetention = '/discipline/detention';
  static const String disciplineSettings = '/discipline/settings';

  // LMS routes
  static const String lmsDashboard = '/lms';
  static const String lmsCatalog = '/lms/catalog';
  static const String lmsCourseDetail = '/lms/course/:courseId';
  static const String lmsCourseBuilder = '/lms/course-builder';
  static const String lmsCourseBuilderEdit = '/lms/course-builder/:courseId';
  static const String lmsCourseProgress = '/lms/progress/:enrollmentId';
  static const String lmsModuleContent = '/lms/progress/:enrollmentId/module/:moduleId/content/:contentId';
  static const String lmsDiscussionForum = '/lms/course/:courseId/discussions';
  static const String lmsCertificate = '/lms/certificate/:enrollmentId';
  static const String lmsMyCourses = '/lms/my-courses';

  // HR & Payroll routes
  static const String hrDashboard = '/hr';
  static const String hrDepartments = '/hr/departments';
  static const String hrDepartmentDetail = '/hr/departments/:departmentId';
  static const String hrStaffDirectory = '/hr/staff-directory';
  static const String hrStaffProfile = '/hr/staff-profile/:staffId';
  static const String hrContracts = '/hr/contracts';
  static const String hrPayroll = '/hr/payroll';
  static const String hrPayrollRun = '/hr/payroll/run';
  static const String hrPayrollRunDetail = '/hr/payroll/run/:runId';
  static const String hrSalarySlips = '/hr/salary-slips';
  static const String hrStaffAttendance = '/hr/staff-attendance';
  static const String hrTaxDeclarations = '/hr/tax-declarations';

  // Alumni routes
  static const String alumniDashboard = '/alumni';
  static const String alumniDirectory = '/alumni/directory';
  static const String alumniProfile = '/alumni/profile/:alumniId';
  static const String alumniEvents = '/alumni/events';
  static const String alumniEventDetail = '/alumni/events/:eventId';
  static const String alumniDonations = '/alumni/donations';
  static const String alumniMentorship = '/alumni/mentorship';
  static const String alumniStories = '/alumni/stories';
  static const String alumniRegistration = '/alumni/register';

  // Visitor Management routes
  static const String visitorDashboard = '/visitors';
  static const String visitorCheckIn = '/visitors/check-in';
  static const String visitorCheckOut = '/visitors/check-out';
  static const String visitorLog = '/visitors/log';
  static const String visitorPreRegister = '/visitors/pre-register';
  static const String visitorDetail = '/visitors/:visitorId';

  // Certificate Generator routes
  static const String certificateDashboard = '/certificates';
  static const String certificateTemplates = '/certificates/templates';
  static const String issueCertificate = '/certificates/issue';
  static const String certificateList = '/certificates/list';
  static const String certificatePreview = '/certificates/preview/:certId';
  static const String verifyCertificate = '/certificates/verify';

  // Online Exam routes
  static const String onlineExams = '/online-exams';
  static const String onlineExamCreate = '/online-exams/create';
  static const String onlineExamBuilder = '/online-exams/builder/:examId';
  static const String onlineExamDetail = '/online-exams/:examId';
  static const String takeOnlineExam = '/online-exams/take/:examId';
  static const String onlineExamResult = '/online-exams/result/:attemptId';
  static const String onlineExamAnalytics = '/online-exams/analytics/:examId';
  static const String onlineExamGrade = '/online-exams/grade/:attemptId';
  static const String onlineExamSettings = '/online-exams/settings/:examId';

  // Bus GPS Tracking routes
  static const String busTrackingDashboard = '/bus-tracking';
  static const String busTrackingLiveMap = '/bus-tracking/live-map';
  static const String busTrackingVehicleDetail = '/bus-tracking/vehicle/:vehicleId';
  static const String busTrackingVehicleForm = '/bus-tracking/vehicle-form';
  static const String busTrackingGeofences = '/bus-tracking/geofences';
  static const String busTrackingAlerts = '/bus-tracking/alerts';
  static const String busTrackingDriverPanel = '/bus-tracking/driver';
  static const String busTrackingTrips = '/bus-tracking/trips';

  // Communication Hub routes
  static const String communicationDashboard = '/communication';
  static const String communicationTemplates = '/communication/templates';
  static const String communicationTemplateEditor = '/communication/templates/editor';
  static const String communicationCampaignCreate = '/communication/campaigns/create';
  static const String communicationCampaigns = '/communication/campaigns';
  static const String communicationCampaignDetail = '/communication/campaigns/:campaignId';
  static const String communicationAutoRules = '/communication/auto-rules';
  static const String communicationSmsSettings = '/communication/sms-settings';
  static const String communicationEmailSettings = '/communication/email-settings';
  static const String communicationLog = '/communication/log';

  // Inventory & Assets routes
  static const String inventoryDashboard = '/inventory';
  static const String inventoryAssets = '/inventory/assets';
  static const String inventoryAssetDetail = '/inventory/assets/:assetId';
  static const String inventoryAssetForm = '/inventory/assets/form';
  static const String inventoryAssetScan = '/inventory/scan';
  static const String inventoryAssetAssign = '/inventory/assets/:assetId/assign';
  static const String inventoryStock = '/inventory/stock';
  static const String inventoryTransactions = '/inventory/transactions';
  static const String inventoryPurchaseRequests = '/inventory/purchase-requests';
  static const String inventoryMaintenance = '/inventory/maintenance';
  static const String inventoryAudit = '/inventory/audit';
  static const String inventoryCategories = '/inventory/categories';

  // Homework Tracker routes
  static const String homeworkDashboard = '/homework';
  static const String homeworkCreate = '/homework/create';
  static const String homeworkDetail = '/homework/:homeworkId';
  static const String homeworkSubmit = '/homework/:homeworkId/submit';
  static const String homeworkSubmissions = '/homework/:homeworkId/submissions';
  static const String homeworkCalendar = '/homework/calendar';

  // Notice Board routes
  static const String noticeBoard = '/notice-board';
  static const String noticeBoardDetail = '/notice-board/:noticeId';
  static const String noticeBoardCreate = '/notice-board/create';
  static const String noticeBoardEdit = '/notice-board/:noticeId/edit';

  // Student Portfolio routes
  static const String studentPortfolio = '/portfolio/:studentId';
  static const String portfolioWork = '/portfolio/:studentId/work';

  // Digital ID Card
  static const String digitalIdCard = '/student/:studentId/id-card';
}

/// Router provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final supabase = ref.read(supabaseProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(
      supabase.auth.onAuthStateChange.map((event) => event.session),
    ),
    redirect: (context, state) {
      // Read current session and user synchronously on every redirect
      final session = supabase.auth.currentSession;
      final currentUser = ref.read(currentUserProvider);
      final isLoggedIn = session != null || currentUser != null;
      final isLoggingIn = state.matchedLocation == AppRoutes.login;
      final isSplash = state.matchedLocation == AppRoutes.splash;

      developer.log(
        'Router redirect: location=${state.matchedLocation}, '
        'session=${session != null}, currentUser=${currentUser != null}, '
        'isLoggedIn=$isLoggedIn',
        name: 'AppRouter',
      );

      // If on splash, don't redirect
      if (isSplash) return null;

      // If not logged in and not on login page, redirect to login
      if (!isLoggedIn && !isLoggingIn) {
        return AppRoutes.login;
      }

      // If logged in and on login page, redirect to dashboard
      if (isLoggedIn && isLoggingIn) {
        return _getDashboardRoute(ref);
      }

      // Role-based route guards for authenticated users
      if (isLoggedIn && currentUser != null) {
        final role = currentUser.primaryRole ?? '';
        final location = state.matchedLocation;

        // Super-admin routes require super_admin role
        if (location.startsWith('/super-admin') && role != 'super_admin') {
          return _getDashboardRoute(ref);
        }

        // Admin routes require super_admin, tenant_admin, or principal
        if (location.startsWith('/admin') &&
            !const ['super_admin', 'tenant_admin', 'principal'].contains(role)) {
          return _getDashboardRoute(ref);
        }

        // Teacher routes require teacher role
        if (location.startsWith('/teacher') && role != 'teacher') {
          return _getDashboardRoute(ref);
        }
      }

      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // Main Shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          // Dashboard Routes
          GoRoute(
            path: AppRoutes.adminDashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminDashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.teacherDashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TeacherDashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.studentDashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: StudentDashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.parentDashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ParentDashboardScreen(),
            ),
          ),

          // Students
          GoRoute(
            path: AppRoutes.students,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: StudentsListScreen(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => StudentDetailScreen(
                  studentId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),

          // Attendance
          GoRoute(
            path: AppRoutes.attendance,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AttendanceScreen(),
            ),
            routes: [
              GoRoute(
                path: 'mark/:sectionId',
                builder: (context, state) => MarkAttendanceScreen(
                  sectionId: state.pathParameters['sectionId']!,
                  date: state.uri.queryParameters['date'],
                ),
              ),
            ],
          ),

          // Exams
          GoRoute(
            path: AppRoutes.exams,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ExamsScreen(),
            ),
            routes: [
              GoRoute(
                path: ':examId/marks',
                builder: (context, state) => MarksEntryScreen(
                  examId: state.pathParameters['examId']!,
                ),
              ),
            ],
          ),

          // Fees
          GoRoute(
            path: AppRoutes.fees,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FeesScreen(),
            ),
          ),

          // Messages
          GoRoute(
            path: AppRoutes.messages,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MessagesScreen(),
            ),
          ),

          // ==================== CANTEEN ====================
          GoRoute(
            path: AppRoutes.canteen,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CanteenMenuScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.canteenCart,
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: AppRoutes.canteenWallet,
            builder: (context, state) => const WalletScreen(),
          ),
          GoRoute(
            path: AppRoutes.canteenOrders,
            builder: (context, state) => const OrderHistoryScreen(),
          ),

          // ==================== LIBRARY ====================
          GoRoute(
            path: AppRoutes.library,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LibraryScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.libraryBookDetail,
            builder: (context, state) => BookDetailScreen(
              bookId: state.pathParameters['bookId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.libraryMyBooks,
            builder: (context, state) => const MyBooksScreen(),
          ),

          // ==================== TRANSPORT ====================
          GoRoute(
            path: AppRoutes.transport,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TransportScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.transportRouteDetail,
            builder: (context, state) => RouteDetailScreen(
              routeId: state.pathParameters['routeId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.transportMyRoute,
            builder: (context, state) => const MyTransportScreen(),
          ),

          // ==================== HOSTEL ====================
          GoRoute(
            path: AppRoutes.hostel,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HostelScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.hostelMyRoom,
            builder: (context, state) => const MyHostelScreen(),
          ),
          GoRoute(
            path: AppRoutes.hostelDetail,
            builder: (context, state) => HostelDetailScreen(
              hostelId: state.pathParameters['hostelId']!,
            ),
          ),

          // ==================== NOTIFICATIONS ====================
          GoRoute(
            path: AppRoutes.notifications,
            builder: (context, state) => const NotificationCenterScreen(),
          ),

          // ==================== HEALTH ====================
          GoRoute(
            path: AppRoutes.healthProfile,
            builder: (context, state) => StudentHealthProfileScreen(
              studentId: state.pathParameters['studentId']!,
            ),
          ),

          // ==================== GAMIFICATION ====================
          GoRoute(
            path: AppRoutes.achievements,
            builder: (context, state) => AchievementsScreen(
              studentId: state.pathParameters['studentId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.leaderboard,
            builder: (context, state) => const LeaderboardScreen(),
          ),

          // ==================== INSIGHTS ====================
          GoRoute(
            path: AppRoutes.childInsights,
            builder: (context, state) => ChildInsightsScreen(
              studentId: state.pathParameters['studentId']!,
            ),
          ),

          // ==================== ASSESSMENTS ====================
          GoRoute(
            path: AppRoutes.assessments,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: QuizzesScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.takeQuiz,
            builder: (context, state) => TakeQuizScreen(
              quizId: state.pathParameters['quizId']!,
              studentId: state.uri.queryParameters['studentId'] ?? '',
            ),
          ),
          GoRoute(
            path: AppRoutes.quizResult,
            builder: (context, state) => QuizResultScreen(
              attemptId: state.pathParameters['attemptId']!,
            ),
          ),

          // ==================== PTM ====================
          GoRoute(
            path: AppRoutes.ptm,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PTMSchedulerScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.ptmBook,
            builder: (context, state) => BookAppointmentScreen(
              scheduleId: state.pathParameters['scheduleId']!,
            ),
          ),

          // ==================== EMERGENCY ====================
          GoRoute(
            path: AppRoutes.emergency,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: EmergencyDashboardScreen(),
            ),
          ),

          // ==================== LEAVE ====================
          GoRoute(
            path: AppRoutes.leave,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LeaveManagementScreen(),
            ),
          ),

          // ==================== RESOURCES ====================
          GoRoute(
            path: AppRoutes.resources,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ResourceLibraryScreen(),
            ),
          ),

          // ==================== REPORT CARDS (LEGACY) ====================
          GoRoute(
            path: AppRoutes.reports,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReportCardsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.reportDetail,
            builder: (context, state) => ReportCardViewScreen(
              reportId: state.pathParameters['reportId']!,
            ),
          ),

          // ==================== REPORT CARD GENERATOR (FULL MODULE) ====================
          GoRoute(
            path: AppRoutes.reportCardDashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReportCardDashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.reportCardTemplates,
            builder: (context, state) => const TemplateListScreen(),
          ),
          GoRoute(
            path: AppRoutes.reportCardTemplateNew,
            builder: (context, state) => const TemplateEditorScreen(),
          ),
          GoRoute(
            path: AppRoutes.reportCardTemplateEdit,
            builder: (context, state) => TemplateEditorScreen(
              templateId: state.pathParameters['templateId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.reportCardGradingScales,
            builder: (context, state) => const GradingScaleScreen(),
          ),
          GoRoute(
            path: AppRoutes.reportCardGenerate,
            builder: (context, state) => const GenerateReportCardsScreen(),
          ),
          GoRoute(
            path: AppRoutes.reportCardList,
            builder: (context, state) => const ReportCardListScreen(),
          ),
          GoRoute(
            path: AppRoutes.reportCardDetail,
            builder: (context, state) => ReportCardDetailScreen(
              reportId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.reportCardPreview,
            builder: (context, state) => ReportCardPreviewScreen(
              reportId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.reportCardComments,
            builder: (context, state) => AddCommentsScreen(
              reportId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.reportCardSkills,
            builder: (context, state) => SkillsRatingScreen(
              reportId: state.pathParameters['id']!,
            ),
          ),

          // Student Results
          GoRoute(
            path: AppRoutes.studentResults,
            builder: (context, state) => StudentResultsScreen(
              studentId: state.uri.queryParameters['studentId'],
            ),
          ),

          // Student Assignments
          GoRoute(
            path: AppRoutes.studentAssignments,
            builder: (context, state) => const StudentAssignmentsScreen(),
          ),

          // Class Analytics
          GoRoute(
            path: AppRoutes.classAnalytics,
            builder: (context, state) => ClassAnalyticsScreen(
              sectionId: state.pathParameters['sectionId']!,
              sectionName: state.uri.queryParameters['name'],
            ),
          ),

          // Admin Student Management
          GoRoute(
            path: AppRoutes.studentManagement,
            builder: (context, state) => const StudentManagementScreen(),
          ),

          // Admin Staff Management
          GoRoute(
            path: AppRoutes.staffManagement,
            builder: (context, state) => const StaffManagementScreen(),
          ),

          // Admin Academic Config
          GoRoute(
            path: AppRoutes.academicConfig,
            builder: (context, state) => const AcademicConfigScreen(),
          ),

          // Student Timetable
          GoRoute(
            path: AppRoutes.studentTimetable,
            builder: (context, state) => const StudentTimetableScreen(),
          ),

          // Student Attendance
          GoRoute(
            path: AppRoutes.studentAttendance,
            builder: (context, state) => StudentAttendanceScreen(
              studentId: state.uri.queryParameters['studentId'],
            ),
          ),

          // Student Fees
          GoRoute(
            path: AppRoutes.studentFees,
            builder: (context, state) => StudentFeesScreen(
              studentId: state.uri.queryParameters['studentId'],
            ),
          ),

          // Parent Child Results
          GoRoute(
            path: AppRoutes.childResults,
            builder: (context, state) => ChildResultsScreen(
              childId: state.pathParameters['childId']!,
              childName: state.uri.queryParameters['name'],
            ),
          ),

          // Teacher Assignments Management
          GoRoute(
            path: AppRoutes.teacherAssignments,
            builder: (context, state) => const AssignmentsManagementScreen(),
          ),

          // Teacher My Classes
          GoRoute(
            path: AppRoutes.teacherClasses,
            builder: (context, state) => const MyClassesScreen(),
          ),

          // Teacher Class Students
          GoRoute(
            path: AppRoutes.classStudents,
            builder: (context, state) => ClassStudentsScreen(
              sectionId: state.pathParameters['sectionId']!,
              className: state.uri.queryParameters['name'],
            ),
          ),

          // Parent Fee Payment
          GoRoute(
            path: AppRoutes.feePayment,
            builder: (context, state) => FeePaymentScreen(
              childId: state.pathParameters['childId']!,
              childName: state.uri.queryParameters['name'],
            ),
          ),

          // Admin Exam Management
          GoRoute(
            path: AppRoutes.examManagement,
            builder: (context, state) => const ExamManagementScreen(),
          ),

          // Admin Fee Management
          GoRoute(
            path: AppRoutes.feeManagement,
            builder: (context, state) => const FeeManagementScreen(),
          ),

          // Admin Announcements
          GoRoute(
            path: AppRoutes.announcements,
            builder: (context, state) => const AnnouncementsScreen(),
          ),

          // Teacher Timetable
          GoRoute(
            path: AppRoutes.teacherTimetable,
            builder: (context, state) => const TeacherTimetableScreen(),
          ),

          // ==================== QR SCAN & ID CARD ====================
          GoRoute(
            path: AppRoutes.qrScanner,
            builder: (context, state) => QrScannerScreen(
              mode: state.uri.queryParameters['mode'] ?? 'lookup',
              sectionId: state.uri.queryParameters['sectionId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.studentIdCard,
            builder: (context, state) => StudentIdCardScreen(
              studentId: state.pathParameters['studentId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.classTeacherDashboard,
            builder: (context, state) => ClassTeacherDashboardScreen(
              sectionId: state.pathParameters['sectionId']!,
              sectionName: state.uri.queryParameters['name'],
            ),
          ),

          // Super Admin Dashboard
          GoRoute(
            path: AppRoutes.superAdminDashboard,
            builder: (context, state) => const SuperAdminDashboardScreen(),
          ),

          // Tenants List
          GoRoute(
            path: AppRoutes.tenantsList,
            builder: (context, state) => const TenantsListScreen(),
          ),

          // Create Tenant
          GoRoute(
            path: AppRoutes.createTenant,
            builder: (context, state) => const CreateTenantScreen(),
          ),

          // Tenant Detail
          GoRoute(
            path: AppRoutes.tenantDetail,
            builder: (context, state) => TenantDetailScreen(
              tenantId: state.pathParameters['tenantId']!,
            ),
          ),

          // ==================== AI INSIGHTS ====================
          GoRoute(
            path: AppRoutes.riskDashboard,
            builder: (context, state) => RiskDashboardScreen(
              academicYearId: state.uri.queryParameters['yearId'] ?? '',
            ),
          ),
          GoRoute(
            path: AppRoutes.studentRiskDetail,
            builder: (context, state) => StudentRiskDetailScreen(
              studentId: state.pathParameters['studentId']!,
              academicYearId: state.uri.queryParameters['yearId'] ?? '',
            ),
          ),
          GoRoute(
            path: AppRoutes.attendanceInsights,
            builder: (context, state) => AttendanceInsightsScreen(
              sectionId: state.pathParameters['sectionId']!,
              sectionName: state.uri.queryParameters['name'],
            ),
          ),
          GoRoute(
            path: AppRoutes.trendDashboard,
            builder: (context, state) => TrendDashboardScreen(
              sectionId: state.uri.queryParameters['sectionId'],
              studentId: state.uri.queryParameters['studentId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.parentDigests,
            builder: (context, state) => ParentDigestListScreen(
              parentId: state.uri.queryParameters['parentId'] ?? '',
              studentId: state.uri.queryParameters['studentId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.parentDigestDetail,
            builder: (context, state) => ParentDigestDetailScreen(
              digestId: state.pathParameters['digestId']!,
            ),
          ),

          // ==================== EARLY WARNING ALERTS ====================
          GoRoute(
            path: AppRoutes.earlyWarningAlerts,
            builder: (context, state) =>
                const EarlyWarningDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.alertDetail,
            builder: (context, state) => AlertDetailScreen(
              alertId: state.pathParameters['alertId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.alertRulesConfig,
            builder: (context, state) =>
                const AlertRulesConfigScreen(),
          ),

          // ==================== AI FEATURES (ADDITIONAL) ====================
          GoRoute(
            path: AppRoutes.studyRecommendations,
            builder: (context, state) =>
                const StudyRecommendationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.generateRemarks,
            builder: (context, state) =>
                const GenerateRemarksScreen(),
          ),
          GoRoute(
            path: AppRoutes.aiMessageComposer,
            builder: (context, state) =>
                const AIMessageComposerScreen(),
          ),
          GoRoute(
            path: AppRoutes.classIntelligence,
            builder: (context, state) => ClassIntelligenceScreen(
              sectionId: state.pathParameters['sectionId']!,
              sectionName: state.uri.queryParameters['name'],
            ),
          ),

          // ==================== SYLLABUS & TOPICS ====================
          GoRoute(
            path: AppRoutes.syllabusList,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SyllabusListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.syllabusEditor,
            builder: (context, state) => SyllabusEditorScreen(
              subjectId: state.uri.queryParameters['subjectId']!,
              classId: state.uri.queryParameters['classId']!,
              academicYearId: state.uri.queryParameters['yearId']!,
              sectionId: state.uri.queryParameters['sectionId'],
              subjectName: state.uri.queryParameters['subjectName'],
              className: state.uri.queryParameters['className'],
            ),
          ),
          GoRoute(
            path: AppRoutes.topicDetail,
            builder: (context, state) => TopicDetailScreen(
              topicId: state.pathParameters['topicId']!,
              sectionId: state.uri.queryParameters['sectionId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.topicForm,
            builder: (context, state) => TopicFormScreen(
              subjectId: state.uri.queryParameters['subjectId']!,
              classId: state.uri.queryParameters['classId']!,
              academicYearId: state.uri.queryParameters['yearId']!,
              parentTopicId: state.uri.queryParameters['parentId'],
              topicId: state.uri.queryParameters['topicId'],
              parentLevel: state.uri.queryParameters['parentLevel'],
            ),
          ),
          GoRoute(
            path: AppRoutes.syllabusAIGenerator,
            builder: (context, state) => AISyllabusGeneratorScreen(
              subjectId: state.uri.queryParameters['subjectId']!,
              classId: state.uri.queryParameters['classId']!,
              academicYearId: state.uri.queryParameters['yearId']!,
              subjectName: state.uri.queryParameters['subjectName'],
              className: state.uri.queryParameters['className'],
            ),
          ),
          GoRoute(
            path: AppRoutes.coverageDashboard,
            builder: (context, state) => const CoverageDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.sectionCoverage,
            builder: (context, state) => SectionCoverageScreen(
              subjectId: state.uri.queryParameters['subjectId']!,
              classId: state.uri.queryParameters['classId']!,
              academicYearId: state.uri.queryParameters['yearId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.lessonPlan,
            builder: (context, state) => LessonPlanScreen(
              planId: state.pathParameters['planId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.lessonPlanForm,
            builder: (context, state) => LessonPlanFormScreen(
              topicId: state.pathParameters['topicId']!,
              topicTitle: state.uri.queryParameters['topicTitle'],
              sectionId: state.uri.queryParameters['sectionId'],
              planId: state.uri.queryParameters['planId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.studentSyllabus,
            builder: (context, state) => const StudentSyllabusScreen(),
          ),

          // ==================== QUESTION PAPER ====================
          GoRoute(
            path: AppRoutes.questionPaperList,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: QuestionPaperListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.questionPaperCreate,
            builder: (context, state) =>
                const QuestionPaperGeneratorScreen(),
          ),
          GoRoute(
            path: AppRoutes.questionPaperDetail,
            builder: (context, state) => QuestionPaperDetailScreen(
              paperId: state.pathParameters['paperId']!,
            ),
          ),

          // ==================== SUBSTITUTION ====================
          GoRoute(
            path: AppRoutes.substitutionDashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SubstitutionDashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.reportAbsence,
            builder: (context, state) => const ReportAbsenceScreen(),
          ),

          // ==================== ADMISSIONS ====================
          GoRoute(
            path: AppRoutes.admissionDashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdmissionDashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.admissionInquiries,
            builder: (context, state) => const InquiryListScreen(),
          ),
          GoRoute(
            path: AppRoutes.admissionInquiryForm,
            builder: (context, state) => InquiryFormScreen(
              inquiry: state.extra as dynamic,
            ),
          ),
          GoRoute(
            path: AppRoutes.admissionApplications,
            builder: (context, state) => const ApplicationListScreen(),
          ),
          GoRoute(
            path: AppRoutes.admissionApplicationDetail,
            builder: (context, state) => ApplicationDetailScreen(
              applicationId: state.pathParameters['applicationId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.admissionApplicationForm,
            builder: (context, state) => ApplicationFormScreen(
              inquiryId: state.uri.queryParameters['inquiryId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.admissionInterviews,
            builder: (context, state) => InterviewScheduleScreen(
              applicationId: state.uri.queryParameters['applicationId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.admissionSettings,
            builder: (context, state) => const AdmissionSettingsScreen(),
          ),

          // ==================== DISCIPLINE ====================
          GoRoute(
            path: AppRoutes.disciplineDashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DisciplineDashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.disciplineIncidents,
            builder: (context, state) => const IncidentListScreen(),
          ),
          GoRoute(
            path: AppRoutes.disciplineReportIncident,
            builder: (context, state) => ReportIncidentScreen(
              preselectedStudentId: state.uri.queryParameters['studentId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.disciplineIncidentDetail,
            builder: (context, state) => IncidentDetailScreen(
              incidentId: state.pathParameters['incidentId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.disciplinePlans,
            builder: (context, state) => BehaviorPlanScreen(
              studentId: state.uri.queryParameters['studentId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.disciplineRecognitions,
            builder: (context, state) =>
                const PositiveRecognitionScreen(),
          ),
          GoRoute(
            path: AppRoutes.disciplineStudentProfile,
            builder: (context, state) =>
                StudentBehaviorProfileScreen(
              studentId: state.pathParameters['studentId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.disciplineDetention,
            builder: (context, state) =>
                const DetentionManagementScreen(),
          ),
          GoRoute(
            path: AppRoutes.disciplineSettings,
            builder: (context, state) =>
                const BehaviorSettingsScreen(),
          ),

          // ==================== LMS ====================
          GoRoute(
            path: AppRoutes.lmsDashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LmsDashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.lmsCatalog,
            builder: (context, state) => const CourseCatalogScreen(),
          ),
          GoRoute(
            path: AppRoutes.lmsMyCourses,
            builder: (context, state) => const LmsDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.lmsCourseDetail,
            builder: (context, state) => CourseDetailScreen(
              courseId: state.pathParameters['courseId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.lmsCourseBuilder,
            builder: (context, state) => const CourseBuilderScreen(),
          ),
          GoRoute(
            path: AppRoutes.lmsCourseBuilderEdit,
            builder: (context, state) => CourseBuilderScreen(
              courseId: state.pathParameters['courseId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.lmsCourseProgress,
            builder: (context, state) => CourseProgressScreen(
              enrollmentId: state.pathParameters['enrollmentId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.lmsModuleContent,
            builder: (context, state) => ModuleContentScreen(
              enrollmentId: state.pathParameters['enrollmentId']!,
              moduleId: state.pathParameters['moduleId']!,
              contentId: state.pathParameters['contentId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.lmsDiscussionForum,
            builder: (context, state) => DiscussionForumScreen(
              courseId: state.pathParameters['courseId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.lmsCertificate,
            builder: (context, state) => CertificateScreen(
              enrollmentId: state.pathParameters['enrollmentId']!,
            ),
          ),

          // ==================== VISITOR MANAGEMENT ====================
          GoRoute(
            path: AppRoutes.visitorDashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: VisitorDashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.visitorCheckIn,
            builder: (context, state) => VisitorCheckInScreen(
              preRegQrData: state.uri.queryParameters['qrData'],
            ),
          ),
          GoRoute(
            path: AppRoutes.visitorCheckOut,
            builder: (context, state) => const VisitorCheckOutScreen(),
          ),
          GoRoute(
            path: AppRoutes.visitorLog,
            builder: (context, state) => const VisitorLogScreen(),
          ),
          GoRoute(
            path: AppRoutes.visitorPreRegister,
            builder: (context, state) => const PreRegistrationScreen(),
          ),
          GoRoute(
            path: AppRoutes.visitorDetail,
            builder: (context, state) => VisitorDetailScreen(
              visitorId: state.pathParameters['visitorId']!,
            ),
          ),

          // ==================== CERTIFICATE GENERATOR ====================
          GoRoute(
            path: AppRoutes.certificateDashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CertificateDashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.certificateTemplates,
            builder: (context, state) => const CertificateTemplateScreen(),
          ),
          GoRoute(
            path: AppRoutes.issueCertificate,
            builder: (context, state) => const IssueCertificateScreen(),
          ),
          GoRoute(
            path: AppRoutes.certificateList,
            builder: (context, state) => const CertificateListScreen(),
          ),
          GoRoute(
            path: AppRoutes.certificatePreview,
            builder: (context, state) => CertificatePreviewScreen(
              certId: state.pathParameters['certId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.verifyCertificate,
            builder: (context, state) => const VerifyCertificateScreen(),
          ),

          // ==================== ONLINE EXAMS ====================
          GoRoute(
            path: AppRoutes.onlineExams,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ExamDashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.onlineExamCreate,
            builder: (context, state) => const ExamBuilderScreen(),
          ),
          GoRoute(
            path: AppRoutes.onlineExamBuilder,
            builder: (context, state) => ExamBuilderScreen(
              examId: state.pathParameters['examId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.onlineExamDetail,
            builder: (context, state) => ExamDetailScreen(
              examId: state.pathParameters['examId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.takeOnlineExam,
            builder: (context, state) => TakeExamScreen(
              examId: state.pathParameters['examId']!,
              studentId: state.uri.queryParameters['studentId'] ?? '',
            ),
          ),
          GoRoute(
            path: AppRoutes.onlineExamResult,
            builder: (context, state) => ExamResultScreen(
              attemptId: state.pathParameters['attemptId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.onlineExamAnalytics,
            builder: (context, state) => ExamAnalyticsScreen(
              examId: state.pathParameters['examId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.onlineExamGrade,
            builder: (context, state) => GradeExamScreen(
              attemptId: state.pathParameters['attemptId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.onlineExamSettings,
            builder: (context, state) => ExamSettingsScreen(
              examId: state.pathParameters['examId']!,
            ),
          ),
        ],
      ),

      // HR & Payroll routes
      GoRoute(
        path: AppRoutes.hrDashboard,
        builder: (context, state) => const HRDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.hrDepartments,
        builder: (context, state) => const DepartmentListScreen(),
      ),
      GoRoute(
        path: AppRoutes.hrDepartmentDetail,
        builder: (context, state) => DepartmentDetailScreen(
          departmentId: state.pathParameters['departmentId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.hrStaffDirectory,
        builder: (context, state) => const StaffDirectoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.hrStaffProfile,
        builder: (context, state) => StaffProfileScreen(
          staffId: state.pathParameters['staffId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.hrContracts,
        builder: (context, state) => const ContractManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.hrPayroll,
        builder: (context, state) => const PayrollDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.hrPayrollRun,
        builder: (context, state) => const PayrollRunScreen(),
      ),
      GoRoute(
        path: AppRoutes.hrPayrollRunDetail,
        builder: (context, state) => PayrollRunScreen(
          payrollRunId: state.pathParameters['runId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.hrSalarySlips,
        builder: (context, state) => SalarySlipScreen(
          staffId: state.uri.queryParameters['staffId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.hrStaffAttendance,
        builder: (context, state) => const StaffAttendanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.hrTaxDeclarations,
        builder: (context, state) => const TaxDeclarationScreen(),
      ),

      // ==================== CALENDAR & EVENTS ====================
      GoRoute(
        path: AppRoutes.calendar,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: CalendarScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.calendarEvents,
        builder: (context, state) => const EventListScreen(),
      ),
      GoRoute(
        path: AppRoutes.calendarEventDetail,
        builder: (context, state) => cal.EventDetailScreen(
          eventId: state.pathParameters['eventId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.calendarCreateEvent,
        builder: (context, state) => CreateEventScreen(
          existingEvent: state.extra as SchoolEvent?,
        ),
      ),
      GoRoute(
        path: AppRoutes.calendarAcademic,
        builder: (context, state) => AcademicCalendarScreen(
          academicYearId: state.uri.queryParameters['yearId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.calendarHolidays,
        builder: (context, state) => HolidayListScreen(
          academicYearId: state.uri.queryParameters['yearId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.calendarEventAttendees,
        builder: (context, state) => EventAttendeesScreen(
          eventId: state.pathParameters['eventId']!,
        ),
      ),

      // ==================== ALUMNI ====================
      GoRoute(
        path: AppRoutes.alumniDashboard,
        builder: (context, state) => const AlumniDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.alumniDirectory,
        builder: (context, state) => const AlumniDirectoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.alumniProfile,
        builder: (context, state) => AlumniProfileScreen(
          alumniId: state.pathParameters['alumniId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.alumniEvents,
        builder: (context, state) => const AlumniEventsScreen(),
      ),
      GoRoute(
        path: AppRoutes.alumniEventDetail,
        builder: (context, state) => EventDetailScreen(
          eventId: state.pathParameters['eventId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.alumniDonations,
        builder: (context, state) => const DonationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.alumniMentorship,
        builder: (context, state) => const MentorshipScreen(),
      ),
      GoRoute(
        path: AppRoutes.alumniStories,
        builder: (context, state) => const SuccessStoriesScreen(),
      ),
      GoRoute(
        path: AppRoutes.alumniRegistration,
        builder: (context, state) => const AlumniRegistrationScreen(),
      ),

      // ==================== BUS GPS TRACKING ====================
      GoRoute(
        path: AppRoutes.busTrackingDashboard,
        builder: (context, state) => const BusTrackingDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.busTrackingLiveMap,
        builder: (context, state) => const LiveMapScreen(),
      ),
      GoRoute(
        path: AppRoutes.busTrackingVehicleDetail,
        builder: (context, state) => VehicleDetailScreen(
          vehicleId: state.pathParameters['vehicleId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.busTrackingVehicleForm,
        builder: (context, state) => const VehicleFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.busTrackingGeofences,
        builder: (context, state) => const GeofenceListScreen(),
      ),
      GoRoute(
        path: AppRoutes.busTrackingAlerts,
        builder: (context, state) => const GeofenceAlertsScreen(),
      ),
      GoRoute(
        path: AppRoutes.busTrackingDriverPanel,
        builder: (context, state) => const DriverPanelScreen(),
      ),
      GoRoute(
        path: AppRoutes.busTrackingTrips,
        builder: (context, state) => const TripHistoryScreen(),
      ),

      // ==================== COMMUNICATION HUB ====================
      GoRoute(
        path: AppRoutes.communicationDashboard,
        builder: (context, state) => const CommunicationDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.communicationTemplates,
        builder: (context, state) => const comm.TemplateListScreen(),
      ),
      GoRoute(
        path: AppRoutes.communicationTemplateEditor,
        builder: (context, state) => comm_editor.TemplateEditorScreen(
          template: state.extra as CommunicationTemplate?,
        ),
      ),
      GoRoute(
        path: AppRoutes.communicationCampaignCreate,
        builder: (context, state) => const CampaignCreateScreen(),
      ),
      GoRoute(
        path: AppRoutes.communicationCampaigns,
        builder: (context, state) => const CampaignListScreen(),
      ),
      GoRoute(
        path: AppRoutes.communicationCampaignDetail,
        builder: (context, state) => CampaignDetailScreen(
          campaignId: state.pathParameters['campaignId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.communicationAutoRules,
        builder: (context, state) => const AutoRulesScreen(),
      ),
      GoRoute(
        path: AppRoutes.communicationSmsSettings,
        builder: (context, state) => const SmsSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.communicationEmailSettings,
        builder: (context, state) => const EmailSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.communicationLog,
        builder: (context, state) => const CommunicationLogScreen(),
      ),

      // ==================== INVENTORY & ASSETS ====================
      GoRoute(
        path: AppRoutes.inventoryDashboard,
        builder: (context, state) => const InventoryDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.inventoryAssets,
        builder: (context, state) => const AssetListScreen(),
      ),
      GoRoute(
        path: AppRoutes.inventoryAssetDetail,
        builder: (context, state) => AssetDetailScreen(
          assetId: state.pathParameters['assetId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.inventoryAssetForm,
        builder: (context, state) => const AssetFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.inventoryAssetScan,
        builder: (context, state) => const AssetScanScreen(),
      ),
      GoRoute(
        path: AppRoutes.inventoryAssetAssign,
        builder: (context, state) => AssetAssignmentScreen(
          preselectedAssetId: state.pathParameters['assetId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.inventoryStock,
        builder: (context, state) => const InventoryListScreen(),
      ),
      GoRoute(
        path: AppRoutes.inventoryTransactions,
        builder: (context, state) => const InventoryTransactionScreen(),
      ),
      GoRoute(
        path: AppRoutes.inventoryPurchaseRequests,
        builder: (context, state) => const PurchaseRequestScreen(),
      ),
      GoRoute(
        path: AppRoutes.inventoryMaintenance,
        builder: (context, state) => const MaintenanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.inventoryAudit,
        builder: (context, state) => const AuditScreen(),
      ),
      GoRoute(
        path: AppRoutes.inventoryCategories,
        builder: (context, state) => const CategoryManagementScreen(),
      ),

      // ==================== HOMEWORK TRACKER ====================
      GoRoute(
        path: AppRoutes.homeworkDashboard,
        builder: (context, state) => const HomeworkDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.homeworkCreate,
        builder: (context, state) => const HomeworkCreateScreen(),
      ),
      GoRoute(
        path: AppRoutes.homeworkDetail,
        builder: (context, state) => HomeworkDetailScreen(
          homeworkId: state.pathParameters['homeworkId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.homeworkSubmit,
        builder: (context, state) => HomeworkSubmitScreen(
          homeworkId: state.pathParameters['homeworkId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.homeworkSubmissions,
        builder: (context, state) => HomeworkSubmissionsScreen(
          homeworkId: state.pathParameters['homeworkId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.homeworkCalendar,
        builder: (context, state) => const HomeworkCalendarScreen(),
      ),

      // ==================== NOTICE BOARD ====================
      GoRoute(
        path: AppRoutes.noticeBoard,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: NoticeBoardScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.noticeBoardCreate,
        builder: (context, state) => const NoticeFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.noticeBoardDetail,
        builder: (context, state) => NoticeDetailScreen(
          noticeId: state.pathParameters['noticeId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.noticeBoardEdit,
        builder: (context, state) => NoticeFormScreen(
          existingNotice: state.extra as notice.Notice?,
        ),
      ),

      // ==================== STUDENT PORTFOLIO ====================
      GoRoute(
        path: AppRoutes.studentPortfolio,
        builder: (context, state) => StudentPortfolioScreen(
          studentId: state.pathParameters['studentId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.portfolioWork,
        builder: (context, state) => PortfolioWorkScreen(
          studentId: state.pathParameters['studentId']!,
        ),
      ),

      // ==================== DIGITAL ID CARD ====================
      GoRoute(
        path: AppRoutes.digitalIdCard,
        builder: (context, state) => DigitalIdScreen(
          studentId: state.pathParameters['studentId']!,
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});

/// Get dashboard route based on user role
String _getDashboardRoute(Ref ref) {
  final currentUser = ref.read(currentUserProvider);
  final primaryRole = currentUser?.primaryRole;

  developer.log('Getting dashboard route for role: $primaryRole',
      name: 'AppRouter');

  switch (primaryRole) {
    case 'super_admin':
      return AppRoutes.superAdminDashboard;
    case 'tenant_admin':
    case 'principal':
      return AppRoutes.adminDashboard;
    case 'teacher':
      return AppRoutes.teacherDashboard;
    case 'student':
      return AppRoutes.studentDashboard;
    case 'parent':
      return AppRoutes.parentDashboard;
    default:
      developer.log('No valid role found, redirecting to login',
          name: 'AppRouter', level: 800);
      return AppRoutes.login;
  }
}

/// Converts a [Stream] into a [ChangeNotifier] for GoRouter's refreshListenable
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
