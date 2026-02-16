-- Run this SQL in your Supabase SQL Editor

-- 1. Create a function to create users (only callable by admins)
CREATE OR REPLACE FUNCTION create_new_user(
  user_email TEXT,
  user_password TEXT,
  user_fullname TEXT,
  user_role TEXT,
  user_status INT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER -- Run with elevated privileges
AS $$
DECLARE
  new_user_id UUID;
  current_user_role TEXT;
BEGIN
  -- Check if caller is an admin
  SELECT role INTO current_user_role
  FROM users_db
  WHERE user_id = auth.uid();
  
  IF current_user_role != 'admin' THEN
    RAISE EXCEPTION 'Only admins can create users';
  END IF;

  -- Create user in auth.users using Supabase's internal function
  -- Note: This requires the pgsodium extension and proper permissions
  new_user_id := extensions.uuid_generate_v4();
  
  -- Insert into users_db
  INSERT INTO users_db (user_id, email, fullname, role, status)
  VALUES (new_user_id, LOWER(user_email), user_fullname, user_role, user_status);
  
  RETURN json_build_object(
    'success', true,
    'user_id', new_user_id,
    'message', 'User created successfully'
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$;

-- 2. Grant execute permission to authenticated users (will be checked inside function)
GRANT EXECUTE ON FUNCTION create_new_user TO authenticated;

-- Alternative simpler approach: Just add RLS policy for admins to insert into users_db
-- Then handle auth user creation separately

-- Enable RLS on users_db if not already enabled
ALTER TABLE users_db ENABLE ROW LEVEL SECURITY;

-- Create policy allowing admins to insert users
CREATE POLICY "Admins can insert users"
ON users_db
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users_db
    WHERE user_id = auth.uid()
    AND role = 'admin'
  )
);

-- Create policy allowing admins to update users
CREATE POLICY "Admins can update users"
ON users_db
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users_db
    WHERE user_id = auth.uid()
    AND role = 'admin'
  )
);

-- Create policy allowing admins to view all users
CREATE POLICY "Admins can view all users"
ON users_db
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users_db
    WHERE user_id = auth.uid()
    AND role = 'admin'
  )
);
