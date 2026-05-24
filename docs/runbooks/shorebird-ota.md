# Shorebird OTA — when to enable, how it works

> Status: **scaffolded but inert.** Cost: $20/mo. Decision deferred until
> the first Play Store re-review cycle proves it's worth paying for.

## What it is

Shorebird patches the Flutter Dart code in a deployed app **without
shipping a new Play Store / App Store build**. A user opens the app,
Shorebird checks for a patch, downloads it (~50-500 KB), reloads the
Dart VM with the new code on next launch. No Play Store review queue.

Native code (Java/Kotlin/Swift) cannot be patched — that still needs a
real release.

## When to enable

Don't enable it just because you read this doc. Enable it when **one
of these specific things happens**:

1. **You ship a Dart-only crash** to production. Play Store re-review
   takes 1-7 days. With Shorebird, the fix reaches users in <10 minutes.
2. **You need to A/B a hotfix** behind a flag without revving the app
   version.
3. **A demo school says "this one bug is blocking us"** and the bug is
   Dart-side.

Until one of these happens, the $20/mo isn't earning its keep.

## Enabling — 4 steps, ~30 min

### 1. Sign up + install

```bash
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh | bash
shorebird login
shorebird account subscribe   # $20/mo
```

### 2. Initialize the project

```bash
shorebird init
# Pick: New Shorebird Code Push project
# This creates shorebird.yaml with your app_id.
# Commit shorebird.yaml; do NOT commit the access token.
```

### 3. Wire into main.dart

Add to `pubspec.yaml` (already noted in the file but commented):

```yaml
  shorebird_code_push: ^1.1.5
```

Then in `lib/main.dart`, after `AppEnvironment.initialize()`:

```dart
// Shorebird patch check — non-blocking, fire-and-forget. The next app
// launch picks up any downloaded patch.
unawaited(_checkForShorebirdPatch());
```

A small helper (skip when Shorebird isn't initialized):

```dart
Future<void> _checkForShorebirdPatch() async {
  if (!AppEnvironment.shorebirdEnabled) return;
  try {
    final updater = ShorebirdUpdater();
    if (await updater.checkForUpdate() == UpdateStatus.outdated) {
      await updater.update();
    }
  } catch (e) {
    developer.log('shorebird patch check failed', name: 'Shorebird', error: e);
  }
}
```

Add to `app_environment.dart`:

```dart
static bool get shorebirdEnabled =>
    dotenv.env['SHOREBIRD_ENABLED']?.toLowerCase() == 'true';
```

This means: even after install, OTA is gated by the env var. Flip
`SHOREBIRD_ENABLED=true` in `.env.production` only.

### 4. Build + release flow

```bash
# Initial release (replaces flutter build apk --release):
shorebird release android

# Subsequent hotfixes — no Play Store touch:
shorebird patch android
```

## Where Shorebird fits in the existing release flow

The `.github/workflows/release.yml` workflow (Stage 2) currently runs
`flutter build apk --release --split-debug-info=... --obfuscate
--tree-shake-icons`. To switch to Shorebird:

- Replace `flutter build apk --release` with `shorebird release android`
  (it wraps the same flags + uploads the artifact).
- Add `SHOREBIRD_TOKEN` to GitHub secrets.
- For hotfixes, a separate workflow `release-patch.yml` runs
  `shorebird patch android` on a tag like `v1.0.0+patch1`.

## Cost ceiling

- $20/mo flat for "Hobby" tier — 1 app, unlimited patches.
- $40/mo "Pro" tier — up to 10 apps + analytics. Stay on Hobby.
- Free trial: 14 days.

## What this does NOT solve

- **Native crashes** (Java/Kotlin/Swift) — still need a Play Store release.
- **Asset changes** (new fonts, new images) — bundled in the APK; OTA
  can ship new *code* that references existing assets, but new asset
  files require a release.
- **AndroidManifest / Info.plist changes** — release-only.

## Closing the "Shorebird OTA" task

This runbook **closes S3.20** in the scope of "decide the policy + leave
a 30-min ready-to-flip-on procedure." The actual install + Hobby-tier
signup is left for the moment the first qualifying incident makes it
worth $20/mo. Until then: no install, no `shorebird.yaml`, no patch
checks at boot. Zero $/zero overhead.
