# Verifying `getVerifiedTenantId` (JWT signature check)

No Deno test runner exists yet in this repo (`supabase/functions/` has zero
`*.test.ts` files), so this is a manual verification script rather than an
automated regression test. Run it after any change to `index.ts`'s auth
handling, and before deploying this function.

`getVerifiedTenantId` is injectable (`supabaseAdmin` is a parameter), so a
real `Deno.test` suite is possible later — pass a fake admin whose
`auth.getUser` returns canned `{error}` / `{data: {user}}` responses and
assert the four cases below without touching the network. Wiring that up is
a separate infra decision (new `deno test` CI job); flagging it, not doing
it here.

## Setup

```bash
supabase functions serve send-whatsapp --no-verify-jwt
# in another terminal:
ANON_KEY=$(supabase status -o env | grep ANON_KEY | cut -d'"' -f2)
```

`--no-verify-jwt` deliberately simulates the platform's `verify_jwt` gate
being off — the worst case the fix needs to hold up against.

## Case 1 — forged/unsigned JWT must be rejected

```bash
FORGED_HEADER=$(printf '{"alg":"HS256","typ":"JWT"}' | base64 | tr '+/' '-_' | tr -d '=')
FORGED_PAYLOAD=$(printf '{"app_metadata":{"tenant_id":"11111111-1111-1111-1111-111111111111"}}' | base64 | tr '+/' '-_' | tr -d '=')
FORGED_JWT="${FORGED_HEADER}.${FORGED_PAYLOAD}.not-a-real-signature"

curl -s -X POST http://127.0.0.1:54321/functions/v1/send-whatsapp \
  -H "Authorization: Bearer $FORGED_JWT" \
  -H "Content-Type: application/json" \
  -d '{"to":"919876543210","templateName":"test_template"}' -w "\nHTTP_STATUS:%{http_code}\n"
```

Expected: `403 {"ok":false,"reason":"no_tenant_in_jwt"}`.

If instead you see the request proceed to `whatsapp_not_in_plan` /
`whatsapp_not_configured` / a Meta API call, the signature check regressed —
the forged `tenant_id` was accepted.

## Case 2 — a real, validly-signed session token must still work

Sign in as a real seeded user (or craft an HS256 JWT with the local dev
secret `super-secret-jwt-token-with-at-least-32-characters-long`, `sub` =
a real `auth.users.id`, `app_metadata.tenant_id` = a real tenant) and repeat
the same request with that token.

Expected: request proceeds past the auth check to whatever the next gate is
(subscription plan check, WhatsApp config check, etc.) — i.e. NOT
`403 no_tenant_in_jwt`.

## Last run

- 2026-07-06: both cases passed against local Supabase (commit dab6db2).
