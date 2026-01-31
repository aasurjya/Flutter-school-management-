import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/tenant.dart';
import '../../../data/repositories/tenant_repository.dart';

/// Tenant repository provider
final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  return TenantRepository(Supabase.instance.client);
});

/// All tenants provider
final tenantsProvider = FutureProvider.family<List<Tenant>, TenantsFilter>(
  (ref, filter) async {
    final repository = ref.watch(tenantRepositoryProvider);
    return repository.getAllTenants(
      status: filter.status,
      searchQuery: filter.searchQuery,
    );
  },
);

/// Single tenant provider
final tenantByIdProvider = FutureProvider.family<Tenant?, String>(
  (ref, tenantId) async {
    final repository = ref.watch(tenantRepositoryProvider);
    return repository.getTenantById(tenantId);
  },
);

/// Tenant statistics provider
final tenantStatsProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, tenantId) async {
    final repository = ref.watch(tenantRepositoryProvider);
    return repository.getTenantStats(tenantId);
  },
);

/// Platform statistics provider (Super Admin)
final platformStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(tenantRepositoryProvider);
  return repository.getPlatformStats();
});

/// Tenants filter
class TenantsFilter {
  final String? status;
  final String? searchQuery;

  const TenantsFilter({
    this.status,
    this.searchQuery,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TenantsFilter &&
        other.status == status &&
        other.searchQuery == searchQuery;
  }

  @override
  int get hashCode => Object.hash(status, searchQuery);
}

/// Tenants state notifier for CRUD operations
class TenantsNotifier extends StateNotifier<AsyncValue<List<Tenant>>> {
  final TenantRepository _repository;
  final Ref _ref;

  TenantsNotifier(this._repository, this._ref) : super(const AsyncValue.loading());

  Future<void> loadTenants({String? status, String? searchQuery}) async {
    state = const AsyncValue.loading();
    try {
      final tenants = await _repository.getAllTenants(
        status: status,
        searchQuery: searchQuery,
      );
      state = AsyncValue.data(tenants);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Tenant> createTenant(Map<String, dynamic> data) async {
    final tenant = await _repository.createTenant(data);
    await loadTenants();
    return tenant;
  }

  Future<Tenant> updateTenant(String tenantId, Map<String, dynamic> data) async {
    final tenant = await _repository.updateTenant(tenantId, data);
    await loadTenants();
    return tenant;
  }

  Future<void> suspendTenant(String tenantId) async {
    await _repository.suspendTenant(tenantId);
    await loadTenants();
  }

  Future<void> activateTenant(String tenantId) async {
    await _repository.activateTenant(tenantId);
    await loadTenants();
  }

  Future<void> deleteTenant(String tenantId) async {
    await _repository.deleteTenant(tenantId);
    await loadTenants();
  }
}

/// Tenants notifier provider
final tenantsNotifierProvider =
    StateNotifierProvider<TenantsNotifier, AsyncValue<List<Tenant>>>((ref) {
  final repository = ref.watch(tenantRepositoryProvider);
  return TenantsNotifier(repository, ref);
});
