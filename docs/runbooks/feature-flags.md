# Feature flags — dark-launch, staged rollout, kill switches per feature

## Schema reminder

Table: `public.feature_flags` (migration `00062_feature_flags.sql`)

| Column            | Meaning                                              |
|-------------------|------------------------------------------------------|
| `key`             | Identifier read by Flutter, e.g. `ai_streaming`.     |
| `enabled`         | Master switch. False = off for everyone.             |
| `rollout_percent` | 0-100. % of tenants the flag is on for, stable.      |
| `audience`        | UUID[] tenant allowlist. Non-empty = ignore percent. |
| `payload`         | jsonb. Free-form variant data.                       |

Resolution order (in both SQL and Flutter):
1. `enabled = false` → off.
2. `audience` non-empty → on iff tenant_id ∈ audience.
3. Else: `hash(tenant_id || ':' || key) % 100 < rollout_percent`.

The hash is stable per (tenant, key) — once on, always on for that tenant
(unless rollout_percent drops below their bucket).

## Common operations

### Add a new flag

```sql
INSERT INTO public.feature_flags (key, enabled, rollout_percent, description)
VALUES ('ai_streaming', false, 100,
        'Sentence-by-sentence AI streaming on principal digest. Default off.');
```

Flutter reads it via:

```dart
final tenantId = ref.watch(currentTenantIdProvider);
final on = ref.watch(flagProvider(('ai_streaming', tenantId)));
```

### Dark-launch (ship code but keep off)

Ship the feature behind the flag with `enabled = false`. No users see it.

### Internal-only release (pilot schools)

```sql
UPDATE public.feature_flags
SET enabled = true,
    audience = ARRAY['11111111-1111-1111-1111-111111111111'::uuid,
                     '22222222-2222-2222-2222-222222222222'::uuid]
WHERE key = 'ai_streaming';
```

### Staged percent rollout

```sql
UPDATE public.feature_flags
SET enabled = true, audience = ARRAY[]::UUID[], rollout_percent = 5
WHERE key = 'ai_streaming';
-- Watch Sentry / PostHog for 1-2 hours, then bump:
UPDATE public.feature_flags SET rollout_percent = 25 WHERE key = 'ai_streaming';
UPDATE public.feature_flags SET rollout_percent = 100 WHERE key = 'ai_streaming';
```

### Emergency disable

```sql
UPDATE public.feature_flags SET enabled = false WHERE key = 'ai_streaming';
```

Already-running app sessions pick up the change on next boot. For force-now
fallback, also engage the [killswitch](./killswitch.md).

## Convention: every new feature gets a flag

When you ship a feature that isn't fundamental UX (a new screen, a new AI
surface, a new background job), wrap it in a flag with `enabled = false` by
default. Costs ~3 lines of code; pays for itself the first time the feature
misbehaves.

Don't flag-protect: navigation, theming, copy changes, layout fixes. Flag
inflation is a real problem — every flag is a permanent runtime branch.

## Cleanup

Once a flag has been at `enabled = true, rollout_percent = 100, audience = []`
for two release cycles with zero incidents, **delete the flag and the
branching code in the same PR**. Old flags become invisible foot-guns.

## Limitations

- This is NOT an experimentation framework. No variant A/B/C, no
  significance testing. Use PostHog Experiments for that (Stage 2).
- Flag fetches once at app open. Long-running sessions won't see toggles.
  Acceptable trade-off — daily-use app, users restart frequently.
- Hash bucketing matches Postgres `hashtext()`-style, not Murmur. If you
  ever migrate to a different hash, expect bucket reshuffling.
