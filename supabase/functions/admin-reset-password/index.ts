// 2026-05-16: Admin-initiated password reset. CRITICAL-1 audit follow-up.
// Caller must be super_admin / principal / tenant_admin in the target user's tenant.
// Overwrites the bcrypt hash via Supabase admin API; returns new plaintext ONCE.
// Audit row in user_credentials is upserted with the resetter's id.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Environment-driven CORS allowlist. Set ALLOWED_ORIGINS in Supabase
// function secrets as a comma-separated list of trusted origins.
const ALLOWED_ORIGINS = (Deno.env.get('ALLOWED_ORIGINS') ?? 'http://localhost:3000')
  .split(',').map(s => s.trim())

function corsHeadersFor(req: Request) {
  const origin = req.headers.get('origin') ?? '';
  const isAllowed = ALLOWED_ORIGINS.includes(origin);
  return {
    ...(isAllowed ? { 'Access-Control-Allow-Origin': origin } : {}),
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };
}

// Same generator semantics as Flutter CredentialGenerator:
// 16 chars, mixed case + digits + 2 special characters.
function generatePassword(): string {
  const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  const lower = 'abcdefghjkmnpqrstuvwxyz';
  const digit = '23456789';
  const special = '@#$%&!';
  const all = upper + lower + digit + special;
  // crypto.getRandomValues for cryptographically secure random selection.
  const secureRandom = (s: string): string => {
    const arr = new Uint32Array(1);
    crypto.getRandomValues(arr);
    return s[arr[0] % s.length];
  };
  const chars = [
    secureRandom(upper),
    secureRandom(lower),
    secureRandom(digit),
    secureRandom(special),
  ];
  for (let i = 4; i < 16; i++) chars.push(secureRandom(all));
  // Fisher-Yates shuffle using crypto.getRandomValues.
  for (let i = chars.length - 1; i > 0; i--) {
    const arr = new Uint32Array(1);
    crypto.getRandomValues(arr);
    const j = arr[0] % (i + 1);
    [chars[i], chars[j]] = [chars[j], chars[i]];
  }
  return chars.join('');
}

serve(async (req: Request) => {
  // Preflight — reject origins not in the allowlist with 403.
  if (req.method === 'OPTIONS') {
    const origin = req.headers.get('origin') ?? ''
    if (!ALLOWED_ORIGINS.includes(origin)) {
      return new Response('Forbidden', { status: 403 })
    }
    return new Response('ok', { headers: corsHeadersFor(req) })
  }

  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      { status: 405, headers: { ...corsHeadersFor(req), 'Content-Type': 'application/json' } }
    )
  }

  try {
    // Authenticate caller from Authorization header (consistent with create-user pattern).
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeadersFor(req), 'Content-Type': 'application/json' } }
      )
    }

    // Caller client — validates the JWT and gets the authenticated user.
    const callerClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user: caller }, error: callerError } = await callerClient.auth.getUser()
    if (callerError || !caller) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeadersFor(req), 'Content-Type': 'application/json' } }
      )
    }

    const body = await req.json()
    const { target_user_id } = body as { target_user_id?: string }

    if (!target_user_id || typeof target_user_id !== 'string') {
      return new Response(
        JSON.stringify({ error: 'target_user_id is required' }),
        { status: 400, headers: { ...corsHeadersFor(req), 'Content-Type': 'application/json' } }
      )
    }

    // Admin client for privileged reads + the actual password overwrite.
    const adminClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Resolve caller's roles from user_roles table — consistent with create-user pattern.
    const { data: callerRoleRows } = await callerClient
      .from('user_roles')
      .select('role, tenant_id')
      .eq('user_id', caller.id)
      .in('role', ['super_admin', 'principal', 'tenant_admin'])

    if (!callerRoleRows || callerRoleRows.length === 0) {
      return new Response(
        JSON.stringify({ error: 'Forbidden' }),
        { status: 403, headers: { ...corsHeadersFor(req), 'Content-Type': 'application/json' } }
      )
    }

    type RoleRow = { role: string; tenant_id: string }
    const callerRoleSet = new Set((callerRoleRows as RoleRow[]).map(r => r.role))
    const callerTenantIds = new Set((callerRoleRows as RoleRow[]).map(r => r.tenant_id))

    const callerIsSuper = callerRoleSet.has('super_admin')
    const callerIsPrincipal = callerRoleSet.has('principal')
    const callerIsTenantAdmin = callerRoleSet.has('tenant_admin')

    // Load the target user's profile + roles to enforce tenant and role hierarchy rules.
    const { data: targetUserData, error: targetErr } = await adminClient.auth.admin.getUserById(target_user_id)
    if (targetErr || !targetUserData.user) {
      return new Response(
        JSON.stringify({ error: 'Target user not found' }),
        { status: 404, headers: { ...corsHeadersFor(req), 'Content-Type': 'application/json' } }
      )
    }

    const targetAuthUser = targetUserData.user
    const targetEmail: string = targetAuthUser.email ?? ''

    // Resolve target's tenant + roles from user_roles table.
    const { data: targetRoleRows } = await adminClient
      .from('user_roles')
      .select('role, tenant_id')
      .eq('user_id', target_user_id)

    type TargetRoleRow = { role: string; tenant_id: string }
    const targetRoleSet = new Set((targetRoleRows as TargetRoleRow[] | null ?? []).map(r => r.role))
    const targetTenantIds = new Set((targetRoleRows as TargetRoleRow[] | null ?? []).map(r => r.tenant_id))
    // Use first resolved tenant_id as canonical tenant for the audit row.
    const targetTenant: string | undefined = (targetRoleRows as TargetRoleRow[] | null)?.[0]?.tenant_id

    // Permission matrix:
    //   super_admin → can reset anyone EXCEPT another super_admin.
    //   principal   → can reset within same tenant; cannot reset super_admin or other principals.
    //   tenant_admin → can reset within same tenant; cannot reset super_admin, principal, or other tenant_admins.
    if (callerIsSuper && targetRoleSet.has('super_admin') && targetAuthUser.id !== caller.id) {
      return new Response(
        JSON.stringify({ error: 'Cannot reset another super_admin' }),
        { status: 403, headers: { ...corsHeadersFor(req), 'Content-Type': 'application/json' } }
      )
    }

    if (!callerIsSuper) {
      // Non-super admins must share a tenant with the target.
      const sharedTenant = [...callerTenantIds].some(tid => targetTenantIds.has(tid))
      if (!sharedTenant) {
        return new Response(
          JSON.stringify({ error: 'Cross-tenant reset is not allowed' }),
          { status: 403, headers: { ...corsHeadersFor(req), 'Content-Type': 'application/json' } }
        )
      }

      if (targetRoleSet.has('super_admin')) {
        return new Response(
          JSON.stringify({ error: 'Cannot reset a super_admin' }),
          { status: 403, headers: { ...corsHeadersFor(req), 'Content-Type': 'application/json' } }
        )
      }

      // Only super_admin or principal can reset a principal.
      if (!callerIsPrincipal && targetRoleSet.has('principal')) {
        return new Response(
          JSON.stringify({ error: 'Only super_admin or principal can reset a principal' }),
          { status: 403, headers: { ...corsHeadersFor(req), 'Content-Type': 'application/json' } }
        )
      }

      // Only super_admin or principal can reset a tenant_admin.
      if (!callerIsPrincipal && !callerIsSuper && targetRoleSet.has('tenant_admin')) {
        return new Response(
          JSON.stringify({ error: 'Only super_admin or principal can reset a tenant_admin' }),
          { status: 403, headers: { ...corsHeadersFor(req), 'Content-Type': 'application/json' } }
        )
      }
    }

    // Generate the new password and update the auth hash.
    const newPassword = generatePassword()
    const { error: updErr } = await adminClient.auth.admin.updateUserById(target_user_id, {
      password: newPassword,
    })
    if (updErr) {
      console.error('admin-reset-password updateUserById:', updErr)
      return new Response(
        JSON.stringify({ error: 'An internal error occurred.' }),
        { status: 500, headers: { ...corsHeadersFor(req), 'Content-Type': 'application/json' } }
      )
    }

    // Upsert audit row recording the resetter + timestamp.
    // Password is NOT persisted — only the reset event metadata.
    if (targetTenant) {
      await adminClient
        .from('user_credentials')
        .upsert(
          {
            user_id: target_user_id,
            tenant_id: targetTenant,
            email: targetEmail,
            created_by: caller.id,
          },
          { onConflict: 'user_id' }
        )
    }

    return new Response(
      // one_time_password is returned once for admin to relay — never persisted.
      JSON.stringify({
        target_user_id,
        email: targetEmail,
        one_time_password: newPassword,
      }),
      { headers: { ...corsHeadersFor(req), 'Content-Type': 'application/json' } }
    )

  } catch (error: unknown) {
    // Log full error server-side only; return generic message to client.
    console.error('admin-reset-password unhandled error:', error)
    return new Response(
      JSON.stringify({ error: 'An internal error occurred.' }),
      { status: 500, headers: { ...corsHeadersFor(req), 'Content-Type': 'application/json' } }
    )
  }
})
