import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase client provider - single source of truth for DI
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
