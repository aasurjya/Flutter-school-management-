#!/usr/bin/env bash
# =============================================================
# test_and_push.sh — Full CI pipeline (local dev version)
#
# Usage:
#   bash scripts/test_and_push.sh
#
# Required environment variables (set in .env.test or exported):
#   SUPABASE_ACCESS_TOKEN   — personal access token for `supabase link`
#   SUPABASE_URL            — https://qykjmurexpydteuarzwm.supabase.co
#   SUPABASE_ANON_KEY       — anon/public key from Supabase dashboard
#   TEST_ADMIN_EMAIL        — test admin user email
#   TEST_ADMIN_PASSWORD     — test admin user password
#
# Optional:
#   SKIP_DB_PUSH=1          — skip supabase db push (faster local runs)
#   SKIP_INTEGRATION=1      — skip integration tests
#   SKIP_GIT_PUSH=1         — skip git commit + push
# =============================================================

set -eo pipefail

# Load .env.test if present (never committed, gitignored)
if [ -f "$(dirname "$0")/../.env.test" ]; then
  # shellcheck source=/dev/null
  source "$(dirname "$0")/../.env.test"
  echo "Loaded credentials from .env.test"
fi

PROJECT_REF="qykjmurexpydteuarzwm"

# ---------------------------------------------------------------------------
echo ""
echo "==== 1/5  flutter analyze (zero errors gate) ===="
# Capture output; fail only if actual *errors* are found (warnings/infos are OK)
ANALYZE_OUT=$(flutter analyze --no-pub 2>&1 || true)
echo "$ANALYZE_OUT" | tail -5
if echo "$ANALYZE_OUT" | grep -qE "^   error "; then
  echo "✗  flutter analyze found errors — aborting"
  echo "$ANALYZE_OUT" | grep -E "^   error "
  exit 1
fi
echo "✓  analyze passed (no errors)"

# ---------------------------------------------------------------------------
echo ""
echo "==== 2/5  unit + widget tests ===="
flutter test test/ --reporter=expanded
echo "✓  unit + widget tests passed"

# ---------------------------------------------------------------------------
if [ "${SKIP_DB_PUSH:-0}" != "1" ]; then
  echo ""
  echo "==== 3/5  supabase db push ===="

  if [ -z "${SUPABASE_ACCESS_TOKEN:-}" ]; then
    echo "⚠  SUPABASE_ACCESS_TOKEN not set — skipping db push"
    echo "   Export the variable or add it to .env.test"
  else
    supabase link --project-ref "$PROJECT_REF"
    supabase db push
    echo "✓  supabase db push completed"
  fi
else
  echo ""
  echo "==== 3/5  supabase db push (SKIPPED via SKIP_DB_PUSH=1) ===="
fi

# ---------------------------------------------------------------------------
if [ "${SKIP_INTEGRATION:-0}" != "1" ]; then
  echo ""
  echo "==== 4/5  integration tests (against remote DB) ===="

  : "${SUPABASE_URL:?'SUPABASE_URL must be set for integration tests'}"
  : "${SUPABASE_ANON_KEY:?'SUPABASE_ANON_KEY must be set for integration tests'}"
  : "${TEST_ADMIN_EMAIL:?'TEST_ADMIN_EMAIL must be set for integration tests'}"
  : "${TEST_ADMIN_PASSWORD:?'TEST_ADMIN_PASSWORD must be set for integration tests'}"

  flutter test integration_test/ \
    --dart-define="TEST_SUPABASE_URL=${SUPABASE_URL}" \
    --dart-define="TEST_SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}" \
    --dart-define="TEST_ADMIN_EMAIL=${TEST_ADMIN_EMAIL}" \
    --dart-define="TEST_ADMIN_PASSWORD=${TEST_ADMIN_PASSWORD}" \
    -d chrome \
    --reporter=expanded

  echo "✓  integration tests passed"
else
  echo ""
  echo "==== 4/5  integration tests (SKIPPED via SKIP_INTEGRATION=1) ===="
fi

# ---------------------------------------------------------------------------
if [ "${SKIP_GIT_PUSH:-0}" != "1" ]; then
  echo ""
  echo "==== 5/5  git commit + push ===="

  # Only commit if there are staged or unstaged changes
  if ! git diff --quiet HEAD 2>/dev/null || [ -n "$(git status --porcelain)" ]; then
    LAST_MSG=$(git log -1 --format='%s' 2>/dev/null || echo "chore: update")
    git add -A
    git commit -m "${LAST_MSG} [tested+deployed]" || echo "Nothing to commit"
    git push
    echo "✓  git push completed"
  else
    echo "  No changes to commit"
  fi
else
  echo ""
  echo "==== 5/5  git push (SKIPPED via SKIP_GIT_PUSH=1) ===="
fi

echo ""
echo "=== Pipeline complete ==="
