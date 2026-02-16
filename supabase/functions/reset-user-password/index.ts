import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { 
      headers: { 
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      } 
    })
  }

  try {
    if (req.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 })
    }

    // Create Supabase client with service role key
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // Get the authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'No authorization header' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token)

    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized: ' + (authError?.message || 'Invalid token') }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Check if user is admin
    const { data: profile, error: profileError } = await supabaseAdmin
      .from('users_db')
      .select('role')
      .eq('user_id', user.id)
      .single()

    if (profileError || profile?.role !== 'admin') {
      return new Response(JSON.stringify({ error: 'Forbidden: Admin access required' }), {
        status: 403,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Get request body
    const { user_id, new_password } = await req.json()

    if (!user_id || !new_password) {
      return new Response(JSON.stringify({ error: 'user_id and new_password are required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Update user password
    const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(
      user_id,
      { password: new_password }
    )

    if (updateError) {
      return new Response(JSON.stringify({ error: updateError.message }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    return new Response(
      JSON.stringify({ success: true, message: 'Password updated successfully' }),
      { status: 200, headers: { 'Content-Type': 'application/json' } },
    )
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
