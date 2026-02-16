-- FIXED SOLUTION: Use helper function to avoid infinite recursion
-- Run this SQL in your Supabase SQL Editor

-- FIRST: Drop all existing policies to start fresh
DROP POLICY IF EXISTS "Admins can insert users" ON users_db;
DROP POLICY IF EXISTS "Admins can update users" ON users_db;
DROP POLICY IF EXISTS "Admins can view all users" ON users_db;
DROP POLICY IF EXISTS "Users can view own data" ON users_db;
DROP POLICY IF EXISTS "Admins can delete users" ON users_db;

-- 1. Create a helper function to check if user is admin (bypasses RLS)
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER -- This bypasses RLS to avoid infinite recursion
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users_db
    WHERE user_id = auth.uid()
    AND role = 'admin'
  );
END;
$$;

-- 2. Enable RLS on users_db
ALTER TABLE users_db ENABLE ROW LEVEL SECURITY;

-- 3. Create policy allowing admins to SELECT all users
CREATE POLICY "Admins can view all users"
ON users_db
FOR SELECT
TO authenticated
USING (is_admin());

-- 4. Create policy for users to view their own data
CREATE POLICY "Users can view own data"
ON users_db
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- 5. Create policy allowing admins to INSERT users
CREATE POLICY "Admins can insert users"
ON users_db
FOR INSERT
TO authenticated
WITH CHECK (is_admin());

-- 6. Create policy allowing admins to UPDATE any user
CREATE POLICY "Admins can update users"
ON users_db
FOR UPDATE
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());

-- 7. Create policy allowing admins to DELETE users
CREATE POLICY "Admins can delete users"
ON users_db
FOR DELETE
TO authenticated
USING (is_admin());

-- IMPORTANT: After running this SQL:
-- 1. Go to Supabase Dashboard → Authentication → Providers → Email
-- 2. Enable "Enable email signups" 
-- 3. (Optional) Disable "Confirm email" for immediate login

-- The is_admin() function with SECURITY DEFINER bypasses RLS, preventing infinite recursion!
