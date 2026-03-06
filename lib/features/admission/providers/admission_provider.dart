import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/admission.dart';
import '../../../data/repositories/admission_repository.dart';

/// Repository provider
final admissionRepositoryProvider = Provider<AdmissionRepository>((ref) {
  return AdmissionRepository(ref.watch(supabaseProvider));
});

// ============================================
// INQUIRY PROVIDERS
// ============================================

final admissionInquiriesProvider =
    FutureProvider.family<List<AdmissionInquiry>, InquiryFilter>(
  (ref, filter) async {
    final repository = ref.watch(admissionRepositoryProvider);
    return repository.getInquiries(
      status: filter.status,
      classId: filter.classId,
      limit: filter.limit,
      offset: filter.offset,
    );
  },
);

final allInquiriesProvider =
    FutureProvider<List<AdmissionInquiry>>((ref) async {
  final repository = ref.watch(admissionRepositoryProvider);
  return repository.getInquiries();
});

// ============================================
// APPLICATION PROVIDERS
// ============================================

final admissionApplicationsProvider =
    FutureProvider.family<List<AdmissionApplication>, ApplicationFilter>(
  (ref, filter) async {
    final repository = ref.watch(admissionRepositoryProvider);
    return repository.getApplications(
      status: filter.status,
      classId: filter.classId,
      academicYearId: filter.academicYearId,
      limit: filter.limit,
      offset: filter.offset,
    );
  },
);

final allApplicationsProvider =
    FutureProvider<List<AdmissionApplication>>((ref) async {
  final repository = ref.watch(admissionRepositoryProvider);
  return repository.getApplications();
});

final applicationByIdProvider =
    FutureProvider.family<AdmissionApplication?, String>(
  (ref, applicationId) async {
    final repository = ref.watch(admissionRepositoryProvider);
    return repository.getApplicationById(applicationId);
  },
);

// ============================================
// INTERVIEW PROVIDERS
// ============================================

final admissionInterviewsProvider =
    FutureProvider.family<List<AdmissionInterview>, InterviewFilter>(
  (ref, filter) async {
    final repository = ref.watch(admissionRepositoryProvider);
    return repository.getInterviews(
      applicationId: filter.applicationId,
      interviewerId: filter.interviewerId,
      status: filter.status,
      fromDate: filter.fromDate,
      toDate: filter.toDate,
    );
  },
);

final allInterviewsProvider =
    FutureProvider<List<AdmissionInterview>>((ref) async {
  final repository = ref.watch(admissionRepositoryProvider);
  return repository.getInterviews();
});

// ============================================
// SETTINGS PROVIDERS
// ============================================

final admissionSettingsProvider =
    FutureProvider.family<List<AdmissionSettings>, SettingsFilter>(
  (ref, filter) async {
    final repository = ref.watch(admissionRepositoryProvider);
    return repository.getSettings(
      academicYearId: filter.academicYearId,
      classId: filter.classId,
    );
  },
);

final allAdmissionSettingsProvider =
    FutureProvider<List<AdmissionSettings>>((ref) async {
  final repository = ref.watch(admissionRepositoryProvider);
  return repository.getSettings();
});

// ============================================
// STATS PROVIDER
// ============================================

final admissionStatsProvider =
    FutureProvider.family<AdmissionStats, String?>((ref, academicYearId) async {
  final repository = ref.watch(admissionRepositoryProvider);
  return repository.getAdmissionStats(academicYearId: academicYearId);
});

final currentAdmissionStatsProvider =
    FutureProvider<AdmissionStats>((ref) async {
  final repository = ref.watch(admissionRepositoryProvider);
  return repository.getAdmissionStats();
});

// ============================================
// STATE NOTIFIERS
// ============================================

class AdmissionNotifier
    extends StateNotifier<AsyncValue<List<AdmissionApplication>>> {
  final AdmissionRepository _repository;

  AdmissionNotifier(this._repository)
      : super(const AsyncValue.loading());

  Future<void> loadApplications({
    String? status,
    String? classId,
    String? academicYearId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final apps = await _repository.getApplications(
        status: status,
        classId: classId,
        academicYearId: academicYearId,
      );
      state = AsyncValue.data(apps);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<AdmissionApplication> createApplication(
      Map<String, dynamic> data) async {
    final app = await _repository.createApplication(data);
    await loadApplications();
    return app;
  }

  Future<AdmissionApplication> updateStatus(
    String applicationId, {
    required ApplicationStatus status,
    String? statusNotes,
  }) async {
    final app = await _repository.updateApplicationStatus(
      applicationId,
      status: status,
      statusNotes: statusNotes,
    );
    await loadApplications();
    return app;
  }

  Future<void> deleteApplication(String applicationId) async {
    await _repository.deleteApplication(applicationId);
    await loadApplications();
  }
}

final admissionNotifierProvider = StateNotifierProvider<AdmissionNotifier,
    AsyncValue<List<AdmissionApplication>>>((ref) {
  final repository = ref.watch(admissionRepositoryProvider);
  return AdmissionNotifier(repository);
});

class InquiryNotifier
    extends StateNotifier<AsyncValue<List<AdmissionInquiry>>> {
  final AdmissionRepository _repository;

  InquiryNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadInquiries({String? status}) async {
    state = const AsyncValue.loading();
    try {
      final inquiries = await _repository.getInquiries(status: status);
      state = AsyncValue.data(inquiries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<AdmissionInquiry> createInquiry(Map<String, dynamic> data) async {
    final inquiry = await _repository.createInquiry(data);
    await loadInquiries();
    return inquiry;
  }

  Future<AdmissionInquiry> updateInquiry(
      String id, Map<String, dynamic> data) async {
    final inquiry = await _repository.updateInquiry(id, data);
    await loadInquiries();
    return inquiry;
  }

  Future<void> deleteInquiry(String id) async {
    await _repository.deleteInquiry(id);
    await loadInquiries();
  }
}

final inquiryNotifierProvider = StateNotifierProvider<InquiryNotifier,
    AsyncValue<List<AdmissionInquiry>>>((ref) {
  final repository = ref.watch(admissionRepositoryProvider);
  return InquiryNotifier(repository);
});

// ============================================
// FILTER CLASSES
// ============================================

class InquiryFilter {
  final String? status;
  final String? classId;
  final int limit;
  final int offset;

  const InquiryFilter({
    this.status,
    this.classId,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InquiryFilter &&
          other.status == status &&
          other.classId == classId &&
          other.limit == limit &&
          other.offset == offset;

  @override
  int get hashCode => Object.hash(status, classId, limit, offset);
}

class ApplicationFilter {
  final String? status;
  final String? classId;
  final String? academicYearId;
  final int limit;
  final int offset;

  const ApplicationFilter({
    this.status,
    this.classId,
    this.academicYearId,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApplicationFilter &&
          other.status == status &&
          other.classId == classId &&
          other.academicYearId == academicYearId &&
          other.limit == limit &&
          other.offset == offset;

  @override
  int get hashCode =>
      Object.hash(status, classId, academicYearId, limit, offset);
}

class InterviewFilter {
  final String? applicationId;
  final String? interviewerId;
  final String? status;
  final DateTime? fromDate;
  final DateTime? toDate;

  const InterviewFilter({
    this.applicationId,
    this.interviewerId,
    this.status,
    this.fromDate,
    this.toDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterviewFilter &&
          other.applicationId == applicationId &&
          other.interviewerId == interviewerId &&
          other.status == status &&
          other.fromDate == fromDate &&
          other.toDate == toDate;

  @override
  int get hashCode =>
      Object.hash(applicationId, interviewerId, status, fromDate, toDate);
}

class SettingsFilter {
  final String? academicYearId;
  final String? classId;

  const SettingsFilter({
    this.academicYearId,
    this.classId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsFilter &&
          other.academicYearId == academicYearId &&
          other.classId == classId;

  @override
  int get hashCode => Object.hash(academicYearId, classId);
}
