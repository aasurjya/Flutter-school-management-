import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/invoice.dart';
import '../../../data/repositories/fee_repository.dart';

final feeRepositoryProvider = Provider<FeeRepository>((ref) {
  return FeeRepository(ref.watch(supabaseProvider));
});

final feeHeadsProvider = FutureProvider<List<FeeHead>>((ref) async {
  final repository = ref.watch(feeRepositoryProvider);
  return repository.getFeeHeads();
});

final feeStructuresProvider = FutureProvider.family<List<FeeStructure>, FeeStructureFilter>(
  (ref, filter) async {
    final repository = ref.watch(feeRepositoryProvider);
    return repository.getFeeStructures(
      academicYearId: filter.academicYearId,
      classId: filter.classId,
      termId: filter.termId,
    );
  },
);

final invoicesProvider = FutureProvider.family<List<Invoice>, InvoicesFilter>(
  (ref, filter) async {
    final repository = ref.watch(feeRepositoryProvider);
    return repository.getInvoices(
      studentId: filter.studentId,
      status: filter.status,
      academicYearId: filter.academicYearId,
    );
  },
);

final invoiceByIdProvider = FutureProvider.family<Invoice?, String>(
  (ref, invoiceId) async {
    final repository = ref.watch(feeRepositoryProvider);
    return repository.getInvoiceById(invoiceId);
  },
);

final studentFeeSummaryProvider = FutureProvider.family<FeeSummary?, StudentFeeFilter>(
  (ref, filter) async {
    final repository = ref.watch(feeRepositoryProvider);
    return repository.getStudentFeeSummary(
      studentId: filter.studentId,
      academicYearId: filter.academicYearId,
    );
  },
);

final feeSummariesProvider = FutureProvider.family<List<FeeSummary>, FeeSummaryFilter>(
  (ref, filter) async {
    final repository = ref.watch(feeRepositoryProvider);
    return repository.getFeeSummaries(
      sectionId: filter.sectionId,
      classId: filter.classId,
      academicYearId: filter.academicYearId,
    );
  },
);

final feeCollectionStatsProvider = FutureProvider.family<Map<String, double>, String?>(
  (ref, academicYearId) async {
    final repository = ref.watch(feeRepositoryProvider);
    return repository.getFeeCollectionStats(academicYearId: academicYearId);
  },
);

final overdueInvoicesProvider = FutureProvider<List<Invoice>>((ref) async {
  final repository = ref.watch(feeRepositoryProvider);
  return repository.getOverdueInvoices();
});

final paymentsProvider = FutureProvider.family<List<Payment>, PaymentsFilter>(
  (ref, filter) async {
    final repository = ref.watch(feeRepositoryProvider);
    return repository.getPayments(
      invoiceId: filter.invoiceId,
      studentId: filter.studentId,
    );
  },
);

class FeeStructureFilter {
  final String academicYearId;
  final String? classId;
  final String? termId;

  const FeeStructureFilter({
    required this.academicYearId,
    this.classId,
    this.termId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeeStructureFilter &&
          other.academicYearId == academicYearId &&
          other.classId == classId &&
          other.termId == termId;

  @override
  int get hashCode => Object.hash(academicYearId, classId, termId);
}

class InvoicesFilter {
  final String? studentId;
  final String? status;
  final String? academicYearId;

  const InvoicesFilter({
    this.studentId,
    this.status,
    this.academicYearId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoicesFilter &&
          other.studentId == studentId &&
          other.status == status &&
          other.academicYearId == academicYearId;

  @override
  int get hashCode => Object.hash(studentId, status, academicYearId);
}

class StudentFeeFilter {
  final String studentId;
  final String? academicYearId;

  const StudentFeeFilter({
    required this.studentId,
    this.academicYearId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentFeeFilter &&
          other.studentId == studentId &&
          other.academicYearId == academicYearId;

  @override
  int get hashCode => Object.hash(studentId, academicYearId);
}

class FeeSummaryFilter {
  final String? sectionId;
  final String? classId;
  final String? academicYearId;

  const FeeSummaryFilter({
    this.sectionId,
    this.classId,
    this.academicYearId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeeSummaryFilter &&
          other.sectionId == sectionId &&
          other.classId == classId &&
          other.academicYearId == academicYearId;

  @override
  int get hashCode => Object.hash(sectionId, classId, academicYearId);
}

class PaymentsFilter {
  final String? invoiceId;
  final String? studentId;

  const PaymentsFilter({
    this.invoiceId,
    this.studentId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentsFilter &&
          other.invoiceId == invoiceId &&
          other.studentId == studentId;

  @override
  int get hashCode => Object.hash(invoiceId, studentId);
}

class FeesNotifier extends StateNotifier<AsyncValue<List<Invoice>>> {
  final FeeRepository _repository;

  FeesNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadInvoices({
    String? studentId,
    String? status,
    String? academicYearId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final invoices = await _repository.getInvoices(
        studentId: studentId,
        status: status,
        academicYearId: academicYearId,
      );
      state = AsyncValue.data(invoices);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Invoice> createInvoice(Map<String, dynamic> data) async {
    final invoice = await _repository.createInvoice(data);
    await loadInvoices();
    return invoice;
  }

  Future<int> generateClassInvoices({
    required String classId,
    required String academicYearId,
    String? termId,
    DateTime? dueDate,
  }) async {
    final count = await _repository.generateClassInvoices(
      classId: classId,
      academicYearId: academicYearId,
      termId: termId,
      dueDate: dueDate,
    );
    await loadInvoices();
    return count;
  }

  Future<Payment> recordPayment({
    required String invoiceId,
    required double amount,
    required String paymentMethod,
    String? transactionId,
    String? remarks,
  }) async {
    final payment = await _repository.recordPayment(
      invoiceId: invoiceId,
      amount: amount,
      paymentMethod: paymentMethod,
      transactionId: transactionId,
      remarks: remarks,
    );
    await loadInvoices();
    return payment;
  }
}

final feesNotifierProvider =
    StateNotifierProvider<FeesNotifier, AsyncValue<List<Invoice>>>((ref) {
  final repository = ref.watch(feeRepositoryProvider);
  return FeesNotifier(repository);
});

class FeeHeadsNotifier extends StateNotifier<AsyncValue<List<FeeHead>>> {
  final FeeRepository _repository;

  FeeHeadsNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadFeeHeads() async {
    state = const AsyncValue.loading();
    try {
      final feeHeads = await _repository.getFeeHeads();
      state = AsyncValue.data(feeHeads);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<FeeHead> createFeeHead(Map<String, dynamic> data) async {
    final feeHead = await _repository.createFeeHead(data);
    await loadFeeHeads();
    return feeHead;
  }
}

final feeHeadsNotifierProvider =
    StateNotifierProvider<FeeHeadsNotifier, AsyncValue<List<FeeHead>>>((ref) {
  final repository = ref.watch(feeRepositoryProvider);
  return FeeHeadsNotifier(repository);
});
