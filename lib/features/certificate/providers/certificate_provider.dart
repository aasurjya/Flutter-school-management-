import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/certificate.dart';
import '../../../data/repositories/certificate_repository.dart';

/// Repository provider
final certificateRepositoryProvider =
    Provider<CertificateRepository>((ref) {
  return CertificateRepository(ref.watch(supabaseProvider));
});

// ============================================
// TEMPLATE PROVIDERS
// ============================================

final certificateTemplatesProvider =
    FutureProvider.family<List<CertificateTemplate>, TemplateFilter>(
  (ref, filter) async {
    final repository = ref.watch(certificateRepositoryProvider);
    return repository.getTemplates(
      type: filter.type,
      isActive: filter.isActive,
      limit: filter.limit,
      offset: filter.offset,
    );
  },
);

final allTemplatesProvider =
    FutureProvider<List<CertificateTemplate>>((ref) async {
  final repository = ref.watch(certificateRepositoryProvider);
  return repository.getTemplates(isActive: true);
});

final templateByIdProvider =
    FutureProvider.family<CertificateTemplate?, String>(
  (ref, templateId) async {
    final repository = ref.watch(certificateRepositoryProvider);
    return repository.getTemplateById(templateId);
  },
);

// ============================================
// ISSUED CERTIFICATE PROVIDERS
// ============================================

final issuedCertificatesProvider =
    FutureProvider.family<List<IssuedCertificate>, CertificateFilter>(
  (ref, filter) async {
    final repository = ref.watch(certificateRepositoryProvider);
    return repository.getIssuedCertificates(
      templateId: filter.templateId,
      studentId: filter.studentId,
      status: filter.status,
      type: filter.type,
      search: filter.search,
      limit: filter.limit,
      offset: filter.offset,
    );
  },
);

final allIssuedCertificatesProvider =
    FutureProvider<List<IssuedCertificate>>((ref) async {
  final repository = ref.watch(certificateRepositoryProvider);
  return repository.getIssuedCertificates();
});

final certificateByIdProvider =
    FutureProvider.family<IssuedCertificate?, String>(
  (ref, certId) async {
    final repository = ref.watch(certificateRepositoryProvider);
    return repository.getCertificateById(certId);
  },
);

final verifyCertificateProvider =
    FutureProvider.family<IssuedCertificate?, String>(
  (ref, certNumber) async {
    final repository = ref.watch(certificateRepositoryProvider);
    return repository.verifyCertificate(certNumber);
  },
);

// ============================================
// STATS PROVIDER
// ============================================

final certificateStatsProvider =
    FutureProvider<CertificateStats>((ref) async {
  final repository = ref.watch(certificateRepositoryProvider);
  return repository.getCertificateStats();
});

// ============================================
// STATE NOTIFIERS
// ============================================

class CertificateTemplateNotifier
    extends StateNotifier<AsyncValue<List<CertificateTemplate>>> {
  final CertificateRepository _repository;

  CertificateTemplateNotifier(this._repository)
      : super(const AsyncValue.loading());

  Future<void> loadTemplates({CertificateType? type}) async {
    state = const AsyncValue.loading();
    try {
      final templates =
          await _repository.getTemplates(type: type, isActive: true);
      state = AsyncValue.data(templates);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<CertificateTemplate> createTemplate(
      Map<String, dynamic> data) async {
    final template = await _repository.createTemplate(data);
    await loadTemplates();
    return template;
  }

  Future<CertificateTemplate> updateTemplate(
      String id, Map<String, dynamic> data) async {
    final template = await _repository.updateTemplate(id, data);
    await loadTemplates();
    return template;
  }

  Future<void> deleteTemplate(String id) async {
    await _repository.deleteTemplate(id);
    await loadTemplates();
  }
}

final templateNotifierProvider = StateNotifierProvider<
    CertificateTemplateNotifier,
    AsyncValue<List<CertificateTemplate>>>((ref) {
  final repository = ref.watch(certificateRepositoryProvider);
  return CertificateTemplateNotifier(repository);
});

class IssuedCertificateNotifier
    extends StateNotifier<AsyncValue<List<IssuedCertificate>>> {
  final CertificateRepository _repository;

  IssuedCertificateNotifier(this._repository)
      : super(const AsyncValue.loading());

  Future<void> loadCertificates({
    String? studentId,
    CertificateStatus? status,
  }) async {
    state = const AsyncValue.loading();
    try {
      final certs = await _repository.getIssuedCertificates(
        studentId: studentId,
        status: status,
      );
      state = AsyncValue.data(certs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<IssuedCertificate> issueCertificate(
      Map<String, dynamic> data) async {
    final cert = await _repository.issueCertificate(data);
    await loadCertificates();
    return cert;
  }

  Future<IssuedCertificate> markAsIssued(String certId) async {
    final cert = await _repository.markAsIssued(certId);
    await loadCertificates();
    return cert;
  }

  Future<IssuedCertificate> revoke(
      String certId, String reason) async {
    final cert =
        await _repository.revokeCertificate(certId, reason: reason);
    await loadCertificates();
    return cert;
  }

  Future<void> deleteCertificate(String certId) async {
    await _repository.deleteCertificate(certId);
    await loadCertificates();
  }
}

final issuedCertificateNotifierProvider = StateNotifierProvider<
    IssuedCertificateNotifier,
    AsyncValue<List<IssuedCertificate>>>((ref) {
  final repository = ref.watch(certificateRepositoryProvider);
  return IssuedCertificateNotifier(repository);
});

// ============================================
// FILTER CLASSES
// ============================================

class TemplateFilter {
  final CertificateType? type;
  final bool? isActive;
  final int limit;
  final int offset;

  const TemplateFilter({
    this.type,
    this.isActive,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateFilter &&
          other.type == type &&
          other.isActive == isActive &&
          other.limit == limit &&
          other.offset == offset;

  @override
  int get hashCode => Object.hash(type, isActive, limit, offset);
}

class CertificateFilter {
  final String? templateId;
  final String? studentId;
  final CertificateStatus? status;
  final CertificateType? type;
  final String? search;
  final int limit;
  final int offset;

  const CertificateFilter({
    this.templateId,
    this.studentId,
    this.status,
    this.type,
    this.search,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CertificateFilter &&
          other.templateId == templateId &&
          other.studentId == studentId &&
          other.status == status &&
          other.type == type &&
          other.search == search &&
          other.limit == limit &&
          other.offset == offset;

  @override
  int get hashCode =>
      Object.hash(templateId, studentId, status, type, search, limit, offset);
}
