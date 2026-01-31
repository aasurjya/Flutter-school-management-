# Codebase Analysis & Supabase Integration Plan

## Executive Summary

### What's Already Implemented (Real Supabase)

| Layer | Status | Details |
|-------|--------|---------|
| **Database Schema** | ✅ Complete | 7 migrations with full schema for multi-tenant SaaS |
| **Base Repository** | ✅ Complete | tenant_id scoping, real-time subscriptions |
| **Models** | ✅ Complete | 23 models with freezed serialization |
| **Core Repositories** | ✅ Complete | 8 repositories with real Supabase queries |
| **Providers** | ✅ Complete | 8 Riverpod providers connected to repositories |
| **Auth Flow** | ✅ Complete | Login, logout, role-based routing |

### What Uses Mock Data (Needs Integration)

| Screen | Mock Data Used | Fix Priority |
|--------|---------------|--------------|
| Super Admin Dashboard | `_tenants` list hard-coded | HIGH |
| Tenants List Screen | `_tenants` list hard-coded | HIGH |
| Create Tenant Screen | No actual insert | HIGH |
| Tenant Detail Screen | `_tenant` map hard-coded | HIGH |
| Admin Fee Management | `_summary`, `_feeStructures` hard-coded | HIGH |
| Admin Exam Management | `_exams` list hard-coded | MEDIUM |
| Admin Announcements | `_announcements` list hard-coded | MEDIUM |
| Teacher My Classes | `_classes` list hard-coded | HIGH |
| Teacher Class Students | `_students` list hard-coded | MEDIUM |
| Teacher Timetable | `_getSchedule` returns mock | MEDIUM |
| Student Timetable | Mock timetable data | MEDIUM |
| Student Attendance | Mock summary data | MEDIUM |
| Student Fees | Mock fee summary | MEDIUM |
| Parent Fee Payment | Mock invoice data | HIGH |
| Staff Management | Mock staff list | MEDIUM |

---

## 1. Role → Feature Matrix

### 1.1 Student Role

| Feature | Read | Write | Tables Used |
|---------|------|-------|-------------|
| Profile | ✅ | ❌ | `students`, `users` |
| Timetable | ✅ | ❌ | `timetable_entries` |
| Attendance History | ✅ | ❌ | `attendance`, `v_attendance_summary` |
| Exam Results | ✅ | ❌ | `marks`, `mv_student_performance`, `v_student_ranks` |
| Assignments | ✅ | Submit only | `assignments`, `submissions` |
| Fee Status | ✅ | ❌ | `invoices`, `v_fee_summary` |
| Announcements | ✅ | ❌ | `announcements` |
| Messages | ✅ | ✅ | `messages`, `message_threads` |

### 1.2 Parent Role

| Feature | Read | Write | Tables Used |
|---------|------|-------|-------------|
| Children List | ✅ | ❌ | `students` via `student_parents` |
| Child Attendance | ✅ | ❌ | `attendance`, `v_attendance_summary` |
| Child Results | ✅ | ❌ | `marks`, `mv_student_performance` |
| Child Assignments | ✅ | ❌ | `assignments`, `submissions` |
| Fee Payment | ✅ | Pay | `invoices`, `payments` |
| Announcements | ✅ | ❌ | `announcements` |
| Messages | ✅ | ✅ | `messages`, `message_threads` |

### 1.3 Teacher Role

| Feature | Read | Write | Tables Used |
|---------|------|-------|-------------|
| Timetable | ✅ | ❌ | `timetable_entries`, `teacher_assignments` |
| My Classes | ✅ | ❌ | `sections`, `teacher_assignments` |
| Class Students | ✅ | ❌ | `students`, `student_enrollments` |
| Mark Attendance | ✅ | ✅ | `attendance` |
| Assignments | ✅ | CRUD | `assignments`, `submissions` |
| Enter Marks | ✅ | ✅ | `marks`, `exam_subjects` |
| Class Analytics | ✅ | ❌ | `v_class_exam_stats`, `v_student_ranks` |

### 1.4 School Admin Role (tenant_admin/principal)

| Feature | Read | Write | Tables Used |
|---------|------|-------|-------------|
| Students | ✅ | CRUD | `students`, `student_enrollments` |
| Staff | ✅ | CRUD | `users`, `user_roles` |
| Academic Config | ✅ | CRUD | `academic_years`, `classes`, `sections`, `subjects` |
| Exams | ✅ | CRUD | `exams`, `exam_subjects` |
| Fees | ✅ | CRUD | `fee_structures`, `invoices`, `payments` |
| Announcements | ✅ | CRUD | `announcements` |
| Analytics | ✅ | ❌ | All analytics views |

### 1.5 Super Admin Role

| Feature | Read | Write | Tables Used |
|---------|------|-------|-------------|
| Tenants | ✅ | CRUD | `tenants` |
| Tenant Users | ✅ | Create Admin | `users`, `user_roles` |
| Platform Metrics | ✅ | ❌ | Aggregate across tenants |

---

## 2. Existing Repository Analysis

### ✅ Fully Implemented Repositories

```
lib/data/repositories/
├── base_repository.dart     ✅ tenant_id, currentUserId, real-time
├── student_repository.dart  ✅ Full CRUD, enrollment, parent children
├── attendance_repository.dart ✅ Mark, bulk mark, stats, real-time
├── exam_repository.dart     ✅ Exams, marks, rankings, analytics
├── assignment_repository.dart ✅ Full CRUD, submissions, grading
├── fee_repository.dart      ✅ Invoices, payments, summaries
├── message_repository.dart  ✅ Threads, messages, real-time
├── timetable_repository.dart ✅ Entries by section/teacher
```

### ✅ Fully Implemented Providers

```
lib/features/*/providers/
├── auth_provider.dart       ✅ Auth, current user, tenant
├── students_provider.dart   ✅ List, detail, CRUD operations
├── attendance_provider.dart ✅ Section, student, bulk mark
├── exams_provider.dart      ✅ List, marks entry, analytics
├── assignments_provider.dart ✅ List, submissions, grading
├── fees_provider.dart       ✅ Invoices, payments, summaries
├── messages_provider.dart   ✅ Threads, send, real-time
├── timetable_provider.dart  ✅ By section, by teacher
```

---

## 3. Missing Repositories (Need to Create)

### 3.1 TenantRepository (Super Admin)

```dart
// lib/data/repositories/tenant_repository.dart
class TenantRepository extends BaseRepository {
  TenantRepository(super.client);

  Future<List<Tenant>> getAllTenants() async {
    final response = await client
        .from('tenants')
        .select('*')
        .order('created_at', ascending: false);
    return (response as List).map((json) => Tenant.fromJson(json)).toList();
  }

  Future<Tenant> createTenant(Map<String, dynamic> data) async {
    final response = await client
        .from('tenants')
        .insert(data)
        .select()
        .single();
    return Tenant.fromJson(response);
  }

  Future<Tenant> updateTenant(String id, Map<String, dynamic> data) async {
    final response = await client
        .from('tenants')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return Tenant.fromJson(response);
  }

  Future<void> suspendTenant(String id) async {
    await client.from('tenants').update({'is_active': false}).eq('id', id);
  }

  Future<void> activateTenant(String id) async {
    await client.from('tenants').update({'is_active': true}).eq('id', id);
  }

  Future<Map<String, dynamic>> getTenantStats(String tenantId) async {
    final response = await client.rpc('get_tenant_stats', params: {
      'p_tenant_id': tenantId,
    });
    return response as Map<String, dynamic>;
  }
}
```

### 3.2 AcademicRepository (Admin Config)

```dart
// lib/data/repositories/academic_repository.dart
class AcademicRepository extends BaseRepository {
  AcademicRepository(super.client);

  // Academic Years
  Future<List<AcademicYear>> getAcademicYears() async {
    final response = await client
        .from('academic_years')
        .select('*')
        .eq('tenant_id', tenantId!)
        .order('start_date', ascending: false);
    return (response as List).map((j) => AcademicYear.fromJson(j)).toList();
  }

  Future<AcademicYear> createAcademicYear(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;
    final response = await client.from('academic_years').insert(data).select().single();
    return AcademicYear.fromJson(response);
  }

  // Classes
  Future<List<SchoolClass>> getClasses() async {
    final response = await client
        .from('classes')
        .select('*, sections(*)')
        .eq('tenant_id', tenantId!)
        .order('sequence_order');
    return (response as List).map((j) => SchoolClass.fromJson(j)).toList();
  }

  // Sections
  Future<List<Section>> getSections({String? classId, String? academicYearId}) async {
    var query = client.from('sections').select('*, classes(*)').eq('tenant_id', tenantId!);
    if (classId != null) query = query.eq('class_id', classId);
    if (academicYearId != null) query = query.eq('academic_year_id', academicYearId);
    final response = await query.order('name');
    return (response as List).map((j) => Section.fromJson(j)).toList();
  }

  // Subjects
  Future<List<Subject>> getSubjects() async {
    final response = await client.from('subjects').select('*').eq('tenant_id', tenantId!).order('name');
    return (response as List).map((j) => Subject.fromJson(j)).toList();
  }
}
```

### 3.3 StaffRepository (Admin)

```dart
// lib/data/repositories/staff_repository.dart
class StaffRepository extends BaseRepository {
  StaffRepository(super.client);

  Future<List<Staff>> getStaff({String? role}) async {
    var query = client
        .from('users')
        .select('*, user_roles!inner(*)')
        .eq('user_roles.tenant_id', tenantId!)
        .neq('user_roles.role', 'student')
        .neq('user_roles.role', 'parent');
    
    if (role != null) {
      query = query.eq('user_roles.role', role);
    }
    
    final response = await query.order('full_name');
    return (response as List).map((j) => Staff.fromJson(j)).toList();
  }

  Future<Staff> createStaff(Map<String, dynamic> userData, String role) async {
    // 1. Create auth user via Edge Function or admin API
    // 2. Insert into users table
    // 3. Assign role
    final response = await client.rpc('create_staff_user', params: {
      'p_tenant_id': tenantId,
      'p_email': userData['email'],
      'p_full_name': userData['full_name'],
      'p_phone': userData['phone'],
      'p_role': role,
    });
    return Staff.fromJson(response);
  }
}
```

### 3.4 AnnouncementRepository

```dart
// lib/data/repositories/announcement_repository.dart
class AnnouncementRepository extends BaseRepository {
  AnnouncementRepository(super.client);

  Future<List<Announcement>> getAnnouncements({bool publishedOnly = true}) async {
    var query = client.from('announcements').select('*').eq('tenant_id', tenantId!);
    if (publishedOnly) {
      query = query.eq('is_published', true);
    }
    final response = await query.order('created_at', ascending: false);
    return (response as List).map((j) => Announcement.fromJson(j)).toList();
  }

  Future<Announcement> createAnnouncement(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;
    data['created_by'] = currentUserId;
    final response = await client.from('announcements').insert(data).select().single();
    return Announcement.fromJson(response);
  }

  Future<void> publishAnnouncement(String id) async {
    await client.from('announcements').update({
      'is_published': true,
      'published_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }
}
```

---

## 4. Screen-by-Screen Integration Plan

### 4.1 Super Admin Screens

#### TenantsListScreen → Real Data

**Current (Mock):**
```dart
final List<Map<String, dynamic>> _tenants = [
  {'id': '1', 'name': 'Delhi Public School', ...},
  ...
];
```

**After (Real):**
```dart
// Provider
final tenantsProvider = FutureProvider<List<Tenant>>((ref) async {
  final repo = ref.watch(tenantRepositoryProvider);
  return repo.getAllTenants();
});

// Screen
class TenantsListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantsAsync = ref.watch(tenantsProvider);
    
    return tenantsAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
      data: (tenants) => ListView.builder(
        itemCount: tenants.length,
        itemBuilder: (_, i) => _TenantCard(tenant: tenants[i]),
      ),
    );
  }
}
```

#### CreateTenantScreen → Real Insert

**Add to form submit:**
```dart
Future<void> _submitForm() async {
  final repo = ref.read(tenantRepositoryProvider);
  
  // 1. Create tenant
  final tenant = await repo.createTenant({
    'name': _schoolNameController.text,
    'slug': _subdomainController.text,
    'email': _emailController.text,
    'phone': _phoneController.text,
    'address': _addressController.text,
    'subscription_plan': _selectedPlan,
  });
  
  // 2. Create admin user for tenant
  await repo.createTenantAdmin(
    tenantId: tenant.id,
    email: _adminEmailController.text,
    fullName: _adminNameController.text,
    phone: _adminPhoneController.text,
  );
}
```

### 4.2 Admin Screens

#### FeeManagementScreen → Real Data

**Replace:**
```dart
// FROM: Hard-coded
final Map<String, dynamic> _summary = {'totalCollected': 4500000.0, ...};

// TO: Provider
final feeStatsProvider = FutureProvider<Map<String, double>>((ref) async {
  final repo = ref.watch(feeRepositoryProvider);
  return repo.getFeeCollectionStats();
});

// In widget:
final statsAsync = ref.watch(feeStatsProvider);
statsAsync.when(
  data: (stats) => _SummaryCard(
    title: 'Collected',
    value: '₹${_formatAmount(stats['total_paid']!)}',
  ),
  ...
);
```

#### StaffManagementScreen → Real Data

```dart
// Provider
final staffProvider = FutureProvider.family<List<Staff>, String?>((ref, role) async {
  final repo = ref.watch(staffRepositoryProvider);
  return repo.getStaff(role: role);
});

// Tabs use different roles
final teachers = ref.watch(staffProvider('teacher'));
final admins = ref.watch(staffProvider('tenant_admin'));
```

### 4.3 Teacher Screens

#### MyClassesScreen → Real Data

**Current:** Hard-coded `_classes` list

**After:**
```dart
// Use existing timetable provider
final teacherClassesProvider = FutureProvider<List<Section>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  final repo = ref.watch(timetableRepositoryProvider);
  return repo.getTeacherSections(userId!);
});

// In widget
final classesAsync = ref.watch(teacherClassesProvider);
```

#### ClassStudentsScreen → Real Data

Already has provider! Just use it:
```dart
// Use existing provider
final studentsAsync = ref.watch(studentsBySectionProvider(widget.sectionId));
```

### 4.4 Student Screens

#### StudentTimetableScreen → Real Data

**Replace mock with:**
```dart
final studentTimetableProvider = FutureProvider<List<TimetableEntry>>((ref) async {
  final student = await ref.watch(currentStudentProvider.future);
  if (student == null) return [];
  
  final enrollment = student.currentEnrollment;
  if (enrollment == null) return [];
  
  final repo = ref.watch(timetableRepositoryProvider);
  return repo.getTimetableBySection(enrollment.sectionId);
});
```

#### StudentAttendanceScreen → Real Data

```dart
final studentAttendanceProvider = FutureProvider<List<Attendance>>((ref) async {
  final student = await ref.watch(currentStudentProvider.future);
  if (student == null) return [];
  
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getStudentAttendance(studentId: student.id);
});

final attendanceStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final student = await ref.watch(currentStudentProvider.future);
  if (student == null) return {};
  
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getAttendanceStats(studentId: student.id);
});
```

---

## 5. Button Action Checklist

### Remove or Wire These Mock Buttons:

| Screen | Button | Current | Action |
|--------|--------|---------|--------|
| TenantsListScreen | Suspend | setState only | Call `repo.suspendTenant()` |
| TenantsListScreen | Delete | setState only | Call `repo.deleteTenant()` |
| CreateTenantScreen | Create | Shows dialog only | Call `repo.createTenant()` |
| FeeManagementScreen | Generate Invoices | Shows dialog | Call `repo.generateClassInvoices()` |
| FeeManagementScreen | Record Payment | Shows sheet | Call `repo.recordPayment()` |
| AnnouncementsScreen | Publish | setState only | Call `repo.publishAnnouncement()` |
| AnnouncementsScreen | Delete | setState only | Call `repo.deleteAnnouncement()` |
| StaffManagementScreen | Add Teacher | No action | Call `repo.createStaff()` |
| ExamManagementScreen | Create Exam | Dialog only | Call `repo.createExam()` |
| ExamManagementScreen | Publish Results | Dialog only | Call `repo.publishExam()` |

---

## 6. Multi-Tenant Query Pattern

### Every tenant-scoped query MUST include:

```dart
// In repository methods
.eq('tenant_id', tenantId!)

// tenantId comes from BaseRepository
String? get tenantId {
  final claims = _client.auth.currentUser?.appMetadata;
  return claims?['tenant_id'] as String?;
}
```

### For Super Admin (cross-tenant):

```dart
// No tenant filter - sees all
Future<List<Tenant>> getAllTenants() async {
  final response = await client
      .from('tenants')
      .select('*')
      .order('created_at', ascending: false);
  return (response as List).map((json) => Tenant.fromJson(json)).toList();
}
```

---

## 7. Real-Time Subscriptions Pattern

### Already implemented in BaseRepository:

```dart
RealtimeChannel subscribeToTable(
  String table, {
  required void Function(PostgresChangePayload payload) onInsert,
  void Function(PostgresChangePayload payload)? onUpdate,
  void Function(PostgresChangePayload payload)? onDelete,
  String? filter,
})
```

### Example usage in AttendanceRepository:

```dart
RealtimeChannel subscribeToSectionAttendance({
  required String sectionId,
  required DateTime date,
  required void Function(PostgresChangePayload) onUpdate,
}) {
  return subscribeToTable(
    'attendance',
    filter: 'section_id=eq.$sectionId',
    onInsert: onUpdate,
    onUpdate: onUpdate,
  );
}
```

### Add to more tables:

```dart
// Announcements real-time
RealtimeChannel subscribeToAnnouncements(void Function(PostgresChangePayload) onUpdate) {
  return subscribeToTable(
    'announcements',
    filter: 'tenant_id=eq.$tenantId',
    onInsert: onUpdate,
  );
}

// Messages real-time (already exists in MessageRepository)
```

---

## 8. Implementation Priority

### Phase 1: Critical (Do First) ✅ DONE
1. ✅ Create TenantRepository
2. ✅ Create TenantProvider
3. ✅ Wire Super Admin screens to real data
4. ✅ Wire Admin Fee Management to real data
5. ✅ Fix all "mock-only" buttons

### Phase 2: High Priority ✅ DONE
1. ✅ Wire Teacher My Classes to real data
2. ✅ Wire Student Timetable to real data
3. ✅ Wire Student Attendance to real data
4. Wire Student Fees to real data (partial - uses existing provider)
5. Wire Parent Fee Payment to real data (partial - uses existing provider)

### Phase 3: Medium Priority
1. Wire Admin Staff Management (needs StaffRepository)
2. Wire Admin Exam Management (uses existing provider)
3. Wire Admin Announcements (needs AnnouncementRepository)
4. ✅ Wire Teacher Class Students (already has provider)

### Phase 4: Polish
1. ✅ Add loading states everywhere
2. ✅ Add error handling UI
3. ✅ Add pull-to-refresh
4. Add real-time subscriptions to critical lists

---

## 9. Files to Create/Modify

### New Files Needed:
```
lib/data/repositories/
├── tenant_repository.dart        ← NEW
├── academic_repository.dart      ← NEW
├── staff_repository.dart         ← NEW
├── announcement_repository.dart  ← NEW

lib/features/super_admin/providers/
├── tenant_provider.dart          ← NEW

lib/features/admin/providers/
├── academic_provider.dart        ← NEW
├── staff_provider.dart           ← NEW
├── announcement_provider.dart    ← NEW
```

### Files to Modify:
```
lib/features/super_admin/presentation/screens/
├── super_admin_dashboard_screen.dart  ← Use real providers
├── tenants_list_screen.dart           ← Use real providers
├── create_tenant_screen.dart          ← Real insert
├── tenant_detail_screen.dart          ← Use real providers

lib/features/admin/presentation/screens/
├── fee_management_screen.dart         ← Use real providers
├── staff_management_screen.dart       ← Use real providers
├── exam_management_screen.dart        ← Use real providers
├── announcements_screen.dart          ← Use real providers

lib/features/teacher/presentation/screens/
├── my_classes_screen.dart             ← Use real providers
├── class_students_screen.dart         ← Use existing provider
├── teacher_timetable_screen.dart      ← Use real providers

lib/features/student/presentation/screens/
├── student_timetable_screen.dart      ← Use real providers
├── student_attendance_screen.dart     ← Use real providers
├── student_fees_screen.dart           ← Use real providers
```

---

*Generated: December 6, 2025*
