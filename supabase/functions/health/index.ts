// ============================================================================
// supabase/functions/health
//
// Liveness + lightweight readiness probe. Returns 200 if:
//   • the function host is up
//   • a `SELECT 1` against the DB succeeds within 2 s
//
// Free uptime monitors (UptimeRobot, Cronitor, BetterStack) hit this every
// 5 minutes from multiple regions. The Stage 1 GitHub canary
// (.github/workflows/canary.yml) also relies on it indirectly via the
// killswitch + students/invoices probes.
//
// Public (no auth required). Returns a small JSON body so monitors can
// content-match on `status:ok` if their HTTP-code check isn't enough.
// ============================================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  if (req.method !== 'GET') {
    return new Response(
      JSON.stringify({ status: 'error', error: 'method_not_allowed' }),
      { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }

  const startedAt = Date.now()
  let dbOk = false
  let dbError: string | null = null

  try {
    // Service role bypasses RLS — we only need to prove the DB is reachable,
    // not exfiltrate data. The query is the cheapest possible read.
    const client = createClient(SUPABASE_URL, SERVICE_ROLE)
    const probe = client
      .from('app_killswitch')
      .select('key')
      .limit(1)
      .maybeSingle()

    // Hard 2 s ceiling — a slow DB is "unhealthy" even if it eventually replies.
    const { error } = await Promise.race([
      probe,
      new Promise<{ error: { message: string } }>((resolve) =>
        setTimeout(
          () => resolve({ error: { message: 'db_timeout_2s' } }),
          2000,
        ),
      ),
    ])

    if (error) {
      dbError = error.message
    } else {
      dbOk = true
    }
  } catch (e) {
    dbError = e instanceof Error ? e.message : String(e)
  }

  const elapsedMs = Date.now() - startedAt
  const status = dbOk ? 'ok' : 'degraded'
  const httpStatus = dbOk ? 200 : 503

  return new Response(
    JSON.stringify({
      status,
      db: dbOk ? 'ok' : 'fail',
      db_error: dbError,
      elapsed_ms: elapsedMs,
      ts: new Date().toISOString(),
    }),
    {
      status: httpStatus,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    },
  )
})
