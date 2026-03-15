# /handle-pr-comments

Handle review comments on pull requests with appropriate responses and resolutions.

## Usage

```text
/handle-pr-comments <pr-number>
```

## CRITICAL: Complete PR Lifecycle Protocol

**A PR is NOT complete until ALL of the following are true:**

1. All CI checks pass (flutter analyze clean, flutter test passing)
2. **EVERY** code review comment has been addressed (including trivial/nitpicks)
3. **EVERY** comment thread has received an individual response
4. All threads are marked as resolved (after reviewer approval)
5. Any work > 1 day has a GitHub issue created
6. No pending reviewer comments awaiting response
7. ALL tests pass — fix underlying issues, never disable tests
8. **No new reviews after last commit with actionable items** (Section 1d)

### Mandatory Comment Handling Rules

| Comment Type | Action | DO NOT Skip |
|---|---|---|
| Critical/Major | Fix immediately | Never |
| High/Medium | Fix before merge | Never |
| Minor | Fix | Never |
| **Trivial/Nitpick** | **FIX THESE TOO** | These matter! |
| **Out-of-scope** | **INVESTIGATE THOROUGHLY** | Often the BEST insights! |
| Human comments | Always address | Never |

### Work Sizing Decision

For EACH comment:

- **< 1 day of work** → Implement the fix in this PR
- **> 1 day of work** OR architectural change → Create a new GitHub issue, link it in response

### Iteration Loop

```text
REPEAT until (all_threads_resolved AND no_new_comments AND no_new_reviews_after_commit):
  1. Fetch ALL inline comments (including trivial, out-of-scope)
  1b. CHECK REVIEW BODIES for "Outside diff range" comments (Section 1c)
      - These are NOT threads - they're in the review body text
      - Commonly missed because they don't appear as threads!
  2. Check for NEW REVIEWS after last commit (Section 1d)
  3. For each comment: fix OR create issue OR respond with disagreement
  4. Run validation: flutter analyze + flutter test
  5. Commit and push
  6. Respond to EVERY thread individually
  6b. For "Outside diff range" comments: leave a general PR comment acknowledging
  7. CRITICAL: WAIT FOR CI/CD, then RE-CHECK for NEW comments/reviews
     - Monitor CI/CD: gh pr checks $PR_NUMBER --watch
     - Wait until ALL checks complete (not just pass — complete)
     - Automated reviewers post comments during/after their check
     - Check BOTH inline threads AND review bodies for new feedback
  8. If new comments OR new reviews exist → GO TO STEP 1
  9. If no new comments/reviews AND all checks complete → verify all threads resolved, then complete
```

**THE #1 WORKFLOW FAILURE**: Stopping after responding without checking for new comments/reviews.
**THE #2 WORKFLOW FAILURE**: Missing "Outside diff range" comments in review bodies.

## Workflow

### 1. Check for New Comments

```bash
PR_NUMBER=$1  # Or set manually
OWNER=$(gh repo view --json owner -q .owner.login)
REPO_NAME=$(gh repo view --json name -q .name)

echo "=== PR #$PR_NUMBER COMMENT COUNTS ==="
ISSUE_COUNT=$(gh api "repos/$OWNER/$REPO_NAME/issues/$PR_NUMBER/comments" --paginate -q 'length')
REVIEW_COUNT=$(gh api "repos/$OWNER/$REPO_NAME/pulls/$PR_NUMBER/comments" --paginate -q 'length')
echo "Issue comments: $ISSUE_COUNT"
echo "Review comments (inline): $REVIEW_COUNT"

echo ""
echo "=== INLINE REVIEW COMMENTS ==="
gh api "repos/$OWNER/$REPO_NAME/pulls/$PR_NUMBER/comments" --paginate \
  -q '.[] | "ID: \(.id) [\(.path):\(.line // .original_line // "?")] @\(.user.login): \(.body[0:100])..."'
```

### 1b. Extract "Outside Diff Range" Comments (CRITICAL)

```bash
echo "=== OUTSIDE DIFF RANGE COMMENTS ==="
gh api "repos/$OWNER/$REPO_NAME/pulls/$PR_NUMBER/reviews" --paginate | \
  python3 -c "
import json, sys
reviews = json.load(sys.stdin)
for r in reviews:
    if r.get('body') and 'diff range' in r['body'].lower():
        print(f\"Review {r['id']} by @{r['user']['login']}:\")
        print(r['body'][:500])
        print('---')
"
```

### 1c. Check for New Reviews After Last Commit

```bash
LATEST_SHA=$(gh pr view $PR_NUMBER --json headRefOid -q .headRefOid)
COMMIT_TIME=$(gh api "repos/$OWNER/$REPO_NAME/commits/$LATEST_SHA" -q .commit.committer.date)
echo "Latest commit: $LATEST_SHA at $COMMIT_TIME"

gh api "repos/$OWNER/$REPO_NAME/pulls/$PR_NUMBER/reviews" --paginate > /tmp/pr_reviews.json

python3 << 'PYEOF'
import json
from datetime import datetime

with open('/tmp/pr_reviews.json') as f:
    reviews = json.load(f)

commit_time_str = open('/tmp/commit_time.txt').read().strip() if False else None
# Read from env or manual entry
import os
commit_time = datetime.fromisoformat(os.environ.get('COMMIT_TIME', '2020-01-01T00:00:00Z').replace('Z', '+00:00'))

new_reviews = [r for r in reviews
               if datetime.fromisoformat(r['submitted_at'].replace('Z', '+00:00')) > commit_time]

if new_reviews:
    print(f"Found {len(new_reviews)} review(s) after last commit!")
    for r in new_reviews:
        actionable = 'Actionable comments posted:' in (r.get('body') or '')
        print(f"  @{r['user']['login']} [{r['state']}] {'⚠️ ACTIONABLE' if actionable else ''}")
        print(f"  Body: {(r.get('body') or '')[:150]}")
else:
    print("No new reviews after last commit")
PYEOF
```

### 2. Flutter-Specific Validation Before Push

After making fixes, run the Flutter quality gate:

```bash
echo "=== FLUTTER QUALITY GATE ==="
flutter analyze || { echo "ANALYZE FAILED"; exit 1; }
flutter test || { echo "TESTS FAILED"; exit 1; }
echo "Quality gate PASSED"
```

### 3. Post Inline Replies

```bash
COMMENT_ID=<current-comment-id>
CURRENT_USER=$(gh api user -q .login)

gh api "/repos/$OWNER/$REPO_NAME/pulls/$PR_NUMBER/comments/$COMMENT_ID/replies" \
  -X POST \
  -f body="Fixed in commit $(git rev-parse --short HEAD).

*(Response by Claude on behalf of @$CURRENT_USER)*"
```

### 4. Post-Push Verification (MANDATORY)

```bash
echo "Waiting for CI/CD checks..."
gh pr checks $PR_NUMBER --watch
echo "Re-checking for new comments..."
# Then re-run Section 1 checks
```

### 5. Best Practices

1. **Be Thorough**: Address ALL comments — including trivial/nitpicks and out-of-scope
2. **Flutter-Specific**: When fixing Flutter issues, always re-run `flutter analyze` after each fix
3. **Be Iterative**: Follow the Iteration Loop — don't declare complete until ALL threads resolved
4. **Be Responsive**: Reply to EVERY comment thread individually (not batch responses)
5. **Be Specific**: Reference exact commits, files, and line numbers
6. **Be Transparent**: Include `*(Response by Claude on behalf of @username)*`

### 6. When is the PR Truly Complete?

A PR is **NOT ready for merge** until:

1. All CI checks pass
2. `flutter analyze` is clean
3. All tests pass
4. **EVERY** comment (including trivial/nitpicks/out-of-scope) has been addressed
5. **EVERY** thread has an individual response
6. All threads marked resolved (after reviewer approval)
7. GitHub issues created for any deferred work (> 1 day)
8. **No new reviews after last commit with actionable items**

**If ANY of these are false, continue iterating.**
