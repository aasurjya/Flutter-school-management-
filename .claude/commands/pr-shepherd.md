---
description: Monitor a PR through to merge — handles CI failures, reviews, and thread resolution
---

# PR Shepherd

Monitor a PR from creation through merge, handling CI failures, review comments, and thread resolution.

## Usage

```text
/pr-shepherd [pr-number]
```

If no PR number provided, uses the PR associated with the current branch.

## What This Does

1. **Monitors CI/CD** — Polls for status changes
2. **Monitors Reviews** — Watches for new comments and unresolved threads
3. **Auto-fixes simple Flutter issues** — `flutter analyze` errors, missing `mounted` checks, null safety
4. **Asks before complex fixes** — Presents options with pros/cons for approval
5. **Handles review comments** — Delegates to `/handle-pr-comments`
6. **Checkpoints at 4 hours** — Asks if you want to continue or handoff

## Steps

### 1. Get PR Information

```bash
PR_NUMBER=${1:-$(gh pr view --json number -q .number 2>/dev/null)}
if [ -z "$PR_NUMBER" ]; then
  echo "No PR found. Provide PR number: /pr-shepherd 123"
  exit 1
fi

echo "Shepherding PR #$PR_NUMBER"
gh pr view $PR_NUMBER --json title,state,headRefName,checksUrl
```

### 2. Begin Monitoring Loop

Check every 60 seconds:

- CI status (flutter analyze, flutter test, build checks)
- New review comments
- Unresolved thread count
- Take action based on state

### 3. State Machine

```
PR_STATE:
  CHECKS_RUNNING   → Wait, poll every 60s
  CHECKS_FAILED    → Diagnose → auto-fix OR ask user
  REVIEWS_PENDING  → Invoke /handle-pr-comments
  ALL_GREEN        → Verify all threads resolved → report ready to merge
  STUCK            → Checkpoint with user at 4h
```

### 4. Handle Issues

**CI failures — auto-fix candidates:**
```bash
# flutter analyze errors
flutter analyze 2>&1  # Diagnose
dart fix --apply       # Auto-fix safe issues
flutter analyze        # Verify clean

# Regenerate Freezed/Riverpod code
flutter pub run build_runner build --delete-conflicting-outputs
```

**Complex failures → present options to user:**
> Found: `MissingPluginException` in CI but not local.
> Options:
> 1. Add platform channel mock to test setup
> 2. Skip this test in CI with `@Skip('CI platform issue')` + create issue
> 3. Investigate with `flutter test --verbose`
> Which approach?

### 5. Exit Conditions

**Success:**
- All CI checks pass
- All review threads resolved
- No pending reviewer comments
- Report: "PR #N is ready to merge ✓"

**4-hour checkpoint:**
- Ask: "It's been 4 hours. Continue shepherding or handoff?"

## Example

```text
/pr-shepherd 42

Shepherding PR #42: "feat: add hostel room assignment"

Current status:
- CI: ✓ flutter analyze (clean)
- CI: ✓ flutter test (47 tests passing)
- CI: ✗ build apk (failed — missing asset)
- Threads: 2 unresolved

Auto-fixing build failure...
[Adds missing asset to pubspec.yaml]
Committed fix. Waiting for CI re-run...

CI re-check:
- CI: ✓ All checks passing
- Threads: 2 unresolved

Invoking /handle-pr-comments 42...
```

## Notes

- All code changes use TDD process (test first)
- Complex issues always get user approval before fixing
- Flutter-specific: always run `flutter analyze` after any code change
- Tenant safety: any Supabase query fix must include `tenant_id` check
