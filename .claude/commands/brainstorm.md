# Brainstorm

Collaborative design process for new features or complex problems, followed by the design review gate.

## Usage

```text
/brainstorm <idea or problem description>
```

## Behavior

1. Ask clarifying questions one at a time to fully understand the problem
2. Propose 2-3 approaches with trade-offs, school-management-specific constraints
3. Present design sections for approval
4. Write design doc to `docs/plans/YYYY-MM-DD-<topic>-design.md`
5. **Automatically trigger `/review-design`** — all 5 agents must APPROVE before proceeding to planning

## Clarifying Questions to Ask

For any school management feature, explore:

1. **Who uses this?** Which of the 12 roles: super_admin, tenant_admin, principal, teacher, student, parent, accountant, librarian, transport_manager, hostel_warden, canteen_staff, receptionist?
2. **What's the core workflow?** Step-by-step what the user does
3. **What data is involved?** New tables or existing? Tenant-scoped?
4. **Are there existing similar screens?** Check `lib/features/` for reference
5. **Offline support needed?** (Isar sync implications)
6. **Multi-school (multi-tenant) implications?** Any school-specific config?

## Design Document Template

```markdown
# Design: <Feature Name>

**Date**: YYYY-MM-DD
**Status**: Draft

## Problem

<What pain point or user need this addresses>

## Users

| Role | Use Case | Benefit |
|------|----------|---------|

## Solution

### Approach A: <name>
- Pros: ...
- Cons: ...

### Approach B: <name>
- Pros: ...
- Cons: ...

### Recommended: Approach X

## Architecture

### New Files
- `lib/features/<name>/presentation/screens/<screen>.dart`
- `lib/features/<name>/providers/<provider>.dart`
- `lib/features/<name>/data/repositories/<repo>.dart`

### New Routes
- `/<path>` — added to `app_router.dart`

### New Tables (if any)
- `table_name` — columns, tenant_id: YES, RLS: YES
- Migration: `supabase/migrations/<timestamp>_<name>.sql`

### Freezed Models (if any)
- `lib/data/models/<model>.dart` — fields

## Screens

### Screen 1: <ScreenName>
- Purpose: ...
- State: (loading / loaded / error / empty)
- Actions: ...

## Security Considerations

- tenant_id on all queries: YES/NO
- Role guards: which roles access which screens
- Input validation: ...

## Testing Strategy

- Unit tests: repositories, providers
- Widget tests: key screens
- Edge cases: empty state, error state, pagination

## Definition of Done

- [ ] <verifiable item 1>
- [ ] <verifiable item 2>
- [ ] All screens have loading/error/empty states
- [ ] flutter analyze clean
- [ ] flutter test passing with 80%+ coverage
- [ ] Supabase migration applied and tested
```

## After Brainstorming

**MANDATORY HANDOFF**: After design document is committed, you MUST:

1. STOP — do NOT proceed directly to implementation
2. Run `/review-design docs/plans/<filename>.md`
3. Wait for all 5 review agents (PM, Architect, Designer, Security, CTO) to APPROVE
4. Only after ALL APPROVED, proceed to `/plan`

## Related Commands

- `/review-design` — Auto-triggered after brainstorming
- `/plan` — Detailed implementation planning (after design approval)
- `/start-task` — Task entry point after planning
