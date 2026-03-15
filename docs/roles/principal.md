# Principal

## System Role

- **Internal key:** `principal`
- **Portal:** `/admin` (shared with tenant_admin)
- **Scope:** Single tenant (their school)
- **Business meaning:** School Super Admin — highest authority within a school

## Responsibility

The principal is the top-level authority inside a school. They oversee all academic and administrative operations, manage school admins and staff, and have visibility into every aspect of their school.

## Permissions

### Staff Management (Full)
- Create and manage `tenant_admin` accounts
- Create and manage `teacher` accounts
- Create and manage all operational staff: `accountant`, `librarian`, `transport_manager`, `hostel_warden`, `canteen_staff`, `receptionist`
- View staff directory, contracts, attendance
- Approve/reject staff leave requests

### Student Management (Full)
- View all student records, enrollments, and profiles
- Add, edit, and remove students
- Manage student-parent linkages
- View student portfolios and digital IDs
- Access student health records

### Academic Operations (Full)
- Configure academic years, terms, classes, sections, subjects
- Manage teacher assignments (which teacher teaches what)
- Oversee exam schedules, grading scales, report card templates
- Review and approve syllabus/lesson plans
- Monitor timetable creation and conflicts
- Access LMS course management

### Financial Operations (Full)
- Configure fee heads and fee structures
- View all invoices, payments, and outstanding balances
- Access financial reports and summaries
- Oversee HR payroll and salary disbursement

### Admissions (Full)
- Manage admission pipeline: inquiries, applications, interviews
- Configure admission settings and workflows
- View admission analytics and conversion rates

### Communication (Full)
- Send school-wide announcements and notices
- Configure bulk notification campaigns (SMS/Email/WhatsApp)
- Manage communication templates and auto-rules
- Access all message threads (oversight)

### Discipline & Behavior (Full)
- View and manage behavioral incidents
- Configure behavior plans and recognition programs
- Manage detention records

### Monitoring & Analytics
- Access admin dashboard with school-wide KPIs
- View AI insights: student risk analysis, early warnings, class intelligence
- Access attendance analytics and trends
- View parent engagement metrics

### Transport, Hostel, Canteen, Library (Full)
- Full oversight and configuration of all operational modules
- Can create routes, allocate rooms, manage menus, catalog books

### Calendar & Events (Full)
- Create and manage school events, holidays, PTM schedules
- Configure academic calendar

### Visitor Management (Full)
- View visitor logs and pre-registrations
- Configure visitor policies

## Account Creation

| Attribute | Detail |
|-----------|--------|
| **Who creates** | `super_admin` (Platform Admin) |
| **Creation path** | Super Admin → Tenant Detail → Users tab → Add User → Principal |
| **Fields filled by admin** | Full Name, optional Phone |
| **Username (auto-generated)** | `{firstname}.{lastname}@{tenantslug}.edu` |
| **Password (auto-generated)** | 10-char random: 1 uppercase + 1 lowercase + 1 digit + 1 special (`@#$!`) |

### Where credentials appear

1. **In the creation sheet** — username builds live as the admin types the name; password shown masked with show/copy/regenerate controls
2. **In `CredentialDisplayDialog`** — displayed immediately after submission, non-dismissible, with a "Copy All" button

```
Example:
  Full Name:  Sarah Johnson
  Username:   sarah.johnson@greenview.edu
  Password:   Kx3@mPq!7z
```

The admin **must copy these credentials and hand them to the principal** (via email, SMS, or in person) before the dialog is dismissed.

---

## First-Login UX Journey

```
[super_admin creates Principal account]
       ↓
[super_admin copies username + password from CredentialDisplayDialog]
       ↓
[super_admin hands credentials to Principal]
       ↓
[Principal opens app → Login screen]
  Email:    sarah.johnson@greenview.edu
  Password: Kx3@mPq!7z
       ↓
[App checks: profile_complete = false]
       ↓
[Redirected to Profile Setup → /profile-setup/admin]
  Principal fills in:
  - Profile photo
  - Phone number
  - Date of birth
  - Designation (e.g. "School Principal")
  - Short bio
       ↓
[Principal taps "Save & Continue"]
       ↓
[App sets profile_complete = true]
       ↓
[Redirected to /admin dashboard]
       ↓
[All subsequent logins → straight to /admin dashboard]
```

---

## Restrictions

- **Cannot** create `super_admin` accounts
- **Cannot** create another `principal` account
- **Cannot** access other tenants' data
- **Cannot** manage platform-level settings (subscriptions, tenant config)

## Data Boundary

```
principal
  +-- Full read/write: all data within their tenant
  +-- Cannot access: other tenants, platform settings
  +-- Staff creation: tenant_admin + all below
```

## Differences from tenant_admin

| Capability | principal | tenant_admin |
|-----------|:-:|:-:|
| Create `tenant_admin` | Yes | No |
| Staff management tabs | teacher, tenant_admin, other | teacher, other |
| HR & Payroll access | Full | No |
| Final authority on discipline | Yes | Escalated |

## Key Code Paths

| What | Where |
|------|-------|
| Route guard | `app_router.dart:637-660` (same as tenant_admin) |
| Dashboard | `admin_dashboard_screen.dart` |
| Staff management | `staff_management_screen.dart:31` (`canManageAdmins = true`) |
| Staff creation | `add_staff_sheet.dart:57-59` (includes tenant_admin) |
| Bottom nav | `main_shell.dart:141-170` (Dashboard, Students, Attendance, Fees) |
