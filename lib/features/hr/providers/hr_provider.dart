import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/hr_payroll.dart';
import '../../../data/repositories/hr_repository.dart';

// ==========================================================================
// Repository provider
// ==========================================================================

final hrRepositoryProvider = Provider<HRRepository>((ref) {
  return HRRepository(ref.watch(supabaseProvider));
});

// ==========================================================================
// Dashboard
// ==========================================================================

final hrStatsProvider = FutureProvider<HRDashboardStats>((ref) async {
  final repository = ref.watch(hrRepositoryProvider);
  return repository.getHRDashboardStats();
});

// ==========================================================================
// Departments
// ==========================================================================

final departmentsProvider = FutureProvider<List<Department>>((ref) async {
  final repository = ref.watch(hrRepositoryProvider);
  return repository.getDepartments();
});

final departmentByIdProvider = FutureProvider.family<Department, String>(
  (ref, id) async {
    final repository = ref.watch(hrRepositoryProvider);
    return repository.getDepartmentById(id);
  },
);

// ==========================================================================
// Designations
// ==========================================================================

final designationsProvider =
    FutureProvider.family<List<Designation>, String?>(
  (ref, departmentId) async {
    final repository = ref.watch(hrRepositoryProvider);
    return repository.getDesignations(departmentId: departmentId);
  },
);

// ==========================================================================
// Staff Contracts
// ==========================================================================

final staffContractsProvider =
    FutureProvider.family<List<StaffContract>, StaffContractFilter>(
  (ref, filter) async {
    final repository = ref.watch(hrRepositoryProvider);
    return repository.getStaffContracts(
      staffId: filter.staffId,
      status: filter.status,
      expiringOnly: filter.expiringOnly,
    );
  },
);

final activeContractProvider =
    FutureProvider.family<StaffContract?, String>(
  (ref, staffId) async {
    final repository = ref.watch(hrRepositoryProvider);
    return repository.getActiveContract(staffId);
  },
);

final expiringContractsProvider = FutureProvider<List<StaffContract>>((ref) async {
  final repository = ref.watch(hrRepositoryProvider);
  return repository.getStaffContracts(expiringOnly: true);
});

// ==========================================================================
// Payroll
// ==========================================================================

final payrollRunsProvider =
    FutureProvider.family<List<PayrollRun>, int?>(
  (ref, year) async {
    final repository = ref.watch(hrRepositoryProvider);
    return repository.getPayrollRuns(year: year);
  },
);

final payrollRunByIdProvider =
    FutureProvider.family<PayrollRun?, String>(
  (ref, id) async {
    final repository = ref.watch(hrRepositoryProvider);
    return repository.getPayrollRunById(id);
  },
);

// ==========================================================================
// Staff Attendance
// ==========================================================================

final staffAttendanceProvider =
    FutureProvider.family<List<StaffAttendanceDaily>, DateTime>(
  (ref, date) async {
    final repository = ref.watch(hrRepositoryProvider);
    return repository.getStaffAttendance(date: date);
  },
);

final staffAttendanceSummaryProvider =
    FutureProvider.family<Map<String, int>, StaffAttendanceSummaryFilter>(
  (ref, filter) async {
    final repository = ref.watch(hrRepositoryProvider);
    return repository.getStaffAttendanceSummary(
      staffId: filter.staffId,
      month: filter.month,
      year: filter.year,
    );
  },
);

// ==========================================================================
// Tax Declarations
// ==========================================================================

final taxDeclarationsProvider =
    FutureProvider.family<List<TaxDeclaration>, TaxDeclarationFilter>(
  (ref, filter) async {
    final repository = ref.watch(hrRepositoryProvider);
    return repository.getTaxDeclarations(
      staffId: filter.staffId,
      financialYear: filter.financialYear,
      status: filter.status,
    );
  },
);

// ==========================================================================
// Salary Structures
// ==========================================================================

final salaryStructuresProvider =
    FutureProvider<List<SalaryStructure>>((ref) async {
  final repository = ref.watch(hrRepositoryProvider);
  return repository.getSalaryStructures();
});

// ==========================================================================
// Staff Documents
// ==========================================================================

final staffDocumentsProvider =
    FutureProvider.family<List<StaffDocument>, String>(
  (ref, staffId) async {
    final repository = ref.watch(hrRepositoryProvider);
    return repository.getStaffDocuments(staffId);
  },
);

// ==========================================================================
// Salary Slips
// ==========================================================================

final salarySlipsProvider =
    FutureProvider.family<List<SalarySlip>, String?>(
  (ref, staffId) async {
    final repository = ref.watch(hrRepositoryProvider);
    return repository.getSalarySlips(staffId: staffId);
  },
);

// ==========================================================================
// Notifiers (for mutable operations)
// ==========================================================================

class HRNotifier extends StateNotifier<AsyncValue<void>> {
  final HRRepository _repository;

  HRNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<Department> createDepartment(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final dept = await _repository.createDepartment(data);
      state = const AsyncValue.data(null);
      return dept;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Department> updateDepartment(
      String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final dept = await _repository.updateDepartment(id, data);
      state = const AsyncValue.data(null);
      return dept;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<StaffContract> createContract(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final contract = await _repository.createContract(data);
      state = const AsyncValue.data(null);
      return contract;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<String> generatePayroll({
    required int month,
    required int year,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final runId = await _repository.generatePayroll(
        month: month,
        year: year,
        notes: notes,
      );
      state = const AsyncValue.data(null);
      return runId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<PayrollRun> approvePayroll(String payrollRunId) async {
    state = const AsyncValue.loading();
    try {
      final run = await _repository.approvePayroll(payrollRunId);
      state = const AsyncValue.data(null);
      return run;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> upsertStaffAttendance(
      List<Map<String, dynamic>> records) async {
    state = const AsyncValue.loading();
    try {
      await _repository.upsertStaffAttendance(records);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<TaxDeclaration> createTaxDeclaration(
      Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final dec = await _repository.createTaxDeclaration(data);
      state = const AsyncValue.data(null);
      return dec;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<TaxDeclaration> verifyTaxDeclaration(String id) async {
    state = const AsyncValue.loading();
    try {
      final dec = await _repository.verifyTaxDeclaration(id);
      state = const AsyncValue.data(null);
      return dec;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final hrNotifierProvider =
    StateNotifierProvider<HRNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(hrRepositoryProvider);
  return HRNotifier(repository);
});

// ==========================================================================
// Filter classes
// ==========================================================================

class StaffContractFilter {
  final String? staffId;
  final String? status;
  final bool expiringOnly;

  const StaffContractFilter({
    this.staffId,
    this.status,
    this.expiringOnly = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffContractFilter &&
          other.staffId == staffId &&
          other.status == status &&
          other.expiringOnly == expiringOnly;

  @override
  int get hashCode => Object.hash(staffId, status, expiringOnly);
}

class StaffAttendanceSummaryFilter {
  final String staffId;
  final int month;
  final int year;

  const StaffAttendanceSummaryFilter({
    required this.staffId,
    required this.month,
    required this.year,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffAttendanceSummaryFilter &&
          other.staffId == staffId &&
          other.month == month &&
          other.year == year;

  @override
  int get hashCode => Object.hash(staffId, month, year);
}

class TaxDeclarationFilter {
  final String? staffId;
  final String? financialYear;
  final String? status;

  const TaxDeclarationFilter({
    this.staffId,
    this.financialYear,
    this.status,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaxDeclarationFilter &&
          other.staffId == staffId &&
          other.financialYear == financialYear &&
          other.status == status;

  @override
  int get hashCode => Object.hash(staffId, financialYear, status);
}
