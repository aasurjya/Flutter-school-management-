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

# Rules to enforce. See https://squawkhq.com/docs/rules for the full list.
# We pick the ones that catch P0 prod-breaking patterns.
RULES=(
  adding-required-field            # ADD COLUMN NOT NULL without default
  adding-not-nullable-field        # same family, stricter
  changing-column-type             # rewrites the table
  disallowed-unique-constraint     # blocking unique on big tables
  prefer-big-int                   # foot-gun: int32 PKs run out
  prefer-bigint-over-int           # same
  prefer-bigint-over-smallint      # same
  prefer-identity                  # serial vs identity
  prefer-text-field                # varchar(N) with too-small N
  renaming-column                  # breaks deployed clients
  renaming-table                   # ditto
  require-concurrent-index-creation # CREATE INDEX without CONCURRENTLY
  require-concurrent-index-deletion # DROP INDEX without CONCURRENTLY
  transaction-nesting              # nested BEGINs inside Supabase wrappers
  ban-drop-column                  # data loss is rarely intentional
  ban-drop-database                # data loss is rarely intentional
  ban-drop-not-null                # changes contract; needs review
)

EXCLUDE_RULES=""
for r in "${RULES[@]}"; do
  EXCLUDE_RULES+=" --include $r"
done

FAILED=0
for f in $CHANGED; do
  if [ ! -f "$f" ]; then continue; fi
  echo "::group::Squawk $f"
  if ! $SQUAWK $EXCLUDE_RULES "$f"; then
    echo "::error file=$f::squawk flagged a dangerous schema change — see docs/runbooks/migrations.md"
    FAILED=1
  fi
  echo "::endgroup::"
done

if [ "$FAILED" -eq 1 ]; then
  exit 1
fi
echo "✓ all migrations passed Squawk"
