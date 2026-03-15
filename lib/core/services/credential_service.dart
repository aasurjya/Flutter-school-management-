import 'package:supabase_flutter/supabase_flutter.dart';

class UserCredential {
  final String email;
  final String initialPassword;
  final DateTime createdAt;

  const UserCredential({
    required this.email,
    required this.initialPassword,
    required this.createdAt,
  });
}

class CredentialService {
  final SupabaseClient _client;
  const CredentialService(this._client);

  /// Fetches stored initial credentials for a user.
  /// Returns null if not found or caller lacks permission.
  Future<UserCredential?> getCredentials(String userId) async {
    final response = await _client
        .from('user_credentials')
        .select('email, initial_password, created_at')
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;

    return UserCredential(
      email: response['email'] as String,
      initialPassword: response['initial_password'] as String,
      createdAt: DateTime.parse(response['created_at'] as String),
    );
  }
}
