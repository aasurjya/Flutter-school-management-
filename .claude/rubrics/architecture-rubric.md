# Architecture Rubric — Flutter/School Management

**Used By**: Architect Agent, Plan Reviewer Agent
**Purpose**: Ensure implementation plans follow Flutter architecture and patterns
**Version**: 1.0

---

## Flutter Architecture Layers

```
UI (Screens/Widgets)
    ↓
Riverpod Providers (FutureProvider, StateNotifier, StateProvider)
    ↓
Repository Layer (extends BaseRepository)
    ↓
Supabase (cloud) + Isar (local offline)
```

Every piece of code belongs in exactly one layer. Violations are HIGH or CRITICAL.

---

## Reference Documents

| Document | Purpose |
| --- | --- |
| `CLAUDE.md` | Architecture, known issues, 12 roles, key file paths |
| `.claude/guides/coding-standards.md` | Dart null safety, Riverpod patterns, multi-tenant rules |
| `lib/data/repositories/base_repository.dart` | BaseRepository — the data layer contract |
| `lib/core/router/app_router.dart` | GoRouter — role-based routing (12 roles) |

---

## Evaluation Categories

### 1. Layer Placement (CRITICAL)

| Layer | Purpose | Location |
| --- | --- | --- |
| **Screens** | UI rendering, user interaction | `lib/features/<name>/presentation/screens/` |
| **Widgets** | Reusable sub-widgets | `lib/features/<name>/presentation/widgets/` |
| **Providers** | State management, business logic | `lib/features/<name>/providers/` |
| **Repositories** | Data access (Supabase + Isar) | `lib/features/<name>/data/repositories/` |
| **Models** | Data classes (Freezed preferred) | `lib/features/<name>/data/models/` |

**Check**: Is the proposed code in the correct layer?

```dart
// WRONG — business logic in screen
class StudentScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final data = await supabase.from('students').select(); // direct DB call!
    ...
  }
}

// RIGHT — screen delegates to provider → repository
class StudentScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(studentsProvider('tenant_123'));
    ...
  }
}
```

---

### 2. Riverpod Patterns (HIGH)

| Check | Criterion |
| --- | --- |
| `ref.watch` only in `build()` | Not in callbacks, initState, or async methods |
| `ref.read` in callbacks | Event handlers, onPressed, initState |
| `autoDispose` for screen-specific | Don't leak providers between screens |
| `family` for parameterized data | e.g., `studentsProvider(tenantId)` |
| StateNotifier uses `copyWith` | Never mutate state directly |

---

### 3. Repository Pattern (HIGH)

| Check | Criterion |
| --- | --- |
| Extends `BaseRepository` | All repositories use base class |
| `tenant_id` on all queries | Every query scoped to tenant |
| Pagination present | `.range(offset, offset + pageSize - 1)` |
| No direct Supabase in providers | Providers call repositories, not Supabase |
| Isar for offline | Offline-first data uses Isar, not Supabase |

---

### 4. GoRouter / Navigation (MEDIUM)

| Check | Criterion |
| --- | --- |
| Named routes used | Not hardcoded path strings |
| Role-based guards | Routes check user role via GoRouter redirect |
| ShellRoute for bottom nav | Persistent navigation uses existing shell |
| New routes added to `app_router.dart` | Not using `Navigator.push` directly for main flows |

---

### 5. Multi-Tenant Data Model (CRITICAL)

| Check | Criterion |
| --- | --- |
| New tables have `tenant_id` | Every schema addition scoped to tenant |
| RLS policies added | Row-level security for each new table |
| Migration is idempotent | `IF NOT EXISTS` on all create statements |
| Indexes for query patterns | New `.eq()` patterns have supporting indexes |

---

### 6. Offline Sync (Isar) (MEDIUM)

| Check | Criterion |
| --- | --- |
| Isar models exist if offline needed | Don't block offline on missing models |
| Sync logic planned | Don't just add Isar model without sync |
| Conflict resolution defined | Server wins vs local wins policy |

---

### 7. Error Handling Strategy (HIGH)

| Layer | Error Handling |
| --- | --- |
| Screens | Show error widget, retry button |
| Providers | Expose `AsyncError` state |
| Repositories | Catch `PostgrestException`, rethrow domain exception |

---

## Review Checklist

```markdown
### Layer Placement
- [ ] Screens only do UI, no direct DB calls
- [ ] Providers contain business logic
- [ ] Repositories contain all Supabase/Isar calls
- [ ] Models are in data/models/

### Riverpod
- [ ] ref.watch only in build()
- [ ] ref.read in callbacks
- [ ] autoDispose used for screen-specific providers
- [ ] StateNotifier uses copyWith

### Repository
- [ ] Extends BaseRepository
- [ ] All queries have tenant_id filter
- [ ] Pagination present on list queries
- [ ] No direct Supabase in providers

### Navigation
- [ ] Named routes used
- [ ] Role guards respected
- [ ] New routes added to app_router.dart

### Data Model
- [ ] New tables have tenant_id
- [ ] Migrations are idempotent (IF NOT EXISTS)
- [ ] RLS policies added
- [ ] Indexes for new queries

### Testing
- [ ] Provider tests use ProviderContainer + overrides
- [ ] Repository tests verify tenant_id filter
- [ ] Widget tests wrap in ProviderScope
```

---

## Output Format

```markdown
## Architecture Review: <feature or task>

### Verdict: APPROVED | NEEDS REVISION

### Layer Placement
**Status**: Correct | Needs Adjustment
<Analysis>

### Riverpod Patterns
**Status**: Correct | Needs Adjustment
<Analysis>

### Multi-Tenant Safety
**Status**: Correct | Needs Adjustment
<Analysis>

### Recommendations
1. <Specific recommendation>

### Reference Examples
- `lib/features/attendance/providers/` — provider pattern with tenant scoping
- `lib/features/fees/data/repositories/` — BaseRepository with pagination
```

---

## Common Issues

### 1. Business Logic in Screens

Move calculations and Supabase calls to providers/repositories.

### 2. Missing pagination

Every list screen MUST paginate. Will crash with large school datasets.

### 3. Missing tenant_id

CRITICAL multi-tenant safety violation. Can cause data leaks between schools.

### 4. Provider not autoDisposed

Memory leak — provider stays alive after screen is removed.

### 5. Force-unwrapped tenantId

`tenantId!` crashes for super_admin users who have no tenantId in JWT.
