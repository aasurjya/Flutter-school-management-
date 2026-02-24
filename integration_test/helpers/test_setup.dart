/// Integration test bootstrap.
///
/// Reads Supabase credentials from `--dart-define` environment variables
/// (injected by the CI pipeline or the local script) and initialises
/// the Supabase client before any test runs.
///
/// Required dart-defines:
///   TEST_SUPABASE_URL          — e.g. https://qykjmurexpydteuarzwm.supabase.co
///   TEST_SUPABASE_ANON_KEY     — anon/public key from Supabase dashboard
///   TEST_ADMIN_EMAIL           — email of the seeded test-admin user
///   TEST_ADMIN_PASSWORD        — password of the seeded test-admin user
library test_setup;

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = String.fromEnvironment(
  'TEST_SUPABASE_URL',
  defaultValue: '',
);

const _supabaseAnonKey = String.fromEnvironment(
  'TEST_SUPABASE_ANON_KEY',
  defaultValue: '',
);

const testAdminEmail = String.fromEnvironment(
  'TEST_ADMIN_EMAIL',
  defaultValue: 'test-admin@school.test',
);

const testAdminPassword = String.fromEnvironment(
  'TEST_ADMIN_PASSWORD',
  defaultValue: '',
);

/// Call once in `setUpAll` of each integration test file.
Future<void> initIntegrationTest() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
    throw StateError(
      'Integration test credentials are missing.\n'
      'Pass them via --dart-define=TEST_SUPABASE_URL=... etc.\n'
      'See scripts/test_and_push.sh for the full invocation.',
    );
  }

  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );
}

/// Signs in with the test admin credentials.
/// Returns the session or throws if sign-in fails.
Future<AuthResponse> signInAsAdmin() async {
  final response = await Supabase.instance.client.auth.signInWithPassword(
    email: testAdminEmail,
    password: testAdminPassword,
  );

  if (response.user == null) {
    throw StateError(
      'Integration test sign-in failed for $testAdminEmail. '
      'Ensure supabase/seed/test_seed.sql has been applied.',
    );
  }

  return response;
}

/// Signs out the current session (call in tearDownAll).
Future<void> signOut() async {
  await Supabase.instance.client.auth.signOut();
}
