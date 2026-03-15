# User Flows

> Define user interactions before work unit decomposition.
> Each flow must have a clear trigger, steps, and visible outcome.
> Use this template when brainstorming or designing new screens.

---

## Screens

<!-- Describe each screen with a text wireframe showing layout and interactive elements -->

### Screen: [Screen Name]

```
┌─────────────────────────────────────┐
│ AppBar: [Title]              [Action]│
├─────────────────────────────────────┤
│                                     │
│  [Content area]                     │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ GlassCard                   │    │
│  │  Title           [Button]   │    │
│  │  Subtitle                   │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
│  [BottomNavigationBar]              │
└─────────────────────────────────────┘
```

**Roles that can access**: _e.g., teacher, principal_
**Provider**: _e.g., `attendanceProvider(classId)`_
**Repository**: _e.g., `AttendanceRepository`_

---

## User Flows

<!-- Each flow: trigger → steps → outcome. Must map to work units. -->

### Flow: [Action Name]

| Step | User Action | System Response | Widget |
|------|------------|-----------------|--------|
| 1 | _User taps X_ | _Show loading indicator_ | _CircularProgressIndicator_ |
| 2 | _Data loads_ | _Render list with GlassCard items_ | _ListView.builder_ |
| 3 | _User taps item_ | _Navigate to detail screen_ | _GoRouter.push_ |
| 4 | _User fills form_ | _Validate inline, enable submit_ | _Form + TextFormField_ |
| 5 | _User taps Submit_ | _Show loading, call repository_ | _ElevatedButton_ |
| 6 | _Success_ | _Pop screen, show SnackBar_ | _ScaffoldMessenger_ |

**Error States**: _e.g., Network failure → show AppErrorWidget with retry button_
**Loading States**: _e.g., CircularProgressIndicator centered while AsyncLoading_
**Empty States**: _e.g., EmptyState widget with 'No records yet' and action button_

---

## Role-Based UI Variations

<!-- If the screen behaves differently by role, document here -->

| Role | What They See | What They Can Do |
|------|--------------|-----------------|
| teacher | Own classes only | Mark attendance |
| principal | All classes | View reports only |
| student | Own schedule | View only |

---

## Flutter Widget Mapping

<!-- Map each UI element to a Flutter widget -->

| UI Element | Flutter Widget | Notes |
|-----------|---------------|-------|
| Page container | `Scaffold` + `ConsumerWidget` | |
| Card items | `GlassCard` | Use project's GlassCard, not Card() |
| Loading state | `CircularProgressIndicator` | Centered with `Center` widget |
| Error state | `AppErrorWidget` | From `lib/core/widgets/` |
| Empty state | `EmptyState` | From `lib/core/widgets/` |
| Primary button | `ElevatedButton` | Not TextButton for primary actions |
| Status badges | `StatusChip` | From `lib/core/widgets/` |

---

## Integration Checklist

- [ ] All screens added to GoRouter with correct role guards
- [ ] All providers use `autoDispose` + `family` where appropriate
- [ ] All repository queries include `tenant_id` filter and pagination
- [ ] Error, loading, and empty states implemented in every screen
- [ ] Navigation wired from role dashboard to new screen
- [ ] Back navigation works correctly
