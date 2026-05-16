import 'package:supabase_flutter/supabase_flutter.dart';

/// Audit-log record for a user's account creation event.
/// The plaintext password is NOT stored and cannot be retrieved.
/// To issue a new password, use AdminUserService.resetPassword(userId).
class UserCredentialAudit {
  final String email;
  final DateTime createdAt;
  final String? createdBy;

  const UserCredentialAudit({
    required this.email,
    required this.createdAt,
    this.createdBy,
  });
}

/// Deprecated wrapper retained for call-site compatibility only.
/// Does NOT expose initialPassword — that field was removed in the
/// 2026-05-16 security audit (CRITICAL-1).
/// Migrate callers to UserCredentialAudit and auditLookup().
@Deprecated(
    'Use UserCredentialAudit. Password is no longer stored. See AdminUserService.resetPassword.')
class UserCredential {
  final String email;
  final DateTime createdAt;
  const UserCredential({required this.email, required this.createdAt});
}

class CredentialService {
  final SupabaseClient _client;
  const CredentialService(this._client);

  /// Returns the audit-log record for when this user was created and by whom.
  /// Returns null if not found or caller lacks permission.
  ///
  /// Passwords are NEVER returned. Plaintext storage was removed in the
  /// 2026-05-16 security audit (CRITICAL-1). For password reset, see
  /// `AdminUserService.resetPassword(userId)`.
  Future<UserCredentialAudit?> auditLookup(String userId) async {
    final response = await _client
        .from('user_credentials')
        .select('email, created_at, created_by')
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;

    return UserCredentialAudit(
      email: response['email'] as String,
      createdAt: DateTime.parse(response['created_at'] as String),
      createdBy: response['created_by'] as String?,
    );
  }

  /// Deprecated. Use auditLookup() instead.
  /// Forwards to auditLookup() and returns the deprecated UserCredential shape
  /// (without initialPassword). Callers that read .initialPassword will get a
  /// compile error — intentional; fix those sites by migrating to auditLookup().
  @Deprecated('Use auditLookup(); password is no longer in the response.')
  Future<UserCredential?> getCredentials(String userId) async {
    final audit = await auditLookup(userId);
    if (audit == null) return null;
    return UserCredential(email: audit.email, createdAt: audit.createdAt);
  }
}
