-- ============================================================================
-- 00071_fix_threads_rls_recursion_and_wallet_insert.sql
--
-- (1) threads / thread_participants — break an RLS recursion (42P17)
--     The "View own threads" policy on threads subqueried thread_participants,
--     and the "View thread participants" policy on thread_participants
--     subqueried threads (and itself). Any SELECT on threads therefore recursed
--     and PostgREST returned 500 "infinite recursion detected in policy for
--     relation threads" — breaking the whole messaging feature.
--
--     Fix: move the membership lookup into a SECURITY DEFINER helper that reads
--     thread_participants WITHOUT triggering RLS, and have both policies call
--     it instead of cross-referencing each other.
--
-- (2) wallets — add the missing INSERT policy
--     wallets had SELECT + UPDATE policies but no INSERT policy, so the first
--     getOrCreateWallet() (e.g. opening canteen/orders) was denied with 403.
-- ============================================================================

-- ── (1) threads recursion ───────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.is_thread_participant(
  p_thread_id UUID,
  p_user_id   UUID
)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1
    FROM thread_participants tp
    WHERE tp.thread_id = p_thread_id
      AND tp.user_id   = p_user_id
  );
$$;

REVOKE EXECUTE ON FUNCTION public.is_thread_participant(UUID, UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.is_thread_participant(UUID, UUID) TO authenticated;

DROP POLICY IF EXISTS "View own threads" ON threads;
CREATE POLICY "View own threads" ON threads
  FOR SELECT
  USING (
    tenant_id = public.tenant_id()
    AND (
      created_by = auth.uid()
      OR public.is_thread_participant(id, auth.uid())
    )
  );

DROP POLICY IF EXISTS "View thread participants" ON thread_participants;
CREATE POLICY "View thread participants" ON thread_participants
  FOR SELECT
  USING (
    user_id = auth.uid()
    OR public.is_thread_participant(thread_id, auth.uid())
  );

-- ── (2) wallets INSERT policy ───────────────────────────────────────────────
-- Mirrors the existing "Manage own wallet" UPDATE policy's predicate.
DROP POLICY IF EXISTS "Create own wallet" ON wallets;
CREATE POLICY "Create own wallet" ON wallets
  FOR INSERT
  WITH CHECK (
    tenant_id = public.tenant_id()
    AND (
      public.is_admin()
      OR user_id = auth.uid()
      OR student_id IN (
        SELECT sp.student_id
        FROM student_parents sp
        JOIN parents p ON sp.parent_id = p.id
        WHERE p.user_id = auth.uid()
      )
    )
  );
