---
description: Load relevant knowledge base facts into context before starting work
---

# Knowledge Prime

**CRITICAL**: Run this command at the START of any investigation, planning, or implementation work to load relevant knowledge into your context.

## When to Use

- Starting work on a GitHub Issue or task
- Beginning investigation/research
- Before writing a plan
- Before implementing changes
- When switching to a new area of the codebase
- After context compaction (context recovery)

## How It Works

This command reads the `.claude/knowledge/*.jsonl` files for facts relevant to your current context, ensuring you:

1. Follow established patterns and rules
2. Avoid known gotchas and pitfalls
3. Make decisions aligned with architectural choices
4. Don't repeat mistakes that have been documented

## What Gets Loaded

### 1. MUST FOLLOW (Critical Rules)

Non-negotiable rules (NEVER/ALWAYS/MUST):

- "NEVER force-unwrap `tenantId!` in BaseRepository — crashes for super_admin"
- "ALWAYS add `.eq('tenant_id', tenantId)` to all Supabase queries on tenant-scoped tables"
- "ALWAYS check `mounted` before using BuildContext after an `await`"

### 2. GOTCHAS (Common Pitfalls)

Known issues to avoid:

- "Real-time Supabase channels not cleaned up → memory/connection leaks"
- "Attendance overwrite has no confirmation → silent data loss"
- "Quiz timer is client-side only → exploitable by students"

### 3. PATTERNS (Best Practices)

Established patterns in this codebase:

- "Use `ref.read` in callbacks, `ref.watch` in build()"
- "All models use `fromJson`/`toJson` with snake_case conversion"
- "Extend `BaseRepository` for all data access"

### 4. DECISIONS (Architectural Choices)

Documented decisions:

- "B&W monochromatic design system — no colored UI elements"
- "Riverpod for state, GoRouter for routing, Isar for offline"
- "12 roles with route-based access control"

## Usage

### Step 1: Read ALL knowledge files

```bash
python3 -c "
import json, sys

files = [
    '.claude/knowledge/flutter-patterns.jsonl',
    '.claude/knowledge/supabase-patterns.jsonl',
    '.claude/knowledge/school-mgmt-decisions.jsonl',
]

categories = {'must_follow': [], 'gotcha': [], 'pattern': [], 'decision': [], 'security': [], 'performance': []}

for path in files:
    try:
        with open(path) as f:
            for line in f:
                line = line.strip()
                if line:
                    fact = json.loads(line)
                    t = fact.get('type', 'pattern')
                    if t in categories:
                        categories[t].append(fact)
    except FileNotFoundError:
        pass

print('# Loaded Knowledge Base Facts\n')
for cat, facts in categories.items():
    if facts:
        print(f'## {cat.upper().replace(\"_\", \" \")} ({len(facts)} facts)\n')
        for f in facts:
            conf = f.get('confidence', 'medium')
            tags = ', '.join(f.get('tags', []))
            print(f'- [{conf}] {f[\"fact\"]}')
            if tags:
                print(f'  Tags: {tags}')
        print()
"
```

### Step 2: Filter by Keywords (Optional)

When working on a specific topic, filter relevant facts:

```bash
python3 -c "
import json, sys

keyword = sys.argv[1].lower() if len(sys.argv) > 1 else ''

files = [
    '.claude/knowledge/flutter-patterns.jsonl',
    '.claude/knowledge/supabase-patterns.jsonl',
    '.claude/knowledge/school-mgmt-decisions.jsonl',
]

for path in files:
    try:
        with open(path) as f:
            for line in f:
                line = line.strip()
                if line:
                    fact = json.loads(line)
                    if not keyword or keyword in fact['fact'].lower() or any(keyword in t for t in fact.get('tags', [])):
                        print(f\"[{fact.get('type','pattern')}] {fact['fact']}\")
    except FileNotFoundError:
        pass
" -- <KEYWORD>
```

### Step 3: Check for Active Plan

```bash
# Check if there's an interrupted plan to resume
ls -la .claude/plans/active-plan.md 2>/dev/null && echo "ACTIVE PLAN EXISTS" || echo "No active plan"
```

## Context Recovery (After Compaction)

When resuming after context compaction, run the full prime and also:

1. Check `git log --oneline -5` — see what was recently committed
2. Check `git status` — see what's in progress
3. Check `gh pr list --author @me --state open` — see open PRs

## Manual Knowledge Check

Search the knowledge base for specific topics:

```bash
# Search all knowledge files
grep -i "tenant" .claude/knowledge/*.jsonl

# Show all MUST FOLLOW / security facts
python3 -c "
import json
for path in ['.claude/knowledge/flutter-patterns.jsonl', '.claude/knowledge/supabase-patterns.jsonl', '.claude/knowledge/school-mgmt-decisions.jsonl']:
    try:
        with open(path) as f:
            for line in f:
                if line.strip():
                    fact = json.loads(line.strip())
                    if fact.get('type') in ['security', 'gotcha'] or fact.get('confidence') == 'high':
                        print(f\"[{fact['type']}] {fact['fact']}\")
    except: pass
"
```

## Output Format

After running prime, confirm:

```markdown
# Knowledge Base Loaded

_N facts loaded from 3 files_

## MUST FOLLOW
- [high] NEVER force-unwrap tenantId! — super_admin has no tenantId in JWT
- [high] ALWAYS add .eq('tenant_id', tenantId) to all Supabase queries

## GOTCHAS
- [high] Real-time channels not cleaned up on dispose — memory leak
- [high] Attendance overwrite has no confirmation — data loss risk

## PATTERNS
- [medium] Use ref.read in callbacks, ref.watch in build()
- [medium] All list screens need pagination with .range(offset, limit)

## DECISIONS
- [high] B&W monochromatic design system — Poppins font, GlassCard widgets
```

## Verification

After priming, confirm you can answer:

1. What critical rules must I follow for this task?
2. What gotchas should I watch out for in the files I'll touch?
3. What patterns should I apply?
4. What architectural decisions constrain my options?
