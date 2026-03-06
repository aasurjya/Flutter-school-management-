import '../models/inventory.dart';
import 'base_repository.dart';

class InventoryRepository extends BaseRepository {
  InventoryRepository(super.client);

  // ==================== CATEGORIES ====================

  Future<List<AssetCategory>> getCategories({bool activeOnly = true}) async {
    var query = client
        .from('inv_asset_categories')
        .select()
        .eq('tenant_id', requireTenantId);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final response = await query.order('name');
    final flat = (response as List)
        .map((json) => AssetCategory.fromJson(json))
        .toList();

    return _buildCategoryTree(flat);
  }

  List<AssetCategory> _buildCategoryTree(List<AssetCategory> flat) {
    final Map<String, List<AssetCategory>> childrenMap = {};
    final List<AssetCategory> roots = [];

    for (final cat in flat) {
      if (cat.parentCategoryId != null) {
        childrenMap.putIfAbsent(cat.parentCategoryId!, () => []);
        childrenMap[cat.parentCategoryId!]!.add(cat);
      }
    }

    for (final cat in flat) {
      if (cat.parentCategoryId == null) {
        roots.add(cat.copyWith(
          children: _getChildrenRecursive(cat.id, childrenMap, flat),
        ));
      }
    }

    return roots;
  }

  List<AssetCategory> _getChildrenRecursive(
    String parentId,
    Map<String, List<AssetCategory>> childrenMap,
    List<AssetCategory> flat,
  ) {
    final children = childrenMap[parentId] ?? [];
    return children.map((child) {
      return child.copyWith(
        children: _getChildrenRecursive(child.id, childrenMap, flat),
      );
    }).toList();
  }

  Future<List<AssetCategory>> getFlatCategories({bool activeOnly = true}) async {
    var query = client
        .from('inv_asset_categories')
        .select()
        .eq('tenant_id', requireTenantId);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final response = await query.order('name');
    return (response as List)
        .map((json) => AssetCategory.fromJson(json))
        .toList();
  }

  Future<AssetCategory> createCategory(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;
    final response = await client
        .from('inv_asset_categories')
        .insert(data)
        .select()
        .single();
    return AssetCategory.fromJson(response);
  }

  Future<AssetCategory> updateCategory(
      String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    final response = await client
        .from('inv_asset_categories')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return AssetCategory.fromJson(response);
  }

  Future<void> deleteCategory(String id) async {
    await client.from('inv_asset_categories').delete().eq('id', id);
  }

  // ==================== ASSETS ====================

  Future<List<Asset>> getAssets({
    String? categoryId,
    String? status,
    String? location,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('inv_assets')
        .select('''
          *,
          inv_asset_categories(*),
          users(full_name)
        ''')
        .eq('tenant_id', requireTenantId);

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }

    if (status != null) {
      query = query.eq('status', status);
    }

    if (location != null) {
      query = query.eq('location', location);
    }

    final response =
        await query.order('name').range(offset, offset + limit - 1);

    var assets =
        (response as List).map((json) => Asset.fromJson(json)).toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchLower = searchQuery.toLowerCase();
      assets = assets.where((asset) {
        return asset.name.toLowerCase().contains(searchLower) ||
            asset.assetCode.toLowerCase().contains(searchLower) ||
            (asset.serialNumber?.toLowerCase().contains(searchLower) ?? false) ||
            (asset.location?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }

    return assets;
  }

  Future<Asset?> getAssetById(String id) async {
    final response = await client
        .from('inv_assets')
        .select('''
          *,
          inv_asset_categories(*),
          users(full_name)
        ''')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Asset.fromJson(response);
  }

  Future<Asset?> getAssetByQrCode(String qrCodeData) async {
    final response = await client
        .from('inv_assets')
        .select('''
          *,
          inv_asset_categories(*),
          users(full_name)
        ''')
        .eq('tenant_id', requireTenantId)
        .eq('qr_code_data', qrCodeData)
        .maybeSingle();

    if (response == null) return null;
    return Asset.fromJson(response);
  }

  Future<Asset?> getAssetByCode(String assetCode) async {
    final response = await client
        .from('inv_assets')
        .select('''
          *,
          inv_asset_categories(*),
          users(full_name)
        ''')
        .eq('tenant_id', requireTenantId)
        .eq('asset_code', assetCode)
        .maybeSingle();

    if (response == null) return null;
    return Asset.fromJson(response);
  }

  Future<Asset> createAsset(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;
    // Auto-generate QR code data if not provided
    if (data['qr_code_data'] == null || data['qr_code_data'] == '') {
      data['qr_code_data'] =
          'ASSET:$requireTenantId:${data['asset_code']}';
    }
    final response = await client
        .from('inv_assets')
        .insert(data)
        .select('''
          *,
          inv_asset_categories(*),
          users(full_name)
        ''')
        .single();
    return Asset.fromJson(response);
  }

  Future<Asset> updateAsset(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    final response = await client
        .from('inv_assets')
        .update(data)
        .eq('id', id)
        .select('''
          *,
          inv_asset_categories(*),
          users(full_name)
        ''')
        .single();
    return Asset.fromJson(response);
  }

  Future<void> deleteAsset(String id) async {
    await client.from('inv_assets').delete().eq('id', id);
  }

  Future<List<String>> getAssetLocations() async {
    final response = await client
        .from('inv_assets')
        .select('location')
        .eq('tenant_id', requireTenantId)
        .not('location', 'is', null)
        .order('location');

    final locations = <String>{};
    for (final item in response as List) {
      if (item['location'] != null) {
        locations.add(item['location'] as String);
      }
    }
    return locations.toList();
  }

  // ==================== ASSET ASSIGNMENTS ====================

  Future<AssetAssignment> assignAsset({
    required String assetId,
    required String assignedTo,
    DateTime? expectedReturnDate,
    AssetCondition condition = AssetCondition.good,
    String? notes,
  }) async {
    // Create assignment record
    final assignmentResponse = await client
        .from('inv_asset_assignments')
        .insert({
          'asset_id': assetId,
          'assigned_to': assignedTo,
          'assigned_by': requireUserId,
          'expected_return_date':
              expectedReturnDate?.toIso8601String().split('T')[0],
          'condition_at_assign': condition.value,
          'notes': notes,
          'status': 'active',
        })
        .select()
        .single();

    // Update asset status
    await client.from('inv_assets').update({
      'status': AssetStatus.inUse.value,
      'assigned_to': assignedTo,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', assetId);

    return AssetAssignment.fromJson(assignmentResponse);
  }

  Future<AssetAssignment> returnAsset({
    required String assignmentId,
    AssetCondition returnCondition = AssetCondition.good,
    String? notes,
  }) async {
    // Get assignment details
    final assignment = await client
        .from('inv_asset_assignments')
        .select()
        .eq('id', assignmentId)
        .single();

    // Update assignment
    final response = await client
        .from('inv_asset_assignments')
        .update({
          'return_date': DateTime.now().toIso8601String().split('T')[0],
          'condition_at_return': returnCondition.value,
          'notes': notes ?? assignment['notes'],
          'status': 'returned',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', assignmentId)
        .select()
        .single();

    // Update asset - determine status based on return condition
    final newStatus = returnCondition == AssetCondition.poor
        ? AssetStatus.damaged.value
        : AssetStatus.available.value;

    await client.from('inv_assets').update({
      'status': newStatus,
      'assigned_to': null,
      'condition': returnCondition.value,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', assignment['asset_id']);

    return AssetAssignment.fromJson(response);
  }

  Future<List<AssetAssignment>> getAssignmentHistory(String assetId) async {
    final response = await client
        .from('inv_asset_assignments')
        .select()
        .eq('asset_id', assetId)
        .order('assigned_date', ascending: false);

    return (response as List)
        .map((json) => AssetAssignment.fromJson(json))
        .toList();
  }

  Future<List<AssetAssignment>> getActiveAssignments() async {
    final response = await client
        .from('inv_asset_assignments')
        .select('''
          *,
          inv_assets!inner(*, tenant_id)
        ''')
        .eq('inv_assets.tenant_id', requireTenantId)
        .eq('status', 'active')
        .order('assigned_date', ascending: false);

    return (response as List)
        .map((json) => AssetAssignment.fromJson(json))
        .toList();
  }

  // ==================== MAINTENANCE ====================

  Future<List<AssetMaintenance>> getMaintenanceRecords({
    String? assetId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('inv_asset_maintenance')
        .select('''
          *,
          inv_assets!inner(*, tenant_id, name, asset_code)
        ''')
        .eq('inv_assets.tenant_id', requireTenantId);

    if (assetId != null) {
      query = query.eq('asset_id', assetId);
    }

    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query
        .order('scheduled_date', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => AssetMaintenance.fromJson(json))
        .toList();
  }

  Future<List<AssetMaintenance>> getMaintenanceDue() async {
    final response = await client
        .from('inv_asset_maintenance')
        .select('''
          *,
          inv_assets!inner(*, tenant_id, name, asset_code)
        ''')
        .eq('inv_assets.tenant_id', requireTenantId)
        .inFilter('status', ['scheduled', 'in_progress'])
        .order('scheduled_date');

    return (response as List)
        .map((json) => AssetMaintenance.fromJson(json))
        .toList();
  }

  Future<AssetMaintenance> createMaintenance(
      Map<String, dynamic> data) async {
    final response = await client
        .from('inv_asset_maintenance')
        .insert(data)
        .select()
        .single();

    // Optionally update asset status to maintenance
    if (data['status'] == 'in_progress') {
      await client.from('inv_assets').update({
        'status': AssetStatus.maintenance.value,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', data['asset_id']);
    }

    return AssetMaintenance.fromJson(response);
  }

  Future<AssetMaintenance> updateMaintenance(
      String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    final response = await client
        .from('inv_asset_maintenance')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    // If completed, restore asset status
    if (data['status'] == 'completed') {
      final maintenance = AssetMaintenance.fromJson(response);
      await client.from('inv_assets').update({
        'status': AssetStatus.available.value,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', maintenance.assetId);
    }

    return AssetMaintenance.fromJson(response);
  }

  Future<void> deleteMaintenance(String id) async {
    await client.from('inv_asset_maintenance').delete().eq('id', id);
  }

  // ==================== INVENTORY ITEMS ====================

  Future<List<InventoryItem>> getInventoryItems({
    String? categoryId,
    bool? lowStockOnly,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('inv_inventory_items')
        .select('''
          *,
          inv_asset_categories(*)
        ''')
        .eq('tenant_id', requireTenantId)
        .eq('is_active', true);

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }

    final response =
        await query.order('name').range(offset, offset + limit - 1);

    var items = (response as List)
        .map((json) => InventoryItem.fromJson(json))
        .toList();

    if (lowStockOnly == true) {
      items = items.where((item) => item.isLowStock).toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchLower = searchQuery.toLowerCase();
      items = items.where((item) {
        return item.name.toLowerCase().contains(searchLower) ||
            item.itemCode.toLowerCase().contains(searchLower);
      }).toList();
    }

    return items;
  }

  Future<InventoryItem?> getInventoryItemById(String id) async {
    final response = await client
        .from('inv_inventory_items')
        .select('''
          *,
          inv_asset_categories(*)
        ''')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return InventoryItem.fromJson(response);
  }

  Future<List<InventoryItem>> getLowStockItems() async {
    final response = await client
        .from('inv_inventory_items')
        .select('''
          *,
          inv_asset_categories(*)
        ''')
        .eq('tenant_id', requireTenantId)
        .eq('is_active', true)
        .order('current_stock');

    return (response as List)
        .map((json) => InventoryItem.fromJson(json))
        .where((item) => item.isLowStock)
        .toList();
  }

  Future<InventoryItem> createInventoryItem(
      Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;
    final response = await client
        .from('inv_inventory_items')
        .insert(data)
        .select('''
          *,
          inv_asset_categories(*)
        ''')
        .single();
    return InventoryItem.fromJson(response);
  }

  Future<InventoryItem> updateInventoryItem(
      String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    final response = await client
        .from('inv_inventory_items')
        .update(data)
        .eq('id', id)
        .select('''
          *,
          inv_asset_categories(*)
        ''')
        .single();
    return InventoryItem.fromJson(response);
  }

  Future<void> deleteInventoryItem(String id) async {
    await client.from('inv_inventory_items').delete().eq('id', id);
  }

  // ==================== INVENTORY TRANSACTIONS ====================

  Future<InventoryTransaction> recordTransaction(
      Map<String, dynamic> data) async {
    data['issued_by'] = currentUserId;
    final response = await client
        .from('inv_inventory_transactions')
        .insert(data)
        .select()
        .single();
    return InventoryTransaction.fromJson(response);
  }

  Future<List<InventoryTransaction>> getTransactionHistory({
    String? itemId,
    String? transactionType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client.from('inv_inventory_transactions').select('''
          *,
          inv_inventory_items!inner(*, tenant_id)
        ''').eq('inv_inventory_items.tenant_id', requireTenantId);

    if (itemId != null) {
      query = query.eq('item_id', itemId);
    }

    if (transactionType != null) {
      query = query.eq('transaction_type', transactionType);
    }

    if (startDate != null) {
      query = query.gte(
          'transaction_date', startDate.toIso8601String().split('T')[0]);
    }

    if (endDate != null) {
      query = query.lte(
          'transaction_date', endDate.toIso8601String().split('T')[0]);
    }

    final response = await query
        .order('transaction_date', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => InventoryTransaction.fromJson(json))
        .toList();
  }

  // ==================== PURCHASE REQUESTS ====================

  Future<List<PurchaseRequest>> getPurchaseRequests({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('inv_purchase_requests')
        .select('''
          *,
          requester:requested_by(full_name),
          approver:approved_by(full_name)
        ''')
        .eq('tenant_id', requireTenantId);

    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => PurchaseRequest.fromJson(json))
        .toList();
  }

  Future<PurchaseRequest?> getPurchaseRequestById(String id) async {
    final response = await client
        .from('inv_purchase_requests')
        .select('''
          *,
          requester:requested_by(full_name),
          approver:approved_by(full_name)
        ''')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return PurchaseRequest.fromJson(response);
  }

  Future<PurchaseRequest> createPurchaseRequest(
      Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;
    data['requested_by'] = requireUserId;

    // Auto-generate request number
    if (data['request_number'] == null || data['request_number'] == '') {
      final now = DateTime.now();
      data['request_number'] =
          'PR-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch % 10000}';
    }

    final response = await client
        .from('inv_purchase_requests')
        .insert(data)
        .select('''
          *,
          requester:requested_by(full_name),
          approver:approved_by(full_name)
        ''')
        .single();
    return PurchaseRequest.fromJson(response);
  }

  Future<PurchaseRequest> updatePurchaseRequest(
      String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();

    // If approving, set approved_by and approved_at
    if (data['status'] == 'approved') {
      data['approved_by'] = requireUserId;
      data['approved_at'] = DateTime.now().toIso8601String();
    }

    final response = await client
        .from('inv_purchase_requests')
        .update(data)
        .eq('id', id)
        .select('''
          *,
          requester:requested_by(full_name),
          approver:approved_by(full_name)
        ''')
        .single();
    return PurchaseRequest.fromJson(response);
  }

  Future<void> deletePurchaseRequest(String id) async {
    await client.from('inv_purchase_requests').delete().eq('id', id);
  }

  // ==================== ASSET AUDITS ====================

  Future<List<AssetAudit>> getAudits({
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await client
        .from('inv_asset_audits')
        .select('''
          *,
          conductor:conducted_by(full_name)
        ''')
        .eq('tenant_id', requireTenantId)
        .order('audit_date', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => AssetAudit.fromJson(json))
        .toList();
  }

  Future<AssetAudit> createAudit(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;
    data['conducted_by'] = requireUserId;

    // Get total asset count
    final countResponse = await client
        .from('inv_assets')
        .select('id')
        .eq('tenant_id', requireTenantId)
        .neq('status', 'disposed');
    data['total_assets'] = (countResponse as List).length;

    final response = await client
        .from('inv_asset_audits')
        .insert(data)
        .select('''
          *,
          conductor:conducted_by(full_name)
        ''')
        .single();
    return AssetAudit.fromJson(response);
  }

  Future<AssetAudit> updateAudit(
      String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    final response = await client
        .from('inv_asset_audits')
        .update(data)
        .eq('id', id)
        .select('''
          *,
          conductor:conducted_by(full_name)
        ''')
        .single();
    return AssetAudit.fromJson(response);
  }

  Future<void> deleteAudit(String id) async {
    await client.from('inv_asset_audits').delete().eq('id', id);
  }

  // ==================== STATISTICS ====================

  Future<Map<String, dynamic>> getInventoryStats() async {
    // Asset counts by status
    final assetsResponse = await client
        .from('inv_assets')
        .select('status, purchase_price, current_value')
        .eq('tenant_id', requireTenantId);

    final assets = assetsResponse as List;
    final statusCounts = <String, int>{};
    double totalPurchaseValue = 0;
    double totalCurrentValue = 0;

    for (final asset in assets) {
      final status = asset['status'] as String;
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      totalPurchaseValue += (asset['purchase_price'] as num?)?.toDouble() ?? 0;
      totalCurrentValue += (asset['current_value'] as num?)?.toDouble() ?? 0;
    }

    // Low stock items count
    final lowStockItems = await getLowStockItems();

    // Pending maintenance
    final maintenanceDue = await getMaintenanceDue();

    // Inventory items total value
    final itemsResponse = await client
        .from('inv_inventory_items')
        .select('current_stock, unit_cost')
        .eq('tenant_id', requireTenantId)
        .eq('is_active', true);

    double totalInventoryValue = 0;
    for (final item in itemsResponse as List) {
      totalInventoryValue +=
          (item['current_stock'] as num? ?? 0).toDouble() *
              ((item['unit_cost'] as num?)?.toDouble() ?? 0);
    }

    return {
      'total_assets': assets.length,
      'status_counts': statusCounts,
      'total_purchase_value': totalPurchaseValue,
      'total_current_value': totalCurrentValue,
      'depreciation_total': totalPurchaseValue - totalCurrentValue,
      'low_stock_items': lowStockItems.length,
      'pending_maintenance': maintenanceDue.length,
      'total_inventory_value': totalInventoryValue,
      'maintenance_due': maintenanceDue.take(5).toList(),
      'low_stock_list': lowStockItems.take(5).toList(),
    };
  }

  Future<List<Map<String, dynamic>>> getAssetDepreciation(
      String assetId) async {
    final asset = await getAssetById(assetId);
    if (asset == null || asset.purchasePrice == null || asset.purchaseDate == null) {
      return [];
    }

    // Calculate yearly depreciation based on category rate
    double rate = 10; // default 10% per year
    if (asset.category != null) {
      rate = asset.category!.depreciationRate;
    }

    final List<Map<String, dynamic>> depreciationSchedule = [];
    double currentValue = asset.purchasePrice!;
    final startYear = asset.purchaseDate!.year;
    final currentYear = DateTime.now().year;

    for (int year = startYear; year <= currentYear + 2; year++) {
      depreciationSchedule.add({
        'year': year,
        'value': currentValue,
        'depreciation': currentValue * (rate / 100),
      });
      currentValue -= currentValue * (rate / 100);
      if (currentValue < 0) currentValue = 0;
    }

    return depreciationSchedule;
  }
}
