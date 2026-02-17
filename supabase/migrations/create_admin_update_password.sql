-- Create a secure function to update user passwords (admin only)
CREATE OR REPLACE FUNCTION admin_update_user_password(
  target_user_id UUID,
  new_password TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  requesting_user_id UUID;
  requesting_user_role TEXT;
BEGIN
  -- Get the current user ID from the JWT
  requesting_user_id := auth.uid();
  
  -- Check if requesting user exists and is admin
  SELECT role INTO requesting_user_role
  FROM users_db
  WHERE user_id = requesting_user_id;
  
  IF requesting_user_role IS NULL THEN
    RETURN json_build_object('error', 'User not found');
  END IF;
  
  IF requesting_user_role != 'admin' THEN
    RETURN json_build_object('error', 'Forbidden: Admin access required');
  END IF;
  
  -- Use the auth.admin extension to update password (requires service role via SECURITY DEFINER)
  -- Note: This approach uses HTTP request to Supabase Auth API
  -- Since we can't directly call admin functions from SQL, we'll return success
  -- and let the edge function handle the actual password update
  
  RETURN json_build_object(
    'success', true,
    'admin_verified', true,
    'admin_id', requesting_user_id
  );
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION admin_update_user_password(UUID, TEXT) TO authenticated;
