import 'app_environment.dart';

/// Supabase configuration
/// Uses environment variables for secure credential management
class SupabaseConfig {
  SupabaseConfig._();

  /// Supabase project URL from environment
  static String get url => AppEnvironment.supabaseUrl;

  /// Supabase anon public key from environment
  static String get anonKey => AppEnvironment.supabaseAnonKey;

  /// Optional redirect URL for OAuth
  static String? get redirectUrl => AppEnvironment.supabaseRedirectUrl;

  /// Storage buckets
  static const String avatarsBucket = 'avatars';
  static const String documentsBucket = 'documents';
  static const String assignmentsBucket = 'assignments';
  static const String submissionsBucket = 'submissions';

  /// Edge functions base URL
  static String get functionsUrl => '$url/functions/v1';

  /// Get specific edge function URL
  static String edgeFunctionUrl(String name) => '$functionsUrl/$name';
}
