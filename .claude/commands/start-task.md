# Start Task

Determine task complexity and use the appropriate workflow. This is the **entry point for every development session**.

## Usage

```text
/start-task <task-description>
```

## Steps

### 0. Pre-Task Checklist

**Context Recovery Check**:

- [ ] Check `git status` — any in-progress work?
- [ ] Check `git log --oneline -3` — what was last done?
- [ ] If active work exists: ask user "Resume previous work or start fresh?"

**Knowledge Priming (CRITICAL)**:

- [ ] Run `/prime` to load knowledge base facts
- [ ] Review MUST FOLLOW rules and GOTCHAS before proceeding
- [ ] Note any relevant patterns or decisions that constrain the approach

**PR Check**:

- [ ] Check if there are active PRs with pending comments:
  ```bash
  gh pr list --author @me --state open
  ```
- [ ] For each open PR, check for unresolved comments before starting new work

### 1. Task Assessment

**Use extended thinking** to analyze the task complexity before asking the user.

Consider:
- Number of files likely to be modified
- Whether database/migration changes are needed
- Whether new Supabase tables or RLS policies are required
- Whether Freezed models need regeneration
- Whether new routes need to be added to GoRouter
- Impact on existing functionality
- Whether it touches multi-tenant safety (tenant_id scoping)
- Testing requirements

Then confirm with user:

> **Proposed complexity**: [Simple / Complex] — Does this match your expectation?

**Simple Task (streamlined flow):**

- Bug fixes
- Small UI tweaks (color, padding, copy changes)
- Adding a missing `mounted` check or `dispose()`
- Fixing a null safety warning
- Simple configuration updates

**Complex Task (full checklist):**

- New feature screens (new widget files, new providers, new repositories)
- New Supabase tables or migrations
- Changes to authentication/authorization/routing
- Multi-file refactoring
- New role-based screens
- Performance optimizations affecting multiple screens
- Offline sync (Isar) work

### 1.5. Problem Definition Phase

Before implementation, ensure the problem is well-defined:

**If a GitHub Issue exists:**

```bash
gh issue view <number> --json title,body,labels,comments
```

Extract and verify:
- Clear scope (what's in, what's out)
- Definition of Done items (verifiable acceptance criteria)
- File scope (which files will be affected)
- Human checkpoints (where to pause for review)

**If no GitHub Issue exists:**

- For **simple tasks**: No issue needed. Proceed.
- For **complex tasks**: Ask:
  > "This is a complex task. Should I create a GitHub Issue to track it?"

**If the problem is unclear:**

- Run `/brainstorm` to refine the idea into a design
- After brainstorm commits a design document, run `/review-design` (5-agent parallel review)
- Wait for ALL APPROVED before proceeding to planning

### 2. Simple Task Flow

Essential steps:

- [ ] Run `/prime` to load knowledge base
- [ ] Read relevant files before touching them
- [ ] Check existing patterns for similar functionality
- [ ] Make the change following existing patterns
- [ ] Check against CLAUDE.md known issues (tenant_id, mounted, dispose, pagination)
- [ ] Run `flutter analyze` — must be clean
- [ ] Write/update tests if logic changes
- [ ] Run `/flutter-review <changed-file>` for quick review

### 3. Complex Task Flow

**Full workflow:**

1. **Plan First** — Use `/plan` command (invokes `planner` agent)
2. **Design Review Gate (if new feature)** — `/review-design <design-doc>` — all 5 agents APPROVED
3. **TDD** — Use `/dart-test` command — write tests FIRST
4. **Implement** — Follow the plan
5. **Validate** — `flutter analyze` must be clean; `flutter test --coverage` ≥80%
6. **Code Review** — `/flutter-review <changed-files>`
7. **UX Review** (if UI changed) — `/ux-review <screen-file>`
8. **Supabase Review** (if DB changed) — `/supabase-review`
9. **Self-Reflect** — `/self-reflect` to extract learnings
10. **PR** — Create with comprehensive description

**Pre-Implementation Flutter Checklist:**

- [ ] Migration needed? (New table, column, RLS policy change)
- [ ] Freezed model rebuild needed? (`build_runner`)
- [ ] New route needed in `app_router.dart`?
- [ ] New role-based access? (Update GoRouter redirect logic)
- [ ] tenant_id on all new tables?
- [ ] RLS policies on new tables?
- [ ] Pagination on new list screens?
- [ ] Empty/error/loading states on all async widgets?
- [ ] dispose() for all controllers/subscriptions?

### 4. Task Escalation

If a "simple task" becomes complex during implementation:

- Stop and reassess
- Create a GitHub Issue if not already done
- Switch to full workflow
- Inform user of complexity change
- Consider breaking into multiple PRs

### 5. Per-Task Quality Gates

Before marking ANY task complete:

```bash
# MANDATORY — must pass
flutter analyze          # Zero errors
flutter test             # All tests pass
flutter test --coverage  # 80%+ coverage on changed files
```

For Supabase changes:
```bash
supabase migration list  # Confirm migration applied
```

For Freezed changes:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze  # Re-check after generation
```
