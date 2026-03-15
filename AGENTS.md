# AGENTS.md

## Purpose

Use this file first to keep code exploration narrow and reduce token usage.

## Read First

For role, routing, auth, or super-admin tasks, read only these files first:

- `docs/context-map.json`
- `docs/roles/README.md`
- `lib/core/router/app_router.dart`
- `lib/core/shell/main_shell.dart`

## Authoritative Files by Topic

### Super Admin / Platform Admin
- `lib/core/router/app_router.dart`
- `lib/core/shell/main_shell.dart`
- `lib/features/super_admin/presentation/screens/super_admin_dashboard_screen.dart`
- `lib/features/super_admin/presentation/screens/tenants_list_screen.dart`
- `lib/features/super_admin/presentation/screens/create_tenant_screen.dart`
- `lib/features/super_admin/presentation/screens/tenant_detail_screen.dart`
- `docs/roles/platform_admin.md`

### Roles / Staff Creation / Permissions
- `docs/roles/README.md`
- `docs/roles/platform_admin.md`
- `docs/roles/principal.md`
- `docs/roles/school_admin.md`
- `docs/roles/other_staff.md`
- `docs/roles/teacher.md`
- `docs/roles/student.md`
- `docs/roles/parent.md`
- `lib/features/admin/presentation/widgets/add_staff_sheet.dart`
- `lib/features/admin/presentation/screens/staff_management_screen.dart`
- `lib/data/repositories/staff_repository.dart`
- `supabase/functions/create-user/index.ts`

### Auth / Role Detection
- `lib/features/auth/providers/auth_provider.dart`
- `lib/data/models/user.dart`
- `lib/core/config/app_environment.dart`

## Working Rules

- Do not scan the whole repo for role-related tasks.
- Do not web search unless the user explicitly asks for external research.
- Prefer exact file reads over broad codebase exploration.
- Prefer updating existing role docs over creating new duplicate docs.
- For super-admin issues, inspect only `/super-admin` screens, router, shell, and auth role logic unless a concrete dependency requires more.
- For staff-permission issues, inspect only staff UI, staff repository, user model, and `create-user` edge function first.
- Treat `agents/everything-claude-code/` as a separate embedded project; do not scan it unless the user explicitly asks about that plugin.

## Avoid Unless Explicitly Needed

- `docs/CODEBASE_ANALYSIS_AND_INTEGRATION_PLAN.md`
- `docs/CODEMAP.md`
- `docs/ARCHITECTURE.md`
- `agents/everything-claude-code/`
- broad feature folders unrelated to the request
- web search for internal repo behavior

## Low-Token Workflow

1. Read `docs/context-map.json`.
2. Read only the 2-5 files mapped to the user’s topic.
3. Make the minimal change.
4. Verify with targeted reads or a single targeted command.
5. Do not do parallel broad exploration for small or medium tasks.

## Prompting Guidance

If the user asks for low-token work, follow this pattern:

- read `AGENTS.md` first
- use only mapped files
- no broad repo scan
- no web search
- keep edits minimal and targeted
