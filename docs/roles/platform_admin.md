# Platform Admin (`super_admin`)

## System Role

- **Internal key:** `super_admin`
- **Portal:** `/super-admin` (dedicated panel, no bottom nav)
- **Scope:** Cross-tenant, platform-wide

## Responsibility

The platform admin owns the SaaS platform itself. They onboard schools (tenants), manage billing/subscriptions, monitor platform health, and handle escalations that cross tenant boundaries.

## Permissions

### Tenant Management (Full)
- Create, view, edit, suspend, and delete school tenants
- View tenant details: subscription plan, user counts, storage usage
- Configure tenant-level settings (features enabled, branding)
- Access tenant list and drill into any tenant's data

### User & Role Management (Full)
- Create users with **any** of the 12 roles
- Assign and revoke roles across all tenants
- Reset passwords and manage authentication
- View all staff across all tenants

### Platform Configuration
- Manage subscription plans and pricing tiers
- Configure global feature flags
- Set platform-wide defaults (academic year format, grading scales)
- Manage system-level notification templates

### Monitoring & Analytics
- View platform-wide dashboards (total tenants, total users, revenue)
- Access cross-tenant analytics and usage reports
- Monitor system health, error rates, API usage
- View audit logs across all tenants

### Communication
- Send platform-wide announcements to all tenants
- Broadcast maintenance notices
- Communicate with principals/admins of any tenant

## Restrictions

- **Must not** operate through the regular school admin shell (`/admin`)
- **Must not** be redirected into tenant-specific flows during normal use
- **Cannot** act as a teacher, student, or parent within a school
- **Should not** modify individual student/teacher records directly — delegate to school admins

## Account Creation

Platform admins are **seeded directly into the database** or self-registered via a protected bootstrap endpoint — they are never created through the in-app UI.

| Attribute | Detail |
|-----------|--------|
| **Who creates** | Database seed / platform bootstrap (not via app UI) |
| **Creation path** | Direct DB insert or Supabase Auth admin API |
| **Credentials** | Set manually at seed time (not auto-generated) |
| **Profile setup** | Not required — `super_admin` is exempt from profile setup screens |
| **First login destination** | `/super-admin` dashboard directly |

> There is no `CredentialDisplayDialog` flow for super_admin. Credentials are established outside the app and communicated through a secure out-of-band channel.

---

## Known Issues

- `tenantId` is null for super_admin (comes from JWT `appMetadata`) — `tenantId!` force-unwrap in `BaseRepository` can crash. Repos must handle null tenantId gracefully.
- No subscription enforcement code exists yet — plan/billing checks are not implemented.
- Operational staff roles created by super_admin have no dedicated dashboard to land on.

## Data Boundary

```
super_admin
  +-- Can read/write: tenants, users, user_roles (all tenants)
  +-- Can read: all tenant data (for support/debugging)
  +-- Should not: directly mutate tenant-scoped academic data
```

## Key Code Paths

| What | Where |
|------|-------|
| Route guard | `app_router.dart:637-660` |
| Dashboard | `super_admin_dashboard_screen.dart` |
| Tenant CRUD | `create_tenant_screen.dart`, `tenant_detail_screen.dart` |
| Provider | `tenant_provider.dart` |
| Staff creation | `add_staff_sheet.dart:53-55` (full role list) |
