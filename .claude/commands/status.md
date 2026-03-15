# Status

Show Flutter project diagnostic information and knowledge base stats.

## Usage

```text
/status
```

## What This Reports

### 1. Flutter Environment

```bash
flutter doctor -v | head -30
flutter --version
dart --version
```

### 2. Analysis Status

```bash
echo "=== FLUTTER ANALYZE ==="
flutter analyze --no-pub 2>&1 | tail -5
# Expected: "No issues found!" or count of issues
```

### 3. Knowledge Base Statistics

```bash
python3 -c "
import json, os

files = {
    'flutter-patterns': '.claude/knowledge/flutter-patterns.jsonl',
    'supabase-patterns': '.claude/knowledge/supabase-patterns.jsonl',
    'school-mgmt-decisions': '.claude/knowledge/school-mgmt-decisions.jsonl',
}

total = 0
print('=== KNOWLEDGE BASE ===')
for name, path in files.items():
    try:
        with open(path) as f:
            facts = [l for l in f if l.strip()]
            count = len(facts)
            total += count
            types = {}
            for line in facts:
                try:
                    t = json.loads(line.strip()).get('type', 'unknown')
                    types[t] = types.get(t, 0) + 1
                except: pass
            print(f'{name}: {count} facts — {dict(sorted(types.items()))}')
    except FileNotFoundError:
        print(f'{name}: NOT FOUND — run /self-reflect to populate')
print(f'Total: {total} facts')
"
```

### 4. Active PRs

```bash
echo "=== OPEN PRs ==="
gh pr list --author @me --state open --json number,title,reviewDecision \
  -q '.[] | "#\(.number) \(.reviewDecision // "PENDING") — \(.title)"' 2>/dev/null || echo "No open PRs"
```

### 5. Project Health

```bash
echo "=== PROJECT HEALTH ==="

# Count Dart files
echo "Dart files: $(find lib/ -name '*.dart' | wc -l | tr -d ' ')"

# Count test files
echo "Test files: $(find test/ -name '*_test.dart' 2>/dev/null | wc -l | tr -d ' ')"

# Check for known critical issues
echo ""
echo "=== KNOWN CRITICAL ISSUES CHECK ==="

# Check for hardcoded credentials (demo)
CREDS=$(grep -r "admin@school\|admin123\|password123\|demo@\|test@school" lib/ --include="*.dart" -l 2>/dev/null | head -3)
if [ -n "$CREDS" ]; then
  echo "⚠️  CRITICAL: Demo credentials found in:"
  echo "$CREDS"
else
  echo "✓  No hardcoded demo credentials"
fi

# Check for tenantId! usage
TENANT=$(grep -rn "tenantId!" lib/ --include="*.dart" -l 2>/dev/null | head -3)
if [ -n "$TENANT" ]; then
  echo "⚠️  HIGH: tenantId! force-unwrap found in:"
  echo "$TENANT"
else
  echo "✓  No tenantId! force-unwrap"
fi

# Check for missing mounted checks (basic heuristic)
echo ""
echo "=== COMMANDS AVAILABLE ==="
ls .claude/commands/ | sed 's/\.md$//' | sort | column -c 80
```

### 6. Git Status

```bash
echo "=== GIT STATUS ==="
git branch --show-current
git log --oneline -3
git status --short | head -10
```

## Example Output

```
=== FLUTTER VERSION ===
Flutter 3.22.0 • channel stable
Dart SDK version: 3.4.0

=== FLUTTER ANALYZE ===
No issues found!

=== KNOWLEDGE BASE ===
flutter-patterns: 18 facts — {gotcha: 6, pattern: 8, security: 4}
supabase-patterns: 12 facts — {gotcha: 4, pattern: 5, security: 3}
school-mgmt-decisions: 8 facts — {decision: 6, pattern: 2}
Total: 38 facts

=== OPEN PRs ===
#7 REVIEW_REQUIRED — feat: add hostel room assignment

=== PROJECT HEALTH ===
Dart files: 247
Test files: 23

=== KNOWN CRITICAL ISSUES CHECK ===
⚠️  CRITICAL: Demo credentials found in:
    lib/features/auth/presentation/screens/login_screen.dart
✓  No tenantId! force-unwrap
```
