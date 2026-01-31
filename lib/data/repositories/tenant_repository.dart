import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tenant.dart';
import 'base_repository.dart';

class TenantRepository extends BaseRepository {
  TenantRepository(super.client);

  /// Get all tenants (Super Admin only)
  Future<List<Tenant>> getAllTenants({
    String? status,
    String? searchQuery,
  }) async {
    var query = client.from('tenants').select('*');

    if (status != null && status != 'all') {
      if (status == 'active') {
        query = query.eq('is_active', true);
      } else if (status == 'suspended') {
        query = query.eq('is_active', false);
      }
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or('name.ilike.%$searchQuery%,slug.ilike.%$searchQuery%,email.ilike.%$searchQuery%');
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((json) => Tenant.fromJson(json)).toList();
  }

  /// Get tenant by ID
  Future<Tenant?> getTenantById(String tenantId) async {
    final response = await client
        .from('tenants')
        .select('*')
        .eq('id', tenantId)
        .maybeSingle();

    if (response == null) return null;
    return Tenant.fromJson(response);
  }

  /// Create a new tenant
  Future<Tenant> createTenant(Map<String, dynamic> data) async {
    final response = await client
        .from('tenants')
        .insert(data)
        .select()
        .single();

    return Tenant.fromJson(response);
  }

  /// Update tenant
  Future<Tenant> updateTenant(String tenantId, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();

    final response = await client
        .from('tenants')
        .update(data)
        .eq('id', tenantId)
        .select()
        .single();

    return Tenant.fromJson(response);
  }

  /// Suspend tenant
  Future<void> suspendTenant(String tenantId) async {
    await client.from('tenants').update({
      'is_active': false,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', tenantId);
  }

  /// Activate tenant
  Future<void> activateTenant(String tenantId) async {
    await client.from('tenants').update({
      'is_active': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', tenantId);
  }

  /// Delete tenant (soft delete by deactivating)
  Future<void> deleteTenant(String tenantId) async {
    await client.from('tenants').delete().eq('id', tenantId);
  }

  /// Get tenant statistics
  Future<Map<String, dynamic>> getTenantStats(String tenantId) async {
    // Count students
    final studentsCount = await client
        .from('students')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('is_active', true);

    // Count teachers
    final teachersCount = await client
        .from('user_roles')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('role', 'teacher');

    // Count parents
    final parentsCount = await client
        .from('user_roles')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('role', 'parent');

    // Count admins
    final adminsCount = await client
        .from('user_roles')
        .select('id')
        .eq('tenant_id', tenantId)
        .inFilter('role', ['tenant_admin', 'principal']);

    return {
      'students': (studentsCount as List).length,
      'teachers': (teachersCount as List).length,
      'parents': (parentsCount as List).length,
      'admins': (adminsCount as List).length,
    };
  }

  /// Get platform-wide statistics (Super Admin)
  Future<Map<String, dynamic>> getPlatformStats() async {
    final tenantsResponse = await client.from('tenants').select('id, is_active');
    final tenants = tenantsResponse as List;

    final activeCount = tenants.where((t) => t['is_active'] == true).length;
    final totalCount = tenants.length;

    // Get total users across all tenants
    final usersCount = await client.from('users').select('id');

    return {
      'total_tenants': totalCount,
      'active_tenants': activeCount,
      'suspended_tenants': totalCount - activeCount,
      'total_users': (usersCount as List).length,
    };
  }

  /// Create tenant admin user
  Future<void> createTenantAdmin({
    required String tenantId,
    required String email,
    required String fullName,
    String? phone,
  }) async {
    // This would typically be done via an Edge Function or Admin API
    // For now, we'll use the RPC function if available
    await client.rpc('create_tenant_admin', params: {
      'p_tenant_id': tenantId,
      'p_email': email,
      'p_full_name': fullName,
      'p_phone': phone,
    });
  }
}
