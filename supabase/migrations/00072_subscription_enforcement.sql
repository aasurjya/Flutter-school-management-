-- ============================================================================
-- 00072_subscription_enforcement.sql
--
-- Phase 1.1 — Subscription enforcement foundation.
--
-- Adds:
--   1. subscription_plans   — catalog of sellable plans (free/pro/elite)
--   2. subscription_invoices — Razorpay payment records for tenant billing
--   3. tenant_is_paid()     — SQL helper used by RLS + edge functions
--   4. tenant_plan_limits() — returns {max_students, ai_credits_usd, flags}
--   5. trigger to sync tenants.subscription_plan → tenant_ai_credits.tier/budget
--
-- Design notes:
--   • Gating is OPT-IN. The Flutter SubscriptionGuard and the ai-gateway
--     check tenant_is_paid() / tenant_plan_limits() — but RLS does NOT
--     hard-block writes yet. A feature flag column
--     `tenants.enforcement_enabled` (default false) flips hard RLS on,
--     so we can roll out per-tenant without risking locking out paid users.
--   • Plan prices in INR paise (matches Razorpay). ai_credits_usd is the
--     daily $-budget the ai-gateway already reads from tenant_ai_credits.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. subscription_plans — sellable plan catalog
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.subscription_plans (
  id              TEXT PRIMARY KEY,           -- 'free' | 'pro' | 'elite'
  display_name    TEXT NOT NULL,
  price_inr_paise BIGINT NOT NULL DEFAULT 0
                    CHECK (price_inr_paise >= 0),
  -- Per-billing-period: 'monthly' | 'yearly'. One row per (plan, period).
  billing_period  TEXT NOT NULL DEFAULT 'yearly'
                    CHECK (billing_period IN ('monthly', 'yearly')),
  max_students    INT  NOT NULL DEFAULT 100
                    CHECK (max_students >= 0),
  -- 0 = unlimited
  ai_credits_usd  NUMERIC NOT NULL DEFAULT 0
                    CHECK (ai_credits_usd >= 0),
  -- Feature flags consumed by Flutter SubscriptionGuard + edge functions.
  -- Keys present here are gated ON for this plan.
  feature_flags   JSONB NOT NULL DEFAULT '{}'::jsonb,
  is_active       BOOL NOT NULL DEFAULT true,
  sort_order      INT  NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (id, billing_period)
);

COMMENT ON TABLE public.subscription_plans IS
  'Sellable SaaS plan catalog. One row per (plan_id, billing_period). '
  'feature_flags is a JSONB map of feature_key → true/false; '
  'SubscriptionGuard reads it to gate UI.';

-- Seed the three default plans.
INSERT INTO public.subscription_plans
  (id, display_name, price_inr_paise, billing_period, max_students, ai_credits_usd, feature_flags, sort_order)
VALUES
  ('free',    'Free',    0,       'yearly',  100, 0.50,
    '{"ai_basic": true, "whatsapp": false, "advanced_reports": false, "lms": false}'::jsonb, 0),
  ('pro',     'Pro',     120000,  'yearly',  2000, 5.00,
    '{"ai_basic": true, "ai_advanced": true, "whatsapp": true, "advanced_reports": true, "lms": true}'::jsonb, 10),
  ('elite',   'Elite',   360000,  'yearly',  100000, 25.00,
    '{"ai_basic": true, "ai_advanced": true, "whatsapp": true, "advanced_reports": true, "lms": true, "white_label": true, "priority_support": true}'::jsonb, 20)
ON CONFLICT (id, billing_period) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 2. subscription_invoices — Razorpay payment records for tenant billing
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.subscription_invoices (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id           UUID NOT NULL
                        REFERENCES public.tenants(id) ON DELETE CASCADE,
  plan_id             TEXT NOT NULL
                        REFERENCES public.subscription_plans(id),
  billing_period      TEXT NOT NULL
                        CHECK (billing_period IN ('monthly', 'yearly')),
  amount_inr_paise    BIGINT NOT NULL CHECK (amount_inr_paise >= 0),
  -- Razorpay order/payment ids. payment_id null until webhook confirms.
  razorpay_order_id   TEXT,
  razorpay_payment_id TEXT,
  razorpay_signature  TEXT,
  -- pending → paid | failed | refunded
  status              TEXT NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending', 'paid', 'failed', 'refunded')),
  period_start        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  period_end          TIMESTAMPTZ NOT NULL,
  -- Idempotency: webhook retries with same payment_id update, not insert.
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_sub_invoices_razorpay_payment
  ON public.subscription_invoices (razorpay_payment_id)
  WHERE razorpay_payment_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_sub_invoices_tenant
  ON public.subscription_invoices (tenant_id, created_at DESC);

COMMENT ON TABLE public.subscription_invoices IS
  'Razorpay payment records for SaaS subscription billing (tenant → platform). '
  'Distinct from student fee invoices. Webhook upserts on payment_id.';

-- RLS: tenant_admin reads own invoices; super_admin reads/writes all.
ALTER TABLE public.subscription_invoices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS sub_invoices_read ON public.subscription_invoices;
CREATE POLICY sub_invoices_read
  ON public.subscription_invoices FOR SELECT
  USING (
    tenant_id::TEXT = COALESCE(auth.jwt() -> 'app_metadata' ->> 'tenant_id', '')
    OR COALESCE(auth.jwt() -> 'app_metadata' ->> 'is_super_admin', 'false') = 'true'
  );

DROP POLICY IF EXISTS sub_invoices_write ON public.subscription_invoices;
CREATE POLICY sub_invoices_write
  ON public.subscription_invoices FOR ALL
  USING      (COALESCE(auth.jwt() -> 'app_metadata' ->> 'is_super_admin', 'false') = 'true')
  WITH CHECK (COALESCE(auth.jwt() -> 'app_metadata' ->> 'is_super_admin', 'false') = 'true');

GRANT SELECT ON public.subscription_invoices TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.subscription_invoices TO authenticated;

-- ----------------------------------------------------------------------------
-- 3. tenants.enforcement_enabled — per-tenant hard-gate flag (default OFF)
-- ----------------------------------------------------------------------------
ALTER TABLE public.tenants
  ADD COLUMN IF NOT EXISTS enforcement_enabled BOOL NOT NULL DEFAULT false;

COMMENT ON COLUMN public.tenants.enforcement_enabled IS
  'When true, RLS hard-gates writes on heavy tables based on plan limits. '
  'Default false so rollout is per-tenant and we never lock out a paid tenant '
  'by accident. Flip to true only after the tenant has been onboarded to billing.';

-- ----------------------------------------------------------------------------
-- 4. tenant_is_paid() — SQL helper. True if subscription is active and not free.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.tenant_is_paid(p_tenant_id UUID)
RETURNS BOOL LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.tenants t
    WHERE t.id = p_tenant_id
      AND t.subscription_plan <> 'free'
      AND t.is_active = true
      AND (
        t.subscription_expires_at IS NULL
        OR t.subscription_expires_at > NOW()
      )
  );
$$;

COMMENT ON FUNCTION public.tenant_is_paid(UUID) IS
  'True when tenant has a non-free plan that has not expired. '
  'Used by ai-gateway, enforce-subscription edge fn, and RLS policies.';

-- ----------------------------------------------------------------------------
-- 5. tenant_plan_limits() — returns the active plan row for a tenant.
--    Joins tenants → subscription_plans on plan id (yearly billing).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.tenant_plan_limits(p_tenant_id UUID)
RETURNS TABLE (
  plan_id            TEXT,
  display_name       TEXT,
  max_students       INT,
  ai_credits_usd     NUMERIC,
  feature_flags      JSONB,
  is_paid            BOOL
) LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT sp.id,
         sp.display_name,
         sp.max_students,
         sp.ai_credits_usd,
         sp.feature_flags,
         public.tenant_is_paid(p_tenant_id)
  FROM public.tenants t
  LEFT JOIN public.subscription_plans sp
    ON sp.id = t.subscription_plan
   AND sp.billing_period = 'yearly'
  WHERE t.id = p_tenant_id;
$$;

COMMENT ON FUNCTION public.tenant_plan_limits(UUID) IS
  'Returns the active plan limits for a tenant. '
  'Edge functions and Flutter SubscriptionGuard read this.';

-- ----------------------------------------------------------------------------
-- 6. Trigger: sync tenants.subscription_plan → tenant_ai_credits
--    When a tenant's plan changes (e.g. webhook bumps them to pro),
--    update tenant_ai_credits.tier + budget_usd to match the plan catalog.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.tg_sync_ai_credits_on_plan_change()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_budget NUMERIC;
  v_tier   TEXT;
BEGIN
  IF NEW.subscription_plan IS DISTINCT FROM OLD.subscription_plan THEN
    -- Map plan id → ai_credits_usd + tier
    SELECT ai_credits_usd,
           CASE WHEN id = 'free' THEN 'free'
                WHEN id = 'elite' THEN 'enterprise'
                ELSE 'paid' END
      INTO v_budget, v_tier
    FROM public.subscription_plans
    WHERE id = NEW.subscription_plan AND billing_period = 'yearly'
    LIMIT 1;

    IF v_budget IS NULL THEN
      v_budget := 0.50;
      v_tier   := 'free';
    END IF;

    INSERT INTO public.tenant_ai_credits (tenant_id, tier, budget_usd, updated_at)
    VALUES (NEW.id, v_tier, v_budget, NOW())
    ON CONFLICT (tenant_id) DO UPDATE
      SET tier = EXCLUDED.tier,
          budget_usd = EXCLUDED.budget_usd,
          updated_at = NOW();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_ai_credits_on_plan_change ON public.tenants;
CREATE TRIGGER trg_sync_ai_credits_on_plan_change
  AFTER UPDATE OF subscription_plan ON public.tenants
  FOR EACH ROW EXECUTE FUNCTION public.tg_sync_ai_credits_on_plan_change();

-- ----------------------------------------------------------------------------
-- 7. RLS on subscription_plans — anyone authenticated can read the catalog;
--    only super_admin can write.
-- ----------------------------------------------------------------------------
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS sub_plans_read ON public.subscription_plans;
CREATE POLICY sub_plans_read
  ON public.subscription_plans FOR SELECT
  USING (true);

DROP POLICY IF EXISTS sub_plans_write ON public.subscription_plans;
CREATE POLICY sub_plans_write
  ON public.subscription_plans FOR ALL
  USING      (COALESCE(auth.jwt() -> 'app_metadata' ->> 'is_super_admin', 'false') = 'true')
  WITH CHECK (COALESCE(auth.jwt() -> 'app_metadata' ->> 'is_super_admin', 'false') = 'true');

GRANT SELECT ON public.subscription_plans TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.subscription_plans TO authenticated;

-- ----------------------------------------------------------------------------
-- 8. Backfill tenant_ai_credits for existing tenants to match their plan
-- ----------------------------------------------------------------------------
UPDATE public.tenant_ai_credits c
SET tier = CASE WHEN t.subscription_plan = 'free' THEN 'free'
                WHEN t.subscription_plan = 'elite' THEN 'enterprise'
                ELSE 'paid' END,
    budget_usd = COALESCE(
      (SELECT ai_credits_usd FROM public.subscription_plans
       WHERE id = t.subscription_plan AND billing_period = 'yearly' LIMIT 1),
      0.50
    ),
    updated_at = NOW()
FROM public.tenants t
WHERE c.tenant_id = t.id;
