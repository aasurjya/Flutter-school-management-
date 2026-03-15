# Task Completion Checklist — Flutter

**CRITICAL**: Follow this checklist before marking ANY development task complete.

---

## Quick Tasks (Small bug fixes, single-file changes)

Minimum required for straightforward changes:

1. Run `flutter analyze` — zero errors
2. Run `flutter test test/features/<feature>/` — zero failures
3. Review `git diff` before committing
4. Check `mounted` and `dispose()` for any async/lifecycle changes

Escalate to Full Checklist for: new screens, new providers, new repositories, DB schema changes, multi-file refactoring.

---

## Pre-Work Checklist (Before Writing Code)

- [ ] Check if a screen/provider/repository already exists for this functionality
- [ ] Check `CLAUDE.md` for known issues related to this feature
- [ ] Check if Freezed models need regeneration (new fields added?)
- [ ] Check if a Supabase migration is needed (new table/column?)
- [ ] Check if GoRouter needs updating (new route?)

---

## Full Checklist

### 1. Flutter Analysis

```bash
# Auto-fix safe issues
dart fix --apply

# MUST pass with 0 errors
flutter analyze
```

- [ ] `flutter analyze` returns 0 errors
- [ ] No `dart fix` suggestions ignored without explanation

### 2. Test Verification

```bash
# Run all tests
flutter test

# Run tests for changed feature only
flutter test test/features/<feature>/

# Coverage check
flutter test --coverage && lcov --summary coverage/lcov.info
```

- [ ] All tests pass (0 failures)
- [ ] No tests removed or commented out
- [ ] Coverage ≥ 80% on new/changed code
- [ ] Edge cases tested (null, empty, error state)

### 3. Freezed / Code Generation (If Models Changed)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
```

- [ ] `build_runner` run if any `@freezed`, `@riverpod`, or `@JsonSerializable` changes
- [ ] Generated `.freezed.dart` and `.g.dart` files committed
- [ ] `flutter analyze` passes after regeneration

### 4. Multi-Tenant Safety

- [ ] All new Supabase queries include `.eq('tenant_id', tenantId)`
- [ ] No `tenantId!` force-unwrap without null guard
- [ ] New tables have `tenant_id` column and RLS policies
- [ ] Migrations are idempotent (`IF NOT EXISTS`)

### 5. Flutter Safety

- [ ] All controllers/subscriptions disposed in `dispose()`
- [ ] `if (!mounted) return;` after every `await` that uses `BuildContext`
- [ ] `ref.watch` only in `build()`, `ref.read` in callbacks
- [ ] `const` used on all static widgets/values

### 6. Security Check

- [ ] No hardcoded credentials (`admin@school.com`, `admin123`)
- [ ] No tokens or secrets in `print()` / `debugPrint()`
- [ ] User input validated before Supabase writes
- [ ] Role-based route guards respected

### 7. Performance

- [ ] List screens use `.range()` for pagination
- [ ] No N+1 query patterns (no Supabase calls in loops)
- [ ] Real-time subscriptions properly scoped and disposed

### 8. Build Verification (Optional but Recommended for Larger Changes)

```bash
flutter build apk --debug
```

- [ ] APK builds without errors
- [ ] No new runtime warnings in debug output

### 9. PR Preparation

- [ ] `git diff` reviewed — no unintended changes
- [ ] `git diff --name-only` checked — only in-scope files changed
- [ ] Commit message follows conventional commits format
- [ ] Branch follows naming convention (`feature/`, `fix/`, `migration/`, etc.)

---

## Red Flags — Stop and Think

- About to skip `flutter analyze`? **STOP** — always analyze before committing
- About to commit without tests for new code? **STOP** — write tests first
- Seeing `tenantId!` in new code? **STOP** — add null check
- About to commit generated files that show unrelated changes? **STOP** — run `build_runner` cleanly

---

## Final Verification

Before responding that the task is complete:

1. Has `flutter analyze` been run and returned 0 errors?
2. Do all tests pass?
3. Is coverage ≥ 80% on changed code?
4. Is the code production-safe (no demo creds, tenant_id scoped, disposed)?

If any answer is "no" — continue working.
