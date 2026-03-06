import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/visitor.dart';
import '../../../data/repositories/visitor_repository.dart';

/// Repository provider
final visitorRepositoryProvider = Provider<VisitorRepository>((ref) {
  return VisitorRepository(ref.watch(supabaseProvider));
});

// ============================================
// VISITOR PROVIDERS
// ============================================

final visitorsProvider =
    FutureProvider.family<List<Visitor>, VisitorFilter>(
  (ref, filter) async {
    final repository = ref.watch(visitorRepositoryProvider);
    return repository.getVisitors(
      search: filter.search,
      isBlacklisted: filter.isBlacklisted,
      limit: filter.limit,
      offset: filter.offset,
    );
  },
);

final allVisitorsProvider = FutureProvider<List<Visitor>>((ref) async {
  final repository = ref.watch(visitorRepositoryProvider);
  return repository.getVisitors();
});

final visitorByIdProvider = FutureProvider.family<Visitor?, String>(
  (ref, visitorId) async {
    final repository = ref.watch(visitorRepositoryProvider);
    return repository.getVisitorById(visitorId);
  },
);

// ============================================
// VISITOR LOG PROVIDERS
// ============================================

final visitorLogsProvider =
    FutureProvider.family<List<VisitorLog>, VisitorLogFilter>(
  (ref, filter) async {
    final repository = ref.watch(visitorRepositoryProvider);
    return repository.getVisitorLogs(
      visitorId: filter.visitorId,
      status: filter.status,
      fromDate: filter.fromDate,
      toDate: filter.toDate,
      search: filter.search,
      limit: filter.limit,
      offset: filter.offset,
    );
  },
);

final todayLogsProvider = FutureProvider<List<VisitorLog>>((ref) async {
  final repository = ref.watch(visitorRepositoryProvider);
  return repository.getTodayLogs();
});

final logByIdProvider = FutureProvider.family<VisitorLog?, String>(
  (ref, logId) async {
    final repository = ref.watch(visitorRepositoryProvider);
    return repository.getLogById(logId);
  },
);

// ============================================
// PRE-REGISTRATION PROVIDERS
// ============================================

final preRegistrationsProvider =
    FutureProvider.family<List<VisitorPreRegistration>, PreRegFilter>(
  (ref, filter) async {
    final repository = ref.watch(visitorRepositoryProvider);
    return repository.getPreRegistrations(
      status: filter.status,
      fromDate: filter.fromDate,
      toDate: filter.toDate,
      limit: filter.limit,
      offset: filter.offset,
    );
  },
);

final todayPreRegistrationsProvider =
    FutureProvider<List<VisitorPreRegistration>>((ref) async {
  final repository = ref.watch(visitorRepositoryProvider);
  return repository.getTodayPreRegistrations();
});

// ============================================
// STATS PROVIDER
// ============================================

final visitorStatsProvider = FutureProvider<VisitorStats>((ref) async {
  final repository = ref.watch(visitorRepositoryProvider);
  return repository.getVisitorStats();
});

// ============================================
// STATE NOTIFIERS
// ============================================

class VisitorNotifier extends StateNotifier<AsyncValue<List<Visitor>>> {
  final VisitorRepository _repository;

  VisitorNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadVisitors({String? search, bool? isBlacklisted}) async {
    state = const AsyncValue.loading();
    try {
      final visitors = await _repository.getVisitors(
        search: search,
        isBlacklisted: isBlacklisted,
      );
      state = AsyncValue.data(visitors);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Visitor> createVisitor(Map<String, dynamic> data) async {
    final visitor = await _repository.createVisitor(data);
    await loadVisitors();
    return visitor;
  }

  Future<Visitor> updateVisitor(
      String id, Map<String, dynamic> data) async {
    final visitor = await _repository.updateVisitor(id, data);
    await loadVisitors();
    return visitor;
  }

  Future<void> toggleBlacklist(String id, bool blacklist) async {
    await _repository.toggleBlacklist(id, blacklist);
    await loadVisitors();
  }

  Future<void> deleteVisitor(String id) async {
    await _repository.deleteVisitor(id);
    await loadVisitors();
  }
}

final visitorNotifierProvider =
    StateNotifierProvider<VisitorNotifier, AsyncValue<List<Visitor>>>(
        (ref) {
  final repository = ref.watch(visitorRepositoryProvider);
  return VisitorNotifier(repository);
});

class VisitorLogNotifier
    extends StateNotifier<AsyncValue<List<VisitorLog>>> {
  final VisitorRepository _repository;

  VisitorLogNotifier(this._repository)
      : super(const AsyncValue.loading());

  Future<void> loadTodayLogs() async {
    state = const AsyncValue.loading();
    try {
      final logs = await _repository.getTodayLogs();
      state = AsyncValue.data(logs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<VisitorLog> checkIn(Map<String, dynamic> data) async {
    final log = await _repository.checkInVisitor(data);
    await loadTodayLogs();
    return log;
  }

  Future<VisitorLog> checkOut(String logId) async {
    final log = await _repository.checkOutVisitor(logId);
    await loadTodayLogs();
    return log;
  }

  Future<VisitorLog> deny(String logId, {String? notes}) async {
    final log = await _repository.denyVisitor(logId, notes: notes);
    await loadTodayLogs();
    return log;
  }
}

final visitorLogNotifierProvider = StateNotifierProvider<
    VisitorLogNotifier, AsyncValue<List<VisitorLog>>>((ref) {
  final repository = ref.watch(visitorRepositoryProvider);
  return VisitorLogNotifier(repository);
});

// ============================================
// FILTER CLASSES
// ============================================

class VisitorFilter {
  final String? search;
  final bool? isBlacklisted;
  final int limit;
  final int offset;

  const VisitorFilter({
    this.search,
    this.isBlacklisted,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisitorFilter &&
          other.search == search &&
          other.isBlacklisted == isBlacklisted &&
          other.limit == limit &&
          other.offset == offset;

  @override
  int get hashCode => Object.hash(search, isBlacklisted, limit, offset);
}

class VisitorLogFilter {
  final String? visitorId;
  final String? status;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? search;
  final int limit;
  final int offset;

  const VisitorLogFilter({
    this.visitorId,
    this.status,
    this.fromDate,
    this.toDate,
    this.search,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisitorLogFilter &&
          other.visitorId == visitorId &&
          other.status == status &&
          other.fromDate == fromDate &&
          other.toDate == toDate &&
          other.search == search &&
          other.limit == limit &&
          other.offset == offset;

  @override
  int get hashCode =>
      Object.hash(visitorId, status, fromDate, toDate, search, limit, offset);
}

class PreRegFilter {
  final String? status;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int limit;
  final int offset;

  const PreRegFilter({
    this.status,
    this.fromDate,
    this.toDate,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreRegFilter &&
          other.status == status &&
          other.fromDate == fromDate &&
          other.toDate == toDate &&
          other.limit == limit &&
          other.offset == offset;

  @override
  int get hashCode => Object.hash(status, fromDate, toDate, limit, offset);
}
