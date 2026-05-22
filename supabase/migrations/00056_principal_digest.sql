-- Migration: 00056_principal_digest
-- Purpose: Sprint 1.2 — weekly executive briefing for tenant_admin / principal.
--
-- A single row per (tenant, week_start) caches the LLM narrative + the
-- snapshot of KPIs it was generated from. The Flutter card reads this row;
-- a weekly server job (TODO Phase 2) repopulates Monday mornings. The card
-- can also trigger an on-demand regenerate which writes a new row.
--
-- Distinct from parent_digests (already in 00010): different audience,
-- school-level KPIs not student-level highlights, executive tone.
--
-- Pattern mirrors parent_digests in 00010_ai_phase1.sql:
--   - tenant_id-scoped RLS
--   - role gated for read (tenant_admin / principal only)
--   - service-role-only writes (filled by edge job or in-app gen call)
--
-- Rollback: DROP TABLE principal_digests CASCADE.

CREATE TABLE IF NOT EXISTS public.principal_digests (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  week_start      DATE NOT NULL,
  narrative       TEXT NOT NULL,
  kpis            JSONB NOT NULL DEFAULT '{}'::jsonb,
  ai_generated    BOOLEAN NOT NULL DEFAULT TRUE,
  ai_provider     TEXT,
  generated_by    UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (tenant_id, week_start)
);

CREATE INDEX IF NOT EXISTS idx_principal_digests_tenant_week
  ON public.principal_digests (tenant_id, week_start DESC);

DROP TRIGGER IF EXISTS trg_principal_digests_modtime ON public.principal_digests;
CREATE TRIGGER trg_principal_digests_modtime
  BEFORE UPDATE ON public.principal_digests
  FOR EACH ROW
  EXECUTE PROCEDURE moddatetime(updated_at);

COMMENT ON TABLE public.principal_digests IS
  'Sprint 1.2: weekly executive briefing for tenant_admin/principal. Cached LLM narrative + KPI snapshot. One row per (tenant, week).';
COMMENT ON COLUMN public.principal_digests.kpis IS
  'JSON snapshot of week KPIs the narrative was generated from. Fields: attendance_pct, attendance_delta_pct, fee_pct, fee_delta_pct, incidents_count, incidents_delta, escalating_count, at_risk_count.';

-- ============================================================================
-- RLS
-- ============================================================================

ALTER TABLE public.principal_digests ENABLE ROW LEVEL SECURITY;

-- Read: admins (tenant_admin/principal in this codebase) within the tenant.
DROP POLICY IF EXISTS "Admins read principal digest" ON public.principal_digests;
CREATE POLICY "Admins read principal digest"
ON public.principal_digests FOR SELECT
USING (
  tenant_id = (SELECT public.tenant_id())
  AND (SELECT public.is_admin())
);

-- Super-admin read-all (defense in depth, mirrors 00054 pattern).
DROP POLICY IF EXISTS "Super admin reads all principal digests" ON public.principal_digests;
CREATE POLICY "Super admin reads all principal digests"
ON public.principal_digests FOR SELECT
USING ((SELECT public.has_role('super_admin')));

-- Writes restricted to service_role only.
REVOKE INSERT, UPDATE, DELETE ON public.principal_digests FROM authenticated, anon;

-- ============================================================================
-- RPC: upsert_principal_digest  (called by the Flutter client after the
-- gateway returns a freshly generated narrative)
-- ============================================================================
-- SECURITY DEFINER so the call works without granting INSERT to the role,
-- but the function itself verifies tenant scope + admin role.

CREATE OR REPLACE FUNCTION public.upsert_principal_digest(
  p_week_start  DATE,
  p_narrative   TEXT,
  p_kpis        JSONB,
  p_ai_provider TEXT,
  p_ai_generated BOOLEAN
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_tenant UUID;
  v_user   UUID := auth.uid();
  v_id     UUID;
BEGIN
  v_tenant := tenant_id();
  IF v_tenant IS NULL THEN
    RAISE EXCEPTION 'no_tenant_in_jwt';
  END IF;
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'admin_role_required';
  END IF;

  INSERT INTO principal_digests (
    tenant_id, week_start, narrative, kpis,
    ai_provider, ai_generated, generated_by
  ) VALUES (
    v_tenant, p_week_start, p_narrative, COALESCE(p_kpis, '{}'::jsonb),
    p_ai_provider, p_ai_generated, v_user
  )
  ON CONFLICT (tenant_id, week_start) DO UPDATE
    SET narrative    = EXCLUDED.narrative,
        kpis         = EXCLUDED.kpis,
        ai_provider  = EXCLUDED.ai_provider,
        ai_generated = EXCLUDED.ai_generated,
        generated_by = EXCLUDED.generated_by
  RETURNING id INTO v_id;

  RETURN v_id;
END $$;

REVOKE EXECUTE ON FUNCTION public.upsert_principal_digest(DATE, TEXT, JSONB, TEXT, BOOLEAN) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.upsert_principal_digest(DATE, TEXT, JSONB, TEXT, BOOLEAN) TO authenticated;

COMMENT ON FUNCTION public.upsert_principal_digest IS
  'Sprint 1.2: called by Flutter client after gateway returns a fresh narrative. Enforces tenant + admin role server-side.';

-- ============================================================================
-- Done.
-- ============================================================================
