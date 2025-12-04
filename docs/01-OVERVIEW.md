# School Management SaaS - Overview

## Tech Stack
- **Frontend**: Flutter (mobile-first, web-ready)
- **State Management**: Riverpod
- **Local Database**: Isar (offline-first)
- **Backend**: Supabase (PostgreSQL + Auth + Storage + Edge Functions)
- **Charts**: fl_chart
- **PDF Generation**: pdf + printing

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter Clients                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Mobile    │  │   Tablet    │  │          Web            │  │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬─────────────┘  │
└─────────┼────────────────┼─────────────────────┼────────────────┘
          └────────────────┼─────────────────────┘
                           │
┌──────────────────────────┼──────────────────────────────────────┐
│                    SUPABASE PLATFORM                            │
│  ┌───────────────┐ ┌─────▼─────┐ ┌────────────┐ ┌────────────┐  │
│  │    Supabase   │ │PostgreSQL │ │  Supabase  │ │   Edge     │  │
│  │     Auth      │ │   + RLS   │ │  Storage   │ │ Functions  │  │
│  └───────────────┘ └───────────┘ └────────────┘ └────────────┘  │
└──────────────────────────────────────────────────────────────────┘
                           │
                    ┌──────▼──────┐
                    │   External  │ • FCM (Push)
                    │  Services   │ • Razorpay/Stripe
                    └─────────────┘
```

## Multi-Tenancy Strategy

Every data table includes `tenant_id` referencing `tenants.id`. Row Level Security (RLS) policies enforce tenant isolation at the database level.

```sql
-- Every table pattern
CREATE TABLE example (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    -- other columns...
);

-- RLS Policy
CREATE POLICY tenant_isolation ON example
    FOR ALL USING (tenant_id = auth.tenant_id());
```

## Communication Patterns

| Action Type | Method | Why |
|-------------|--------|-----|
| Simple CRUD | Direct Supabase SDK | Fast, cached, RLS protected |
| Sensitive logic | Edge Functions | Server-side validation |
| File uploads | Supabase Storage | Secure, CDN-backed |
| Auth | Supabase Auth | JWT-based, MFA support |
| Payments | Edge Functions | Secure webhook handling |
| Bulk operations | Edge Functions | Transaction safety |

## User Roles

- **super_admin**: Platform owner
- **tenant_admin**: School admin
- **principal**: School principal
- **teacher**: Class teacher
- **student**: Student user
- **parent**: Parent/guardian
- **accountant**: Fee management
- **librarian**: Library management
- **transport_manager**: Transport management
- **hostel_warden**: Hostel management
- **canteen_staff**: Canteen operations
