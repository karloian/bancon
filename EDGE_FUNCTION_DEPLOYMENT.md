# Deploy Supabase Edge Function

## Prerequisites
Install Supabase CLI:
```bash
brew install supabase/tap/supabase
```

## Steps to Deploy

1. **Login to Supabase**:
```bash
supabase login
```

2. **Link your project**:
```bash
supabase link --project-ref zherygbltlspznshjczb
```

3. **Deploy the function**:
```bash
supabase functions deploy create-user
```

4. **Test the deployment** (optional):
The function is now live and will be called automatically by your Flutter app when adding users.

## How it works
- The edge function runs on Supabase's servers with the service role key
- It verifies the caller is an admin
- It creates users with admin privileges (bypassing signup restrictions)
- Your admin session stays intact

## Alternative: Quick Test Without Deployment
If you want to test immediately without deploying:
1. Go to Supabase Dashboard → Authentication → Settings
2. **Temporarily** enable "Enable email signups"
3. Test user creation
4. Disable signups again after testing

**Note**: The edge function is the secure, production-ready solution.
