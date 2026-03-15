# Security Risk Tasks — Pre-Production

Deferred items to address before going live with real schools.

## CRITICAL

- [ ] **Rotate exposed API keys** — Deepseek `sk-64…` and OpenRouter `ssk-or-v1-f3…` are in git history. Revoke on provider dashboards and generate new ones.
- [ ] **Plaintext passwords in `user_credentials` table** — Any DB leak exposes all initial passwords. Hash with bcrypt or drop the column after onboarding. Target: after 1-2 school onboarding.

## HIGH

- [ ] **CORS wildcard on `create-user` Edge Function** — Currently allows any origin (`*`). Restrict to your domain once purchased. File: `supabase/functions/create-user/index.ts`

## DONE

- [x] Set real Supabase URL in `.env.prod` (was localhost:54321) — Fixed 2026-03-15
- [x] Apply migrations 00047 + 00048 via `supabase db push`
