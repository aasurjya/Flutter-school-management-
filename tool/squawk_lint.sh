#!/usr/bin/env bash
# Squawk migration linter — blocks dangerous schema changes before they merge.
#
# Run locally: bash tool/squawk_lint.sh
#
# Strategy: ratchet, like design_token_lint. Only NEW migrations (since the
# main branch's last common ancestor) are scanned. This lets us land Stage 1
# without rewriting 60+ existing migrations.
#
# Squawk reference: https://squawkhq.com/docs/rules
# Exit codes: 0 = pass, 1 = lint failure, 2 = setup error.

set -euo pipefail

MIGRATIONS_DIR="supabase/migrations"
BASE_REF="${SQUAWK_BASE_REF:-origin/main}"

if [ ! -d "$MIGRATIONS_DIR" ]; then
  echo "::error::$MIGRATIONS_DIR not found — run from repo root"
  exit 2
fi

# Install squawk via npx if not on PATH. Pinned to a known version so the
# rule set is reproducible across CI / local.
SQUAWK="${SQUAWK_BIN:-npx --yes squawk-cli@1.5.4}"

# Find migrations added/modified vs the base branch.
# Fall back to the most recent migration if `git` doesn't have history (e.g.
# shallow CI clone with depth=1 — github checkout@v4 fetches full by default).
if git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
  CHANGED=$(git diff --name-only --diff-filter=AM "$BASE_REF"...HEAD -- "$MIGRATIONS_DIR/*.sql" || true)
else
  echo "::notice::base ref $BASE_REF not available; linting the latest migration only"
  CHANGED=$(ls -t "$MIGRATIONS_DIR"/*.sql 2>/dev/null | head -1)
fi

if [ -z "$CHANGED" ]; then
  echo "no new/modified migrations to lint — skipping"
  exit 0
fi

echo "Linting migrations:"
echo "$CHANGED" | sed 's/^/  - /'
echo ""

# Rules we care about (P0 prod-breaking patterns). All of these are in
# Squawk's default rule set as of 1.5.4 — listed here as documentation of
# what we expect to be enforced. Squawk 1.x removed the `--include` flag;
# the supported pattern is "run defaults; --exclude noisy rules if needed".
# Reference: https://squawkhq.com/docs/rules
#
#   adding-required-field, adding-not-nullable-field, changing-column-type,
#   disallowed-unique-constraint, prefer-big-int, prefer-bigint-over-int,
#   prefer-bigint-over-smallint, prefer-identity, prefer-text-field,
#   renaming-column, renaming-table, require-concurrent-index-creation,
#   require-concurrent-index-deletion, transaction-nesting,
#   ban-drop-column, ban-drop-database, ban-drop-not-null.
#
# If a default rule starts flagging too many false positives on a migration
# we can't restructure, add it to EXCLUDE below with a comment explaining why.
#
#   prefer-big-int / prefer-bigint-over-int:
#     False-positive prone for bounded config columns (CHECK-constrained,
#     enum-like). These rules matter for PKs/FKs/counters, not for columns
#     like `max_tokens INT CHECK (max_tokens BETWEEN 50 AND 8000)`. Manual
#     review of new PK/FK definitions catches the real cases.
EXCLUDE="--exclude prefer-big-int,prefer-bigint-over-int"

FAILED=0
for f in $CHANGED; do
  if [ ! -f "$f" ]; then continue; fi
  echo "::group::Squawk $f"
  if ! $SQUAWK $EXCLUDE "$f"; then
    echo "::error file=$f::squawk flagged a dangerous schema change — see docs/runbooks/migrations.md"
    FAILED=1
  fi
  echo "::endgroup::"
done

if [ "$FAILED" -eq 1 ]; then
  exit 1
fi
echo "✓ all migrations passed Squawk"
