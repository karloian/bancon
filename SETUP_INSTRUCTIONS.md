# Supabase Setup Instructions for Authentication

## 1. Create New Database Table

Run this SQL in Supabase SQL Editor:

```sql
-- Drop old table
DROP TABLE IF EXISTS users_db CASCADE;

-- Create new users_db table with proper schema
CREATE TABLE users_db (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  fullname TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin', 'supervisor', 'encoder', 'agent')),
  status INTEGER NOT NULL DEFAULT 1 CHECK (status IN (1, 2)),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX users_db_user_id_idx ON users_db(user_id);
CREATE INDEX users_db_email_idx ON users_db(email);
CREATE INDEX users_db_role_idx ON users_db(role);

-- Enable RLS
ALTER TABLE users_db ENABLE ROW LEVEL SECURITY;
```

## 2. Setup RLS Policies

Run this SQL to create security policies:

```sql
-- Allow authenticated users full access to users_db
CREATE POLICY "Allow authenticated full access" 
ON users_db 
FOR ALL 
TO authenticated 
USING (true) 
WITH CHECK (true);
```

## 3. Enable Email Auth

1. Go to **Authentication** → **Providers**
2. Enable **Email** provider
3. Disable email confirmation (for testing): **Authentication** → **Settings** → Disable "Enable email confirmations"

## 4. Create First Admin User

**Step-by-step:**

1. Go to **Authentication** → **Users** → Click **Add User** button
2. Enter:
   - Email: `admin@example.com` (or your email)
   - Password: Create a strong password
   - Check "Auto Confirm User" if available
3. Click **Create User**
4. After created, you'll see the user in the list - **click on the user row**
5. Copy the **ID** field (this is the UUID you need - looks like: `a1b2c3d4-e5f6-7890-abcd-ef1234567890`)
6. Go to **Table Editor** → **users_db** → Click **Insert** → **Insert row**
7. Fill in:
   - `user_id`: Paste the UUID you copied
   - `email`: Same email as step 2
   - `fullname`: `Admin User`
   - `role`: `admin`
   - `status`: `1`
8. Click **Save**

Now you can log in with that email and password!

## 5. Test the Changes

After completing the above:
1. Restart your Flutter app
2. Try logging in with the admin credentials
3. Try adding new users from the admin dashboard

The app now uses proper Supabase Authentication instead of custom password checking.
