-- FIX: Allow users to read their own profile during login
-- Run this SQL in Supabase Dashboard → SQL Editor

-- First, drop the problematic policies
DROP POLICY IF EXISTS "Users can view own data" ON users_db;
DROP POLICY IF EXISTS "Admins can view all users" ON users_db;

-- Recreate is_admin function (if it doesn't exist)
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
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

-- Create NEW policy: Users can ALWAYS read their own data (this is critical for login)
CREATE POLICY "Users can view own data"
ON users_db
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Create policy: Admins can view all users
CREATE POLICY "Admins can view all users"
ON users_db
FOR SELECT
TO authenticated
USING (is_admin());

-- Verify policies were created
SELECT tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'users_db';
