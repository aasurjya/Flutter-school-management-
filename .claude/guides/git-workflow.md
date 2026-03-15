# Git Workflow Guide — Flutter/School Management

Covers branch naming, commit conventions, pre-commit verification, and PR workflows.

---

## Current Branch Awareness

**CRITICAL**: Always check your current branch before any git operation.

```bash
CURRENT_BRANCH=$(git branch --show-current)
echo "Current branch: $CURRENT_BRANCH"
gh pr list --head "$CURRENT_BRANCH" --state open
```

Never work directly on `main`.

---

## Branch Naming Conventions

| Prefix | Purpose | Example |
|--------|---------|---------|
| `feature/` | New feature screen or module | `feature/hostel-room-assignment` |
| `fix/` | Bug fix | `fix/attendance-overwrite-confirmation` |
| `chore/` | Deps, config, pubspec updates | `chore/update-flutter-3-24` |
| `refactor/` | Code restructuring | `refactor/extract-base-repository` |
| `migration/` | Supabase migration only | `migration/add-alumni-tables` |
| `test/` | Test additions | `test/attendance-provider-coverage` |
| `docs/` | Documentation | `docs/api-patterns` |
| `ci/` | CI/CD pipeline | `ci/add-coverage-gate` |
| `hotfix/` | Urgent production fixes | `hotfix/tenant-id-null-crash` |

Use kebab-case, include issue numbers: `fix/issue-42-tenant-id-crash`.

---

## Commit Guidelines

### Conventional Commit Format

```
<type>(<optional scope>): <description>

<optional body>
```

Types: `feat`, `fix`, `chore`, `refactor`, `test`, `docs`, `style`, `perf`, `ci`, `migration`

### Flutter-Specific Examples

```bash
# New feature
feat(hostel): add room assignment screen for hostel_warden role

# Bug fix
fix(auth): add mounted check before Navigator.pop() after async login

# Migration
migration: add alumni tables with tenant_id and RLS policies

# Freezed rebuild
chore(models): regenerate Freezed models after adding fee_type field

# Critical bug
fix(tenant): prevent tenantId! null crash for super_admin users
```

### Commit Message Quality

- Subject line: under 72 characters, imperative mood ("add" not "added")
- Body: explain WHY (not what — the diff shows what)
- Reference issue: `Closes #42` or `Fixes #38`

---

## Pre-Commit Verification

Before any commit:

```bash
# 1. Check current branch
git branch --show-current

# 2. Check what you're committing
git diff --staged | head -50

# 3. Flutter analysis (MANDATORY)
flutter analyze

# 4. Tests for changed files
flutter test test/features/<changed-feature>/

# 5. Build check (optional, but recommended for larger changes)
flutter build apk --debug
```

**For Supabase migration commits:**
```bash
# Verify migration file is idempotent
cat supabase/migrations/<new-migration>.sql | grep -c "IF NOT EXISTS"
# Should match number of CREATE TABLE/INDEX statements
```

**For Freezed model commits:**
```bash
# Always run build_runner before committing Freezed changes
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
# Commit both the model file AND the generated .freezed.dart / .g.dart files
```

---

## PR Creation Workflow

```bash
# 1. Verify branch
git branch --show-current

# 2. Push
git push -u origin <branch-name>

# 3. Create PR
gh pr create --title "feat: clear description" --body "$(cat <<'EOF'
## Summary
Brief description of what this PR does and why.

## Changes
- Change 1
- Change 2

## Flutter Quality
- [ ] `flutter analyze` passes (0 errors)
- [ ] `flutter test` passes
- [ ] Coverage ≥80% on changed files
- [ ] `flutter build apk --debug` succeeds

## Supabase (if applicable)
- [ ] Migration is idempotent (`IF NOT EXISTS`)
- [ ] tenant_id on all new tables
- [ ] RLS policies enabled
- [ ] Indexes for new query patterns

## Testing
- [ ] Unit tests for providers/repositories
- [ ] Widget tests for new screens
- [ ] Edge cases: loading/error/empty states

## Related Issues
Closes #XX
EOF
)"
```

---

## PR Comment Monitoring

Check for PR comments:

1. **After completing significant work** — before committing new changes
2. **After pushing to an existing PR** — check for new automated review feedback
3. **Before starting new tasks** — check all open PRs first

```bash
# List your open PRs
gh pr list --author @me --state open

# Check for new comments on a PR
gh pr view <pr-number> --json comments,reviews
```

Use `/handle-pr-comments <pr-number>` for systematic resolution.

---

## Migration Branch Pattern

For Supabase migrations:

1. Create branch with `migration/` prefix
2. Write migration in `supabase/migrations/<timestamp>_<name>.sql`
3. Test locally: `supabase db reset` (careful — destroys local data)
4. Add corresponding Flutter repository code
5. PR description must include: table names, tenant_id status, RLS status, indexes

```bash
# New migration naming
supabase migration new add_alumni_module
# Creates: supabase/migrations/20260313120000_add_alumni_module.sql
```

---

## Pipeline Pattern (Parallel Work)

When multiple agents work in parallel (e.g., across worktrees), pipeline — don't batch:

As soon as an agent finishes → push + PR + shepherd immediately. Don't wait for all agents.

---

## Best Practices

1. **Commit frequently**: Small, logical commits that each represent one coherent change
2. **Review before push**: Always `git diff` before pushing. Catch mistakes early.
3. **Keep branches updated**: Regularly `git rebase origin/main`
4. **Never force-push to main**
5. **Include generated files**: Commit `.freezed.dart` and `.g.dart` files with their source

---

## See Also

- [Build Validation](./build-validation.md) — Pre-commit validation workflow
- [Testing Patterns](./testing-patterns.md) — Test writing and coverage
