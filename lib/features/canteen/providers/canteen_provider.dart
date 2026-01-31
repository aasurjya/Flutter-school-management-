import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/canteen.dart';
import '../../../data/repositories/canteen_repository.dart';

final canteenRepositoryProvider = Provider<CanteenRepository>((ref) {
  return CanteenRepository(Supabase.instance.client);
});

// Menu providers
final menuItemsProvider = FutureProvider.family<List<CanteenItem>, String?>(
  (ref, category) async {
    final repository = ref.watch(canteenRepositoryProvider);
    return repository.getMenuItems(category: category);
  },
);

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(canteenRepositoryProvider);
  return repository.getCategories();
});

// Wallet providers
final walletProvider = FutureProvider.family<Wallet?, WalletFilter>(
  (ref, filter) async {
    final repository = ref.watch(canteenRepositoryProvider);
    return repository.getWallet(userId: filter.userId, studentId: filter.studentId);
  },
);

final currentUserWalletProvider = FutureProvider<Wallet?>((ref) async {
  final repository = ref.watch(canteenRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;
  return repository.getOrCreateWallet(userId: userId);
});

final walletTransactionsProvider = FutureProvider.family<List<WalletTransaction>, String>(
  (ref, walletId) async {
    final repository = ref.watch(canteenRepositoryProvider);
    return repository.getTransactions(walletId);
  },
);

// Order providers
final ordersProvider = FutureProvider.family<List<CanteenOrder>, OrdersFilter>(
  (ref, filter) async {
    final repository = ref.watch(canteenRepositoryProvider);
    return repository.getOrders(
      walletId: filter.walletId,
      status: filter.status,
    );
  },
);

final orderByIdProvider = FutureProvider.family<CanteenOrder?, String>(
  (ref, orderId) async {
    final repository = ref.watch(canteenRepositoryProvider);
    return repository.getOrderById(orderId);
  },
);

// Daily stats provider (for canteen staff)
final dailyStatsProvider = FutureProvider.family<Map<String, dynamic>, DateTime>(
  (ref, date) async {
    final repository = ref.watch(canteenRepositoryProvider);
    return repository.getDailyStats(date);
  },
);

// Cart state
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(CanteenItem item) {
    final index = state.indexWhere((cartItem) => cartItem.item.id == item.id);
    if (index >= 0) {
      state = [
        ...state.sublist(0, index),
        CartItem(item: item, quantity: state[index].quantity + 1),
        ...state.sublist(index + 1),
      ];
    } else {
      state = [...state, CartItem(item: item)];
    }
  }

  void removeItem(String itemId) {
    state = state.where((cartItem) => cartItem.item.id != itemId).toList();
  }

  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }
    final index = state.indexWhere((cartItem) => cartItem.item.id == itemId);
    if (index >= 0) {
      state = [
        ...state.sublist(0, index),
        CartItem(item: state[index].item, quantity: quantity),
        ...state.sublist(index + 1),
      ];
    }
  }

  void clear() {
    state = [];
  }

  double get totalAmount => state.fold<double>(0, (sum, item) => sum + item.totalPrice);

  int get itemCount => state.fold<int>(0, (sum, item) => sum + item.quantity);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold<double>(0, (sum, item) => sum + item.totalPrice);
});

final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold<int>(0, (sum, item) => sum + item.quantity);
});

// Filter classes
class WalletFilter {
  final String? userId;
  final String? studentId;

  const WalletFilter({this.userId, this.studentId});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WalletFilter &&
        other.userId == userId &&
        other.studentId == studentId;
  }

  @override
  int get hashCode => Object.hash(userId, studentId);
}

class OrdersFilter {
  final String? walletId;
  final String? status;

  const OrdersFilter({this.walletId, this.status});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrdersFilter &&
        other.walletId == walletId &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(walletId, status);
}
