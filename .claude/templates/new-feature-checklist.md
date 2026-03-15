# New Feature Checklist — Flutter Module

Use this checklist when building a new feature module from scratch.

---

## File Structure to Create

```
lib/features/<feature_name>/
  presentation/
    screens/
      <feature>_screen.dart          ← Main screen widget (ConsumerWidget)
    widgets/
      <feature>_card.dart            ← Reusable sub-widgets
  providers/
    <feature>_provider.dart          ← Riverpod providers + StateNotifier
  data/
    repositories/
      <feature>_repository.dart      ← Supabase data access (extends BaseRepository)
    models/
      <feature>.dart                 ← Data class (@freezed preferred)
      <feature>.freezed.dart         ← Generated (run build_runner)
      <feature>.g.dart               ← Generated (run build_runner)

test/features/<feature_name>/
  presentation/
    screens/
      <feature>_screen_test.dart
  providers/
    <feature>_provider_test.dart
  data/
    repositories/
      <feature>_repository_test.dart
```

---

## Implementation Checklist

### 1. Model (Data Class)

- [ ] Create `lib/features/<name>/data/models/<model>.dart`
- [ ] Use `@freezed` annotation for new models
- [ ] Include `tenant_id` field on all tenant-scoped models
- [ ] Run `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] Commit both `.dart` and `.freezed.dart`/`.g.dart` files

### 2. Repository

- [ ] Create `lib/features/<name>/data/repositories/<name>_repository.dart`
- [ ] Extend `BaseRepository`
- [ ] Add `.eq('tenant_id', tenantId)` to all queries
- [ ] Add `.range(offset, offset + pageSize - 1)` for list queries
- [ ] Handle `PostgrestException` explicitly
- [ ] No `tenantId!` force-unwrap

### 3. Riverpod Provider

- [ ] Create `lib/features/<name>/providers/<name>_provider.dart`
- [ ] Use `autoDispose` for screen-specific providers
- [ ] Use `family` for parameterized providers
- [ ] Expose `AsyncValue<T>` for async data
- [ ] State mutations use `state = state.copyWith(...)`
- [ ] `ref.watch` only used in `build()` contexts

### 4. Screen Widget

- [ ] Create `lib/features/<name>/presentation/screens/<name>_screen.dart`
- [ ] Extends `ConsumerWidget` (or `ConsumerStatefulWidget`)
- [ ] Handle all 3 states: loading, error, data
- [ ] Show `CircularProgressIndicator` or shimmer while loading
- [ ] Show `AppErrorWidget` with retry on error
- [ ] Show `EmptyState` widget when data is empty
- [ ] `const` constructors on all static widgets
- [ ] `if (!mounted) return;` after any `await` using `BuildContext`

### 5. GoRouter Integration

- [ ] Add route constant to `lib/core/router/app_router.dart`
- [ ] Add route to appropriate role's navigation section
- [ ] Add to role-based redirect if role-restricted
- [ ] Add to bottom nav shell if appropriate
- [ ] Test navigation from other screens

### 6. Supabase Migration (If New Tables)

- [ ] Run `supabase migration new <feature_name>` to create migration file
- [ ] Add `tenant_id UUID NOT NULL REFERENCES tenants(id)` to all new tables
- [ ] Enable RLS: `ALTER TABLE <name> ENABLE ROW LEVEL SECURITY`
- [ ] Add RLS policy for tenant isolation
- [ ] Add index on `tenant_id`
- [ ] Add indexes for expected query patterns
- [ ] Verify idempotency: all statements use `IF NOT EXISTS`
- [ ] Test migration with `supabase db reset` (local only — destroys local data)

### 7. Tests

- [ ] Repository test: verifies `tenant_id` filter is applied
- [ ] Repository test: verifies pagination `.range()` is called
- [ ] Provider test: uses `ProviderContainer` with overrides
- [ ] Provider test: tests loading, success, and error states
- [ ] Widget test: tests all 3 UI states (loading, error, data)
- [ ] Widget test: tests empty state
- [ ] Widget test: `expect(find.text('admin@school.com'), findsNothing)` (if login-adjacent)
- [ ] Coverage ≥ 80% on new files

### 8. Integration

- [ ] Feature accessible from correct dashboard role(s)
- [ ] Navigation from dashboard to screen works
- [ ] Back navigation works
- [ ] `flutter analyze` passes with 0 errors
- [ ] `flutter test` passes with 0 failures

---

## Quality Gates Before PR

```bash
# 1. Freeze models regenerated
flutter pub run build_runner build --delete-conflicting-outputs

# 2. Analysis clean
flutter analyze

# 3. Tests pass with coverage
flutter test --coverage
lcov --summary coverage/lcov.info

# 4. Build succeeds
flutter build apk --debug
```

All 4 must pass before creating a PR.
