# Build Validation Guide — Flutter

This guide covers the Flutter build pipeline, validation workflows, and systematic error resolution.

---

## Command Timeout Guidelines

Claude Code has a default 2-minute timeout for Bash commands.

| Command | Timeout (ms) | Duration |
|---------|-------------|---------|
| `flutter analyze` | 120000 | 2 minutes |
| `flutter test` | 300000 | 5 minutes |
| `flutter test --coverage` | 360000 | 6 minutes |
| `flutter build apk` | 600000 | 10 minutes |
| `flutter pub run build_runner build` | 300000 | 5 minutes |
| `flutter clean` + `flutter pub get` | 120000 | 2 minutes |

---

## Build Process Overview

Standard validation pipeline for Flutter, executed in order:

```text
1. dart fix --apply          — Auto-fix safe analysis issues
2. flutter analyze           — Structural correctness + type safety
3. flutter test              — Behavioral correctness
4. flutter test --coverage   — Coverage threshold enforcement (80%)
5. flutter build apk --debug — Production artifact generation
```

### Validation Order (Fail Fast)

Always validate in this order:

1. **`dart fix --apply`** — Fix auto-fixable issues first
2. **`flutter analyze`** — Catches type errors, null safety issues, lint
3. **`flutter test`** — Catches behavioral regressions
4. **`flutter test --coverage`** — Ensures coverage ≥80% on changed code
5. **`flutter build apk --debug`** — Ensures APK can be produced

If any step fails, stop and fix before proceeding.

---

## Critical Validation Workflow

**Before marking ANY task complete**, you MUST validate your changes.

### Incremental Checks (During Development)

```bash
# Quick analysis on changed files
flutter analyze

# Run tests for specific feature
flutter test test/features/<feature>/
```

### Full Validation (Before Completion)

```bash
# MANDATORY before marking task complete:
dart fix --apply                          # Auto-fix safe issues
flutter analyze                           # Must pass with 0 errors
flutter test                              # Must pass with 0 failures
flutter test --coverage                   # Must meet 80% target
flutter build apk --debug                 # Must build successfully
```

### Code Generation (When Freezed/Riverpod Models Changed)

```bash
# Regenerate Freezed models and Riverpod code
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze  # Re-check after generation
```

**Run build_runner when:**
- Adding a new `@freezed` model
- Adding a new Riverpod provider with `@riverpod` annotation
- Adding a new `@JsonSerializable` class
- Seeing errors about missing `.freezed.dart` or `.g.dart` files

---

## File Tracking for Targeted Validation

```bash
# Check what you've changed
git diff --name-only --diff-filter=ACM | grep "\.dart$"

# Run analysis on changed files only
flutter analyze $(git diff --name-only --diff-filter=ACM | grep "\.dart$" | head -10)
```

---

## Coverage Enforcement

**Target: 80% on new/changed code.**

```bash
# Generate coverage report
flutter test --coverage

# View summary (requires lcov)
lcov --summary coverage/lcov.info

# Extract coverage for specific feature
lcov --extract coverage/lcov.info "*/features/fees/*" \
  --output-file /tmp/fees.info
lcov --summary /tmp/fees.info

# Generate HTML report for detailed view
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## Build Error Resolution

### Systematic Error Fixing Process

1. **Identify ALL errors first**: `flutter analyze 2>&1 | head -100`
2. **Group errors by type**: Null safety, missing imports, type mismatches, Freezed issues
3. **Fix errors systematically**: Start with missing imports (often cascade), then types
4. **Verify each fix**: Re-run `flutter analyze` after each batch

### Build Failure Triage

| Error Type | First Action | Common Cause |
|---|---|---|
| Null safety errors | Add `?`, `??`, or null check | Type change or missing initialization |
| `Missing concrete implementation` | Implement abstract methods | Interface added to class |
| `Cannot find module` | Check pubspec.yaml, run `flutter pub get` | Missing package |
| Freezed errors | Run `build_runner build` | Generated files out of date |
| `mounted` warning | Add `if (!mounted) return;` | Context used after await |
| `ref.watch` in callback | Change to `ref.read` | Wrong provider read method |
| Widget test failure | Check `pumpAndSettle()` after async | Async widget not settled |

### Quick Recovery Scripts

```bash
# Nuclear clean + rebuild
flutter clean && flutter pub get && flutter analyze

# With code generation
flutter clean && flutter pub get && \
  flutter pub run build_runner build --delete-conflicting-outputs && \
  flutter analyze

# Fix auto-fixable issues
dart fix --apply && flutter analyze
```

---

## CI/CD Pipeline

### GitHub Actions Flutter Template

Located at `.claude/templates/ci.yml` — copy to `.github/workflows/ci.yml`.

**Pipeline stages:**
1. `flutter pub get`
2. `flutter analyze`
3. `flutter test --coverage`
4. Coverage check (≥80%)
5. `flutter build apk --release` (optional)

---

## Pre-Commit Checklist

Before ANY git commit:

```bash
# 1. Analysis
flutter analyze

# 2. Tests
flutter test

# 3. Coverage (for new features)
flutter test --coverage && lcov --summary coverage/lcov.info

# 4. Build check
flutter build apk --debug
```

**Success Criteria**: Only mark task complete when:
- `flutter analyze` returns 0 errors
- `flutter test` returns 0 failures
- Coverage ≥80% on changed code
- `flutter build apk --debug` succeeds

---

## Common Flutter-Specific Gotchas

1. **Build order matters**: Modify pubspec.yaml → `flutter pub get` → `build_runner` → `flutter analyze`
2. **Freezed part directives**: Always have `part 'model.freezed.dart'` before any Freezed usage
3. **Generated file conflicts**: Use `--delete-conflicting-outputs` with `build_runner`
4. **Platform channel tests**: Some plugins need platform mocking in widget tests
5. **Async widget tests**: Always `await tester.pumpAndSettle()` after async operations

---

## See Also

- [Coding Standards](./coding-standards.md) — Dart/Flutter quality rules
- [Testing Patterns](./testing-patterns.md) — Test writing and coverage
- [Git Workflow](./git-workflow.md) — Commit and PR conventions
