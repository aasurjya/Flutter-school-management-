import 'package:supabase_flutter/supabase_flutter.dart';

/// Result returned after successfully creating a user.
class CreatedUserResult {
  final String userId;
  final String email;
  final String password;

  const CreatedUserResult({
    required this.userId,
    required this.email,
    required this.password,
  });
}

/// Thrown when admin user creation fails.
class AdminUserCreationException implements Exception {
  final String message;
  const AdminUserCreationException(this.message);

  @override
  String toString() => 'AdminUserCreationException: $message';
}

/// Service for creating users server-side via the `create-user` Edge Function.
/// This is the ONLY place in the Flutter app that initiates user account creation.
/// The service_role key never touches the Flutter client — it lives in the Edge Function.
class AdminUserService {
  final SupabaseClient _client;

  const AdminUserService(this._client);

  /// Creates a new auth user + profile + role assignment via Edge Function.
  /// Returns the created user's ID, email, and plaintext password (show once to admin).
  Future<CreatedUserResult> createUser({
    required String email,
    required String password,
    required String fullName,
    required String tenantId,
    required String role,
    String? phone,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'create-user',
        body: {
          'email': email,
          'password': password,
          'full_name': fullName,
          'tenant_id': tenantId,
          'role': role,
          if (phone != null) 'phone': phone,
        },
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw const AdminUserCreationException('Empty response from server');
      }

      final error = data['error'] as String?;
      if (error != null) {
        throw AdminUserCreationException(error);
      }

      final userId = data['user_id'] as String?;
      final returnedEmail = data['email'] as String?;
      if (userId == null || returnedEmail == null) {
        throw const AdminUserCreationException('Invalid response structure');
      }

      return CreatedUserResult(
        userId: userId,
        email: returnedEmail,
        password: password,
      );
    } on AdminUserCreationException {
      rethrow;
    } on FunctionException catch (e) {
      throw AdminUserCreationException(
        e.details?.toString() ?? 'Edge Function error: ${e.status}',
      );
    } catch (e) {
      throw AdminUserCreationException('Unexpected error: $e');
    }
  }

  /// Deletes an orphaned auth user — call this on rollback if subsequent DB inserts fail.
  Future<void> deleteUser(String userId) async {
    try {
      await _client.functions.invoke(
        'create-user',
        body: {'action': 'delete', 'user_id': userId},
      );
    } catch (_) {
      // Best-effort cleanup. Log the orphaned userId for manual cleanup.
    }
  }
}
