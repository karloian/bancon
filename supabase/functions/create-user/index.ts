import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    // Only allow POST requests
    if (req.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 })
    }

    // Create Supabase client with service role key (has admin privileges)
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // Verify the caller is authenticated and is an admin
    const authHeader = req.headers.get('Authorization')!
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token)

    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Check if user is admin
    const { data: profile } = await supabaseAdmin
      .from('users_db')
      .select('role')
      .eq('user_id', user.id)
      .single()

    if (profile?.role !== 'admin') {
      return new Response(JSON.stringify({ error: 'Forbidden: Admin access required' }), {
        status: 403,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Get request body
    const { email, password, fullname, role, status } = await req.json()

    // Create user with admin privileges
    const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true, // Auto-confirm email
    })

    if (createError) {
      return new Response(JSON.stringify({ error: createError.message }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Insert into users_db
    const { error: insertError } = await supabaseAdmin
      .from('users_db')
      .insert({
        user_id: newUser.user.id,
        email: email.toLowerCase(),
        fullname,
        role,
        status,
      })

    if (insertError) {
      // Rollback: delete the auth user if db insert fails
      await supabaseAdmin.auth.admin.deleteUser(newUser.user.id)
      return new Response(JSON.stringify({ error: insertError.message }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    return new Response(
      JSON.stringify({ success: true, user: newUser.user }),
      { status: 200, headers: { 'Content-Type': 'application/json' } },
    )
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
