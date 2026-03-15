# Review Design

Run the design review gate on a design document with 5 parallel review agents.

## Usage

```bash
/review-design <path-to-design-doc>
```

## Examples

```bash
# Review a specific design document
/review-design docs/plans/2026-03-13-hostel-management-design.md

# Review the most recent design document
/review-design --latest

# Re-run review after revisions
/review-design docs/plans/2026-03-13-hostel-management-design.md --iteration 2
```

## What This Does

1. **Validates the design document exists** and is in the expected format
2. **Spawns five review agents in parallel**:
   - **Product Manager Agent** — Validates use cases and user benefits for school stakeholders
   - **Architect Agent** — Reviews Flutter/Supabase architecture alignment
   - **Designer Agent** — Reviews UX flows, screen design, role-appropriate patterns
   - **Security Design Agent** — Reviews tenant isolation, RLS, auth, OWASP
   - **CTO Agent** — Reviews TDD readiness, migration safety, codebase alignment
3. **Aggregates results** from all five agents
4. **Reports outcome**: APPROVED / NEEDS_REVISION / ESCALATED

## Review Verdicts

### APPROVED

All agents approve. Output includes:
- Summary of what each agent reviewed
- Non-blocking suggestions for future improvement
- Next steps for implementation

### NEEDS_REVISION

One or more agents found blocking issues. Output includes:
- List of blocking issues by agent
- Questions requiring clarification
- Iteration count (max 3 before escalation)

### ESCALATED

After 3 iterations without approval:
- Summary of remaining blockers
- Options: Override / Defer / Cancel

## Agent Details

### Product Manager Agent

Focuses on:
- WHO uses this feature (which of the 12 roles: super_admin, tenant_admin, principal, teacher, student, parent, accountant, librarian, transport_manager, hostel_warden, canteen_staff, receptionist)
- WANTS what (specific user need)
- SO THAT (measurable benefit for school operations)
- MVP scope vs nice-to-have
- Success metrics

### Architect Agent

Focuses on:
- Flutter layer separation: Screen → Provider → Repository → Supabase/Isar
- New routes needed in `app_router.dart`
- New providers (FutureProvider, StateNotifier)
- New repositories extending BaseRepository
- Integration with existing 32 feature modules
- GoRouter redirect logic for role-based access

### Designer Agent

Focuses on:
- B&W monochromatic design system compliance (Poppins, GlassCard, no colors)
- Material 3 patterns
- Empty/error/loading states for all async operations
- Mobile-first (low-end Android devices common in schools)
- Role-appropriate UX (teacher workflows vs parent vs admin)

### Security Design Agent

Focuses on:
- Multi-tenant isolation (tenant_id on all new tables, RLS policies)
- Role-based access guards in GoRouter
- `tenantId!` null safety for super_admin
- OWASP Top 10 for mobile/API
- Input validation
- No demo credentials in production paths

### CTO Agent

Focuses on:
- TDD readiness (testWidgets, Provider overrides, mocktail)
- Supabase migration needed? (idempotent, up+down)
- Freezed model rebuild needed?
- build_runner implications
- No pagination = crash risk with large datasets
- Known issues from CLAUDE.md not introduced again

## Success Criteria

The review gate passes when:

- [ ] All five agents return APPROVED
- [ ] All blocking issues resolved
- [ ] All clarifying questions answered
- [ ] Design document updated with revisions (if any)

## Integration

### After Brainstorming

This command is automatically triggered by `/brainstorm` after a design document is committed.

### Manual Invocation

Use when:
- Reviewing an existing design
- Re-reviewing after revisions
- Running selective agent review (`--skip-agent pm`)

## Related Commands

- `/brainstorm` — Creates design doc, auto-triggers this
- `/start-task` — Begins implementation after design approved
- `/plan` — Detailed implementation planning after design approval
