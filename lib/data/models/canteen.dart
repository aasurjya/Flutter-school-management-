/// Canteen menu item model
class CanteenItem {
  final String id;
  final String tenantId;
  final String name;
  final String? description;
  final double price;
  final String? category;
  final String? imageUrl;
  final bool isAvailable;
  final List<int> availableDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CanteenItem({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description,
    required this.price,
    this.category,
    this.imageUrl,
    this.isAvailable = true,
    this.availableDays = const [1, 2, 3, 4, 5],
    required this.createdAt,
    required this.updatedAt,
  });

  factory CanteenItem.fromJson(Map<String, dynamic> json) {
    return CanteenItem(
      id: json['id'],
      tenantId: json['tenant_id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      category: json['category'],
      imageUrl: json['image_url'],
      isAvailable: json['is_available'] ?? true,
      availableDays: json['available_days'] != null
          ? List<int>.from(json['available_days'])
          : [1, 2, 3, 4, 5],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'image_url': imageUrl,
      'is_available': isAvailable,
      'available_days': availableDays,
    };
  }

  bool get isAvailableToday {
    final today = DateTime.now().weekday;
    return isAvailable && availableDays.contains(today);
  }

  String get priceFormatted => '\u20B9${price.toStringAsFixed(2)}';
}

/// Wallet model
class Wallet {
  final String id;
  final String tenantId;
  final String? userId;
  final String? studentId;
  final double balance;
  final DateTime? lastTransactionAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Wallet({
    required this.id,
    required this.tenantId,
    this.userId,
    this.studentId,
    required this.balance,
    this.lastTransactionAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'],
      tenantId: json['tenant_id'],
      userId: json['user_id'],
      studentId: json['student_id'],
      balance: (json['balance'] as num).toDouble(),
      lastTransactionAt: json['last_transaction_at'] != null
          ? DateTime.parse(json['last_transaction_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  String get balanceFormatted => '\u20B9${balance.toStringAsFixed(2)}';

  bool canAfford(double amount) => balance >= amount;
}

/// Wallet transaction model
class WalletTransaction {
  final String id;
  final String tenantId;
  final String walletId;
  final String txnType;
  final double amount;
  final double balanceAfter;
  final String? description;
  final String? referenceType;
  final String? referenceId;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.tenantId,
    required this.walletId,
    required this.txnType,
    required this.amount,
    required this.balanceAfter,
    this.description,
    this.referenceType,
    this.referenceId,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'],
      tenantId: json['tenant_id'],
      walletId: json['wallet_id'],
      txnType: json['txn_type'],
      amount: (json['amount'] as num).toDouble(),
      balanceAfter: (json['balance_after'] as num).toDouble(),
      description: json['description'],
      referenceType: json['reference_type'],
      referenceId: json['reference_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isCredit => txnType == 'credit';
  bool get isDebit => txnType == 'debit';

  String get amountFormatted =>
      '${isCredit ? '+' : '-'}\u20B9${amount.toStringAsFixed(2)}';
}

/// Canteen order model
class CanteenOrder {
  final String id;
  final String tenantId;
  final String orderNumber;
  final String walletId;
  final double totalAmount;
  final String status;
  final String? notes;
  final DateTime orderedAt;
  final DateTime? confirmedAt;
  final DateTime? deliveredAt;
  final String? confirmedBy;
  final List<CanteenOrderItem>? items;

  const CanteenOrder({
    required this.id,
    required this.tenantId,
    required this.orderNumber,
    required this.walletId,
    required this.totalAmount,
    required this.status,
    this.notes,
    required this.orderedAt,
    this.confirmedAt,
    this.deliveredAt,
    this.confirmedBy,
    this.items,
  });

  factory CanteenOrder.fromJson(Map<String, dynamic> json) {
    List<CanteenOrderItem>? items;
    if (json['canteen_order_items'] != null) {
      items = (json['canteen_order_items'] as List)
          .map((item) => CanteenOrderItem.fromJson(item))
          .toList();
    }

    return CanteenOrder(
      id: json['id'],
      tenantId: json['tenant_id'],
      orderNumber: json['order_number'],
      walletId: json['wallet_id'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'],
      notes: json['notes'],
      orderedAt: DateTime.parse(json['ordered_at']),
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'])
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
      confirmedBy: json['confirmed_by'],
      items: items,
    );
  }

  String get totalFormatted => '\u20B9${totalAmount.toStringAsFixed(2)}';

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready for Pickup';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  bool get canCancel => status == 'pending';
  bool get isCompleted => status == 'delivered';
}

/// Canteen order item model
class CanteenOrderItem {
  final String id;
  final String orderId;
  final String menuItemId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final CanteenItem? menuItem;

  const CanteenOrderItem({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.menuItem,
  });

  factory CanteenOrderItem.fromJson(Map<String, dynamic> json) {
    return CanteenOrderItem(
      id: json['id'],
      orderId: json['order_id'],
      menuItemId: json['menu_item_id'],
      quantity: json['quantity'],
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      menuItem: json['canteen_menu'] != null
          ? CanteenItem.fromJson(json['canteen_menu'])
          : null,
    );
  }
}

/// Cart item for ordering
class CartItem {
  final CanteenItem item;
  int quantity;

  CartItem({
    required this.item,
    this.quantity = 1,
  });

  double get totalPrice => item.price * quantity;
  String get totalPriceFormatted => '\u20B9${totalPrice.toStringAsFixed(2)}';
}
