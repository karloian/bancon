-- SIMPLE SOLUTION: Use RLS policies + enable signups
-- Run this SQL in your Supabase SQL Editor

-- 1. Enable RLS on users_db (if not already enabled)
ALTER TABLE users_db ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing policies if any (optional - be careful!)
-- DROP POLICY IF EXISTS "Admins can insert users" ON users_db;
-- DROP POLICY IF EXISTS "Admins can update users" ON users_db;
-- DROP POLICY IF EXISTS "Admins can view all users" ON users_db;

-- 3. Create policy allowing admins to insert users
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

-- 4. Create policy allowing admins to update any user
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
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users_db
    WHERE user_id = auth.uid()
    AND role = 'admin'
  )
);

-- 5. Create policy allowing admins to view all users
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

-- 6. Create policy for users to view their own data
CREATE POLICY "Users can view own data"
ON users_db
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- After running this:
-- 1. Go to Supabase Dashboard → Authentication → Providers → Email
-- 2. Enable "Enable email signups" 
-- 3. (Optional) Disable "Confirm email" if you want users to login immediately

-- The RLS policies will ensure only admins can insert into users_db
-- Regular signups from the public won't work because they won't be able to insert into users_db
