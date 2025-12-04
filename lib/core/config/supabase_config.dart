class SupabaseConfig {
  SupabaseConfig._();

  // Supabase project URL from Settings → API → Project URL
  static const String url = 'https://qykjmurexpydteuarzwm.supabase.co';

  // Supabase anon public key from Settings → API → anon public
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF5a2ptdXJleHB5ZHRldWFyendtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ4NDg1NzYsImV4cCI6MjA4MDQyNDU3Nn0.JiLmY0OSZ8K-npbCj6eKP1ZdJXh2apbCZndvDhAobAc';

  // Storage buckets
  static const String avatarsBucket = 'avatars';
  static const String documentsBucket = 'documents';
  static const String assignmentsBucket = 'assignments';
  static const String submissionsBucket = 'submissions';

  // Edge functions
  static const String functionsUrl = '$url/functions/v1';
  static String edgeFunctionUrl(String name) => '$functionsUrl/$name';

  // Optional extras for auth
  static const String redirectUrl =
      String.fromEnvironment('SUPABASE_REDIRECT_URL', defaultValue: '');

  // Optional (do NOT set in mobile frontend)
  static const String serviceRoleKey =
      String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY', defaultValue: '');
}
