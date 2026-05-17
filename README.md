# EduSaaS - School Management System

A comprehensive, multi-tenant School Management SaaS application built with Flutter and Supabase.

## 🚀 Features

### Core Modules
- **Authentication** - Multi-role login with Supabase Auth
- **Dashboard** - Role-specific dashboards (Admin, Teacher, Student, Parent)
- **Students** - Complete student management with enrollment
- **Attendance** - Daily/period-wise attendance with offline support
- **Exams & Results** - Exam management, marks entry, and analytics
- **Fees** - Invoice generation, payment tracking, and collection reports
- **Messaging** - In-app communication and announcements

### Additional Modules (Phase 2)
- Canteen & Wallet
- Library Management
- Transport Management
- Hostel Management
- Timetable & Calendar

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | Flutter (mobile-first, web-ready) |
| **State Management** | Riverpod |
| **Local Database** | Isar (offline-first) |
| **Backend** | Supabase (PostgreSQL + Auth + Storage + Edge Functions) |
| **Charts** | fl_chart |
| **PDF Generation** | pdf + printing |

## 📁 Project Structure

```
lib/
├── main.dart
├── core/
│   ├── config/          # App & Supabase configuration
│   ├── router/          # GoRouter setup
│   ├── theme/           # App theme & colors
│   ├── services/        # Local storage, sync services
│   └── shell/           # Main navigation shell
├── data/
│   ├── models/          # Domain models
│   ├── local/           # Isar models for offline storage
│   └── repositories/    # Data repositories
├── features/
│   ├── auth/            # Authentication
│   ├── dashboard/       # Role-based dashboards
│   ├── students/        # Student management
│   ├── attendance/      # Attendance marking
│   ├── exams/           # Exams & results
│   ├── fees/            # Fee management
│   └── messaging/       # Communication
└── shared/
    └── widgets/         # Reusable UI components
```

## 🗄️ Database Schema

See `/supabase/migrations/` for complete database schema including:
- Multi-tenant architecture with `tenant_id` on all tables
- Row Level Security (RLS) policies
- Indexed queries for performance

## 🚦 Getting Started

### Prerequisites
- Flutter SDK >= 3.2.0
- Supabase account
- Node.js (for Supabase CLI)

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd School-Management-Flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Configure Supabase**
   
   Update `lib/core/config/supabase_config.dart`:
   ```dart
   static const String url = 'YOUR_SUPABASE_URL';
   static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

   Or use environment variables:
   ```bash
   flutter run --dart-define=SUPABASE_URL=your-url --dart-define=SUPABASE_ANON_KEY=your-key
   ```

5. **Run database migrations**
   ```bash
   supabase db push
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

## 🔐 Authentication & Roles

### User Roles
| Role | Access Level |
|------|--------------|
| `super_admin` | Platform-wide access |
| `tenant_admin` | School-wide access |
| `principal` | School management |
| `teacher` | Class & subject access |
| `student` | Personal data only |
| `parent` | Children's data only |
| `accountant` | Fee management |
| `librarian` | Library management |

### Multi-Tenancy
- Each school is a separate tenant
- All data is isolated using `tenant_id`
- RLS policies enforce tenant isolation at database level

## 📱 Screens

### Authentication
- Splash Screen
- Login Screen

### Admin Dashboard
- Stats overview
- Quick actions
- Recent activity

### Teacher Dashboard  
- Today's schedule
- My classes
- Pending tasks

### Student Dashboard
- Class schedule
- Performance overview
- Upcoming events

### Parent Dashboard
- Child selector
- Attendance overview
- Fee summary
- Performance comparison

## 🎨 UI/UX

- **Design System**: Material Design 3 with custom theme
- **Glassmorphism**: Frosted glass cards and overlays
- **Responsive**: Mobile-first, tablet & web ready
- **Animations**: Smooth transitions with Flutter Animate
- **Charts**: Interactive charts with fl_chart

## 🔄 Offline Support

- **Isar Database**: Local data caching
- **Sync Queue**: Pending operations stored locally
- **Conflict Resolution**: Server-wins strategy
- **Sync Status**: Visual indicators for sync state

## 📊 API Patterns

### Direct SDK Calls (Simple CRUD)
```dart
final students = await supabase
  .from('students')
  .select('*, enrollment:student_enrollments(*)')
  .eq('tenant_id', tenantId);
```

### Edge Functions (Complex Logic)
- Bulk operations
- Payment processing
- Report generation
- Notification triggers

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

## 📦 Build

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## 🗺️ Roadmap

### Phase 1 (MVP) ✅
- [x] Authentication & multi-tenancy
- [x] Student management
- [x] Attendance (offline-first)
- [x] Exams & results
- [x] Fee management
- [x] Messaging & announcements

### Phase 2
- [ ] Canteen & wallet
- [ ] Library management
- [ ] Transport management
- [ ] Hostel management
- [ ] Advanced analytics
- [ ] PDF report cards

### Phase 3
- [ ] AI-based insights
- [ ] Recommendation system
- [ ] 3D campus tours
- [ ] Mobile apps (iOS/Android)

## 📄 License

This project is licensed under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

---

## 🔐 Demo Login Credentials

> ⚠️ **TEST/DEV ONLY.** These accounts seed the demo tenant. Do **not** use in production — rotate before any public deployment. Full setup instructions live in [`LOGIN_CREDENTIALS.md`](./LOGIN_CREDENTIALS.md).

**Default password for every account below:** `Demo@2026`

### Production Super Admin
| Role | Email | Password |
|------|-------|----------|
| Super Admin (prod seed) | `superadmin@schoolsaas.com` | `SuperAdmin@123` |

### Demo Tenant — All 15 Accounts

#### Administration
| Role | Name | Email | Password |
|------|------|-------|----------|
| Super Admin | — | `superadmin@demoschool.edu` | `Demo@2026` |
| Tenant Admin | — | `admin@demoschool.edu` | `Demo@2026` |
| Principal | Dr. Principal Smith | `principal@demoschool.edu` | `Demo@2026` |

#### Teachers
| Name | Subject | Employee ID | Email | Password |
|------|---------|-------------|-------|----------|
| John Teacher | Mathematics | EMP001 | `teacher1@demoschool.edu` | `Demo@2026` |
| Mary Teacher | English | EMP002 | `teacher2@demoschool.edu` | `Demo@2026` |
| Bob Teacher | Science | EMP003 | `teacher3@demoschool.edu` | `Demo@2026` |

#### Finance
| Name | Role | Employee ID | Email | Password |
|------|------|-------------|-------|----------|
| Alice Accountant | Accountant | EMP010 | `accountant@demoschool.edu` | `Demo@2026` |

#### Students
| Name | Grade / Section | Admission # | Email | Password |
|------|-----------------|-------------|-------|----------|
| Emma Student | Grade 1 / A | ADM2025001 | `student1@demoschool.edu` | `Demo@2026` |
| Liam Student | Grade 1 / A | ADM2025002 | `student2@demoschool.edu` | `Demo@2026` |
| Olivia Student | Grade 2 / A | ADM2025003 | `student3@demoschool.edu` | `Demo@2026` |
| Noah Student¹ | Grade 10 / A | ADM2025004 | `student4@demoschool.edu` | `Demo@2026` |
| Ava Student | Grade 10 / A | ADM2025005 | `student5@demoschool.edu` | `Demo@2026` |

¹ *Noah has a seeded AI prediction flagging high dropout risk — useful for testing risk dashboards.*

#### Parents
| Name | Occupation | Children | Email | Password |
|------|------------|----------|-------|----------|
| Robert Parent | Engineer | Emma, Liam | `parent1@demoschool.edu` | `Demo@2026` |
| Sarah Parent | Doctor | Olivia | `parent2@demoschool.edu` | `Demo@2026` |
| Michael Parent | Lawyer | Noah, Ava | `parent3@demoschool.edu` | `Demo@2026` |

### Account Summary
| Role | Count |
|------|------:|
| Super Admin | 1 |
| Tenant Admin | 1 |
| Principal | 1 |
| Teachers | 3 |
| Accountant | 1 |
| Students | 5 |
| Parents | 3 |
| **Total** | **15** |

### Quick Login Snippet
```dart
final response = await supabase.auth.signInWithPassword(
  email: 'admin@demoschool.edu',
  password: 'Demo@2026',
);
```

### Local Endpoints (when running `supabase start`)
| Service | URL / Value |
|---------|-------------|
| Supabase Studio | `http://localhost:54323` |
| API URL | `http://localhost:54321` |
| Postgres host | `localhost:54322` (user `postgres`, password `postgres`, db `postgres`) |

### Security Notes
- Password `Demo@2026` is for development only — enforce a strong policy and rotate before production.
- All tables enforce RLS; users must have correct `tenant_id` + `roles` in `app_metadata` to see data.
- Consider enabling MFA for `super_admin` / `tenant_admin` in production.
- Login attempts are recorded in the `login_audit` table.