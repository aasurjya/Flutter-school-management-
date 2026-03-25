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

/// Default password for all seeded demo users (from seed_auth_users.sql).
const _defaultDemoPassword = String.fromEnvironment(
  'TEST_DEMO_PASSWORD',
  defaultValue: 'Demo@2026',
);

/// Credential map for all 12 seeded demo roles.
///
/// Each entry maps a role name to its email. All share [_defaultDemoPassword].
/// These match the users created in `supabase/seed_auth_users.sql`.
const roleCredentials = <String, String>{
  'super_admin': 'superadmin@demoschool.edu',
  'tenant_admin': 'admin@demoschool.edu',
  'principal': 'principal@demoschool.edu',
  'teacher': 'teacher1@demoschool.edu',
  'student': 'student1@demoschool.edu',
  'parent': 'parent1@demoschool.edu',
  'accountant': 'accountant@demoschool.edu',
  'librarian': 'librarian@demoschool.edu',
  'transport_manager': 'transport@demoschool.edu',
  'hostel_warden': 'hostelwarden@demoschool.edu',
  'canteen_staff': 'canteen@demoschool.edu',
  'receptionist': 'receptionist@demoschool.edu',
};

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

/// Convenience accessor for the Supabase client.
SupabaseClient get supabase => Supabase.instance.client;

/// Signs in with the test admin credentials (legacy helper).
/// Returns the session or throws if sign-in fails.
Future<AuthResponse> signInAsAdmin() async {
  final response = await supabase.auth.signInWithPassword(
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

/// Signs in as any of the 12 seeded demo roles.
///
/// [role] must be one of the keys in [roleCredentials].
/// Throws [StateError] if the role is unknown or sign-in fails.
Future<AuthResponse> signInAsRole(String role) async {
  final email = roleCredentials[role];
  if (email == null) {
    throw StateError(
      'Unknown role "$role". '
      'Valid roles: ${roleCredentials.keys.join(', ')}',
    );
  }

  final response = await supabase.auth.signInWithPassword(
    email: email,
    password: _defaultDemoPassword,
  );

  if (response.user == null) {
    throw StateError(
      'Sign-in failed for role "$role" ($email). '
      'Ensure supabase/seed_auth_users.sql has been applied.',
    );
  }

  return response;
}

/// Signs out the current session, then signs in as [toRole].
///
/// Useful for cross-role sync tests where you write as one role
/// and verify as another.
Future<AuthResponse> signOutAndSwitch(String toRole) async {
  await signOut();
  return signInAsRole(toRole);
}

/// Signs out the current session (call in tearDownAll).
Future<void> signOut() async {
  await supabase.auth.signOut();
}

/// Returns the current user's primary role from JWT app_metadata.
String? get currentUserRole {
  final roles = supabase.auth.currentUser?.appMetadata['roles'];
  if (roles is List && roles.isNotEmpty) {
    return roles.first as String?;
  }
  return null;
}

/// Returns the current user's tenant_id from JWT app_metadata.
String? get currentTenantId {
  return supabase.auth.currentUser?.appMetadata['tenant_id'] as String?;
}
