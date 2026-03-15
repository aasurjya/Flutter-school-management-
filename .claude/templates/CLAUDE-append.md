
## School Management SaaS — Development Commands

### Workflow Entry Points

| Command | Purpose |
|---|---|
| `/start-task` | Begin any task — primes knowledge, checks PRs, routes simple vs complex |
| `/prime` | Load relevant knowledge base facts before starting work |
| `/brainstorm` | Refine an idea into a design doc before implementation |
| `/review-design` | Parallel 5-agent design review gate (PM, Architect, Designer, Security, CTO) |
| `/plan` | Create step-by-step implementation plan |

### Code Quality

| Command | Purpose |
|---|---|
| `/flutter-review <file>` | Run flutter analyze + code-reviewer agent on changed file |
| `/dart-test <feature>` | TDD workflow — scaffold tests first, implement, check coverage |
| `/supabase-review` | Check migrations for tenant_id, RLS, idempotency, indexes |
| `/ux-review <screen>` | 4 UX agents in parallel — Norman, Grid, Accessibility, Interaction |

### PR Lifecycle

| Command | Purpose |
|---|---|
| `/handle-pr-comments <pr>` | Systematically address all PR review comments |
| `/pr-shepherd <pr>` | Monitor PR through CI to merge — handles failures and reviews |
| `/self-reflect` | Extract learnings from session into knowledge base |

### Quality Gates

| Gate | Trigger | Blocks |
|---|---|---|
| `flutter analyze` | Every commit | 0 errors required |
| `flutter test --coverage` | Every feature PR | 80% coverage required |
| Design Review Gate | After brainstorm | 5 agents must PASS |
| Security Review | New auth/payment code | 0 CRITICAL findings |

### Known Critical Issues (Check Before Working on These Features)

| Issue | Location | Risk |
|---|---|---|
| `tenantId!` null crash | `lib/data/repositories/base_repository.dart` | Crashes for super_admin |
| Demo credentials | `lib/features/auth/presentation/screens/login_screen.dart` | Security — remove before prod |
| No pagination | Most list screens | Crash with large schools |
| Attendance overwrite | Mark attendance screen | Data loss — no confirmation |
| N+1 query | Student list (parents loaded separately) | Performance |
| Offline sync incomplete | Isar models exist, sync logic missing | No offline functionality |
| Quiz timer client-side | Online exam | Exploitable |
| Invoice duplicate | `generate_class_invoices()` RPC | Creates duplicate invoices |
| Wallet race condition | Wallet balance trigger | Overdraft possible |

### Flutter Validation Pipeline

```bash
dart fix --apply                                          # Auto-fix safe issues
flutter analyze                                          # 0 errors required
flutter test                                             # 0 failures required
flutter test --coverage && lcov --summary coverage/lcov.info  # 80% required
flutter build apk --debug                               # Build must succeed
```

### Architecture Quick Reference

```
UI (ConsumerWidget / ConsumerStatefulWidget)
    ↓ ref.watch(provider)
Riverpod Providers (FutureProvider.autoDispose.family)
    ↓ ref.read(repositoryProvider)
Repository (extends BaseRepository)
    ↓ supabase.from('table').eq('tenant_id', tenantId).range(...)
Supabase (cloud) + Isar (local offline — incomplete)
```

### 12 Roles

`super_admin`, `tenant_admin`, `principal`, `teacher`, `student`, `parent`,
`accountant`, `librarian`, `transport_manager`, `hostel_warden`, `canteen_staff`, `receptionist`
