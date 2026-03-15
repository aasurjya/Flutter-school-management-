# Operational Staff Roles

These are domain-specific support roles within a school. They handle specialized operational functions and have focused, limited permissions.

## Current Status

**Important:** These roles currently lack dedicated dashboards in the app. The router falls through to `/login` for unrecognized roles. They need dedicated portals or at minimum a shared operational staff dashboard.

---

## Accountant

- **Internal key:** `accountant`
- **Domain:** Fees, invoices, payments, financial reporting

### Permissions
- **Fees & Payments (Full):** Configure fee heads, generate invoices, record payments, manage outstanding balances, create fee reports
- **HR & Payroll (View):** View salary structures, payslips (for disbursement verification)
- **Inventory (View):** View asset records and purchase orders (for financial auditing)
- **Notice Board (View):** View school notices
- **Notifications (View):** Receive relevant notifications

### Restrictions
- Cannot access student academic data (grades, attendance, assignments)
- Cannot manage staff or students
- Cannot access communication tools beyond notices

---

## Librarian

- **Internal key:** `librarian`
- **Domain:** Book catalog, borrowing, returns, library management

### Permissions
- **Library (Full):** Manage book catalog, process borrowing/returns, track overdue books, manage reservations, generate library reports
- **Inventory (View):** View library-related assets
- **Student Data (View — limited):** View student names and IDs for book issue/return
- **Notice Board (View):** View and post library-related notices

### Restrictions
- Cannot access student academic data
- Cannot manage fees or payments
- Cannot access communication tools beyond notices

---

## Transport Manager

- **Internal key:** `transport_manager`
- **Domain:** Bus routes, vehicle management, driver assignments, live tracking

### Permissions
- **Transport (Full):** Create and manage bus routes, assign drivers, manage vehicles, configure geofences, view live tracking dashboard
- **Student Data (View — limited):** View student transport allocations
- **Bus Tracking (Full):** Monitor all vehicles, manage driver panels, view vehicle details
- **Notice Board (View):** View and post transport-related notices
- **Emergency (View):** Access emergency protocols for transport incidents

### Restrictions
- Cannot access student academic data
- Cannot manage fees or payments
- Cannot access non-transport operational modules

---

## Hostel Warden

- **Internal key:** `hostel_warden`
- **Domain:** Room allocation, hostel management, resident tracking

### Permissions
- **Hostel (Full):** Manage rooms, allocate students, track occupancy, manage hostel rules and announcements
- **Student Data (View — limited):** View hostel resident profiles
- **Attendance (View — hostel):** Track hostel-specific check-in/check-out
- **Notice Board (View):** View and post hostel-related notices
- **Emergency (View):** Access emergency protocols for hostel incidents

### Restrictions
- Cannot access student academic data
- Cannot manage fees or payments
- Cannot access non-hostel operational modules

---

## Canteen Staff

- **Internal key:** `canteen_staff`
- **Domain:** Menu management, orders, wallets, inventory

### Permissions
- **Canteen (Full):** Manage daily menus, process orders, manage student wallets, track order history, generate canteen reports
- **Student Data (View — limited):** View student names and wallet balances
- **Notice Board (View):** View and post canteen-related notices

### Restrictions
- Cannot access student academic data
- Cannot manage fees or payments (separate from canteen wallet)
- Cannot access non-canteen operational modules

---

## Receptionist

- **Internal key:** `receptionist`
- **Domain:** Visitor management, front desk operations, inquiries

### Permissions
- **Visitor Management (Full):** Register visitors, manage pre-registrations, log check-in/check-out, print visitor badges
- **Admission (View):** View admission inquiries and direct walk-ins to the right process
- **Calendar & Events (View):** View school calendar to inform visitors
- **QR Scan (View):** Scan visitor and student QR codes for identification
- **Notice Board (View):** View school notices
- **Emergency (View):** Access emergency protocols (lockdown, evacuation)

### Restrictions
- Cannot access student academic data
- Cannot manage fees, staff, or students
- Cannot access operational modules beyond visitor management

---

## Account Creation (All Operational Staff)

All operational staff accounts are created through the same Staff Management flow.

| Attribute | Detail |
|-----------|--------|
| **Who creates** | `principal`, `tenant_admin`, or `super_admin` |
| **Creation path** | Staff Management → Add Staff → [select role] |
| **Fields filled by admin** | Full Name, optional Phone, Role |
| **Username (auto-generated)** | `{firstname}.{lastname}@{tenantslug}.edu` |
| **Password (auto-generated)** | 10-char random: 1 uppercase + 1 lowercase + 1 digit + 1 special (`@#$!`) |

### Where credentials appear

1. **In the creation sheet** (`add_staff_sheet.dart`) — username builds live as admin types; password shown masked with show/copy/regenerate controls
2. **In `CredentialDisplayDialog`** — displayed immediately after submission, non-dismissible, with a "Copy All" button

```
Examples by role:
  Accountant:        aisha.kumar@greenview.edu   / Pn4@rKj8Wz
  Librarian:         tom.bradley@greenview.edu   / Mv6!qXs1Yt
  Transport Mgr:     ali.hassan@greenview.edu    / Bx2#fLp9Dw
  Hostel Warden:     grace.osei@greenview.edu    / Rk7$nQm3Vc
  Canteen Staff:     mei.lin@greenview.edu        / Hs5@jWt4Zb
  Receptionist:      carlos.diaz@greenview.edu   / Ld8!eNp6Ux
```

The admin **must copy and hand credentials to the staff member** before dismissing the dialog.

---

## First-Login UX Journey (All Operational Staff)

```
[Admin creates Operational Staff account]
       ↓
[Admin copies username + password from CredentialDisplayDialog]
       ↓
[Admin hands credentials to staff member]
       ↓
[Staff member opens app → Login screen]
  Email:    ali.hassan@greenview.edu
  Password: Bx2#fLp9Dw
       ↓
[App checks: profile_complete = false]
       ↓
[Redirected to Profile Setup → /profile-setup/staff]
  Staff fills in:
  - Profile photo
  - Phone number
  - Date of birth
  - Department (e.g. Transport, Library, Finance)
  - Home address
       ↓
[Staff member taps "Save & Continue"]
       ↓
[App sets profile_complete = true]
       ↓
[Redirected to role-specific staff dashboard]
  Accountant        → /staff/accountant
  Librarian         → /staff/librarian
  Transport Manager → /staff/transport-manager
  Hostel Warden     → /staff/hostel-warden
  Canteen Staff     → /staff/canteen-staff
  Receptionist      → /staff/receptionist
       ↓
[All subsequent logins → straight to their staff dashboard]
```

---

## Common Traits (All Operational Staff)

| Attribute | Value |
|-----------|-------|
| Created by | `principal`, `tenant_admin`, or `super_admin` |
| Cannot create | Any user accounts |
| Data scope | Tenant-scoped + domain-limited |
| Dashboard | None currently (needs implementation) |
| Grouped under | "Other Staff" tab in staff management |
| Notice Board | View access (all) |
| Notifications | Receive relevant push notifications |
| Offline Sync | Available |
| Emergency | View access (all) |

## Implementation Gap

These roles need:
1. **Dedicated dashboard screens** — even a shared "Staff Portal" with role-specific widgets
2. **Router entries** — currently fall through to `/login`
3. **Bottom nav configuration** — role-specific navigation items
4. **Feature flag enforcement** — hide irrelevant modules per role
