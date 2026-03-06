// Inventory & Asset Management models

// ==================== ENUMS ====================

enum AssetStatus {
  available,
  inUse,
  maintenance,
  damaged,
  disposed,
  lost;

  String get value {
    switch (this) {
      case AssetStatus.available:
        return 'available';
      case AssetStatus.inUse:
        return 'in_use';
      case AssetStatus.maintenance:
        return 'maintenance';
      case AssetStatus.damaged:
        return 'damaged';
      case AssetStatus.disposed:
        return 'disposed';
      case AssetStatus.lost:
        return 'lost';
    }
  }

  static AssetStatus fromString(String value) {
    switch (value) {
      case 'available':
        return AssetStatus.available;
      case 'in_use':
        return AssetStatus.inUse;
      case 'maintenance':
        return AssetStatus.maintenance;
      case 'damaged':
        return AssetStatus.damaged;
      case 'disposed':
        return AssetStatus.disposed;
      case 'lost':
        return AssetStatus.lost;
      default:
        return AssetStatus.available;
    }
  }

  String get label {
    switch (this) {
      case AssetStatus.available:
        return 'Available';
      case AssetStatus.inUse:
        return 'In Use';
      case AssetStatus.maintenance:
        return 'Maintenance';
      case AssetStatus.damaged:
        return 'Damaged';
      case AssetStatus.disposed:
        return 'Disposed';
      case AssetStatus.lost:
        return 'Lost';
    }
  }
}

enum AssetCondition {
  excellent,
  good,
  fair,
  poor;

  String get value => name;

  static AssetCondition fromString(String value) {
    switch (value) {
      case 'excellent':
        return AssetCondition.excellent;
      case 'good':
        return AssetCondition.good;
      case 'fair':
        return AssetCondition.fair;
      case 'poor':
        return AssetCondition.poor;
      default:
        return AssetCondition.good;
    }
  }

  String get label {
    switch (this) {
      case AssetCondition.excellent:
        return 'Excellent';
      case AssetCondition.good:
        return 'Good';
      case AssetCondition.fair:
        return 'Fair';
      case AssetCondition.poor:
        return 'Poor';
    }
  }
}

enum AssignmentStatus {
  active,
  returned,
  overdue;

  String get value => name;

  static AssignmentStatus fromString(String value) {
    switch (value) {
      case 'active':
        return AssignmentStatus.active;
      case 'returned':
        return AssignmentStatus.returned;
      case 'overdue':
        return AssignmentStatus.overdue;
      default:
        return AssignmentStatus.active;
    }
  }

  String get label {
    switch (this) {
      case AssignmentStatus.active:
        return 'Active';
      case AssignmentStatus.returned:
        return 'Returned';
      case AssignmentStatus.overdue:
        return 'Overdue';
    }
  }
}

enum MaintenanceType {
  preventive,
  corrective,
  emergency;

  String get value => name;

  static MaintenanceType fromString(String value) {
    switch (value) {
      case 'preventive':
        return MaintenanceType.preventive;
      case 'corrective':
        return MaintenanceType.corrective;
      case 'emergency':
        return MaintenanceType.emergency;
      default:
        return MaintenanceType.corrective;
    }
  }

  String get label {
    switch (this) {
      case MaintenanceType.preventive:
        return 'Preventive';
      case MaintenanceType.corrective:
        return 'Corrective';
      case MaintenanceType.emergency:
        return 'Emergency';
    }
  }
}

enum MaintenanceStatus {
  scheduled,
  inProgress,
  completed,
  cancelled;

  String get value {
    switch (this) {
      case MaintenanceStatus.scheduled:
        return 'scheduled';
      case MaintenanceStatus.inProgress:
        return 'in_progress';
      case MaintenanceStatus.completed:
        return 'completed';
      case MaintenanceStatus.cancelled:
        return 'cancelled';
    }
  }

  static MaintenanceStatus fromString(String value) {
    switch (value) {
      case 'scheduled':
        return MaintenanceStatus.scheduled;
      case 'in_progress':
        return MaintenanceStatus.inProgress;
      case 'completed':
        return MaintenanceStatus.completed;
      case 'cancelled':
        return MaintenanceStatus.cancelled;
      default:
        return MaintenanceStatus.scheduled;
    }
  }

  String get label {
    switch (this) {
      case MaintenanceStatus.scheduled:
        return 'Scheduled';
      case MaintenanceStatus.inProgress:
        return 'In Progress';
      case MaintenanceStatus.completed:
        return 'Completed';
      case MaintenanceStatus.cancelled:
        return 'Cancelled';
    }
  }
}

enum InventoryUnit {
  pieces,
  boxes,
  kg,
  liters,
  reams,
  sets,
  pairs,
  packets;

  String get value => name;

  static InventoryUnit fromString(String value) {
    return InventoryUnit.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InventoryUnit.pieces,
    );
  }

  String get label {
    switch (this) {
      case InventoryUnit.pieces:
        return 'Pieces';
      case InventoryUnit.boxes:
        return 'Boxes';
      case InventoryUnit.kg:
        return 'Kg';
      case InventoryUnit.liters:
        return 'Liters';
      case InventoryUnit.reams:
        return 'Reams';
      case InventoryUnit.sets:
        return 'Sets';
      case InventoryUnit.pairs:
        return 'Pairs';
      case InventoryUnit.packets:
        return 'Packets';
    }
  }
}

enum TransactionType {
  purchase,
  issue,
  returnItem,
  adjustment,
  disposal;

  String get value {
    switch (this) {
      case TransactionType.purchase:
        return 'purchase';
      case TransactionType.issue:
        return 'issue';
      case TransactionType.returnItem:
        return 'return';
      case TransactionType.adjustment:
        return 'adjustment';
      case TransactionType.disposal:
        return 'disposal';
    }
  }

  static TransactionType fromString(String value) {
    switch (value) {
      case 'purchase':
        return TransactionType.purchase;
      case 'issue':
        return TransactionType.issue;
      case 'return':
        return TransactionType.returnItem;
      case 'adjustment':
        return TransactionType.adjustment;
      case 'disposal':
        return TransactionType.disposal;
      default:
        return TransactionType.purchase;
    }
  }

  String get label {
    switch (this) {
      case TransactionType.purchase:
        return 'Purchase';
      case TransactionType.issue:
        return 'Issue';
      case TransactionType.returnItem:
        return 'Return';
      case TransactionType.adjustment:
        return 'Adjustment';
      case TransactionType.disposal:
        return 'Disposal';
    }
  }
}

enum PurchaseRequestStatus {
  draft,
  submitted,
  approved,
  rejected,
  ordered,
  received;

  String get value => name;

  static PurchaseRequestStatus fromString(String value) {
    return PurchaseRequestStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PurchaseRequestStatus.draft,
    );
  }

  String get label {
    switch (this) {
      case PurchaseRequestStatus.draft:
        return 'Draft';
      case PurchaseRequestStatus.submitted:
        return 'Submitted';
      case PurchaseRequestStatus.approved:
        return 'Approved';
      case PurchaseRequestStatus.rejected:
        return 'Rejected';
      case PurchaseRequestStatus.ordered:
        return 'Ordered';
      case PurchaseRequestStatus.received:
        return 'Received';
    }
  }
}

enum AuditStatus {
  planned,
  inProgress,
  completed;

  String get value {
    switch (this) {
      case AuditStatus.planned:
        return 'planned';
      case AuditStatus.inProgress:
        return 'in_progress';
      case AuditStatus.completed:
        return 'completed';
    }
  }

  static AuditStatus fromString(String value) {
    switch (value) {
      case 'planned':
        return AuditStatus.planned;
      case 'in_progress':
        return AuditStatus.inProgress;
      case 'completed':
        return AuditStatus.completed;
      default:
        return AuditStatus.planned;
    }
  }

  String get label {
    switch (this) {
      case AuditStatus.planned:
        return 'Planned';
      case AuditStatus.inProgress:
        return 'In Progress';
      case AuditStatus.completed:
        return 'Completed';
    }
  }
}

// ==================== MODELS ====================

class AssetCategory {
  final String id;
  final String tenantId;
  final String name;
  final String? parentCategoryId;
  final String? description;
  final double depreciationRate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related
  final List<AssetCategory> children;

  const AssetCategory({
    required this.id,
    required this.tenantId,
    required this.name,
    this.parentCategoryId,
    this.description,
    this.depreciationRate = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.children = const [],
  });

  factory AssetCategory.fromJson(Map<String, dynamic> json) {
    return AssetCategory(
      id: json['id'],
      tenantId: json['tenant_id'],
      name: json['name'],
      parentCategoryId: json['parent_category_id'],
      description: json['description'],
      depreciationRate: (json['depreciation_rate'] as num?)?.toDouble() ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'name': name,
      'parent_category_id': parentCategoryId,
      'description': description,
      'depreciation_rate': depreciationRate,
      'is_active': isActive,
    };
  }

  AssetCategory copyWith({
    String? name,
    String? parentCategoryId,
    String? description,
    double? depreciationRate,
    bool? isActive,
    List<AssetCategory>? children,
  }) {
    return AssetCategory(
      id: id,
      tenantId: tenantId,
      name: name ?? this.name,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
      description: description ?? this.description,
      depreciationRate: depreciationRate ?? this.depreciationRate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      children: children ?? this.children,
    );
  }
}

class Asset {
  final String id;
  final String tenantId;
  final String assetCode;
  final String name;
  final String? categoryId;
  final String? description;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final double? currentValue;
  final String? vendor;
  final DateTime? warrantyExpiry;
  final String? location;
  final String? assignedTo;
  final AssetStatus status;
  final AssetCondition condition;
  final String? qrCodeData;
  final String? imageUrl;
  final String? serialNumber;
  final Map<String, dynamic> specifications;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data from joins
  final AssetCategory? category;
  final String? assignedToName;

  const Asset({
    required this.id,
    required this.tenantId,
    required this.assetCode,
    required this.name,
    this.categoryId,
    this.description,
    this.purchaseDate,
    this.purchasePrice,
    this.currentValue,
    this.vendor,
    this.warrantyExpiry,
    this.location,
    this.assignedTo,
    this.status = AssetStatus.available,
    this.condition = AssetCondition.good,
    this.qrCodeData,
    this.imageUrl,
    this.serialNumber,
    this.specifications = const {},
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.assignedToName,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    AssetCategory? category;
    if (json['inv_asset_categories'] != null) {
      category = AssetCategory.fromJson(json['inv_asset_categories']);
    }

    String? assignedToName;
    if (json['users'] != null) {
      assignedToName = json['users']['full_name'] as String?;
    }

    return Asset(
      id: json['id'],
      tenantId: json['tenant_id'],
      assetCode: json['asset_code'],
      name: json['name'],
      categoryId: json['category_id'],
      description: json['description'],
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'])
          : null,
      purchasePrice: (json['purchase_price'] as num?)?.toDouble(),
      currentValue: (json['current_value'] as num?)?.toDouble(),
      vendor: json['vendor'],
      warrantyExpiry: json['warranty_expiry'] != null
          ? DateTime.parse(json['warranty_expiry'])
          : null,
      location: json['location'],
      assignedTo: json['assigned_to'],
      status: AssetStatus.fromString(json['status'] ?? 'available'),
      condition: AssetCondition.fromString(json['condition'] ?? 'good'),
      qrCodeData: json['qr_code_data'],
      imageUrl: json['image_url'],
      serialNumber: json['serial_number'],
      specifications: json['specifications'] is Map
          ? Map<String, dynamic>.from(json['specifications'])
          : {},
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      category: category,
      assignedToName: assignedToName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'asset_code': assetCode,
      'name': name,
      'category_id': categoryId,
      'description': description,
      'purchase_date': purchaseDate?.toIso8601String().split('T')[0],
      'purchase_price': purchasePrice,
      'current_value': currentValue,
      'vendor': vendor,
      'warranty_expiry': warrantyExpiry?.toIso8601String().split('T')[0],
      'location': location,
      'assigned_to': assignedTo,
      'status': status.value,
      'condition': condition.value,
      'qr_code_data': qrCodeData,
      'image_url': imageUrl,
      'serial_number': serialNumber,
      'specifications': specifications,
    };
  }

  bool get isUnderWarranty =>
      warrantyExpiry != null && warrantyExpiry!.isAfter(DateTime.now());

  double get depreciationAmount =>
      (purchasePrice ?? 0) - (currentValue ?? 0);

  double get depreciationPercentage {
    if (purchasePrice == null || purchasePrice == 0) return 0;
    return (depreciationAmount / purchasePrice!) * 100;
  }

  String get statusDisplay => status.label;
  String get conditionDisplay => condition.label;
}

class AssetAssignment {
  final String id;
  final String assetId;
  final String assignedTo;
  final String assignedBy;
  final DateTime assignedDate;
  final DateTime? returnDate;
  final DateTime? expectedReturnDate;
  final AssetCondition conditionAtAssign;
  final AssetCondition? conditionAtReturn;
  final String? notes;
  final AssignmentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data
  final Asset? asset;
  final String? assignedToName;
  final String? assignedByName;

  const AssetAssignment({
    required this.id,
    required this.assetId,
    required this.assignedTo,
    required this.assignedBy,
    required this.assignedDate,
    this.returnDate,
    this.expectedReturnDate,
    this.conditionAtAssign = AssetCondition.good,
    this.conditionAtReturn,
    this.notes,
    this.status = AssignmentStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.asset,
    this.assignedToName,
    this.assignedByName,
  });

  factory AssetAssignment.fromJson(Map<String, dynamic> json) {
    Asset? asset;
    if (json['inv_assets'] != null) {
      asset = Asset.fromJson(json['inv_assets']);
    }

    String? assignedToName;
    if (json['assigned_user'] != null) {
      assignedToName = json['assigned_user']['full_name'] as String?;
    }

    String? assignedByName;
    if (json['assigner_user'] != null) {
      assignedByName = json['assigner_user']['full_name'] as String?;
    }

    return AssetAssignment(
      id: json['id'],
      assetId: json['asset_id'],
      assignedTo: json['assigned_to'],
      assignedBy: json['assigned_by'],
      assignedDate: DateTime.parse(json['assigned_date']),
      returnDate: json['return_date'] != null
          ? DateTime.parse(json['return_date'])
          : null,
      expectedReturnDate: json['expected_return_date'] != null
          ? DateTime.parse(json['expected_return_date'])
          : null,
      conditionAtAssign:
          AssetCondition.fromString(json['condition_at_assign'] ?? 'good'),
      conditionAtReturn: json['condition_at_return'] != null
          ? AssetCondition.fromString(json['condition_at_return'])
          : null,
      notes: json['notes'],
      status: AssignmentStatus.fromString(json['status'] ?? 'active'),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      asset: asset,
      assignedToName: assignedToName,
      assignedByName: assignedByName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'asset_id': assetId,
      'assigned_to': assignedTo,
      'assigned_by': assignedBy,
      'assigned_date': assignedDate.toIso8601String().split('T')[0],
      'return_date': returnDate?.toIso8601String().split('T')[0],
      'expected_return_date':
          expectedReturnDate?.toIso8601String().split('T')[0],
      'condition_at_assign': conditionAtAssign.value,
      'condition_at_return': conditionAtReturn?.value,
      'notes': notes,
      'status': status.value,
    };
  }

  bool get isOverdue {
    if (status == AssignmentStatus.returned) return false;
    if (expectedReturnDate == null) return false;
    return DateTime.now().isAfter(expectedReturnDate!);
  }

  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(expectedReturnDate!).inDays;
  }
}

class AssetMaintenance {
  final String id;
  final String assetId;
  final MaintenanceType maintenanceType;
  final String? description;
  final String? reportedBy;
  final String? assignedTo;
  final DateTime scheduledDate;
  final DateTime? completedDate;
  final double cost;
  final String? vendor;
  final MaintenanceStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data
  final Asset? asset;
  final String? reportedByName;
  final String? assignedToName;

  const AssetMaintenance({
    required this.id,
    required this.assetId,
    required this.maintenanceType,
    this.description,
    this.reportedBy,
    this.assignedTo,
    required this.scheduledDate,
    this.completedDate,
    this.cost = 0,
    this.vendor,
    this.status = MaintenanceStatus.scheduled,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.asset,
    this.reportedByName,
    this.assignedToName,
  });

  factory AssetMaintenance.fromJson(Map<String, dynamic> json) {
    Asset? asset;
    if (json['inv_assets'] != null) {
      asset = Asset.fromJson(json['inv_assets']);
    }

    return AssetMaintenance(
      id: json['id'],
      assetId: json['asset_id'],
      maintenanceType:
          MaintenanceType.fromString(json['maintenance_type'] ?? 'corrective'),
      description: json['description'],
      reportedBy: json['reported_by'],
      assignedTo: json['assigned_to'],
      scheduledDate: DateTime.parse(json['scheduled_date']),
      completedDate: json['completed_date'] != null
          ? DateTime.parse(json['completed_date'])
          : null,
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      vendor: json['vendor'],
      status:
          MaintenanceStatus.fromString(json['status'] ?? 'scheduled'),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      asset: asset,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'asset_id': assetId,
      'maintenance_type': maintenanceType.value,
      'description': description,
      'reported_by': reportedBy,
      'assigned_to': assignedTo,
      'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
      'completed_date': completedDate?.toIso8601String().split('T')[0],
      'cost': cost,
      'vendor': vendor,
      'status': status.value,
      'notes': notes,
    };
  }

  bool get isOverdue =>
      status == MaintenanceStatus.scheduled &&
      scheduledDate.isBefore(DateTime.now());
}

class InventoryItem {
  final String id;
  final String tenantId;
  final String itemCode;
  final String name;
  final String? categoryId;
  final String? description;
  final InventoryUnit unit;
  final int currentStock;
  final int minimumStock;
  final int maximumStock;
  final int reorderPoint;
  final double unitCost;
  final String? location;
  final bool isConsumable;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related
  final AssetCategory? category;

  const InventoryItem({
    required this.id,
    required this.tenantId,
    required this.itemCode,
    required this.name,
    this.categoryId,
    this.description,
    this.unit = InventoryUnit.pieces,
    this.currentStock = 0,
    this.minimumStock = 0,
    this.maximumStock = 1000,
    this.reorderPoint = 10,
    this.unitCost = 0,
    this.location,
    this.isConsumable = true,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.category,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    AssetCategory? category;
    if (json['inv_asset_categories'] != null) {
      category = AssetCategory.fromJson(json['inv_asset_categories']);
    }

    return InventoryItem(
      id: json['id'],
      tenantId: json['tenant_id'],
      itemCode: json['item_code'],
      name: json['name'],
      categoryId: json['category_id'],
      description: json['description'],
      unit: InventoryUnit.fromString(json['unit'] ?? 'pieces'),
      currentStock: json['current_stock'] ?? 0,
      minimumStock: json['minimum_stock'] ?? 0,
      maximumStock: json['maximum_stock'] ?? 1000,
      reorderPoint: json['reorder_point'] ?? 10,
      unitCost: (json['unit_cost'] as num?)?.toDouble() ?? 0,
      location: json['location'],
      isConsumable: json['is_consumable'] ?? true,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      category: category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'item_code': itemCode,
      'name': name,
      'category_id': categoryId,
      'description': description,
      'unit': unit.value,
      'current_stock': currentStock,
      'minimum_stock': minimumStock,
      'maximum_stock': maximumStock,
      'reorder_point': reorderPoint,
      'unit_cost': unitCost,
      'location': location,
      'is_consumable': isConsumable,
      'is_active': isActive,
    };
  }

  bool get isLowStock => currentStock <= reorderPoint;
  bool get isOutOfStock => currentStock == 0;
  bool get isOverStock => currentStock > maximumStock;

  double get stockValue => currentStock * unitCost;

  double get stockPercentage {
    if (maximumStock == 0) return 0;
    return (currentStock / maximumStock).clamp(0.0, 1.0);
  }
}

class InventoryTransaction {
  final String id;
  final String itemId;
  final TransactionType transactionType;
  final int quantity;
  final double unitCost;
  final double totalCost;
  final String? referenceNumber;
  final String? issuedTo;
  final String? issuedBy;
  final String? notes;
  final DateTime transactionDate;
  final DateTime createdAt;

  // Related
  final InventoryItem? item;
  final String? issuedToName;
  final String? issuedByName;

  const InventoryTransaction({
    required this.id,
    required this.itemId,
    required this.transactionType,
    required this.quantity,
    this.unitCost = 0,
    this.totalCost = 0,
    this.referenceNumber,
    this.issuedTo,
    this.issuedBy,
    this.notes,
    required this.transactionDate,
    required this.createdAt,
    this.item,
    this.issuedToName,
    this.issuedByName,
  });

  factory InventoryTransaction.fromJson(Map<String, dynamic> json) {
    InventoryItem? item;
    if (json['inv_inventory_items'] != null) {
      item = InventoryItem.fromJson(json['inv_inventory_items']);
    }

    String? issuedToName;
    if (json['issued_to_user'] != null) {
      issuedToName = json['issued_to_user']['full_name'] as String?;
    }

    String? issuedByName;
    if (json['issued_by_user'] != null) {
      issuedByName = json['issued_by_user']['full_name'] as String?;
    }

    return InventoryTransaction(
      id: json['id'],
      itemId: json['item_id'],
      transactionType:
          TransactionType.fromString(json['transaction_type'] ?? 'purchase'),
      quantity: json['quantity'] ?? 0,
      unitCost: (json['unit_cost'] as num?)?.toDouble() ?? 0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0,
      referenceNumber: json['reference_number'],
      issuedTo: json['issued_to'],
      issuedBy: json['issued_by'],
      notes: json['notes'],
      transactionDate: DateTime.parse(json['transaction_date']),
      createdAt: DateTime.parse(json['created_at']),
      item: item,
      issuedToName: issuedToName,
      issuedByName: issuedByName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'transaction_type': transactionType.value,
      'quantity': quantity,
      'unit_cost': unitCost,
      'total_cost': totalCost,
      'reference_number': referenceNumber,
      'issued_to': issuedTo,
      'issued_by': issuedBy,
      'notes': notes,
      'transaction_date': transactionDate.toIso8601String().split('T')[0],
    };
  }
}

class PurchaseRequest {
  final String id;
  final String tenantId;
  final String requestNumber;
  final String requestedBy;
  final List<Map<String, dynamic>> items;
  final String? justification;
  final double totalEstimatedCost;
  final PurchaseRequestStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? vendor;
  final DateTime? deliveryDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related
  final String? requestedByName;
  final String? approvedByName;

  const PurchaseRequest({
    required this.id,
    required this.tenantId,
    required this.requestNumber,
    required this.requestedBy,
    this.items = const [],
    this.justification,
    this.totalEstimatedCost = 0,
    this.status = PurchaseRequestStatus.draft,
    this.approvedBy,
    this.approvedAt,
    this.vendor,
    this.deliveryDate,
    required this.createdAt,
    required this.updatedAt,
    this.requestedByName,
    this.approvedByName,
  });

  factory PurchaseRequest.fromJson(Map<String, dynamic> json) {
    String? requestedByName;
    if (json['requester'] != null) {
      requestedByName = json['requester']['full_name'] as String?;
    }

    String? approvedByName;
    if (json['approver'] != null) {
      approvedByName = json['approver']['full_name'] as String?;
    }

    List<Map<String, dynamic>> items = [];
    if (json['items'] is List) {
      items = (json['items'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    return PurchaseRequest(
      id: json['id'],
      tenantId: json['tenant_id'],
      requestNumber: json['request_number'],
      requestedBy: json['requested_by'],
      items: items,
      justification: json['justification'],
      totalEstimatedCost:
          (json['total_estimated_cost'] as num?)?.toDouble() ?? 0,
      status: PurchaseRequestStatus.fromString(json['status'] ?? 'draft'),
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'])
          : null,
      vendor: json['vendor'],
      deliveryDate: json['delivery_date'] != null
          ? DateTime.parse(json['delivery_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      requestedByName: requestedByName,
      approvedByName: approvedByName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'request_number': requestNumber,
      'requested_by': requestedBy,
      'items': items,
      'justification': justification,
      'total_estimated_cost': totalEstimatedCost,
      'status': status.value,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'vendor': vendor,
      'delivery_date': deliveryDate?.toIso8601String().split('T')[0],
    };
  }
}

class AssetAudit {
  final String id;
  final String tenantId;
  final DateTime auditDate;
  final String conductedBy;
  final int totalAssets;
  final int verifiedCount;
  final int missingCount;
  final int damagedCount;
  final String? notes;
  final AuditStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related
  final String? conductedByName;

  const AssetAudit({
    required this.id,
    required this.tenantId,
    required this.auditDate,
    required this.conductedBy,
    this.totalAssets = 0,
    this.verifiedCount = 0,
    this.missingCount = 0,
    this.damagedCount = 0,
    this.notes,
    this.status = AuditStatus.planned,
    required this.createdAt,
    required this.updatedAt,
    this.conductedByName,
  });

  factory AssetAudit.fromJson(Map<String, dynamic> json) {
    String? conductedByName;
    if (json['conductor'] != null) {
      conductedByName = json['conductor']['full_name'] as String?;
    }

    return AssetAudit(
      id: json['id'],
      tenantId: json['tenant_id'],
      auditDate: DateTime.parse(json['audit_date']),
      conductedBy: json['conducted_by'],
      totalAssets: json['total_assets'] ?? 0,
      verifiedCount: json['verified_count'] ?? 0,
      missingCount: json['missing_count'] ?? 0,
      damagedCount: json['damaged_count'] ?? 0,
      notes: json['notes'],
      status: AuditStatus.fromString(json['status'] ?? 'planned'),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      conductedByName: conductedByName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'audit_date': auditDate.toIso8601String().split('T')[0],
      'conducted_by': conductedBy,
      'total_assets': totalAssets,
      'verified_count': verifiedCount,
      'missing_count': missingCount,
      'damaged_count': damagedCount,
      'notes': notes,
      'status': status.value,
    };
  }

  double get verificationPercentage {
    if (totalAssets == 0) return 0;
    return (verifiedCount / totalAssets) * 100;
  }

  int get unverifiedCount => totalAssets - verifiedCount - missingCount - damagedCount;
}
