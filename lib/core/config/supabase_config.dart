import 'package:flutter/foundation.dart';

class SupabaseConfig {
  SupabaseConfig._();

  // Supabase project URL from Settings → API → Project URL
  // Local for dev, hosted for production
  static String get url {
    if (kDebugMode) {
      return 'http://127.0.0.1:54321'; // Local
    } else {
      return 'https://qykjmurexpydteuarzwm.supabase.co'; // Production
    }
  }

  // Supabase anon public key from Settings → API → anon public
  // Local anon key for dev, hosted for production
  static String get anonKey {
    if (kDebugMode) {
      return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0'; // Local
    } else {
      return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF5a2ptdXJleHB5ZHRldWFyendtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ4NDg1NzYsImV4cCI6MjA4MDQyNDU3Nn0.JiLmY0OSZ8K-npbCj6eKP1ZdJXh2apbCZndvDhAobAc'; // Production
    }
  }

  // Storage buckets
  static const String avatarsBucket = 'avatars';
  static const String documentsBucket = 'documents';
  static const String assignmentsBucket = 'assignments';
  static const String submissionsBucket = 'submissions';

  // Edge functions
  static String get functionsUrl => '${url}/functions/v1';
  static String edgeFunctionUrl(String name) => '$functionsUrl/$name';

  // Optional extras for auth
  static const String redirectUrl =
      String.fromEnvironment('SUPABASE_REDIRECT_URL', defaultValue: '');

  // Optional (do NOT set in mobile frontend)
  static const String serviceRoleKey =
      String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY', defaultValue: '');
}
