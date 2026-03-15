# Teacher

## System Role

- **Internal key:** `teacher`
- **Portal:** `/teacher`
- **Scope:** Assigned classes, sections, and subjects within their tenant
- **Business meaning:** Educator responsible for instruction, assessment, and classroom management

## Responsibility

Teachers are the academic core of the school. They manage their assigned classes — taking attendance, creating assignments, entering grades, tracking student progress, and communicating with students and parents.

## Permissions

### Attendance (Manage — own classes)
- Mark daily attendance for assigned classes/sections
- View attendance history for their students
- Cannot modify attendance policies or rules

### Exams & Grading (Manage — own subjects)
- Enter marks for assigned subjects
- Access gradebook for their classes
- View exam schedules
- Cannot create exam schedules (admin function)

### Assignments & Homework (Manage — own classes)
- Create, edit, and delete assignments for their classes
- Review and grade student submissions
- Set due dates and rubrics
- Track submission status

### Timetable (Own — view only)
- View their own teaching schedule
- Cannot modify timetable (admin function)

### Messages (Manage)
- Send and receive messages to/from students and parents
- Communicate with admins and other teachers
- Participate in message threads

### Student Data (View — own classes)
- View student profiles, attendance, and grades for assigned students
- Cannot edit student records (admin function)
- View student portfolios

### Syllabus & Lesson Plans (Manage — own subjects)
- Create and update lesson plans for assigned subjects
- Track topic coverage progress
- Link resources to syllabus topics

### LMS (Manage — own courses)
- Create course content and modules
- Manage discussion forums
- Track student progress through courses

### Report Cards (Manage — own subjects)
- Enter grades and remarks for their subjects
- View generated report cards
- Cannot configure report card templates (admin function)

### Discipline (Manage)
- Report behavioral incidents
- View discipline records for their students
- Cannot configure behavior policies (admin function)

### AI Insights (View)
- View AI-generated insights about their students
- Access class intelligence dashboard
- View student risk indicators

### PTM (Manage)
- View and manage parent-teacher meeting slots
- Record meeting notes and outcomes

### Leave (Own)
- Apply for leave
- View leave balance and history
- Cannot approve others' leave

### Calendar & Events (View)
- View school calendar, events, and holidays
- Cannot create events (admin function)

### Library, Transport, Hostel, Canteen (View)
- View information in these modules
- Cannot manage or configure

### Notice Board (View)
- View school notices and announcements

### QR Scan / Digital ID (View)
- Scan student QR codes for attendance or identification

### Gamification (View)
- View student achievements and leaderboards

### Emergency (View)
- View emergency protocols and alerts

## Account Creation

| Attribute | Detail |
|-----------|--------|
| **Who creates** | `principal`, `tenant_admin`, or `super_admin` |
| **Creation path** | Staff Management → Add Staff → Teacher |
| **Fields filled by admin** | Full Name, optional Phone |
| **Username (auto-generated)** | `{firstname}.{lastname}@{tenantslug}.edu` |
| **Password (auto-generated)** | 10-char random: 1 uppercase + 1 lowercase + 1 digit + 1 special (`@#$!`) |

### Where credentials appear

1. **In the creation sheet** (`add_staff_sheet.dart`) — username builds live as admin types; password shown masked with show/copy/regenerate controls
2. **In `CredentialDisplayDialog`** — displayed immediately after submission, non-dismissible, with a "Copy All" button

```
Example:
  Full Name:  John Smith
  Username:   john.smith@greenview.edu
  Password:   Kx3@mPq!7z
```

The admin **must copy and hand these credentials to the teacher** before dismissing the dialog.

---

## First-Login UX Journey

```
[Admin creates Teacher account]
       ↓
[Admin copies username + password from CredentialDisplayDialog]
       ↓
[Admin hands credentials to Teacher]
       ↓
[Teacher opens app → Login screen]
  Email:    john.smith@greenview.edu
  Password: Kx3@mPq!7z
       ↓
[App checks: profile_complete = false]
       ↓
[Redirected to Profile Setup → /profile-setup/teacher]
  Teacher fills in:
  - Profile photo
  - Phone number
  - Date of birth
  - Gender
  - Home address
  - Highest qualification
  - Years of experience
  - Subjects they teach
       ↓
[Teacher taps "Save & Continue"]
       ↓
[App sets profile_complete = true]
       ↓
[Redirected to /teacher dashboard]
       ↓
[All subsequent logins → straight to /teacher dashboard]
```

---

## Restrictions

- **Cannot** create any user accounts
- **Cannot** access admin dashboard or admin-level configurations
- **Cannot** view or manage fees, payments, or financial data
- **Cannot** access HR, payroll, or staff management
- **Cannot** access data for students outside their assigned classes
- **Cannot** modify school-wide settings (academic calendar, grading scales, etc.)
- **Cannot** access admission pipeline

## Data Boundary

```
teacher
  +-- Read/write: attendance, grades, assignments for assigned classes
  +-- Read only: student profiles for assigned students
  +-- Own data: timetable, leave, messages
  +-- No access: fees, HR, admissions, other teachers' classes
```

## Key Code Paths

| What | Where |
|------|-------|
| Route guard | `app_router.dart:660-670` |
| Dashboard | `teacher_dashboard_screen.dart` |
| My classes | `my_classes_screen.dart` |
| Gradebook | `assignments_management_screen.dart` |
| Bottom nav | `main_shell.dart:172-200` (Dashboard, Attendance, Exams, Messages) |
| Timetable | `teacher_timetable_screen.dart` |
