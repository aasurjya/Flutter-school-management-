import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_environment.dart';

/// Result returned after successfully creating a user.
class CreatedUserResult {
  final String userId;
  final String email;
  final String password;
  final bool usedFallback;

  const CreatedUserResult({
    required this.userId,
    required this.email,
    required this.password,
    this.usedFallback = false,
  });

  @override
  String toString() =>
      'CreatedUserResult(userId: $userId, email: $email, password: [REDACTED], usedFallback: $usedFallback)';
}

/// Thrown when admin user creation fails.
class AdminUserCreationException implements Exception {
  final String message;
  const AdminUserCreationException(this.message);

  @override
  String toString() => 'AdminUserCreationException: $message';
}

/// Service for creating users server-side via the `create-user` Edge Function,
/// with a client-side fallback using `auth.signUp()` + a SECURITY DEFINER RPC
/// when the Edge Function is unavailable.
class AdminUserService {
  final SupabaseClient _client;

  const AdminUserService(this._client);

  /// Creates a new auth user + profile + role assignment.
  ///
  /// Tries the Edge Function first. If that fails with a network/client error,
  /// falls back to client-side signUp + `create_user_profile` RPC.
  Future<CreatedUserResult> createUser({
    required String email,
    required String password,
    required String fullName,
    required String tenantId,
    required String role,
    String? phone,
  }) async {
    // --- Try Edge Function first ---
    try {
      return await _createUserViaEdgeFunction(
        email: email,
        password: password,
        fullName: fullName,
        tenantId: tenantId,
        role: role,
        phone: phone,
      );
    } on AdminUserCreationException {
      // Edge Function returned a structured error (e.g. 403, 400) — don't fallback
      rethrow;
    } on FunctionException {
      // Edge Function returned an HTTP error — don't fallback for server-side errors
      rethrow;
    } catch (_) {
      // Network/client error (ClientException, SocketException, etc.)
      // → Edge Function likely not deployed. Fall back.
    }

    // --- Fallback: signUp + RPC ---
    return _createUserViaSignUpAndRpc(
      email: email,
      password: password,
      fullName: fullName,
      tenantId: tenantId,
      role: role,
      phone: phone,
    );
  }

  /// Primary path: calls the `create-user` Edge Function.
  Future<CreatedUserResult> _createUserViaEdgeFunction({
    required String email,
    required String password,
    required String fullName,
    required String tenantId,
    required String role,
    String? phone,
  }) async {
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
  }

  /// Fallback path: creates auth user via raw HTTP signUp (avoids platform
  /// issues with ephemeral SupabaseClient on web), then calls
  /// `create_user_profile` RPC on the admin's client.
  Future<CreatedUserResult> _createUserViaSignUpAndRpc({
    required String email,
    required String password,
    required String fullName,
    required String tenantId,
    required String role,
    String? phone,
  }) async {
    String? newUserId;
    try {
      // 1. Create auth user via raw HTTP POST — avoids creating a second
      //    SupabaseClient which crashes on Flutter web due to missing
      //    platform-specific auth storage initialization.
      final signUpResponse = await http.post(
        Uri.parse('${AppEnvironment.supabaseUrl}/auth/v1/signup'),
        headers: {
          'apikey': AppEnvironment.supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'data': {'full_name': fullName},
        }),
      );

      final body = jsonDecode(signUpResponse.body) as Map<String, dynamic>;

      if (signUpResponse.statusCode >= 400) {
        final errorMsg = body['msg'] as String? ??
            body['error_description'] as String? ??
            body['message'] as String? ??
            'Sign-up failed (HTTP ${signUpResponse.statusCode})';

        // Provide actionable guidance for rate limits
        if (signUpResponse.statusCode == 429 || errorMsg.toLowerCase().contains('rate limit')) {
          throw AdminUserCreationException(
            'Email rate limit exceeded. The create-user Edge Function may not '
            'be deployed — deploy it with: supabase functions deploy create-user. '
            'Meanwhile, wait a few minutes before retrying.',
          );
        }

        throw AdminUserCreationException(errorMsg);
      }

      // Supabase returns user inside 'user' key (or at top level for some versions)
      final userObj = body['user'] as Map<String, dynamic>? ?? body;
      newUserId = userObj['id'] as String?;

      if (newUserId == null) {
        throw const AdminUserCreationException(
          'Sign-up failed: email may already be registered',
        );
      }

      // 2. Call RPC to create profile + role + credentials + confirm email
      await _client.rpc('create_user_profile', params: {
        'p_user_id': newUserId,
        'p_tenant_id': tenantId,
        'p_email': email,
        'p_full_name': fullName,
        'p_role': role,
        'p_password': password,
        if (phone != null) 'p_phone': phone,
      });

      return CreatedUserResult(
        userId: newUserId,
        email: email,
        password: password,
        usedFallback: true,
      );
    } catch (e) {
      // If RPC failed but signUp succeeded, clean up the orphaned auth user
      if (newUserId != null && e is! AdminUserCreationException) {
        final cleaned = await _tryDeleteOrphanedUser(newUserId);
        final note = cleaned
            ? '(auth user cleaned up)'
            : '(cleanup FAILED — orphaned user $newUserId may remain)';
        throw AdminUserCreationException(
          'Profile creation failed $note: $e',
        );
      }
      if (e is AdminUserCreationException) rethrow;
      throw AdminUserCreationException('Fallback user creation failed: $e');
    }
  }

  /// Deletes an orphaned auth user via the `delete_auth_user` RPC.
  /// Returns `true` if deletion succeeded, `false` if it failed (best-effort).
  Future<bool> _tryDeleteOrphanedUser(String userId) async {
    try {
      await _client.rpc('delete_auth_user', params: {
        'p_user_id': userId,
      });
      return true;
    } catch (_) {
      // Orphaned user remains — admin must clean up manually
      return false;
    }
  }

  /// Deletes an auth user — call this on rollback if subsequent operations fail.
  Future<void> deleteUser(String userId) async {
    final success = await _tryDeleteOrphanedUser(userId);
    if (!success) {
      throw AdminUserCreationException(
        'Failed to delete user $userId — manual cleanup required',
      );
    }
  }
}
