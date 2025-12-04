import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/user.dart';

/// Supabase client provider
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Auth state provider (Supabase session)
final authStateProvider = StreamProvider<Session?>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return supabase.auth.onAuthStateChange.map((event) => event.session);
});

/// Current user provider
final currentUserProvider = StateProvider<AppUser?>((ref) => null);

/// Current tenant ID provider
final currentTenantIdProvider = StateProvider<String?>((ref) => null);

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseProvider));
});

/// Auth repository
class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  /// Get current session
  Session? get currentSession => _client.auth.currentSession;

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    developer.log('AuthRepository signInWithEmail(email: $email)', name: 'AuthRepository');
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    developer.log('AuthRepository signUpWithEmail(email: $email)', name: 'AuthRepository');
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        if (fullName != null) 'full_name': fullName,
      },
    );
  }

  /// Sign out
  Future<void> signOut() async {
    developer.log('AuthRepository signOut()', name: 'AuthRepository');
    await _client.auth.signOut();
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Update password
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Get user profile from database
  Future<AppUser?> getUserProfile(String userId) async {
    developer.log('AuthRepository getUserProfile(userId: $userId)', name: 'AuthRepository');
    final response = await _client
        .from('users')
        .select('''
          *,
          user_roles(role, is_primary, tenant_id)
        ''')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return AppUser.fromJson(response);
  }

  /// Create user profile in database
  Future<void> createUserProfile({
    required String userId,
    required String email,
    String? fullName,
    String? tenantId,
  }) async {
    await _client.from('users').insert({
      'id': userId,
      'email': email,
      'full_name': fullName,
      'tenant_id': tenantId,
    });
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    await _client.from('users').update({
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  /// Get user's tenants (schools)
  Future<List<Map<String, dynamic>>> getUserTenants(String userId) async {
    final response = await _client
        .from('user_roles')
        .select('tenant:tenants(id, name, slug, logo_url)')
        .eq('user_id', userId);

    return (response as List)
        .map((r) => r['tenant'] as Map<String, dynamic>)
        .toSet()
        .toList();
  }

  /// Set current tenant in session
  Future<void> setCurrentTenant(String tenantId) async {
    // Store in app metadata
    await _client.auth.updateUser(
      UserAttributes(
        data: {'current_tenant_id': tenantId},
      ),
    );
  }
}

/// Auth notifier for managing auth state
class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final user = _repository.currentUser;
    if (user != null) {
      await _loadUserProfile(user.id);
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      developer.log('_loadUserProfile: START - fetching profile for userId=$userId', name: 'AuthNotifier');
      final profile = await _repository.getUserProfile(userId);
      developer.log('_loadUserProfile: Raw profile response = $profile', name: 'AuthNotifier');

      if (profile == null) {
        developer.log('_loadUserProfile: ERROR - profile is NULL for userId=$userId', name: 'AuthNotifier', level: 900);
        state = AsyncValue.error('User profile not found', StackTrace.current);
        return;
      }

      developer.log('_loadUserProfile: profile.id = ${profile.id}', name: 'AuthNotifier');
      developer.log('_loadUserProfile: profile.email = ${profile.email}', name: 'AuthNotifier');
      developer.log('_loadUserProfile: profile.tenantId = ${profile.tenantId}', name: 'AuthNotifier');
      developer.log('_loadUserProfile: profile.primaryRole = ${profile.primaryRole}', name: 'AuthNotifier');
      developer.log('_loadUserProfile: profile.roles = ${profile.roles}', name: 'AuthNotifier');

      state = AsyncValue.data(profile);
      _ref.read(currentUserProvider.notifier).state = profile;

      if (profile.tenantId != null) {
        _ref.read(currentTenantIdProvider.notifier).state = profile.tenantId;
      }

      developer.log('_loadUserProfile: SUCCESS - profile loaded and set', name: 'AuthNotifier');
    } catch (e, st) {
      developer.log('_loadUserProfile: ERROR - $e', name: 'AuthNotifier', error: e, stackTrace: st);
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.signInWithEmail(
        email: email,
        password: password,
      );
      if (response.user != null) {
        await _loadUserProfile(response.user!.id);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );
      if (response.user != null) {
        await _repository.createUserProfile(
          userId: response.user!.id,
          email: email,
          fullName: fullName,
        );
        await _loadUserProfile(response.user!.id);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncValue.data(null);
    _ref.read(currentUserProvider.notifier).state = null;
    _ref.read(currentTenantIdProvider.notifier).state = null;
  }

  Future<void> refreshProfile() async {
    final user = _repository.currentUser;
    if (user != null) {
      await _loadUserProfile(user.id);
    }
  }
}

/// Auth notifier provider
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref,
  );
});
