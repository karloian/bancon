-- COMPLETE FIX FOR LOGIN ISSUE
-- Run this entire script in Supabase Dashboard → SQL Editor

-- Step 1: Disable RLS temporarily
ALTER TABLE users_db DISABLE ROW LEVEL SECURITY;

-- Step 2: Verify your admin account exists
SELECT user_id, email, fullname, role, status 
FROM users_db 
WHERE role = 'admin';
-- If no results, your admin account is missing!

-- Step 3: Drop ALL existing policies
DROP POLICY IF EXISTS "Users can view own data" ON users_db;
DROP POLICY IF EXISTS "Admins can view all users" ON users_db;
DROP POLICY IF EXISTS "Admins can insert users" ON users_db;
DROP POLICY IF EXISTS "Admins can update users" ON users_db;
DROP POLICY IF EXISTS "Admins can delete users" ON users_db;

-- Step 4: Drop and recreate the is_admin function
DROP FUNCTION IF EXISTS is_admin();

CREATE FUNCTION is_admin()
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

-- Step 5: Re-enable RLS
ALTER TABLE users_db ENABLE ROW LEVEL SECURITY;

-- Step 6: Create CORRECT policies
-- Policy 1: Users can ALWAYS read their own data (CRITICAL for login)
CREATE POLICY "Users can view own data"
ON users_db
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Policy 2: Admins can view ALL users
CREATE POLICY "Admins can view all users"
ON users_db
FOR SELECT
TO authenticated
USING (is_admin());

-- Policy 3: Admins can insert users
CREATE POLICY "Admins can insert users"
ON users_db
FOR INSERT
TO authenticated
WITH CHECK (is_admin());

-- Policy 4: Admins can update users
CREATE POLICY "Admins can update users"
ON users_db
FOR UPDATE
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());

-- Policy 5: Admins can delete users
CREATE POLICY "Admins can delete users"
ON users_db
FOR DELETE
TO authenticated
USING (is_admin());

-- Step 7: Verify policies are correct
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'users_db'
ORDER BY policyname;

-- DONE! Try logging in now.
