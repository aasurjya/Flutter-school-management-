---
feature: profile
last_tested: 2026-05-16
tester: product-tester
verdict: SHIP
persona: Mr. Iyer (transport manager) changing his password and updating his phone number
---

# Profile (Phase β — JUST shipped 2026-05-16)

## At a Glance
- **Verdict:** SHIP — solid Phase β delivery. Three small screens, each doing one thing cleanly. This is the gold-standard pattern for the rest of the app.
- **Entry screen:** [[../../lib/features/profile/presentation/screens/account_settings_screen.dart]]
- **Roles with access:** ALL (every authenticated user)

## Axis 1 — Works?

**Pass — every flow lands:**
- `AccountSettingsScreen` reads `currentUserProvider`, post-frame redirects to `/login` if null (correct pattern, avoids build-phase navigation) — `account_settings_screen.dart:14-25`.
- User header card with avatar + name + email + role badge — `:67-126`. Role badge has per-role color map for 8 roles — `:134-143`.
- Two tappable list tiles → `/account/edit` and `/account/password` — `:42-52`. Both go via `context.go` (correct since they're new top-level routes).
- Sign-out button calls `Supabase.instance.client.auth.signOut()` then `context.go('/login')` — `:53-59`. Clean.
- `EditProfileScreen` reads + writes `users` table via Supabase, refreshes `authNotifierProvider` profile, shows snackbar, navigates back — `edit_profile_screen.dart:55-86`. Correctly omits `updated_at` to let DB trigger handle it — `:62`.
- `ProfilePhotoPicker` reused from Phase α security closure (`avatars` bucket policy) — `edit_profile_screen.dart:109-114`. Bucket hardening from yesterday is already paying dividends.
- `ChangePasswordScreen` — three-step flow: re-auth → update → sign-out → redirect — `change_password_screen.dart:92-112`. **This is the correct security pattern** (verifies current password rather than trusting Supabase's bearer token alone).
- Password strength validator in a private static class with proper rules (8+ chars, upper, lower, digit) — `change_password_screen.dart:15-34`.
- "New password must differ from current" check — `:304-308`. Good.
- `AuthException` caught and shows user-friendly message; generic `catch (_)` for everything else; no stack-leak — `:113-127`.
- LoadingButton key `submit_button`, password fields keyed for widget tests — `:169, 266, 289, 315`. **Tests can hook into this without source changes.**

No dead buttons. No mocks. No `coming soon`. No hardcoded IDs.

## Axis 2 — Good?

- **Taps to change password:** 3 (account icon → Change Password → submit). Within budget for a security action.
- **Labels:** plain English — "Edit Profile / Change Password / Sign Out". Persona-friendly.
- **Empty / loading / error:** all 3 covered. Error banner has a dismiss button — `change_password_screen.dart:218-227`. Best-in-class.
- **Phone validation:** lives in `validators.dart` (shared with profile_setup module — good reuse) — `edit_profile_screen.dart:8`.
- **Visibility toggle** on all 3 password fields with separate state — `:53-58, 162-165`. Standard but worth noting.

Nitpicks:
- `_RoleBadge._roleColors` map duplicates color logic from `app_colors.dart` — `account_settings_screen.dart:134-143`. Should pull from a shared role-color util.
- Sign out doesn't confirm. For a mobile user, a one-tap accidental sign-out can be painful (re-login + 2FA flow). Add a small confirm dialog.

## Axis 3 — Necessary?

CRITICAL — user can't function without account management. This was missing pre-Phase β. Ship as-is.

No overlap with anything. `profile_setup/` is the first-time-setup flow; `profile/` is the always-available settings. Clean separation by purpose.

## Axis 4 — Improvable?

- [ ] Add a confirm dialog before sign-out (1 line of code).
- [ ] Move `_RoleBadge._roleColors` to a shared `core/theme/role_colors.dart`. Multiple places reinvent this.
- [ ] Add "Email" to the editable fields (currently only name + phone + avatar). Email changes require re-verification, but worth supporting.
- [ ] Add "Delete Account" or "Request Data Export" — GDPR/India PDPB compliance for tenant-admin tier.

## Notes for the panel

- **Critic:** is this the right pattern to copy for the rest of the app? Yes. Small focused screens with consumer-state and immutable patterns. Should be elevated to the canonical example in [[decisions/]].
- **Security-reviewer:** confirm that the `signOut → context.go('/login')` race condition can't be exploited. Phase α audit fixed the ghost-session issue at `app_router.dart:674` — verify this flow doesn't re-introduce it.
- **Architect:** decide on `core/theme/role_colors.dart` extraction.

## Backlinks

- [[../00 Index]]
- [[../_feature_inventory_2026-05-16]]
- Phase β plan: [[../pending]]
