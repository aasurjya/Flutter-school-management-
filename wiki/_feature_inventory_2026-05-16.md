---
type: inventory
audit_date: 2026-05-16
auditor: product-tester
---

# Feature Inventory — School Management Flutter

> Snapshot of every feature folder under `lib/features/` with entry screen, route, screen count and intended roles. Verdict column populated by [[features/]] audit pages.

| # | Feature | Entry screen | Route | Screens | Primary roles | Verdict |
|---|---|---|---|---|---|---|
| 1 | dashboard | `dashboard/presentation/screens/admin_dashboard_screen.dart` (+ teacher/student/parent variants) | `/admin`, `/teacher`, `/student`, `/parent` | 4 | All | [[features/dashboard\|SHIP]] |
| 2 | fees | `fees/presentation/screens/fees_screen.dart` | `/fees` | 4 | admin, parent, student | [[features/fees\|IMPROVE]] |
| 3 | attendance | `attendance/presentation/screens/attendance_screen.dart` | `/attendance` | 2 | admin, teacher, student | [[features/attendance\|IMPROVE]] |
| 4 | exams | `exams/presentation/screens/exams_screen.dart` | `/exams` | 2 | admin, teacher, student, parent | [[features/exams\|SHIP]] |
| 5 | homework | `homework/presentation/screens/homework_dashboard_screen.dart` | `/homework` | 6 | teacher, student, parent | [[features/homework\|SHIP]] |
| 6 | bus_tracking | `bus_tracking/presentation/screens/bus_tracking_dashboard_screen.dart` | `/bus-tracking` | 8 | transport_manager, admin, parent | [[features/bus_tracking\|IMPROVE]] |
| 7 | communication | `communication/presentation/screens/communication_dashboard_screen.dart` | `/communication` | 13 | admin, principal | [[features/communication\|IMPROVE]] |
| 8 | admission | `admission/presentation/screens/admission_dashboard_screen.dart` | `/admissions` | 8 | admin, receptionist | [[features/admission\|SHIP]] |
| 9 | students | `students/presentation/screens/students_list_screen.dart` | `/students` | 2 | admin, teacher | [[features/students\|IMPROVE]] |
| 10 | profile | `profile/presentation/screens/account_settings_screen.dart` | `/account`, `/account/edit`, `/account/password` | 3 | all | [[features/profile\|SHIP]] |
| 11 | ptm | `ptm/presentation/screens/ptm_scheduler_screen.dart` | `/ptm` | 2 | admin, teacher, parent | [[features/ptm\|IMPROVE]] |
| 12 | ai_insights | `ai_insights/presentation/screens/generate_remarks_screen.dart` (and risk/trend) | `/ai-insights/*` | 13 | admin, teacher | [[features/ai_insights\|IMPROVE]] |

## Other feature folders (not in this pass — see below)

Lower-priority for this audit, deferred:

`academic, admin, alumni, announcements, assessments, assignments, auth, calendar, canteen, certificate, discipline, emergency, gamification, health, hostel, hr, id_card, insights, inventory, leave, library, lms, messaging, notice_board, notifications, offline, online_exam, parent, portfolio, profile_setup, qr_scan, question_paper, report_card, reports, resources, settings, staff_portal, student, student_portfolio, students, substitution, super_admin, syllabus, teacher, timetable, transport, visitor`

### Empty / suspiciously skeletal

| Feature | Files found | Concern |
|---|---|---|
| `timetable` | only `providers/timetable_provider.dart` — **no presentation screens** | Critical Indian K-12 feature. Routes reference `AppRoutes.timetable` from admin dashboard. Where is the screen? |
| `ai_tutor` | only `providers/ai_tutor_provider.dart` + `widgets/tutor_chat_overlay.dart` — **no entry screen** | Feature is overlay-only. Not navigable from the dashboard grids. |

These two are flagged in [[panels/feature-audit-2026-05-16]] for the panel.

## Architectural observations from inventory

- 4 dashboards (admin, teacher, student, parent) + 6 staff-portal mini-dashboards = **10 dashboard surfaces total**. Code reuse between them is unclear from inventory alone; worth a panel pass.
- The 48-feature sprawl flagged by Critic is real: this inventory counts **48 distinct folders**. Many are clearly filler (alumni, gamification, certificate, canteen, hostel for non-residential schools) for the target market (typical Indian K-12 day schools, 200-2000 students).
- The "hub-of-hubs" antipattern: `communication`, `admission`, `bus_tracking`, `ai_insights`, `report_card`, `hr`, `lms` each have their own dashboard with 6-13 sub-screens. Mobile-primary low-bandwidth users will drown in navigation. Worth a Wenger-style information-architecture review.

## Backlinks

- [[00 Index]]
- [[pending]]
- [[panels/feature-audit-2026-05-16]]
