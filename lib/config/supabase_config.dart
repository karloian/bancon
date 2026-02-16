class SupabaseConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://zherygbltlspznshjczb.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpoZXJ5Z2JsdGxzcHpuc2hqY3piIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExNjgxNTIsImV4cCI6MjA4Njc0NDE1Mn0.GwHOcAvAmc89hRDRmQ1ehqXUheg97_uGahr5xngqvWc',
  );
}
