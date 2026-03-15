# School Admin (`tenant_admin`)

## System Role

- **Internal key:** `tenant_admin`
- **Portal:** `/admin` (shared with principal)
- **Scope:** Single tenant (their school)
- **Business meaning:** Day-to-day school administrator

## Responsibility

The school admin handles the daily operations of the school: managing teachers, students, parents, classes, schedules, fees, and communication. They are the operational backbone — the principal delegates most day-to-day work to them.

## Permissions

### Student Management (Full)
- Add, edit, and remove students
- Manage enrollments and class assignments
- Link students to parents
- View student profiles, portfolios, digital IDs
- Access student health records

### Teacher Management (Manage)
- Create and manage `teacher` accounts
- Assign teachers to classes, sections, and subjects
- View teacher schedules and workload

### Operational Staff Management (Manage)
- Create and manage: `accountant`, `librarian`, `transport_manager`, `hostel_warden`, `canteen_staff`, `receptionist`
- Cannot manage `principal` or `tenant_admin` accounts

### Academic Operations (Full)
- Configure classes, sections, subjects, timetables
- Manage exam schedules and grading
- Oversee syllabus and lesson plans
- Manage LMS courses and content

### Attendance (Full)
- View attendance reports for all students and teachers
- Configure attendance rules and policies
- Mark attendance when needed (backup for teachers)

### Fees & Finance (Full)
- Configure fee heads and structures
- Generate and manage invoices
- View payment history and outstanding balances
- Access fee reports

### Admissions (Full)
- Manage the full admission pipeline
- Configure admission settings
- Process applications and interviews

### Communication (Full)
- Send school announcements and notices
- Configure bulk notifications (SMS/Email/WhatsApp)
- Manage templates and auto-rules

### Discipline (Full)
- Record and manage behavioral incidents
- Configure behavior settings and recognition programs
- Escalate to principal when needed

### AI Insights (Full)
- View student risk dashboards
- Access early warning alerts
- View class intelligence reports

### Calendar & Events (Full)
- Create and manage events, holidays, PTM schedules

### Transport, Hostel, Canteen, Library (Full)
- Full management of all operational modules within their scope

### Visitor Management (Full)
- Manage visitor logs and pre-registrations

### Gamification (Full)
- Configure achievements and leaderboards

## Account Creation

| Attribute | Detail |
|-----------|--------|
| **Who creates** | `principal` or `super_admin` |
| **Creation path** | Staff Management → Add Staff → School Admin (tenant_admin) |
| **Fields filled by admin** | Full Name, optional Phone |
| **Username (auto-generated)** | `{firstname}.{lastname}@{tenantslug}.edu` |
| **Password (auto-generated)** | 10-char random: 1 uppercase + 1 lowercase + 1 digit + 1 special (`@#$!`) |

### Where credentials appear

1. **In the creation sheet** (`add_staff_sheet.dart`) — username builds live as admin types; password shown masked with show/copy/regenerate controls
2. **In `CredentialDisplayDialog`** — displayed immediately after submission, non-dismissible, with a "Copy All" button

```
Example:
  Full Name:  Michael Chen
  Username:   michael.chen@greenview.edu
  Password:   Bm7!nRp2Yz
```

The admin **must copy these credentials and hand them to the school admin** before dismissing the dialog.

---

## First-Login UX Journey

```
[principal creates School Admin account]
       ↓
[principal copies username + password from CredentialDisplayDialog]
       ↓
[principal hands credentials to School Admin]
       ↓
[School Admin opens app → Login screen]
  Email:    michael.chen@greenview.edu
  Password: Bm7!nRp2Yz
       ↓
[App checks: profile_complete = false]
       ↓
[Redirected to Profile Setup → /profile-setup/admin]
  School Admin fills in:
  - Profile photo
  - Phone number
  - Date of birth
  - Designation (e.g. "School Administrator")
  - Short bio
       ↓
[School Admin taps "Save & Continue"]
       ↓
[App sets profile_complete = true]
       ↓
[Redirected to /admin dashboard]
       ↓
[All subsequent logins → straight to /admin dashboard]
```

---

## Restrictions

- **Cannot** create `super_admin`, `principal`, or `tenant_admin` accounts
- **Cannot** manage principal-level or platform-level accounts
- **Cannot** access HR/Payroll module (principal-only)
- **Cannot** access other tenants' data
- **Cannot** override principal's decisions on discipline escalations

## Data Boundary

```
tenant_admin
  +-- Full read/write: most data within their tenant
  +-- Cannot access: HR/Payroll, other tenants, platform settings
  +-- Staff creation: teacher + all operational staff
  +-- Cannot manage: principal, tenant_admin, super_admin accounts
```

## Key Code Paths

| What | Where |
|------|-------|
| Route guard | `app_router.dart:637-660` |
| Dashboard | `admin_dashboard_screen.dart` |
| Staff management | `staff_management_screen.dart:31` (`canManageAdmins = false`) |
| Staff creation | `add_staff_sheet.dart:61-63` (no admin roles) |
| Bottom nav | `main_shell.dart:141-170` (Dashboard, Students, Attendance, Fees) |
