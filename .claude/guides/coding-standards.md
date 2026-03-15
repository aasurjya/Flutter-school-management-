# Coding Standards — Flutter/Dart

When reviewing or writing code in this school management project, enforce the following standards. Flag violations clearly and suggest specific fixes.

---

## Dart/Flutter Fundamentals

### Null Safety (CRITICAL)

This project uses Dart null safety. Every `?` and `!` is a contract.

- Use `?` when a value genuinely can be null
- Use `??` for fallback values
- Use `!` ONLY when you are absolutely certain the value is non-null AND can prove it
- Use `?.` for safe property access on nullable types
- Use `late` only for values initialized in `initState()` or `setUp()`

```dart
// BAD — crashes at runtime
final name = user!.name!; // What if user is null?

// GOOD — safe access
final name = user?.name ?? 'Unknown';
```

**CRITICAL PROJECT RULE**: `tenantId!` in BaseRepository crashes for super_admin users (who have no tenantId in their JWT). Never force-unwrap tenantId without checking for the super_admin role first.

### Immutability (CRITICAL)

ALWAYS create new objects, NEVER mutate existing ones:

```dart
// BAD — mutation
void updateStudent(Student student) {
  student.name = 'New Name'; // MUTATION — forbidden
}

// GOOD — immutable update with copyWith
void updateStudent(Student student) {
  final updated = student.copyWith(name: 'New Name');
  state = state.copyWith(student: updated);
}
```

For Riverpod StateNotifier: ALWAYS use `state = state.copyWith(...)`, never mutate `state` properties.

---

## Riverpod Patterns

### ref.watch vs ref.read

```dart
// In build() — use watch (reactive, rebuilds on change)
Widget build(BuildContext context, WidgetRef ref) {
  final students = ref.watch(studentsProvider);
  return StudentList(students: students.value ?? []);
}

// In callbacks, handlers, async methods — use read (one-time, no rebuild)
ElevatedButton(
  onPressed: () {
    ref.read(studentsProvider.notifier).addStudent(student);
  },
)
```

**Never** use `ref.watch` inside `onPressed`, `onTap`, `initState`, `dispose`, or async methods.

### Provider Lifecycle

- Use `autoDispose` for providers tied to a specific screen's lifecycle
- Use `family` for parameterized providers (e.g., `studentProvider(studentId)`)
- Always cancel Supabase real-time subscriptions in `dispose()`

```dart
// Good: autoDispose for screen-specific state
final studentDetailProvider = FutureProvider.autoDispose.family<Student, String>(
  (ref, studentId) => ref.read(studentRepositoryProvider).getStudent(studentId),
);
```

---

## Widget Lifecycle

### dispose() is Mandatory

Every StatefulWidget that creates a controller, animation, stream subscription, or focus node MUST dispose it:

```dart
class _AttendanceScreenState extends State<AttendanceScreen> {
  late final TextEditingController _searchController;
  StreamSubscription? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _realtimeSubscription = supabase.from('attendance').stream(...).listen(...);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}
```

### mounted Check (CRITICAL)

Always check `mounted` before using `BuildContext` after any `await`:

```dart
// BAD — widget may be unmounted during await
Future<void> _save() async {
  await repository.save(data);
  Navigator.of(context).pop(); // CRASH if widget was disposed

// GOOD
Future<void> _save() async {
  await repository.save(data);
  if (!mounted) return;
  Navigator.of(context).pop();
}
```

---

## Multi-Tenant Safety

### tenant_id on ALL queries

Every Supabase query on a tenant-scoped table MUST include `.eq('tenant_id', tenantId)`:

```dart
// BAD — fetches data from ALL tenants
final response = await supabase.from('students').select();

// GOOD — tenant-scoped
final response = await supabase
    .from('students')
    .select()
    .eq('tenant_id', tenantId);
```

Tenant-scoped tables (from CLAUDE.md schema): students, staff, classes, sections, subjects, exams, assignments, attendance, fees, invoices, messages, events, and all feature-specific tables.

### tenantId Null Safety

```dart
// BAD — crashes for super_admin (no tenantId in JWT)
final tenantId = authState.tenantId!;

// GOOD — handle null case
final tenantId = authState.tenantId;
if (tenantId == null) {
  // super_admin can query across all tenants
  // OR throw a clear error if tenantId is required for this operation
}
```

---

## Pagination (CRITICAL)

EVERY list screen MUST paginate. Loading all records will crash with a large dataset.

```dart
// BAD — unbounded query
final students = await supabase.from('students').select();

// GOOD — paginated
const pageSize = 20;
final students = await supabase
    .from('students')
    .select()
    .eq('tenant_id', tenantId)
    .range(offset, offset + pageSize - 1)
    .order('created_at');
```

---

## Error Handling

### Comprehensive Error Handling

Never silently swallow errors. Always handle them explicitly:

```dart
// BAD — silent failure
try {
  await repository.save(data);
} catch (e) {
  // nothing
}

// GOOD — user-facing feedback
try {
  await repository.save(data);
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Saved successfully')),
  );
} catch (e) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error saving: ${e.toString()}')),
  );
}
```

---

## Naming Conventions

### Files (snake_case)
- Screens: `student_list_screen.dart`
- Widgets: `student_card.dart`
- Providers: `students_provider.dart`
- Repositories: `student_repository.dart`
- Models: `student.dart`

### Classes (PascalCase)
- `StudentListScreen`, `StudentRepository`, `StudentState`

### Variables and Functions (camelCase)
- `studentList`, `fetchStudents()`, `isLoading`
- Boolean: `isLoading`, `hasError`, `canEdit` — not `loading`, `error`, `edit`

---

## File Organization

```
lib/features/<feature>/
  presentation/
    screens/         ← Widget screens (UI)
    widgets/         ← Reusable sub-widgets
  providers/         ← Riverpod providers + state
  data/
    repositories/    ← Data access layer
    models/          ← Dart data classes (Freezed preferred)
```

Files: 200-400 lines typical, 800 max. Extract if larger.

---

## const Constructors

Use `const` everywhere possible for performance:

```dart
// BAD
Text('Hello World')
EdgeInsets.all(16)
Icon(Icons.home)

// GOOD
const Text('Hello World')
const EdgeInsets.all(16)
const Icon(Icons.home)
```

Add `const` to any widget or value that doesn't depend on runtime data.

---

## See Also

- [Testing Patterns](./testing-patterns.md) — Flutter test quality and coverage
- [Build Validation](./build-validation.md) — flutter analyze + test workflow
- [Git Workflow](./git-workflow.md) — commit and PR conventions
