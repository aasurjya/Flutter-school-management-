# Observability Setup — Sentry + PostHog accounts

> Last drilled: **never** (~10 min total when you do it)

The code is already wired (Sentry from Stage 1 PR #5, PostHog from Stage 2
PR #6). Both auto-disable when their env vars are missing — so the app
works without doing this. But you'll be flying blind on the first
production-like demo. Do this once before showing the app to a school.

## Sentry (errors + tail-latency)

### Sign up (~3 min)

1. Open https://sentry.io/signup/
2. Sign in with GitHub.
3. Pick **"Flutter"** as the platform when prompted.
4. Skip the SDK tutorial — our `sentry_flutter` is already installed.

### Get the DSN

5. Settings → Projects → your project → Client Keys (DSN).
6. Copy the DSN (looks like `https://abc123@o456.ingest.sentry.io/789`).

### Put it in the right places

```bash
# Local dev:
echo "SENTRY_DSN=https://...@o....ingest.sentry.io/..." >> .env

# Staging (Supabase function secrets — not strictly needed since Sentry
# is a Flutter-side concern, but keep the values together):
supabase secrets set SENTRY_DSN=https://...@o....ingest.sentry.io/...

# GitHub secrets (for the release.yml symbol upload):
gh secret set SENTRY_DSN --body "https://...@o....ingest.sentry.io/..."
gh secret set SENTRY_AUTH_TOKEN --body "<from sentry settings → API → tokens>"
gh secret set SENTRY_ORG --body "your-org-slug"
gh secret set SENTRY_PROJECT --body "your-project-slug"
```

### Verify

7. Run `flutter run` locally. Add a temporary `throw Exception('test');` somewhere in your boot path.
8. Within 30 seconds, the exception appears in Sentry's Issues tab with `tenant_id` and `role` tags from your JWT.
9. Remove the test throw.

### Free tier limits

- **5,000 errors/month** for one user. Plenty for the first 100 schools at typical error rates.
- **1 user seat** on the free tier — if a teammate needs access, upgrade to Team ($26/mo).
- Errors past 5k are dropped silently. Monitor the quota tab.

---

## PostHog (product analytics)

### Sign up (~3 min)

1. Open https://us.posthog.com/signup *(or `eu.posthog.com` for EU data residency)*
2. Sign in with GitHub or email.
3. Create a new project — name it `school-management-staging` (use a separate project for prod when you launch).
4. Skip the auto-detected install steps — our `posthog_flutter` is already wired.

### Get the API key

5. Project Settings → Project API Key (`phc_...`).
6. Copy it.

### Put it in the right places

```bash
# Local dev:
echo "POSTHOG_API_KEY=phc_..." >> .env

# Optional, only if you use EU PostHog:
echo "POSTHOG_HOST=https://eu.posthog.com" >> .env

# Staging:
supabase secrets set POSTHOG_API_KEY=phc_...
```

### Verify

7. Run `flutter run` locally, sign in as any user.
8. PostHog → Live Events. Within 30 s you should see a `dashboard_open_role` event with `tenant_id` and `role` properties.
9. The 5 instrumented events: `login`, `dashboard_open_role`, `feature_used`, `error_shown`, `ai_call_made`.

### Free tier limits

- **1M events/month** — plenty for first 100 schools.
- Unlimited team members.
- 1-year data retention.
- Funnels, retention, paths all included.

---

## Both — recommended setup before demo

| What | When |
|------|------|
| Get a Sentry DSN | Day -3 from demo |
| Get a PostHog API key | Day -3 from demo |
| Deploy `OPENROUTER_KEY` to Supabase secrets (see `scripts/deploy_ai_gateway.sh`) | Day -3 |
| Drill `docs/runbooks/restore.md` once | Day -2 |
| Drill `docs/runbooks/killswitch.md` once | Day -2 |
| Smoke-test a forced crash → confirms Sentry receives it | Day -1 |
| Smoke-test `AI_EVAL=1 AI_EVAL_LIVE=1 flutter test test/ai_evals/` | Day -1 |
| Live demo with a real school | Day 0 |

## Cost summary (free tier)

- **Sentry**: $0 (5k errors/mo)
- **PostHog**: $0 (1M events/mo)
- **OpenRouter**: $0 (50 req/day) or **$10 one-time** (1000 req/day)
- **Supabase**: $0 (Free) or **$25/mo** (Pro — gives PITR backups)

**Minimum cost to demo:** $0. **Recommended:** $35 one-time + first month covered, gives 1000 AI req/day + verified DB backups.
