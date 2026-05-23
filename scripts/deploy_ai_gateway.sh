#!/usr/bin/env bash
# Deploy the AI gateway to a Supabase project. Idempotent; safe to re-run.
#
# Usage:
#   ./scripts/deploy_ai_gateway.sh staging
#   ./scripts/deploy_ai_gateway.sh production
#
# Prerequisites:
#   • supabase CLI installed and logged in (`supabase login`)
#   • Project linked once: `supabase link --project-ref <ref>`
#   • OPENROUTER_KEY env var set in your shell (NOT committed)
#
# What this does (in order):
#   1. Push migrations 00065 (governance) + 00066 (feature_routes).
#   2. Set the OPENROUTER_KEY secret on the Supabase functions runtime.
#   3. Deploy the ai-gateway edge function.
#   4. Print a curl smoke test you can paste to verify.

set -euo pipefail

ENV="${1:-}"
if [[ -z "$ENV" ]]; then
  echo "usage: $0 <staging|production>"
  exit 2
fi

if [[ -z "${OPENROUTER_KEY:-}" ]]; then
  echo "::error::OPENROUTER_KEY env var not set."
  echo ""
  echo "Get a key:"
  echo "  1. https://openrouter.ai/keys"
  echo "  2. Click 'Create Key' (free tier = 50 req/day; \$10 top-up = 1000/day)"
  echo "  3. export OPENROUTER_KEY=sk-or-v1-..."
  echo "  4. re-run $0 $ENV"
  exit 2
fi

echo "==> Deploying ai-gateway to: $ENV"
echo ""

# 1. Push migrations (idempotent).
echo "→ Step 1/3: Push migrations 00065 + 00066"
if ! supabase db push --linked; then
  echo "::error::supabase db push failed. Is the project linked?"
  echo "  fix: supabase link --project-ref <your-project-ref>"
  exit 1
fi
echo "✓ migrations applied"
echo ""

# 2. Set OPENROUTER_KEY secret (overwrites if exists).
echo "→ Step 2/3: Set OPENROUTER_KEY secret"
echo "$OPENROUTER_KEY" | supabase secrets set OPENROUTER_KEY="$OPENROUTER_KEY" >/dev/null
echo "✓ secret set"
echo ""

# 3. Deploy the edge function.
echo "→ Step 3/3: Deploy ai-gateway function"
supabase functions deploy ai-gateway --no-verify-jwt
# --no-verify-jwt: the gateway parses the JWT itself (extracts tenant_id
# from app_metadata). Supabase's default JWT-verify would also work but
# would 401 before our auth-error path fires.
echo "✓ function deployed"
echo ""

# Print the project URL for the smoke test.
PROJECT_URL=$(supabase status --output json 2>/dev/null | jq -r '.api.url // empty')
if [[ -z "$PROJECT_URL" ]]; then
  PROJECT_URL='https://<your-project-ref>.supabase.co'
fi

cat <<EOF
═══════════════════════════════════════════════════════════════════
✓ Gateway deployed to $ENV

Smoke test (replace <JWT> with a real user's access token):

  curl -X POST $PROJECT_URL/functions/v1/ai-gateway \\
    -H "Authorization: Bearer <JWT>" \\
    -H "Content-Type: application/json" \\
    -d '{
      "feature_type": "parent_communication",
      "system_prompt": "You write warm, brief parent updates.",
      "user_prompt": "Summarize this week for student Aarav: 96% attendance, 2 assignments late."
    }'

Expected: 200 + JSON with text, model, status='success'.

Next steps:
  • Verify the tenant_ai_usage table now has a row for that call.
  • Verify the admin dashboard's AI usage card populates (was blank
    pre-deploy because 00060 conditionally installed).
  • Run AI evals: AI_EVAL=1 AI_EVAL_LIVE=1 flutter test test/ai_evals/
═══════════════════════════════════════════════════════════════════
EOF
