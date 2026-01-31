import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/canteen.dart';
import 'base_repository.dart';

class CanteenRepository extends BaseRepository {
  CanteenRepository(super.client);

  // ==================== MENU ====================

  Future<List<CanteenItem>> getMenuItems({
    String? category,
    bool availableOnly = true,
  }) async {
    var query = client
        .from('canteen_menu')
        .select()
        .eq('tenant_id', tenantId!);

    if (availableOnly) {
      query = query.eq('is_available', true);
    }

    if (category != null) {
      query = query.eq('category', category);
    }

    final response = await query.order('category').order('name');
    return (response as List).map((json) => CanteenItem.fromJson(json)).toList();
  }

  Future<List<String>> getCategories() async {
    final response = await client
        .from('canteen_menu')
        .select('category')
        .eq('tenant_id', tenantId!)
        .eq('is_available', true)
        .order('category');

    final categories = <String>{};
    for (final item in response as List) {
      if (item['category'] != null) {
        categories.add(item['category'] as String);
      }
    }
    return categories.toList();
  }

  Future<CanteenItem> createMenuItem(Map<String, dynamic> data) async {
    data['tenant_id'] = tenantId;
    final response = await client
        .from('canteen_menu')
        .insert(data)
        .select()
        .single();
    return CanteenItem.fromJson(response);
  }

  Future<CanteenItem> updateMenuItem(String itemId, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    final response = await client
        .from('canteen_menu')
        .update(data)
        .eq('id', itemId)
        .select()
        .single();
    return CanteenItem.fromJson(response);
  }

  Future<void> deleteMenuItem(String itemId) async {
    await client.from('canteen_menu').delete().eq('id', itemId);
  }

  // ==================== WALLET ====================

  Future<Wallet?> getWallet({String? userId, String? studentId}) async {
    var query = client
        .from('wallets')
        .select()
        .eq('tenant_id', tenantId!);

    if (userId != null) {
      query = query.eq('user_id', userId);
    } else if (studentId != null) {
      query = query.eq('student_id', studentId);
    }

    final response = await query.maybeSingle();
    if (response == null) return null;
    return Wallet.fromJson(response);
  }

  Future<Wallet> getOrCreateWallet({String? userId, String? studentId}) async {
    var wallet = await getWallet(userId: userId, studentId: studentId);
    if (wallet != null) return wallet;

    final data = {
      'tenant_id': tenantId,
      'user_id': userId,
      'student_id': studentId,
      'balance': 0.0,
    };

    final response = await client
        .from('wallets')
        .insert(data)
        .select()
        .single();
    return Wallet.fromJson(response);
  }

  Future<Wallet> addBalance(String walletId, double amount, String description) async {
    // Get current balance
    final walletResponse = await client
        .from('wallets')
        .select('balance')
        .eq('id', walletId)
        .single();

    final currentBalance = (walletResponse['balance'] as num).toDouble();
    final newBalance = currentBalance + amount;

    // Update wallet
    await client
        .from('wallets')
        .update({
          'balance': newBalance,
          'last_transaction_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', walletId);

    // Create transaction
    await client.from('wallet_transactions').insert({
      'tenant_id': tenantId,
      'wallet_id': walletId,
      'txn_type': 'credit',
      'amount': amount,
      'balance_after': newBalance,
      'description': description,
    });

    return (await getWalletById(walletId))!;
  }

  Future<Wallet?> getWalletById(String walletId) async {
    final response = await client
        .from('wallets')
        .select()
        .eq('id', walletId)
        .maybeSingle();
    if (response == null) return null;
    return Wallet.fromJson(response);
  }

  Future<List<WalletTransaction>> getTransactions(String walletId, {int limit = 50}) async {
    final response = await client
        .from('wallet_transactions')
        .select()
        .eq('wallet_id', walletId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => WalletTransaction.fromJson(json))
        .toList();
  }

  // ==================== ORDERS ====================

  Future<CanteenOrder> placeOrder({
    required String walletId,
    required List<CartItem> items,
    String? notes,
  }) async {
    // Calculate total
    final total = items.fold<double>(0, (sum, item) => sum + item.totalPrice);

    // Get wallet and check balance
    final wallet = await getWalletById(walletId);
    if (wallet == null || !wallet.canAfford(total)) {
      throw Exception('Insufficient balance');
    }

    // Generate order number
    final orderNumber = 'ORD${DateTime.now().millisecondsSinceEpoch}';

    // Create order
    final orderResponse = await client
        .from('canteen_orders')
        .insert({
          'tenant_id': tenantId,
          'order_number': orderNumber,
          'wallet_id': walletId,
          'total_amount': total,
          'status': 'pending',
          'notes': notes,
        })
        .select()
        .single();

    final orderId = orderResponse['id'];

    // Create order items
    for (final cartItem in items) {
      await client.from('canteen_order_items').insert({
        'order_id': orderId,
        'menu_item_id': cartItem.item.id,
        'quantity': cartItem.quantity,
        'unit_price': cartItem.item.price,
        'total_price': cartItem.totalPrice,
      });
    }

    // Deduct from wallet
    final newBalance = wallet.balance - total;
    await client
        .from('wallets')
        .update({
          'balance': newBalance,
          'last_transaction_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', walletId);

    // Create transaction
    await client.from('wallet_transactions').insert({
      'tenant_id': tenantId,
      'wallet_id': walletId,
      'txn_type': 'debit',
      'amount': total,
      'balance_after': newBalance,
      'description': 'Order #$orderNumber',
      'reference_type': 'canteen_order',
      'reference_id': orderId,
    });

    return CanteenOrder.fromJson(orderResponse);
  }

  Future<List<CanteenOrder>> getOrders({
    String? walletId,
    String? status,
    int limit = 50,
  }) async {
    var query = client
        .from('canteen_orders')
        .select('''
          *,
          canteen_order_items(
            *,
            canteen_menu(*)
          )
        ''')
        .eq('tenant_id', tenantId!);

    if (walletId != null) {
      query = query.eq('wallet_id', walletId);
    }

    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query
        .order('ordered_at', ascending: false)
        .limit(limit);

    return (response as List).map((json) => CanteenOrder.fromJson(json)).toList();
  }

  Future<CanteenOrder?> getOrderById(String orderId) async {
    final response = await client
        .from('canteen_orders')
        .select('''
          *,
          canteen_order_items(
            *,
            canteen_menu(*)
          )
        ''')
        .eq('id', orderId)
        .maybeSingle();

    if (response == null) return null;
    return CanteenOrder.fromJson(response);
  }

  Future<CanteenOrder> updateOrderStatus(String orderId, String status) async {
    final updates = <String, dynamic>{'status': status};

    if (status == 'confirmed') {
      updates['confirmed_at'] = DateTime.now().toIso8601String();
      updates['confirmed_by'] = currentUserId;
    } else if (status == 'delivered') {
      updates['delivered_at'] = DateTime.now().toIso8601String();
    }

    final response = await client
        .from('canteen_orders')
        .update(updates)
        .eq('id', orderId)
        .select()
        .single();

    return CanteenOrder.fromJson(response);
  }

  Future<void> cancelOrder(String orderId) async {
    // Get order details
    final order = await getOrderById(orderId);
    if (order == null) throw Exception('Order not found');
    if (!order.canCancel) throw Exception('Order cannot be cancelled');

    // Refund to wallet
    final wallet = await getWalletById(order.walletId);
    if (wallet == null) throw Exception('Wallet not found');

    final newBalance = wallet.balance + order.totalAmount;
    await client
        .from('wallets')
        .update({
          'balance': newBalance,
          'last_transaction_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', order.walletId);

    // Create refund transaction
    await client.from('wallet_transactions').insert({
      'tenant_id': tenantId,
      'wallet_id': order.walletId,
      'txn_type': 'credit',
      'amount': order.totalAmount,
      'balance_after': newBalance,
      'description': 'Refund for Order #${order.orderNumber}',
      'reference_type': 'canteen_order_refund',
      'reference_id': orderId,
    });

    // Update order status
    await updateOrderStatus(orderId, 'cancelled');
  }

  // ==================== STATISTICS ====================

  Future<Map<String, dynamic>> getDailyStats(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];

    final ordersResponse = await client
        .from('canteen_orders')
        .select('total_amount, status')
        .eq('tenant_id', tenantId!)
        .gte('ordered_at', '$dateStr 00:00:00')
        .lte('ordered_at', '$dateStr 23:59:59');

    final orders = ordersResponse as List;
    final totalOrders = orders.length;
    final completedOrders = orders.where((o) => o['status'] == 'delivered').length;
    final totalRevenue = orders
        .where((o) => o['status'] != 'cancelled')
        .fold<double>(0, (sum, o) => sum + (o['total_amount'] as num).toDouble());

    return {
      'total_orders': totalOrders,
      'completed_orders': completedOrders,
      'pending_orders': totalOrders - completedOrders,
      'total_revenue': totalRevenue,
    };
  }
}
