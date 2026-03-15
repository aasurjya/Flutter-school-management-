# Student

## System Role

- **Internal key:** `student`
- **Portal:** `/student`
- **Scope:** Own records only within their tenant
- **Business meaning:** Enrolled learner

## Responsibility

Students are the primary end-users of the academic system. They view their own academic data, submit assignments, take exams, check attendance, and communicate with teachers.

## Permissions

### Dashboard (Own)
- View personal dashboard with upcoming classes, assignments, and announcements
- Quick access to attendance, results, and timetable

### Attendance (Own — view only)
- View own attendance history and percentage
- Cannot mark or modify attendance

### Exams & Results (Own — view only)
- View exam schedules
- View own marks and grades
- View result analysis and trends
- Take online exams/quizzes (time-limited, client-side timer)

### Assignments & Homework (Own)
- View assigned homework and assignments
- Submit work before deadlines
- View grades and feedback on submissions
- Cannot create assignments

### Timetable (Own — view only)
- View own class timetable

### Messages (Own)
- Send and receive messages to/from teachers
- Participate in class discussion forums
- Cannot initiate bulk messages

### Fees (Own — view only)
- View own fee status and outstanding balances
- View payment history
- Access payment gateway for online payments

### LMS (Own)
- Access enrolled courses
- View course content and modules
- Participate in discussion forums
- Track own progress and earn certificates

### Report Cards (Own — view only)
- View own report cards
- Download/print report cards

### Library (Own)
- Browse book catalog
- View borrowing history
- Request books

### Canteen (Own)
- View canteen menu
- Place orders and manage wallet
- View order history

### Transport (Own — view only)
- View own bus route and schedule
- Track bus location (if live tracking enabled)

### Hostel (Own — view only)
- View own room allocation
- View hostel rules and announcements

### Gamification (Own)
- View own achievements, badges, and points
- View class/school leaderboards

### QR / Digital ID (Own)
- View and display own digital ID card
- Use QR code for attendance/identification

### Health Records (Own — view only)
- View own health profile

### Certificates (Own — view only)
- View and download issued certificates

### Notice Board (View)
- View school notices and announcements

### Calendar (View)
- View school calendar, events, and holidays

### Emergency (View)
- View emergency protocols and alerts

### Offline Sync (View)
- Access cached data when offline

## Account Creation

| Attribute | Detail |
|-----------|--------|
| **Who creates** | `principal`, `tenant_admin`, or `super_admin` |
| **Creation path** | Admin Dashboard → Student Management → Add Student |
| **Fields filled by admin** | Full Name, optional Phone, Class/Section |
| **Username (auto-generated)** | `{firstname}.{lastname}@{tenantslug}.edu` |
| **Password (auto-generated)** | 10-char random: 1 uppercase + 1 lowercase + 1 digit + 1 special (`@#$!`) |

### Where credentials appear

1. **In the student creation form** (`add_student_form.dart`) — username builds live as admin types; password shown masked with show/copy/regenerate controls
2. **In `CredentialDisplayDialog`** — displayed immediately after submission, non-dismissible, with a "Copy All" button

```
Example:
  Full Name:  Priya Sharma
  Username:   priya.sharma@greenview.edu
  Password:   Tz5#wLn8Qv
```

The admin **must copy and hand these credentials to the student** (or to their parent) before dismissing the dialog.

---

## First-Login UX Journey

```
[Admin creates Student account]
       ↓
[Admin copies username + password from CredentialDisplayDialog]
       ↓
[Admin hands credentials to Student (or parent)]
       ↓
[Student opens app → Login screen]
  Email:    priya.sharma@greenview.edu
  Password: Tz5#wLn8Qv
       ↓
[App checks: profile_complete = false]
       ↓
[Redirected to Profile Setup → /profile-setup/student]
  Student fills in:
  - Profile photo
  - Date of birth
  - Gender
  - Blood group
  - Home address
  - Medical conditions (optional)
  - Emergency contact name + phone
       ↓
[Student taps "Save & Continue"]
       ↓
[App sets profile_complete = true]
       ↓
[Redirected to /student dashboard]
       ↓
[All subsequent logins → straight to /student dashboard]
```

---

## Restrictions

- **Cannot** access any other student's data
- **Cannot** create, edit, or delete any records (except own submissions)
- **Cannot** mark attendance
- **Cannot** access admin, teacher, or staff interfaces
- **Cannot** view fee structures or financial configurations
- **Cannot** access discipline records (own incidents visible to parents only)
- **Cannot** access AI insights, admission, HR, inventory, or communication modules
- **Cannot** manage any operational modules (library, transport, hostel, canteen)

## Data Boundary

```
student
  +-- Read/write: own submissions, canteen orders, messages
  +-- Read only: own attendance, marks, fees, timetable, report cards
  +-- No access: other students' data, admin functions, staff data
  +-- Linked: parent can view this student's data via student_parents
```

## Key Code Paths

| What | Where |
|------|-------|
| Route guard | `app_router.dart:670-680` |
| Dashboard | `student_dashboard_screen.dart` |
| Attendance | `student_attendance_screen.dart` |
| Fees | `student_fees_screen.dart` |
| Timetable | `student_timetable_screen.dart` |
| Bottom nav | `main_shell.dart:202-228` (Dashboard, Attendance, Results, Messages) |
