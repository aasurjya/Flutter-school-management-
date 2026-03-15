import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/tenant.dart';
import '../../../data/repositories/tenant_repository.dart';
import '../../auth/providers/auth_provider.dart';

/// Provider for the current user's tenant (school) data.
/// Used by ID cards to show school name, logo, and contact info.
final currentTenantProvider = FutureProvider<Tenant?>((ref) async {
  final tenantId = ref.watch(currentTenantIdProvider);
  if (tenantId == null) return null;

  final client = ref.watch(supabaseProvider);
  final repo = TenantRepository(client);
  return repo.getTenantById(tenantId);
});

/// Provider to fetch staff record for the current user.
/// Returns employee_id, designation, department, join_date.
final currentStaffRecordProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final client = ref.watch(supabaseProvider);
  final response = await client
      .from('staff')
      .select('id, employee_id, designation, department, date_of_joining')
      .eq('user_id', user.id)
      .maybeSingle();

  return response;
});

/// Provider to fetch a specific staff member's record by user ID.
final staffRecordByUserIdProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  final client = ref.watch(supabaseProvider);
  final response = await client
      .from('staff')
      .select('id, employee_id, designation, department, date_of_joining')
      .eq('user_id', userId)
      .maybeSingle();

  return response;
});
