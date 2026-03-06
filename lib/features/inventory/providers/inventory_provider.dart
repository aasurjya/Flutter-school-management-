import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/inventory.dart';
import '../../../data/repositories/inventory_repository.dart';

// ==================== REPOSITORY ====================

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(ref.watch(supabaseProvider));
});

// ==================== CATEGORIES ====================

final assetCategoriesProvider =
    FutureProvider<List<AssetCategory>>((ref) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getCategories();
});

final flatCategoriesProvider =
    FutureProvider<List<AssetCategory>>((ref) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getFlatCategories();
});

// ==================== ASSETS ====================

final assetsProvider =
    FutureProvider.family<List<Asset>, AssetFilter>((ref, filter) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getAssets(
    categoryId: filter.categoryId,
    status: filter.status,
    location: filter.location,
    searchQuery: filter.searchQuery,
  );
});

final assetByIdProvider =
    FutureProvider.family<Asset?, String>((ref, id) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getAssetById(id);
});

final assetByQrProvider =
    FutureProvider.family<Asset?, String>((ref, qrData) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getAssetByQrCode(qrData);
});

final assetLocationsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getAssetLocations();
});

// ==================== ASSIGNMENTS ====================

final assetAssignmentHistoryProvider =
    FutureProvider.family<List<AssetAssignment>, String>(
        (ref, assetId) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getAssignmentHistory(assetId);
});

final activeAssignmentsProvider =
    FutureProvider<List<AssetAssignment>>((ref) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getActiveAssignments();
});

// ==================== MAINTENANCE ====================

final maintenanceRecordsProvider =
    FutureProvider.family<List<AssetMaintenance>, MaintenanceFilter>(
        (ref, filter) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getMaintenanceRecords(
    assetId: filter.assetId,
    status: filter.status,
  );
});

final maintenanceDueProvider =
    FutureProvider<List<AssetMaintenance>>((ref) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getMaintenanceDue();
});

// ==================== INVENTORY ITEMS ====================

final inventoryItemsProvider =
    FutureProvider.family<List<InventoryItem>, InventoryFilter>(
        (ref, filter) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getInventoryItems(
    categoryId: filter.categoryId,
    lowStockOnly: filter.lowStockOnly,
    searchQuery: filter.searchQuery,
  );
});

final inventoryItemByIdProvider =
    FutureProvider.family<InventoryItem?, String>((ref, id) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getInventoryItemById(id);
});

final lowStockItemsProvider =
    FutureProvider<List<InventoryItem>>((ref) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getLowStockItems();
});

// ==================== TRANSACTIONS ====================

final transactionHistoryProvider = FutureProvider.family<
    List<InventoryTransaction>, TransactionFilter>((ref, filter) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getTransactionHistory(
    itemId: filter.itemId,
    transactionType: filter.transactionType,
    startDate: filter.startDate,
    endDate: filter.endDate,
  );
});

// ==================== PURCHASE REQUESTS ====================

final purchaseRequestsProvider =
    FutureProvider.family<List<PurchaseRequest>, String?>(
        (ref, status) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getPurchaseRequests(status: status);
});

final purchaseRequestByIdProvider =
    FutureProvider.family<PurchaseRequest?, String>((ref, id) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getPurchaseRequestById(id);
});

// ==================== AUDITS ====================

final assetAuditsProvider = FutureProvider<List<AssetAudit>>((ref) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getAudits();
});

// ==================== STATISTICS ====================

final inventoryStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getInventoryStats();
});

final assetDepreciationProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, assetId) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getAssetDepreciation(assetId);
});

// ==================== FILTER CLASSES ====================

class AssetFilter {
  final String? categoryId;
  final String? status;
  final String? location;
  final String? searchQuery;

  const AssetFilter({
    this.categoryId,
    this.status,
    this.location,
    this.searchQuery,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AssetFilter &&
        other.categoryId == categoryId &&
        other.status == status &&
        other.location == location &&
        other.searchQuery == searchQuery;
  }

  @override
  int get hashCode =>
      Object.hash(categoryId, status, location, searchQuery);
}

class MaintenanceFilter {
  final String? assetId;
  final String? status;

  const MaintenanceFilter({this.assetId, this.status});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MaintenanceFilter &&
        other.assetId == assetId &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(assetId, status);
}

class InventoryFilter {
  final String? categoryId;
  final bool? lowStockOnly;
  final String? searchQuery;

  const InventoryFilter({
    this.categoryId,
    this.lowStockOnly,
    this.searchQuery,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryFilter &&
        other.categoryId == categoryId &&
        other.lowStockOnly == lowStockOnly &&
        other.searchQuery == searchQuery;
  }

  @override
  int get hashCode =>
      Object.hash(categoryId, lowStockOnly, searchQuery);
}

class TransactionFilter {
  final String? itemId;
  final String? transactionType;
  final DateTime? startDate;
  final DateTime? endDate;

  const TransactionFilter({
    this.itemId,
    this.transactionType,
    this.startDate,
    this.endDate,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionFilter &&
        other.itemId == itemId &&
        other.transactionType == transactionType &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode =>
      Object.hash(itemId, transactionType, startDate, endDate);
}
