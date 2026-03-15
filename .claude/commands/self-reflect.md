---
description: Extract learnings from recent PR reviews, conversations, and session patterns to update the knowledge base
---

# Self-Reflect

Analyze PR review comments, conversation history, and session patterns to extract high-quality, reusable learnings for the `.claude/knowledge/` base.

**Philosophy**: Quality over quantity. Each learning should make future development measurably better.

## Phase A: PR Comment Analysis

### Step 1: Fetch Recent PR Comments

```bash
# List recent merged/open PRs
gh pr list --author @me --state all --limit 10

# Get comments on a specific PR
PR_NUMBER=<pr-number>
OWNER=$(gh repo view --json owner -q .owner.login)
REPO_NAME=$(gh repo view --json name -q .name)

gh api "repos/$OWNER/$REPO_NAME/pulls/$PR_NUMBER/comments" --paginate \
  -q '.[] | "@\(.user.login): \(.body)"'
```

### Step 2: Evaluate Learnings

**ACCEPT (High Value):**
- ALWAYS/NEVER rules — Clear, enforceable constraints
- Security/correctness issues — `tenantId`, `mounted`, `dispose()`
- Gotchas with WHY — Explains why something is problematic
- Flutter anti-patterns — Specific widget lifecycle or state management issues

**REJECT (Low Value):**
- PR-specific context that doesn't generalize
- Obvious Dart/Flutter basics any developer should know
- Duplicates of existing knowledge base entries

**TRANSFORM (Medium → High Value):**
- Before: "In PR #12, forgot mounted check after await"
- After: "ALWAYS check `mounted` before using BuildContext after any `await` — widget may be disposed during async gap"

### Quality Filter Questions

For each potential learning:

1. **Would this prevent a bug in this codebase?** If yes, high priority.
2. **Is this school-management-specific or universal Flutter?** Tag accordingly.
3. **Do we already have this?** `grep -i "keyword" .claude/knowledge/*.jsonl`
4. **Can an agent act on this?** If not actionable, skip.

## Phase B: Session Mining

Look for these patterns in the current conversation:

| Pattern | Usually Indicates | Value |
|---|---|---|
| "The problem was..." | Debugging insight | High |
| "It turns out..." | Discovery moment | High |
| "We decided to..." | Architectural decision | Very High |
| "The reason we..." | Rationale worth preserving | Very High |
| "Unlike what you'd expect..." | Non-obvious Flutter behavior | High |
| "Never do X because..." | Gotcha/pitfall | High |

## Phase C: Config Reflection

Review `.claude/` config for improvements:
- `.claude/commands/*` — Are commands still accurate?
- `CLAUDE.md` — Any outdated guidance?
- `.claude/settings.local.json` — Missing permissions?

## Step 3: Present Candidates

```markdown
## Candidate Learnings

1. **<Brief title>** — <One sentence description>
2. **<Brief title>** — <One sentence description>

Which numbers to capture? (all / 1,2,3 / none)
```

After user selects, classify each:

```
Fact: [extracted core insight]
Type: [pattern|gotcha|decision|security|performance]
Tags: [flutter, supabase, riverpod, tenant, ui, testing]
Confidence: [high|medium|low]

Does this look right? (yes / edit)
```

## Step 4: Store Learnings

For each validated learning, append to the appropriate `.claude/knowledge/` file:

```bash
# Determine which file based on tags
# flutter-patterns.jsonl → Flutter/Dart/Riverpod/GoRouter patterns
# supabase-patterns.jsonl → Supabase, database, tenant, migration patterns
# school-mgmt-decisions.jsonl → Architecture, design, role decisions

echo '{"fact":"...","type":"gotcha","tags":["flutter","async"],"confidence":"high"}' \
  >> .claude/knowledge/flutter-patterns.jsonl
```

**Canonicalization Rules:**

1. Remove PR references: "In PR #12..." → Remove, keep principle
2. Use imperative mood: "Consider using..." → "Use..."
3. Include the WHY: "Use X" → "Use X because Y"
4. Keep under 200 chars when possible
5. Generalize: `lib/features/auth/login_screen.dart` → `lib/features/*/screens/**`

## Step 5: Deduplication

Before adding, check for semantic duplicates:

```bash
python3 -c "
import json
keyword = 'mounted'  # Replace with your search term
for path in ['.claude/knowledge/flutter-patterns.jsonl', '.claude/knowledge/supabase-patterns.jsonl', '.claude/knowledge/school-mgmt-decisions.jsonl']:
    try:
        with open(path) as f:
            for line in f:
                if line.strip() and keyword in line.lower():
                    fact = json.loads(line.strip())
                    print(f\"EXISTS: {fact['fact']}\")
    except: pass
"
```

## Step 6: Generate Report

```markdown
## Self-Reflection Results

### Summary
- PRs Analyzed: X
- Comments Reviewed: Y
- Session Learnings Mined: Z
- Total New Facts Added: N

### Learnings Added
1. **[gotcha]** ALWAYS check mounted before...
   - Why accepted: Prevented crash in PR #15

### Rejected/Deferred
1. "..." — Too PR-specific, doesn't generalize

### Knowledge Base Stats
- flutter-patterns.jsonl: N facts
- supabase-patterns.jsonl: N facts
- school-mgmt-decisions.jsonl: N facts
```
