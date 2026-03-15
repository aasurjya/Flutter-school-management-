# Roles & Permissions Overview

This folder documents the role hierarchy, permissions, and feature access matrix for the School Management SaaS platform.

## UX Journey: Schools → Roles → Users

This section describes the full end-to-end flow from platform setup to a user's first login.

### Phase 1 — Platform Admin Onboards a School

```
[Platform Admin logs in → /super-admin]
       ↓
[Creates a new tenant: school name, slug, plan]
  Tenant slug example: "greenview"
       ↓
[Creates the first Principal account for that school]
  Admin fills: Full Name, Email/Phone (optional)
  App generates credentials live:
    Username:  sarah.johnson@greenview.edu
    Password:  Kx3@mPq!7z  (10-char, shown in form + CredentialDisplayDialog)
       ↓
[Admin copies credentials → hands to Principal]
```

### Phase 2 — Principal / School Admin Populates the School

```
[Principal logs in with generated credentials]
  → Profile Setup (/profile-setup/admin)
  → Reaches /admin dashboard
       ↓
[Creates School Admin (tenant_admin) accounts]
  → Same credential generation flow
       ↓
[School Admin creates Teachers, Students, Parents, Operational Staff]
  Each creation:
    - Fills name + optional phone
    - App generates: firstname.lastname@greenview.edu + 10-char password
    - CredentialDisplayDialog shown (non-dismissible, copy-all button)
    - Admin hands credentials to user
```

### Phase 3 — Every User's First Login

```
[User opens app → Login screen]
  Email:    john.smith@greenview.edu
  Password: (generated password handed by admin)
       ↓
[App checks: profile_complete = false]
       ↓
[Redirected to role-specific Profile Setup screen]
  Teacher  → /profile-setup/teacher  (photo, DOB, gender, qualification, subjects…)
  Student  → /profile-setup/student  (photo, DOB, blood group, emergency contact…)
  Parent   → /profile-setup/parent   (photo, phone, occupation, relationship to child…)
  Staff    → /profile-setup/staff    (photo, phone, DOB, department, address…)
  Admin/Principal → /profile-setup/admin (photo, phone, designation, bio…)
       ↓
[User taps "Save & Continue"]
       ↓
[App sets profile_complete = true in DB]
       ↓
[Redirected to role-specific dashboard]
  principal / tenant_admin → /admin
  teacher                  → /teacher
  student                  → /student
  parent                   → /parent
  operational staff        → /staff/<role>
       ↓
[All subsequent logins → straight to dashboard (profile_complete = true)]
```

### Credential Generation Rules (from `credential_generator.dart`)

| Field | Format | Example |
|-------|--------|---------|
| Username (Email) | `{firstname}.{lastname}@{tenantslug}.edu` | `john.smith@greenview.edu` |
| Password | 10-char: 1 uppercase + 1 lowercase + 1 digit + 1 special (`@#$!`) | `Kx3@mPq!7z` |

Credentials appear **twice**:
1. **Live in the creation sheet** — username auto-builds as admin types the name; password shown masked with show/copy/regenerate controls
2. **In `CredentialDisplayDialog`** — shown immediately after submission, non-dismissible, with a "Copy All" button

---

## Role Hierarchy

```
Platform Level
  super_admin (Platform Admin)
    |
School Level
    principal (School Super Admin)
      |
      tenant_admin (School Admin)
        |
    +---+---+---+---+---+---+---+---+
    |   |   |   |   |   |   |   |   |
  teacher accountant librarian transport_manager hostel_warden canteen_staff receptionist
    |
  student <---> parent (linked via student_parents)
```

## Role Categories

| Category | Roles | Scope |
|----------|-------|-------|
| **Platform** | `super_admin` | Cross-tenant, platform-wide |
| **School Leadership** | `principal`, `tenant_admin` | Single tenant, full school |
| **Academic** | `teacher` | Assigned classes/sections/subjects |
| **Operational Staff** | `accountant`, `librarian`, `transport_manager`, `hostel_warden`, `canteen_staff`, `receptionist` | Domain-specific within tenant |
| **End Users** | `student`, `parent` | Own data / linked children |

## User Creation Hierarchy

Who can create whom:

| Creator | Can Create |
|---------|-----------|
| `super_admin` | All 12 roles |
| `principal` | `tenant_admin`, `teacher`, all operational staff |
| `tenant_admin` | `teacher`, all operational staff |
| `teacher` | None |
| Operational staff | None |
| `student` / `parent` | None (created by admins or self-registration) |

## Portal Routing

| Role | Portal | Bottom Nav |
|------|--------|------------|
| `super_admin` | `/super-admin` | None (dedicated panel) |
| `principal` | `/admin` | Dashboard, Students, Attendance, Fees |
| `tenant_admin` | `/admin` | Dashboard, Students, Attendance, Fees |
| `teacher` | `/teacher` | Dashboard, Attendance, Exams, Messages |
| `student` | `/student` | Dashboard, Attendance, Results, Messages |
| `parent` | `/parent` | Dashboard, Attendance, Fees, Messages |
| Others | `/login` (no dedicated dashboard yet) | N/A |

All roles also see a "More" overflow menu with: Library, Transport, Hostel, Canteen.

## Feature Access Matrix

55 feature modules exist. The matrix below shows access by role tier.

**Legend:** `F` = Full (CRUD), `M` = Manage, `V` = View only, `O` = Own data only, `-` = No access

| Feature | super_admin | principal | tenant_admin | teacher | student | parent | accountant | librarian | transport_mgr | hostel_warden | canteen_staff | receptionist |
|---------|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| Tenant Management | F | - | - | - | - | - | - | - | - | - | - | - |
| Staff Management | F | F | M | - | - | - | - | - | - | - | - | - |
| Student Management | F | F | F | V | - | - | - | - | - | - | - | - |
| Attendance | F | F | F | M | O | O | - | - | - | - | - | - |
| Exams & Grades | F | F | F | M | O | O | - | - | - | - | - | - |
| Fees & Payments | F | F | F | - | O | O | F | - | - | - | - | - |
| Assignments | F | F | F | M | O | O | - | - | - | - | - | - |
| Homework | F | F | F | M | O | O | - | - | - | - | - | - |
| Messages | F | F | F | M | O | O | - | - | - | - | - | - |
| Admission | F | F | F | - | - | - | - | - | - | - | - | V |
| AI Insights | F | F | F | V | - | V | - | - | - | - | - | - |
| Discipline | F | F | F | M | - | V | - | - | - | - | - | - |
| Calendar/Events | F | F | F | V | V | V | - | - | - | - | - | V |
| Canteen | F | F | F | V | O | O | - | - | - | - | F | - |
| Library | F | F | F | V | O | O | - | F | - | - | - | - |
| Transport | F | F | F | V | O | O | - | - | F | - | - | - |
| Hostel | F | F | F | V | O | O | - | - | - | F | - | - |
| HR & Payroll | F | F | - | - | - | - | V | - | - | - | - | - |
| Communication | F | F | F | V | - | - | - | - | - | - | - | - |
| Inventory | F | F | F | - | - | - | V | V | - | - | - | - |
| Notice Board | F | F | F | V | V | V | V | V | V | V | V | V |
| Notifications | V | F | F | V | V | V | V | V | V | V | V | V |
| Timetable | F | F | F | O | O | V | - | - | - | - | - | - |
| LMS | F | F | F | M | O | V | - | - | - | - | - | - |
| Report Cards | F | F | F | M | O | O | - | - | - | - | - | - |
| Visitor Management | F | F | F | - | - | - | - | - | - | - | - | F |
| QR Scan / Digital ID | F | F | F | V | O | - | - | - | - | - | - | V |
| Gamification | F | F | F | V | O | V | - | - | - | - | - | - |
| Syllabus | F | F | F | M | V | V | - | - | - | - | - | - |
| PTM | F | F | F | M | - | O | - | - | - | - | - | - |
| Leave Management | F | F | F | O | - | - | - | - | - | - | - | - |
| Emergency | F | F | F | V | V | V | V | V | V | V | V | V |
| Health Records | F | F | F | V | O | O | - | - | - | - | - | - |
| Certificates | F | F | F | V | O | O | - | - | - | - | - | - |
| Offline Sync | - | V | V | V | V | V | V | V | V | V | V | V |

## Data Isolation

- **Tenant-level:** Every table has `tenant_id` with Supabase RLS policies
- **super_admin:** Cross-tenant access; `tenantId` comes from JWT `appMetadata` (can be null)
- **All other roles:** Scoped to their assigned tenant only
- **teacher:** Further scoped to assigned classes/sections/subjects
- **student:** Own records only (enrollments, marks, submissions, fees)
- **parent:** Linked children's records only (via `student_parents` table)

## Detailed Role Docs

- [Platform Admin (super_admin)](./platform_admin.md)
- [Principal](./principal.md)
- [School Admin (tenant_admin)](./school_admin.md)
- [Teacher](./teacher.md)
- [Student](./student.md)
- [Parent](./parent.md)
- [Operational Staff](./other_staff.md)

## Security Notes

1. **Client-side routing** is the primary access gate in Flutter — no per-screen role guards exist
2. **Supabase RLS** is the real enforcement layer (server-side)
3. Operational staff roles (accountant, librarian, etc.) lack dedicated dashboards — they fall through to `/login`
4. `tenantId!` force-unwrap in `BaseRepository` can crash for `super_admin`
5. Demo credentials are hardcoded in `LoginScreen` — must be removed for production
