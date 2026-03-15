---
description: Flutter-specific code review — runs flutter analyze first, then invokes code-reviewer with Flutter context
---

# Flutter Review

Run a comprehensive Flutter/Dart code review on a file or directory. Automatically runs `flutter analyze` first, then invokes the `code-reviewer` agent with Flutter-specific context.

## Usage

```text
/flutter-review <file-or-directory>
/flutter-review lib/features/auth/presentation/screens/login_screen.dart
/flutter-review lib/features/fees/
```

## Steps

### 1. Run flutter analyze

```bash
echo "=== FLUTTER ANALYZE ==="
flutter analyze --no-pub $TARGET 2>&1

# Count issues
ISSUES=$(flutter analyze --no-pub $TARGET 2>&1 | grep -c "error\|warning\|info" || true)
echo "Analyze found: $ISSUES issues"
```

If analyze has errors: **fix them first** (use `build-error-resolver` agent).

### 2. Load Knowledge Base Context

```bash
python3 -c "
import json

# Load CRITICAL facts relevant to code review
files = ['.claude/knowledge/flutter-patterns.jsonl', '.claude/knowledge/supabase-patterns.jsonl']
for path in files:
    try:
        with open(path) as f:
            for line in f:
                if line.strip():
                    fact = json.loads(line.strip())
                    if fact.get('type') in ['security', 'gotcha'] or fact.get('confidence') == 'high':
                        print(f\"[{fact['type'].upper()}] {fact['fact']}\")
    except: pass
"
```

### 3. Run Code Review

Invoke the `code-reviewer` agent with the following Flutter-specific focus:

**Context for reviewer:**
- Project: School Management Flutter SaaS (multi-tenant, 12 roles)
- Stack: Flutter 3.2+, Riverpod, GoRouter, Supabase, Isar
- Critical checks: tenant_id scoping, mounted checks, dispose(), pagination, no demo creds

**Review the target file(s) against the Flutter code review checklist:**

1. **CRITICAL — Security**
   - Hardcoded demo credentials?
   - Missing `.eq('tenant_id', tenantId)` on Supabase queries?
   - `tenantId!` force-unwrap (crashes for super_admin)?

2. **HIGH — Flutter Lifecycle**
   - Missing `dispose()` for controllers/streams?
   - `BuildContext` used after `await` without `mounted` check?
   - `ref.watch` in callbacks (should be `ref.read`)?
   - Missing pagination on list screens?

3. **HIGH — State Management**
   - State mutation vs immutable `copyWith`?
   - Supabase real-time subscriptions not cancelled?
   - Missing error/loading states on async widgets?

4. **MEDIUM — Performance**
   - Missing `const` constructors?
   - Large lists without `ListView.builder`?
   - Heavy computation in `build()`?

5. **LOW — Code Quality**
   - Hardcoded strings (missing l10n)?
   - Magic numbers?
   - Missing empty state widgets?

### 4. Output Format

```markdown
## Flutter Review: <filename>

### Analyze Results
✓ No issues / ⚠️ N issues found (list them)

### Security (CRITICAL)
[issues or "None found"]

### Flutter Lifecycle (HIGH)
[issues or "None found"]

### Multi-Tenant Safety (HIGH)
[issues or "None found"]

### State Management (HIGH)
[issues or "None found"]

### Performance (MEDIUM)
[issues or "None found"]

### Code Quality (LOW)
[issues or "None found"]

---
## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 2 |
| MEDIUM | 1 |
| LOW | 1 |

Verdict: WARNING — 2 HIGH issues should be resolved before merge.
```

## Quick Review (Single-Pass)

For a fast check on a single file without full analysis:

```bash
# Quick grep for most critical issues
echo "=== QUICK SECURITY SCAN: $TARGET ==="
echo "Demo creds:"
grep -n "admin@school\|admin123\|password123\|demo@" "$TARGET" || echo "  None found"
echo "tenantId! unwrap:"
grep -n "tenantId!" "$TARGET" || echo "  None found"
echo "Missing mounted check (heuristic):"
grep -n "await " "$TARGET" | grep -v "mounted\|async\|//\|test" | head -5 || echo "  Check manually"
```
