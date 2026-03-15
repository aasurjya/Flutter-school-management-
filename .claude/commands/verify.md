# Verify — Flutter

Run the full Flutter validation pipeline on the current codebase state.

## Pipeline (Execute in Order)

### 1. Auto-fix

```bash
dart fix --apply
```

### 2. Analysis (MUST PASS)

```bash
flutter analyze
```

Reports all errors with file:line. Zero errors required to proceed.

### 3. Tests (MUST PASS)

```bash
flutter test
```

Reports pass/fail count. Zero failures required.

### 4. Coverage

```bash
flutter test --coverage
lcov --summary coverage/lcov.info
```

Target: 80%+ on new/changed code. Report actual percentage.

### 5. Build (Recommended for Larger Changes)

```bash
flutter build apk --debug
```

## Quick Scan (Critical Issues)

```bash
# Check for hardcoded demo credentials
grep -r "admin@school.com\|admin123\|password123" lib/ && echo "CRITICAL: Demo creds found" || echo "OK: No demo creds"

# Check for tenantId! force-unwrap
grep -r "tenantId!" lib/ && echo "WARNING: Force-unwrap found" || echo "OK"

# Check for missing pagination on common list calls
grep -r "\.from(" lib/ | grep -v "\.range(" | grep -v "//.*\.from(" | head -5
```

## Output Format

```
flutter analyze: X errors (0 = PASS)
flutter test: X failures, X tests (0 failures = PASS)
Coverage: X% (≥80% = PASS)
APK build: PASS | FAIL
Demo creds: OK | CRITICAL FOUND
```

## If Any Step Fails

- Analysis errors → use `/build-fix`
- Test failures → use `/dart-test` to diagnose
- Coverage < 80% → add tests for uncovered code
- APK build fails → use `build-error-resolver` agent
