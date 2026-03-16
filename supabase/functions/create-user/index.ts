import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Max-Age': '86400',
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Verify the calling user's JWT
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create a client with the caller's JWT to check their role
    const callerClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    // Get current user
    const { data: { user: caller }, error: callerError } = await callerClient.auth.getUser()
    if (callerError || !caller) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const body = await req.json()

    // Handle delete action (for rollback) — requires admin role
    if (body.action === 'delete' && body.user_id) {
      // Verify caller has admin privileges before allowing deletion
      const { data: callerAdminRoles } = await callerClient
        .from('user_roles')
        .select('role')
        .eq('user_id', caller.id)
        .in('role', ['super_admin', 'tenant_admin', 'principal'])
        .limit(1)

      if (!callerAdminRoles || callerAdminRoles.length === 0) {
        return new Response(
          JSON.stringify({ error: 'Forbidden: only admins can delete users' }),
          { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      const adminClient = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
      )
      await adminClient.auth.admin.deleteUser(body.user_id)
      return new Response(
        JSON.stringify({ success: true }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const { email, password, full_name, tenant_id, role, phone } = body

    // Validate required fields
    if (!email || !password || !full_name || !tenant_id || !role) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: email, password, full_name, tenant_id, role' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check if caller is a super_admin on ANY tenant (super_admin can create for any tenant)
    const { data: superAdminCheck } = await callerClient
      .from('user_roles')
      .select('role')
      .eq('user_id', caller.id)
      .eq('role', 'super_admin')
      .limit(1)

    const isSuperAdmin = superAdminCheck && superAdminCheck.length > 0
    let callerRole: string | null = isSuperAdmin ? 'super_admin' : null

    if (!isSuperAdmin) {
      const { data: callerRoles, error: roleError } = await callerClient
        .from('user_roles')
        .select('role, tenant_id')
        .eq('user_id', caller.id)
        .eq('tenant_id', tenant_id)
        .in('role', ['tenant_admin', 'principal'])

      if (roleError || !callerRoles || callerRoles.length === 0) {
        return new Response(
          JSON.stringify({ error: 'Forbidden: insufficient permissions for this tenant' }),
          { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      const callerRoleSet = new Set(
        (callerRoles as Array<{ role: string }>).map(
          (entry: { role: string }) => entry.role,
        ),
      )
      if (callerRoleSet.has('principal')) {
        callerRole = 'principal'
      } else if (callerRoleSet.has('tenant_admin')) {
        callerRole = 'tenant_admin'
      }
    }

    const allowedRoles = [
      'super_admin',
      'principal',
      'tenant_admin',
      'teacher',
      'student',
      'parent',
      'accountant',
      'librarian',
      'transport_manager',
      'hostel_warden',
      'canteen_staff',
      'receptionist',
    ]

    if (!allowedRoles.includes(role)) {
      return new Response(
        JSON.stringify({ error: `Unsupported role: ${role}` }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!isSuperAdmin) {
      if (role === 'super_admin' || role === 'principal') {
        return new Response(
          JSON.stringify({ error: 'Forbidden: only platform admins can create this role' }),
          { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      if (role === 'tenant_admin' && callerRole !== 'principal') {
        return new Response(
          JSON.stringify({ error: 'Forbidden: only principals can create school admins' }),
          { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }

    // Use service_role client to create auth user without email confirmation
    const adminClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Look up tenant slug for credential generation
    const { data: tenantData } = await adminClient
      .from('tenants')
      .select('slug')
      .eq('id', tenant_id)
      .maybeSingle()
    const tenantSlug: string = (tenantData as { slug: string } | null)?.slug ?? tenant_id.substring(0, 8)

    // Create auth user
    const { data: authData, error: authError } = await adminClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      app_metadata: { tenant_id, tenant_slug: tenantSlug },
      user_metadata: { full_name },
    })

    if (authError || !authData.user) {
      return new Response(
        JSON.stringify({ error: authError?.message ?? 'Failed to create auth user' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const userId = authData.user.id

    // Insert user profile
    const { error: profileError } = await adminClient
      .from('users')
      .insert({
        id: userId,
        tenant_id,
        email,
        full_name,
        phone: phone ?? null,
        is_active: true,
      })

    if (profileError) {
      // Rollback auth user
      await adminClient.auth.admin.deleteUser(userId)
      return new Response(
        JSON.stringify({ error: `Profile creation failed: ${profileError.message}` }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Assign role
    const { error: roleAssignError } = await adminClient
      .from('user_roles')
      .insert({
        user_id: userId,
        tenant_id,
        role,
        is_primary: true,
      })

    if (roleAssignError) {
      // Rollback auth user and profile
      await adminClient.auth.admin.deleteUser(userId)
      return new Response(
        JSON.stringify({ error: `Role assignment failed: ${roleAssignError.message}` }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Store initial credentials so admins can look them up later
    await adminClient.from('user_credentials').insert({
      user_id: userId,
      tenant_id,
      email,
      initial_password: password,
      created_by: caller.id,
    })

    return new Response(
      JSON.stringify({ user_id: userId, email }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : String(error)
    return new Response(
      JSON.stringify({ error: `Internal server error: ${errorMessage}` }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
