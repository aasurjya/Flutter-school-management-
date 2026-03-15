# Parent

## System Role

- **Internal key:** `parent`
- **Portal:** `/parent`
- **Scope:** Linked children's records only (via `student_parents` table)
- **Business meaning:** Guardian with visibility into their children's school life

## Responsibility

Parents monitor their children's academic progress, communicate with teachers, pay fees, and stay informed about school events. A parent can be linked to multiple children (child switcher UI).

## Permissions

### Dashboard (Own)
- View parent dashboard with summaries for each linked child
- Switch between children using the child switcher widget
- View quick stats: attendance, grades, upcoming events, fee status

### Child's Attendance (View — linked children)
- View attendance history and percentage for each child
- Cannot mark attendance

### Child's Results & Grades (View — linked children)
- View exam results, marks, and grade trends
- View report cards
- Access result analysis

### Child's Homework (View — linked children)
- Track homework assignments and due dates
- View submission status and teacher feedback
- Homework tracker with calendar view

### Fees & Payments (Own — linked children)
- View fee status and outstanding balances per child
- Make online payments via payment gateway
- View payment receipts and history

### Messages (Own)
- Send and receive messages to/from teachers
- Communicate with school administration
- Cannot initiate bulk messages

### AI Insights (View — linked children)
- View AI-generated insights about their children
- Receive early warning notifications
- View risk indicators and recommendations

### Discipline (View — linked children)
- View behavioral incident reports for their children
- View recognition and positive behavior records
- Cannot create or modify discipline records

### PTM (Own)
- Book parent-teacher meeting slots
- View meeting history and notes

### Child Insights (View)
- Access dedicated child insights screen with learning analytics
- View parent digest reports

### Canteen (Own — linked children)
- View canteen menu
- Top up child's wallet
- View child's order history

### Library (Own — linked children)
- View child's borrowing history
- Track overdue books

### Transport (Own — linked children)
- View child's bus route and schedule
- Track bus location

### Hostel (Own — linked children)
- View child's room allocation

### Health Records (Own — linked children)
- View child's health profile

### Certificates (Own — linked children)
- View and download child's certificates

### Gamification (View)
- View child's achievements and leaderboard position

### Notice Board (View)
- View school notices and announcements

### Calendar (View)
- View school calendar, events, and holidays

### Emergency (View)
- View emergency protocols and alerts

### Offline Sync (View)
- Access cached data when offline

## Restrictions

- **Cannot** access data for students not linked to them
- **Cannot** create, edit, or delete any school records
- **Cannot** access admin, teacher, or staff interfaces
- **Cannot** mark attendance or enter grades
- **Cannot** access admission, HR, inventory, or communication modules
- **Cannot** manage any operational modules
- **Cannot** view other parents' data

## Account Creation

| Attribute | Detail |
|-----------|--------|
| **Who creates** | `principal`, `tenant_admin`, or `super_admin` |
| **Creation path** | Student Management → Student Detail → Link Parent → Add New Parent |
| **Fields filled by admin** | Full Name, optional Phone, Relationship to child |
| **Username (auto-generated)** | `{firstname}.{lastname}@{tenantslug}.edu` |
| **Password (auto-generated)** | 10-char random: 1 uppercase + 1 lowercase + 1 digit + 1 special (`@#$!`) |

### Where credentials appear

1. **In the parent link dialog** (`parent_link_dialog.dart`) — username builds live as admin types; password shown masked with show/copy/regenerate controls
2. **In `CredentialDisplayDialog`** — displayed immediately after submission, non-dismissible, with a "Copy All" button

```
Example:
  Full Name:  Ravi Sharma
  Username:   ravi.sharma@greenview.edu
  Password:   Qp9$kWn3Lv
```

The admin **must copy and hand these credentials to the parent** before dismissing the dialog. Parents are then linked to their child via the `student_parents` table.

---

## First-Login UX Journey

```
[Admin creates Parent account and links to child]
       ↓
[Admin copies username + password from CredentialDisplayDialog]
       ↓
[Admin hands credentials to Parent]
       ↓
[Parent opens app → Login screen]
  Email:    ravi.sharma@greenview.edu
  Password: Qp9$kWn3Lv
       ↓
[App checks: profile_complete = false]
       ↓
[Redirected to Profile Setup → /profile-setup/parent]
  Parent fills in:
  - Profile photo
  - Phone number
  - Occupation
  - Home address
  - Relationship to child (Father / Mother / Guardian / Other)
       ↓
[Parent taps "Save & Continue"]
       ↓
[App sets profile_complete = true]
       ↓
[Redirected to /parent dashboard — shows linked child's data]
       ↓
[All subsequent logins → straight to /parent dashboard]
```

> If a parent has multiple children, the child switcher widget appears on the dashboard and all child-scoped screens.

---

## Multi-Child Support

Parents can be linked to multiple students via the `student_parents` table. The UI provides a child switcher (`child_switcher.dart`) to toggle between children's data.

## Data Boundary

```
parent
  +-- Read only: linked children's attendance, marks, fees, report cards
  +-- Read/write: own messages, fee payments, PTM bookings
  +-- No access: unlinked students, admin functions, staff data
  +-- Linked via: student_parents (student_id, parent_id)
```

## Key Code Paths

| What | Where |
|------|-------|
| Route guard | `app_router.dart:680-690` |
| Dashboard | `parent_dashboard_screen.dart` |
| Child results | `child_results_screen.dart` |
| Homework tracker | `homework_tracker_screen.dart` |
| Teacher messages | `teacher_message_screen.dart` |
| Child switcher | `child_switcher.dart` |
| Child insights | `child_insights_screen.dart` |
| Bottom nav | `main_shell.dart:230-256` (Dashboard, Attendance, Fees, Messages) |
