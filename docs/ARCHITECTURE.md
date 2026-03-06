# ARCHITECTURE - School Management SaaS

> Generated 2026-03-06 | v1.0.0+1

---

## Table of Contents

1. [System Diagram](#system-diagram)
2. [Data Flow](#data-flow)
3. [Authentication and Authorization Flow](#authentication-and-authorization-flow)
4. [Multi-Tenancy Architecture](#multi-tenancy-architecture)
5. [Module Dependency Map](#module-dependency-map)
6. [Role-Permission Matrix](#role-permission-matrix)
7. [Technology Stack](#technology-stack)
8. [Known Architectural Issues](#known-architectural-issues)

---

## System Diagram

```
+------------------------------------------------------------------+
|                        FLUTTER CLIENT                             |
|                                                                   |
|  +------------------+   +------------------+   +---------------+  |
|  |   Presentation   |   |   State Mgmt     |   |   Data Layer  |  |
|  |                  |   |                  |   |               |  |
|  | Screens (163)    |-->| Riverpod         |-->| Repositories  |  |
|  | Widgets          |   | Providers (52)   |   | (47)          |  |
|  | GoRouter (75+    |   | StateNotifier    |   | BaseRepository|  |
|  |  routes)         |   | FutureProvider   |   | Models (46)   |  |
|  | MainShell        |   | StateProvider    |   |               |  |
|  +------------------+   +------------------+   +-------+-------+  |
|                                                        |          |
|  +------------------+                                  |          |
|  |  Core Services   |                                  |          |
|  |  AI Text Gen     |---------+                        |          |
|  |  AI Image Gen    |         |                        |          |
|  |  DeepSeek        |   +-----v------------------------v-----+   |
|  |  Claude Vision   |   |           Supabase Client          |   |
|  |  Offline Sync    |   |  (supabase_flutter)                |   |
|  |  Payment Gateway |   +------------------------------------+   |
|  |  Local Storage   |                    |                        |
|  +------------------+                    |                        |
+------------------------------------------------------------------+
                                           |
                    =======================|========================
                                           |
+------------------------------------------------------------------+
|                      SUPABASE BACKEND                             |
|                                                                   |
|  +-------------------+  +------------------+  +----------------+  |
|  |  PostgreSQL DB    |  |  Auth (GoTrue)   |  |  Realtime      |  |
|  |  ~170 tables      |  |  JWT + RLS       |  |  WebSocket     |  |
|  |  RLS policies     |  |  12 roles in     |  |  channels      |  |
|  |  Server functions |  |  app_metadata    |  |  (Postgres CDC) |  |
|  |  Triggers         |  +------------------+  +----------------+  |
|  +-------------------+                                            |
|                          +------------------+                     |
|  +-------------------+  |  Storage         |                     |
|  |  Edge Functions   |  |  (file uploads)  |                     |
|  |  (potential)      |  +------------------+                     |
|  +-------------------+                                            |
+------------------------------------------------------------------+
                                           |
                    =======================|========================
                                           |
+------------------------------------------------------------------+
|                    EXTERNAL SERVICES                               |
|                                                                   |
|  +------------------+  +------------------+  +----------------+   |
|  |  DeepSeek API    |  |  OpenRouter API  |  |  Claude API    |   |
|  |  (text gen)      |  |  (image gen)     |  |  (vision)      |   |
|  +------------------+  +------------------+  +----------------+   |
|                                                                   |
|  +------------------+  +------------------+                       |
|  |  Firebase        |  |  Payment Gateway |                       |
|  |  (push notifs)   |  |  (stub)          |                       |
|  +------------------+  +------------------+                       |
+------------------------------------------------------------------+
```

---

## Data Flow

### Read Flow (typical)

```
Screen
  --> calls provider.watch(someDataProvider)
    --> provider triggers repository.fetchData()
      --> repository calls supabase.client.from('table').select()
      --> Supabase applies RLS (checks tenant_id from JWT)
      --> Returns JSON rows
    --> repository maps JSON to Model via fromJson()
  --> provider returns AsyncValue<List<Model>>
--> Screen renders data
```

### Write Flow (typical)

```
Screen (user action)
  --> calls provider method (e.g., notifier.createItem(data))
    --> provider calls repository.create(model.toJson())
      --> repository calls supabase.client.from('table').insert(json)
      --> Supabase validates via RLS + constraints
      --> Returns inserted row
    --> provider updates local state
  --> Screen rebuilds via Riverpod reactivity
```

### Realtime Flow

```
Repository subscribes:
  client.channel('public:table')
    .onPostgresChanges(event: PostgresChangeEvent.insert, ...)
    .subscribe()

  --> Supabase Realtime pushes changes via WebSocket
  --> callback fires in repository
  --> provider.refresh() or state update
  --> UI rebuilds

Subscriptions active for:
  - attendance (section-scoped)
  - notifications (user-scoped)
  - messages/threads
  - announcements (tenant-scoped)
  - assignments
  - communication campaigns
```

### AI Service Flow

```
Screen (e.g., AI Syllabus Generator)
  --> calls AI provider
    --> provider invokes AiTextGenerator / DeepSeekService
      --> HTTP POST to external LLM API (DeepSeek / OpenRouter / Claude)
      --> Returns generated text/JSON
    --> provider stores result in Supabase table
  --> Screen displays generated content
```

---

## Authentication and Authorization Flow

```
1. User opens app
   --> SplashScreen checks Supabase auth session

2. If no session --> LoginScreen
   --> supabase.auth.signInWithPassword(email, password)
   --> Returns JWT with app_metadata containing:
       { "tenant_id": "uuid", "roles": ["teacher", "student"] }

3. GoRouter redirect logic (app_router.dart:233-261):
   --> Reads user role from auth state
   --> Routes to role-specific dashboard:
       super_admin  --> /super-admin
       tenant_admin --> /admin
       principal    --> /admin
       teacher      --> /teacher
       student      --> /student
       parent       --> /parent
       accountant   --> /admin (fees focused)
       librarian    --> /admin (library focused)
       transport_manager --> /admin
       hostel_warden     --> /admin
       canteen_staff     --> /admin
       receptionist      --> /admin

4. Every Supabase query:
   --> RLS policy checks: tenant_id = JWT.app_metadata.tenant_id
   --> Role-based policies further restrict access

5. BaseRepository extracts tenant_id:
   --> tenantId = client.auth.currentUser!.appMetadata['tenant_id']
   --> WARNING: Force-unwrap crashes for super_admin (no tenant_id)
```

---

## Multi-Tenancy Architecture

```
                    +-------------------+
                    |   Super Admin     |
                    |  (no tenant_id)   |
                    +--------+----------+
                             |
              +--------------+--------------+
              |              |              |
     +--------v---+  +------v-----+  +-----v------+
     |  Tenant A  |  |  Tenant B  |  |  Tenant C  |
     |  School X  |  |  School Y  |  |  School Z  |
     +-----+------+  +-----+------+  +-----+------+
           |                |               |
    +------+------+  +------+------+  +-----+------+
    | users       |  | users       |  | users      |
    | students    |  | students    |  | students   |
    | classes     |  | classes     |  | classes    |
    | ...         |  | ...         |  | ...        |
    +-------------+  +-------------+  +------------+
```

**Isolation mechanism:**
- Every data table has a `tenant_id UUID NOT NULL REFERENCES tenants(id)` column
- PostgreSQL Row Level Security (RLS) enforces tenant isolation
- RLS policies use `public.tenant_id()` helper function that extracts tenant from JWT
- No application-level filtering required (enforced at DB level)
- `public.is_admin()` and `public.has_role(role)` helper functions for role checks

---

## Module Dependency Map

### Core Dependencies (used by nearly all features)

```
auth (AuthProvider)
  |
  +--> BaseRepository (Supabase client, tenant_id)
  |      |
  |      +--> All 46 repositories
  |
  +--> GoRouter (role-based routing)
  |
  +--> MainShell (bottom navigation)
```

### Feature Dependency Clusters

```
ACADEMIC CLUSTER
  academic --> admin (config screens)
  academic --> teacher (class assignments)
  academic --> student (enrollment data)
  academic --> exams, attendance, timetable (all reference classes/sections/subjects)

STUDENT DATA CLUSTER
  students --> student (student-role views)
  students --> parent (child data)
  students --> insights (analytics)
  students --> ai_insights (risk scores, predictions)
  students --> health, gamification (student profiles)

ASSESSMENT CLUSTER
  exams --> admin (management)
  exams --> teacher (marks entry)
  exams --> reports, report_card (results display)
  assessments --> question_paper (question bank shared)
  online_exam --> question_paper (question bank)

COMMUNICATION CLUSTER
  messaging --> notifications
  communication --> messaging (campaign delivery)
  announcements --> communication
  ptm --> messaging (appointment notifications)

FINANCIAL CLUSTER
  fees --> admin (fee management)
  fees --> student (view fees)
  fees --> parent (payment)
  canteen --> fees (wallet system)

AI CLUSTER
  ai_insights --> students (risk scoring)
  ai_insights --> attendance (patterns)
  ai_insights --> exams (trend prediction)
  ai_insights --> communication (message drafting)
  ai_insights --> report_card (commentary generation)
  ai_tutor --> syllabus (concept mastery)
  syllabus --> ai_insights (AI syllabus generation)
  question_paper --> ai_insights (AI generation)
  substitution --> ai_insights (AI substitute suggestions)

CAMPUS SERVICES CLUSTER
  canteen (standalone)
  library (standalone)
  transport (standalone)
  hostel (standalone)
  visitor (standalone)

HR CLUSTER
  hr --> admin (staff data)
  hr --> leave (staff leave integration)
  hr --> substitution (teacher availability)

ADMIN CLUSTER
  admin --> academic, students, exams, fees, announcements
  super_admin --> tenants (multi-tenant management)
  discipline --> students (behavior tracking)
  admission --> students (enrollment pipeline)
  inventory --> admin (asset tracking)
  certificate --> students (certificate issuance)
  calendar --> admin (school events)
  alumni --> students (post-graduation tracking)
  lms --> academic (course management)
```

---

## Role-Permission Matrix

Twelve roles with their primary access areas:

| Feature / Module | super_admin | tenant_admin | principal | teacher | student | parent | accountant | librarian | transport_mgr | hostel_warden | canteen_staff | receptionist |
|-----------------|:-----------:|:------------:|:---------:|:-------:|:-------:|:------:|:----------:|:---------:|:-------------:|:-------------:|:-------------:|:------------:|
| **Super Admin Panel** | Full | - | - | - | - | - | - | - | - | - | - | - |
| **Tenant Management** | Full | - | - | - | - | - | - | - | - | - | - | - |
| **Admin Dashboard** | - | Full | Full | - | - | - | View | View | View | View | View | View |
| **Academic Config** | - | Full | Full | View | - | - | - | - | - | - | - | - |
| **Student Management** | - | Full | Full | View | - | - | - | - | - | - | - | - |
| **Staff Management** | - | Full | Full | - | - | - | - | - | - | - | - | - |
| **Attendance (mark)** | - | Full | Full | Full | - | - | - | - | - | - | - | - |
| **Attendance (view own)** | - | - | - | - | View | View | - | - | - | - | - | - |
| **Exams (manage)** | - | Full | Full | Full | - | - | - | - | - | - | - | - |
| **Exams (view results)** | - | - | - | - | View | View | - | - | - | - | - | - |
| **Assignments** | - | Full | Full | Full | View/Submit | View | - | - | - | - | - | - |
| **Fees (manage)** | - | Full | Full | - | - | - | Full | - | - | - | - | - |
| **Fees (view/pay)** | - | - | - | - | View | Pay | - | - | - | - | - | - |
| **Messaging** | - | Full | Full | Full | Full | Full | Full | Full | Full | Full | Full | Full |
| **Announcements** | - | Full | Full | Create | View | View | View | View | View | View | View | View |
| **Timetable** | - | Full | Full | View | View | - | - | - | - | - | - | - |
| **Report Cards** | - | Full | Full | Edit | View | View | - | - | - | - | - | - |
| **AI Insights** | - | Full | Full | View | - | View* | - | - | - | - | - | - |
| **Syllabus** | - | Full | Full | Full | View | - | - | - | - | - | - | - |
| **Question Papers** | - | Full | Full | Full | - | - | - | - | - | - | - | - |
| **Online Exams** | - | Full | Full | Full | Take | View | - | - | - | - | - | - |
| **Canteen** | - | Full | Full | Order | Order | Order | - | - | - | - | Full | - |
| **Library** | - | Full | Full | Borrow | Borrow | - | - | Full | - | - | - | - |
| **Transport** | - | Full | Full | View | View | View | - | - | Full | - | - | - |
| **Hostel** | - | Full | Full | - | View | View | - | - | - | Full | - | - |
| **Health Records** | - | Full | Full | View | View | View | - | - | - | - | - | - |
| **Gamification** | - | Full | Full | View | View | View | - | - | - | - | - | - |
| **PTM** | - | Full | Full | Manage | - | Book | - | - | - | - | - | - |
| **Emergency** | - | Full | Full | View/Report | View | View | View | View | View | View | View | View |
| **Leave** | - | Full | Full | Apply/View | Apply | - | - | - | - | - | - | - |
| **Resources** | - | Full | Full | Upload | View | View | - | - | - | - | - | - |
| **QR Scan** | - | Full | Full | Scan | ID Card | - | - | - | - | - | - | Scan |
| **Discipline** | - | Full | Full | Report/View | View | View | - | - | - | - | - | - |
| **Admission** | - | Full | Full | View | - | Apply | - | - | - | - | - | Full |
| **Communication Hub** | - | Full | Full | View | - | - | - | - | - | - | - | - |
| **HR & Payroll** | - | Full | Full | View own | - | - | - | - | - | - | - | - |
| **Inventory** | - | Full | Full | View | - | - | - | - | - | - | - | - |
| **LMS** | - | Full | Full | Create | Enroll | - | - | - | - | - | - | - |
| **Calendar** | - | Full | Full | View/Create | View | View | View | View | View | View | View | View |
| **Alumni** | - | Full | Full | View | View | - | - | - | - | - | - | - |
| **Visitor** | - | Full | Full | - | - | - | - | - | - | - | - | Full |
| **Certificate** | - | Full | Full | View | View | View | - | - | - | - | - | - |
| **Substitution** | - | Full | Full | Report/View | - | - | - | - | - | - | - | - |
| **AI Tutor** | - | Full | Full | - | Use | - | - | - | - | - | - | - |

**Legend:** Full = full CRUD access, View = read-only, - = no access, * = limited (own child data only)

### Role Descriptions

| Role | Code | Primary Responsibility |
|------|------|----------------------|
| Super Admin | `super_admin` | Platform-level management, tenant provisioning |
| Tenant Admin | `tenant_admin` | School-level administration, all modules |
| Principal | `principal` | School oversight, same access as tenant_admin |
| Teacher | `teacher` | Class management, attendance, grading, content creation |
| Student | `student` | View own data, submit work, take exams, use LMS |
| Parent | `parent` | View child data, pay fees, book PTM, receive digests |
| Accountant | `accountant` | Fee management, invoicing, payment tracking |
| Librarian | `librarian` | Library catalog, book issuance, returns |
| Transport Manager | `transport_manager` | Route management, vehicle tracking, student allocation |
| Hostel Warden | `hostel_warden` | Room allocation, hostel management |
| Canteen Staff | `canteen_staff` | Menu management, order processing |
| Receptionist | `receptionist` | Visitor management, admission inquiries, QR scanning |

---

## Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| UI Framework | Flutter 3.2+ | Cross-platform mobile/web |
| Language | Dart | Application logic |
| State Management | Riverpod | Reactive state, dependency injection |
| Routing | GoRouter | Declarative routing with deep linking |
| Backend | Supabase | BaaS (PostgreSQL, Auth, Realtime, Storage) |
| Local DB | Isar | Offline-first storage (incomplete) |
| Push Notifications | Firebase | FCM for mobile push |
| AI (Text) | DeepSeek, Claude | Text generation (remarks, syllabi, recommendations) |
| AI (Image) | OpenRouter | Image generation |
| AI (Vision) | Claude Vision | Multimodal analysis |
| Design System | Material 3 | UI components, Poppins font |
| Code Generation | Freezed + json_serializable | Immutable models (partial adoption) |

---

## Known Architectural Issues

### Critical

1. **tenantId force-unwrap** - `BaseRepository` uses `tenantId!` which crashes for super_admin users who have no tenant_id in JWT
2. **No pagination** - List screens fetch all records; will fail at scale
3. **No offline sync** - Isar models exist but sync logic is unimplemented
4. **Realtime channel leaks** - Channels not cleaned up on widget dispose

### High

1. **N+1 query in student list** - Parent data loaded separately per student
2. **No transaction guarantees** - Multi-step operations (PTM deletion, invoice generation) lack atomicity
3. **Client-side quiz timer** - Online exam timer runs in Flutter; exploitable by users
4. **No duplicate check in `generate_class_invoices()`** - Can create duplicate invoices

### Medium

1. **Mixed model patterns** - Some Freezed, most plain Dart classes; inconsistent
2. **No automated tests** - Zero test coverage
3. **No localization** - All strings hardcoded in English
4. **Denormalization risks** - `students.payment_status`, `hostel_rooms.occupied`, `wallets.balance` can desync
5. **Missing DB indexes** - Student name search, message sender, invoice due_date
