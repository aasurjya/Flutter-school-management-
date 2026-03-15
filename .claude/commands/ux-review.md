---
description: Run all 4 UX review agents in parallel on a screen and generate a unified CRITICAL/HIGH/MEDIUM/LOW report
---

# UX Review

Run all 4 UX review agents in parallel on a Flutter screen file and produce a unified prioritized report.

## Usage

```text
/ux-review <screen-file>
/ux-review lib/features/dashboard/presentation/screens/admin_dashboard_screen.dart
/ux-review lib/features/auth/presentation/screens/login_screen.dart
```

## What This Does

Spawns 4 agents in **parallel**:

1. **ux-norman-reviewer** — 7 Norman principles (Discoverability, Feedback, Conceptual Model, Affordances, Signifiers, Mapping, Constraints)
2. **ux-grid-reviewer** — Müller-Brockmann grid (8dp system, typography, spacing, alignment)
3. **ux-interaction-reviewer** — Micro-interactions, animations, flow quality, emotional design
4. **ux-accessibility-reviewer** — WCAG AA compliance, touch targets, color contrast, semantics

## School Management Domain Context

Pass this context to all 4 agents:

**Target Users (by role):**
- **Admin/Principal**: Dashboard overview, management tasks — needs information density + clarity
- **Teachers**: Daily attendance, grade entry — needs speed + minimal taps
- **Students**: View grades, assignments, timetable — needs simplicity
- **Parents**: Monitor child's progress — needs reassurance + easy navigation
- **Staff (librarian, canteen, hostel)**: Quick operational tasks on mobile

**Device Context:**
- Primary: Low-to-mid-range Android phones (most common in schools)
- Screen size: 5-6 inch typical
- Touch: Frequent use with one hand, outdoors lighting
- Network: Intermittent — offline states must be handled gracefully

**Design System:**
- B&W monochromatic (no colored UI elements)
- Poppins font family
- GlassCard widget for frosted-glass aesthetic
- Material 3 components

## Aggregated Output Format

```markdown
# UX Review: <ScreenName>

## Overall Score

| Agent | Score |
|-------|-------|
| Norman (Usability) | A-F |
| Grid (Visual System) | A-F |
| Interaction (Feel) | A-F |
| Accessibility (WCAG) | AA/A/FAIL |

---

## CRITICAL Issues (Fix Before Release)

1. **[accessibility]** Touch targets below 48dp: delete icon at line 234 is 24dp
2. **[norman]** No feedback when form submits — user has no confirmation of success

## HIGH Issues (Fix Before Merge)

1. **[grid]** Inconsistent spacing: cards use 13dp padding (should be 12 or 16)
2. **[interaction]** Missing loading state for async data — blank screen during fetch
3. **[accessibility]** Status badge conveys meaning by color only — add text label

## MEDIUM Issues (Fix Soon)

1. **[norman]** Delete action has no confirmation dialog
2. **[grid]** 5 different font sizes on screen — reduce to 3
3. **[interaction]** No skeleton/shimmer loading — jarring blank → full transition

## LOW Issues / Suggestions

1. **[interaction]** Consider success animation after save action
2. **[accessibility]** Add tooltips to icon-only buttons for screen reader users
3. **[norman]** Empty state could include a CTA to create first item

---

## Per-Agent Detail

### Norman Review
[Full JSON output from ux-norman-reviewer]

### Grid Review
[Full JSON output from ux-grid-reviewer]

### Interaction Review
[Full JSON output from ux-interaction-reviewer]

### Accessibility Review
[Full JSON output from ux-accessibility-reviewer]
```

## School-Specific UX Checklist

Always check these school-management-specific patterns:

- [ ] Role-appropriate information density (admin sees more, student sees less)
- [ ] Offline-aware: show cached data indicator when not connected
- [ ] Large touch targets (teachers often use in classrooms while standing)
- [ ] Clear loading states for Supabase data fetches
- [ ] Empty states for new schools (no students/classes yet)
- [ ] Error recovery paths (network error → retry button)
- [ ] Back navigation works from every screen
- [ ] Confirmation dialogs for destructive actions (delete attendance, override marks)
