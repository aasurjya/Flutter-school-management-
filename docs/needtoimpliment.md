# School Management SaaS - Implementation Roadmap

## Status Legend
- ✅ Complete
- 🔄 In Progress
- ⏳ Pending
- ❌ Blocked

---

## Phase 1: Database & Backend Improvements

### 1.1 Analytics Views & Functions
| Task | Status | Priority |
|------|--------|----------|
| Create `mv_student_performance` materialized view | ✅ | HIGH |
| Create `v_class_exam_stats` view | ✅ | HIGH |
| Create `v_student_ranks` view | ✅ | HIGH |
| Create `v_attendance_summary` view | ✅ | HIGH |
| Create `promote_students()` function | ✅ | MEDIUM |
| Create `refresh_analytics()` function | ✅ | MEDIUM |
| Add missing RLS policy for `user_roles` | ✅ | HIGH |
| Add `daily_spending_limit` to `student_parents` | ✅ | LOW |
| Add notification preferences to `student_parents` | ✅ | LOW |

### 1.2 Data Integrity
| Task | Status | Priority |
|------|--------|----------|
| Add unique constraints validation | ⏳ | MEDIUM |
| Add cascade delete rules review | ⏳ | MEDIUM |
| Create audit log table for critical operations | ⏳ | LOW |

---

## Phase 2: Flutter Data Layer

### 2.1 Models
| Task | Status | Priority |
|------|--------|----------|
| Create `ExamStatistics` model | ✅ | HIGH |
| Create `StudentRank` model | ✅ | HIGH |
| Create `AttendanceSummary` model | ✅ | HIGH |
| Create `Assignment` model | ✅ | HIGH |
| Create `Submission` model | ✅ | HIGH |
| Create `Announcement` model | ✅ | MEDIUM |
| Create `Thread` / `Message` models | ✅ | MEDIUM |
| Create `Invoice` / `Payment` models | ✅ | MEDIUM |
| Create `CanteenOrder` / `MenuItem` models | ⏳ | LOW |
| Create `LibraryBook` / `BookIssue` models | ⏳ | LOW |

### 2.2 Repositories
| Task | Status | Priority |
|------|--------|----------|
| Create `StudentRepository` | ✅ | HIGH |
| Create `AttendanceRepository` | ✅ | HIGH |
| Create `ExamRepository` | ✅ | HIGH |
| Create `AssignmentRepository` | ✅ | HIGH |
| Create `FeeRepository` | ✅ | MEDIUM |
| Create `MessageRepository` | ✅ | MEDIUM |
| Create `AnnouncementRepository` | ✅ | MEDIUM |
| Create `TimetableRepository` | ✅ | MEDIUM |

### 2.3 Providers (Riverpod)
| Task | Status | Priority |
|------|--------|----------|
| Create `studentsProvider` | ✅ | HIGH |
| Create `attendanceProvider` | ✅ | HIGH |
| Create `examsProvider` | ✅ | HIGH |
| Create `assignmentsProvider` | ✅ | HIGH |
| Create `feesProvider` | ✅ | MEDIUM |
| Create `messagesProvider` | ✅ | MEDIUM |
| Create `announcementsProvider` | ✅ | MEDIUM |
| Create `timetableProvider` | ✅ | MEDIUM |

---

## Phase 3: Student Portal

### 3.1 Dashboard
| Task | Status | Priority |
|------|--------|----------|
| Show today's timetable | ✅ | HIGH |
| Show attendance percentage | ✅ | HIGH |
| Show upcoming assignments | ✅ | HIGH |
| Show recent exam results | ✅ | HIGH |
| Show fee status summary | ⏳ | MEDIUM |
| Show announcements | ⏳ | MEDIUM |

### 3.2 Screens
| Task | Status | Priority |
|------|--------|----------|
| Timetable screen (weekly view) | ✅ | HIGH |
| Attendance history screen | ✅ | HIGH |
| Exam results screen with analytics | ✅ | HIGH |
| - Subject-wise marks | ✅ | HIGH |
| - Rank in class | ✅ | HIGH |
| - Comparison with class average | ✅ | HIGH |
| - Comparison with topper | ✅ | HIGH |
| - Trend chart over exams | ✅ | HIGH |
| Assignments list screen | ✅ | HIGH |
| Assignment detail screen | ✅ | HIGH |
| Submit assignment screen | ✅ | HIGH |
| Fee status screen (readonly) | ✅ | MEDIUM |
| Announcements screen | ⏳ | MEDIUM |
| Messages screen | ⏳ | MEDIUM |
| Profile screen | ⏳ | LOW |

---

## Phase 4: Parent Portal

### 4.1 Dashboard
| Task | Status | Priority |
|------|--------|----------|
| Child switcher (multiple children) | ✅ | HIGH |
| Selected child's attendance summary | ⏳ | HIGH |
| Selected child's recent results | ⏳ | HIGH |
| Fee payment status | ⏳ | HIGH |
| Upcoming events | ⏳ | MEDIUM |

### 4.2 Screens
| Task | Status | Priority |
|------|--------|----------|
| Children list/switcher widget | ✅ | HIGH |
| Child attendance detail screen | ⏳ | HIGH |
| - Monthly calendar view | ⏳ | HIGH |
| - Attendance trend chart | ⏳ | HIGH |
| Child exam results screen | ✅ | HIGH |
| - Subject-wise performance | ✅ | HIGH |
| - Child vs class average chart | ✅ | HIGH |
| - Child vs topper comparison | ✅ | HIGH |
| - Performance trend over time | ✅ | HIGH |
| Child assignments screen | ⏳ | MEDIUM |
| Fee payment screen | ✅ | HIGH |
| - View invoices | ✅ | HIGH |
| - Payment gateway integration | ✅ | HIGH |
| - Payment history | ✅ | HIGH |
| Wallet management screen | ⏳ | LOW |
| - Top-up wallet | ⏳ | LOW |
| - Set daily spending limit | ⏳ | LOW |
| - Transaction history | ⏳ | LOW |
| Library activity screen | ⏳ | LOW |
| Messages screen (teacher communication) | ⏳ | MEDIUM |
| Schedule PTM screen | ⏳ | LOW |

---

## Phase 5: Teacher Portal

### 5.1 Dashboard
| Task | Status | Priority |
|------|--------|----------|
| Today's schedule | ✅ | HIGH |
| My assigned classes list | ✅ | HIGH |
| Pending tasks (attendance, grading) | ✅ | HIGH |
| Quick action buttons | ✅ | MEDIUM |

### 5.2 Screens
| Task | Status | Priority |
|------|--------|----------|
| My timetable screen | ✅ | HIGH |
| My classes screen | ✅ | HIGH |
| Class students list screen | ✅ | HIGH |
| Mark attendance screen | ✅ | HIGH |
| - Daily attendance | ✅ | HIGH |
| - Period-wise attendance | ⏳ | MEDIUM |
| - Bulk mark present/absent | ✅ | HIGH |
| - Offline support | ⏳ | MEDIUM |
| Attendance reports screen | ⏳ | MEDIUM |
| Assignments management screen | ✅ | HIGH |
| - Create assignment | ✅ | HIGH |
| - Edit assignment | ✅ | HIGH |
| - View submissions | ✅ | HIGH |
| - Grade submission | ✅ | HIGH |
| - Return with feedback | ✅ | HIGH |
| Marks entry screen | ✅ | HIGH |
| - Bulk marks entry | ✅ | HIGH |
| - Import from CSV | ⏳ | LOW |
| Class analytics screen | ✅ | MEDIUM |
| - Class average | ✅ | MEDIUM |
| - Highest/lowest marks | ✅ | MEDIUM |
| - Pass/fail distribution | ✅ | MEDIUM |
| - Weak students list | ✅ | MEDIUM |
| Messages screen | ⏳ | MEDIUM |
| - Message to parents | ⏳ | MEDIUM |
| - Class broadcast | ⏳ | MEDIUM |
| Announcements (class-level) | ⏳ | MEDIUM |

---

## Phase 6: Admin Portal

### 6.1 Dashboard
| Task | Status | Priority |
|------|--------|----------|
| Total students/teachers/staff counts | ✅ | HIGH |
| Today's attendance percentage | ✅ | HIGH |
| Fee collection summary | ✅ | HIGH |
| Recent activity feed | ✅ | MEDIUM |
| Quick action buttons | ✅ | MEDIUM |

### 6.2 Student Management
| Task | Status | Priority |
|------|--------|----------|
| Students list screen (filterable) | ✅ | HIGH |
| Add student screen | ✅ | HIGH |
| Edit student screen | ✅ | HIGH |
| Student detail screen | ✅ | HIGH |
| Bulk student import (CSV) | ⏳ | MEDIUM |
| Student promotion wizard | ⏳ | HIGH |
| Change section/class | ⏳ | HIGH |
| Deactivate student | ✅ | MEDIUM |

### 6.3 Staff Management
| Task | Status | Priority |
|------|--------|----------|
| Staff list screen | ✅ | HIGH |
| Add staff screen | ✅ | HIGH |
| Edit staff screen | ✅ | HIGH |
| Assign teacher to class/subject | ⏳ | HIGH |
| Staff roles management | ⏳ | MEDIUM |

### 6.4 Parent Management
| Task | Status | Priority |
|------|--------|----------|
| Parents list screen | ⏳ | MEDIUM |
| Add parent screen | ⏳ | MEDIUM |
| Link parent to student | ⏳ | MEDIUM |

### 6.5 Academic Configuration
| Task | Status | Priority |
|------|--------|----------|
| Academic years management | ✅ | HIGH |
| Terms management | ✅ | HIGH |
| Classes management | ✅ | HIGH |
| Sections management | ✅ | HIGH |
| Subjects management | ✅ | HIGH |
| Class-subject mapping | ⏳ | HIGH |
| Grading scales configuration | ✅ | MEDIUM |

### 6.6 Exam Management
| Task | Status | Priority |
|------|--------|----------|
| Exams list screen | ✅ | HIGH |
| Create exam screen | ✅ | HIGH |
| Exam subjects configuration | ⏳ | HIGH |
| Publish results | ✅ | HIGH |
| Generate report cards (PDF) | ⏳ | MEDIUM |

### 6.7 Fee Management
| Task | Status | Priority |
|------|--------|----------|
| Fee heads management | ✅ | HIGH |
| Fee structure management | ✅ | HIGH |
| Generate invoices | ✅ | HIGH |
| Record offline payment | ✅ | HIGH |
| Fee reports | ✅ | MEDIUM |
| Fee reminders | ✅ | MEDIUM |

### 6.8 School Analytics
| Task | Status | Priority |
|------|--------|----------|
| Attendance analytics | ⏳ | MEDIUM |
| Exam performance analytics | ⏳ | MEDIUM |
| Fee collection analytics | ⏳ | MEDIUM |
| Export reports (PDF/Excel) | ⏳ | LOW |

### 6.9 Communication
| Task | Status | Priority |
|------|--------|----------|
| School-wide announcements | ⏳ | HIGH |
| Create announcement screen | ✅ | MEDIUM |
| Target audience selection | ✅ | MEDIUM |
| Schedule announcement | ⏳ | LOW |
| Notification integration | ⏳ | MEDIUM |

---

## Phase 7: Super Admin Portal

### 7.1 Screens
| Task | Status | Priority |
|------|--------|----------|
| Tenants list screen | ✅ | HIGH |
| Create tenant screen | ✅ | HIGH |
| Tenant details screen | ✅ | HIGH |
| Suspend/activate tenant | ✅ | HIGH |
| Tenant metrics dashboard | ✅ | MEDIUM |
| Subscription management | ✅ | LOW |

---

## Phase 8: Shared Components

### 8.1 Widgets
| Task | Status | Priority |
|------|--------|----------|
| Role-based navigation shell | ✅ | HIGH |
| Stats card widget | ✅ | - |
| Glass card widget | ✅ | - |
| Chart widgets (bar, line, pie) | ✅ | HIGH |
| Calendar widget | ⏳ | MEDIUM |
| Data table widget | ⏳ | HIGH |
| Search/filter widget | ✅ | HIGH |
| Empty state widget | ✅ | LOW |
| Loading skeleton widget | ⏳ | LOW |
| Error state widget | ✅ | LOW |

### 8.2 Real-time Features
| Task | Status | Priority |
|------|--------|----------|
| Attendance real-time updates | ✅ | HIGH |
| New announcement notifications | ⏳ | MEDIUM |
| Message notifications | ⏳ | MEDIUM |
| Fee payment confirmation | ⏳ | MEDIUM |

### 8.3 Offline Support
| Task | Status | Priority |
|------|--------|----------|
| Attendance offline marking | ⏳ | HIGH |
| Sync queue management | ⏳ | HIGH |
| Conflict resolution | ⏳ | MEDIUM |

---

## Implementation Order

1. **Database migrations** (analytics views, functions, RLS)
2. **Data models and repositories**
3. **Riverpod providers**
4. **Student portal** (highest user count)
5. **Teacher portal** (daily operations)
6. **Parent portal** (engagement)
7. **Admin portal** (management)
8. **Super admin** (platform ops)

---

## Files to Create/Modify

### SQL Migrations
- [ ] `supabase/migrations/00007_analytics_views.sql`

### Flutter Models
- [ ] `lib/data/models/exam_statistics.dart`
- [ ] `lib/data/models/assignment.dart`
- [ ] `lib/data/models/submission.dart`
- [ ] `lib/data/models/announcement.dart`
- [ ] `lib/data/models/message.dart`
- [ ] `lib/data/models/invoice.dart`
- [ ] `lib/data/models/timetable.dart`

### Flutter Repositories
- [ ] `lib/data/repositories/student_repository.dart`
- [ ] `lib/data/repositories/attendance_repository.dart`
- [ ] `lib/data/repositories/exam_repository.dart`
- [ ] `lib/data/repositories/assignment_repository.dart`
- [ ] `lib/data/repositories/fee_repository.dart`
- [ ] `lib/data/repositories/message_repository.dart`
- [ ] `lib/data/repositories/timetable_repository.dart`

### Flutter Providers
- [ ] `lib/features/students/providers/students_provider.dart`
- [ ] `lib/features/attendance/providers/attendance_provider.dart`
- [ ] `lib/features/exams/providers/exams_provider.dart`
- [ ] `lib/features/assignments/providers/assignments_provider.dart`
- [ ] `lib/features/fees/providers/fees_provider.dart`
- [ ] `lib/features/messaging/providers/messages_provider.dart`
- [ ] `lib/features/timetable/providers/timetable_provider.dart`

### Flutter Screens (Student)
- [ ] `lib/features/student/presentation/screens/student_timetable_screen.dart`
- [ ] `lib/features/student/presentation/screens/student_attendance_screen.dart`
- [ ] `lib/features/student/presentation/screens/student_results_screen.dart`
- [ ] `lib/features/student/presentation/screens/student_assignments_screen.dart`
- [ ] `lib/features/student/presentation/screens/submit_assignment_screen.dart`

### Flutter Screens (Parent)
- [ ] `lib/features/parent/presentation/screens/child_switcher_widget.dart`
- [ ] `lib/features/parent/presentation/screens/child_attendance_screen.dart`
- [ ] `lib/features/parent/presentation/screens/child_results_screen.dart`
- [ ] `lib/features/parent/presentation/screens/fee_payment_screen.dart`

### Flutter Screens (Teacher)
- [ ] `lib/features/teacher/presentation/screens/my_classes_screen.dart`
- [ ] `lib/features/teacher/presentation/screens/class_students_screen.dart`
- [ ] `lib/features/teacher/presentation/screens/create_assignment_screen.dart`
- [ ] `lib/features/teacher/presentation/screens/grade_submissions_screen.dart`
- [ ] `lib/features/teacher/presentation/screens/class_analytics_screen.dart`

### Flutter Screens (Admin)
- [ ] `lib/features/admin/presentation/screens/student_management_screen.dart`
- [ ] `lib/features/admin/presentation/screens/add_student_screen.dart`
- [ ] `lib/features/admin/presentation/screens/staff_management_screen.dart`
- [ ] `lib/features/admin/presentation/screens/academic_config_screen.dart`
- [ ] `lib/features/admin/presentation/screens/exam_management_screen.dart`
- [ ] `lib/features/admin/presentation/screens/fee_management_screen.dart`
- [ ] `lib/features/admin/presentation/screens/announcements_screen.dart`

---

*Last Updated: December 6, 2025*
