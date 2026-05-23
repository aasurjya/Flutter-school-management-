# Environments — staging vs production

> Last drilled: **never** (set up before launch)

The app supports three environments via `AppEnvironment`:

| Environment    | `APP_ENV`     | Supabase project              | Reachable at                          |
|----------------|---------------|-------------------------------|----------------------------------------|
| Development    | `development` | local CLI / your own dev one  | `localhost`, `flutter run`             |
| Staging        | `staging`     | `school-management-staging`   | preview Pages deploy on `main` push    |
| Production     | `production`  | `school-management-prod`      | tagged release `v*`                    |

## Why two Supabase projects

A single project is fine when there are zero users. Once schools sign up:

- A breaking migration on prod = an outage; on staging = a meeting.
- Pricing tier upgrades (Pro for PITR) are easier when staging stays Free.
- The Stage-1 [canary](../../.github/workflows/canary.yml) must run against
  *something that isn't prod* or it becomes a fancy synthetic-load source
  that costs real money.

## Setup steps (~30 min, manual)

### 1. Create the staging Supabase project

Dashboard → New project → name `school-management-staging`, same region as
production. Save the URL + anon key + service-role key.

### 2. Apply the migration history to staging

```bash
supabase link --project-ref "$STAGING_PROJECT_REF"
supabase db push --include-all
```

### 3. Seed staging with realistic-but-fake data

Create a small SQL seed file (do **not** copy production data — PII).
Minimum useful seed:
- 2 tenants (so the [tenant_isolation_test](../../test/integration/tenant_isolation_test.dart)
  harness has two distinct test users)
- 1 super_admin
- 1 user per tenant + role combination you actively test
- ~50 students per tenant (enough to exercise pagination on `students_list_screen`)

### 4. Wire the GitHub secrets

In repo settings → Secrets and variables → Actions → New secret:

| Secret                          | Used by                          | Source                       |
|---------------------------------|----------------------------------|------------------------------|
| `STAGING_SUPABASE_URL`          | canary.yml, web staging deploy   | staging dashboard            |
| `STAGING_SUPABASE_ANON_KEY`     | same                             | staging dashboard            |
| `STAGING_SUPABASE_SERVICE_ROLE` | tenant isolation harness         | staging dashboard            |
| `CANARY_USER_EMAIL`             | canary.yml                       | the test user you seeded     |
| `CANARY_USER_PASSWORD`          | canary.yml                       | the test user you seeded     |
| `ISOLATION_TENANT_A_EMAIL`      | tenant isolation harness         | tenant-A test user           |
| `ISOLATION_TENANT_A_PASSWORD`   | same                             | same                         |
| `ISOLATION_TENANT_B_EMAIL`      | tenant isolation harness         | tenant-B test user           |
| `ISOLATION_TENANT_B_PASSWORD`   | same                             | same                         |
| `PROD_SUPABASE_URL`             | release.yml (tag push only)      | production dashboard         |
| `PROD_SUPABASE_ANON_KEY`        | release.yml                      | production dashboard         |
| `SENTRY_DSN`                    | runtime app                      | sentry.io                    |
| `SENTRY_AUTH_TOKEN`             | release.yml symbol upload        | sentry.io → settings → API   |
| `SENTRY_ORG`, `SENTRY_PROJECT`  | release.yml                      | sentry.io                    |
| `POSTHOG_API_KEY`               | runtime app (Stage 2 / S2.12)    | posthog.com                  |
| `SUPER_ADMIN_EMAIL`             | ci.yml, release.yml              | whoever owns the platform    |

### 5. Optional — different `.env` per branch in CI

Out of scope for this commit (existing `ci.yml` injects one `.env` based on
the secrets in scope). When you flip from "single env" to "branch-aware":

```yaml
- name: Create .env (staging or production)
  run: |
    if [ "${{ github.ref_type }}" = "tag" ]; then
      SUPA_URL="${{ secrets.PROD_SUPABASE_URL }}"
      SUPA_KEY="${{ secrets.PROD_SUPABASE_ANON_KEY }}"
      APP_ENV="production"
    else
      SUPA_URL="${{ secrets.STAGING_SUPABASE_URL }}"
      SUPA_KEY="${{ secrets.STAGING_SUPABASE_ANON_KEY }}"
      APP_ENV="staging"
    fi
    cat <<EOF > .env
    SUPABASE_URL=$SUPA_URL
    SUPABASE_ANON_KEY=$SUPA_KEY
    APP_ENV=$APP_ENV
    SHOW_DEMO_CREDENTIALS=false
    SENTRY_DSN=${{ secrets.SENTRY_DSN }}
    POSTHOG_API_KEY=${{ secrets.POSTHOG_API_KEY }}
    EOF
```

## Drill — quarterly

1. Run a full prod migration history against the staging project:
   `supabase db push --linked --include-all`
2. Run the [tenant_isolation_test](../../test/integration/tenant_isolation_test.dart):
   ```bash
   INTEGRATION=1 \
   ISOLATION_SUPABASE_URL="$STAGING_URL" \
   ISOLATION_SERVICE_KEY="$STAGING_SERVICE_KEY" \
   ISOLATION_TENANT_A_EMAIL=... \
   ISOLATION_TENANT_A_PASSWORD=... \
   ISOLATION_TENANT_B_EMAIL=... \
   ISOLATION_TENANT_B_PASSWORD=... \
   flutter test test/integration/
   ```
3. Hit `/health` on the staging functions URL, expect 200.
4. Update `Last drilled:` at top of this file.

## Common pitfalls

- **Copying production data to staging is a GDPR/PII risk** even for
  internal use. Always seed; never `pg_dump`. If you genuinely need real
  data to reproduce a bug, mask first.
- **Migrations in CI run with service-role key.** Don't put anything in a
  migration that depends on session-scoped settings (`current_setting`)
  without explicit handling.
- **Edge function secrets reset on Supabase project changes.** Re-run
  `supabase secrets set` after any project recreation.
