import '../models/certificate.dart';
import 'base_repository.dart';

class CertificateRepository extends BaseRepository {
  CertificateRepository(super.client);

  // ============================================
  // TEMPLATES
  // ============================================

  Future<List<CertificateTemplate>> getTemplates({
    CertificateType? type,
    bool? isActive,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('certificate_templates')
        .select('*')
        .eq('tenant_id', requireTenantId);

    if (type != null) {
      query = query.eq('type', type.value);
    }
    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    final response = await query
        .order('name')
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => CertificateTemplate.fromJson(json))
        .toList();
  }

  Future<CertificateTemplate?> getTemplateById(String templateId) async {
    final response = await client
        .from('certificate_templates')
        .select('*')
        .eq('id', templateId)
        .maybeSingle();

    if (response == null) return null;
    return CertificateTemplate.fromJson(response);
  }

  Future<CertificateTemplate> createTemplate(
      Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;

    final response = await client
        .from('certificate_templates')
        .insert(data)
        .select()
        .single();

    return CertificateTemplate.fromJson(response);
  }

  Future<CertificateTemplate> updateTemplate(
      String templateId, Map<String, dynamic> data) async {
    final response = await client
        .from('certificate_templates')
        .update(data)
        .eq('id', templateId)
        .select()
        .single();

    return CertificateTemplate.fromJson(response);
  }

  Future<void> deleteTemplate(String templateId) async {
    await client
        .from('certificate_templates')
        .delete()
        .eq('id', templateId);
  }

  // ============================================
  // ISSUED CERTIFICATES
  // ============================================

  static const _certSelect = '''
    *,
    certificate_templates(*),
    students(id, first_name, last_name, admission_number,
      student_enrollments(
        sections(id, name,
          classes(id, name)
        )
      )
    ),
    users:issued_by(id, full_name)
  ''';

  Future<List<IssuedCertificate>> getIssuedCertificates({
    String? templateId,
    String? studentId,
    CertificateStatus? status,
    CertificateType? type,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('issued_certificates')
        .select(_certSelect)
        .eq('tenant_id', requireTenantId);

    if (templateId != null) {
      query = query.eq('template_id', templateId);
    }
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (status != null) {
      query = query.eq('status', status.value);
    }
    if (search != null && search.isNotEmpty) {
      query = query.or(
          'certificate_number.ilike.%$search%,purpose.ilike.%$search%');
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => IssuedCertificate.fromJson(json))
        .toList();
  }

  Future<IssuedCertificate?> getCertificateById(String certId) async {
    final response = await client
        .from('issued_certificates')
        .select(_certSelect)
        .eq('id', certId)
        .maybeSingle();

    if (response == null) return null;
    return IssuedCertificate.fromJson(response);
  }

  Future<IssuedCertificate?> getCertificateByNumber(
      String certNumber) async {
    final response = await client
        .from('issued_certificates')
        .select(_certSelect)
        .eq('tenant_id', requireTenantId)
        .eq('certificate_number', certNumber)
        .maybeSingle();

    if (response == null) return null;
    return IssuedCertificate.fromJson(response);
  }

  Future<String> generateCertificateNumber(CertificateType type) async {
    final response = await client.rpc('generate_certificate_number', params: {
      'p_tenant_id': requireTenantId,
      'p_type': type.value,
    });
    return response as String;
  }

  Future<IssuedCertificate> issueCertificate(
      Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;
    data['issued_by'] = currentUserId;

    // Generate certificate number if not provided
    if (data['certificate_number'] == null ||
        (data['certificate_number'] as String).isEmpty) {
      final type =
          CertificateType.fromString(data['type'] ?? 'custom');
      data['certificate_number'] =
          await generateCertificateNumber(type);
    }

    final response = await client
        .from('issued_certificates')
        .insert(data)
        .select(_certSelect)
        .single();

    return IssuedCertificate.fromJson(response);
  }

  Future<IssuedCertificate> updateCertificate(
      String certId, Map<String, dynamic> data) async {
    final response = await client
        .from('issued_certificates')
        .update(data)
        .eq('id', certId)
        .select(_certSelect)
        .single();

    return IssuedCertificate.fromJson(response);
  }

  Future<IssuedCertificate> markAsIssued(String certId) async {
    return updateCertificate(certId, {
      'status': CertificateStatus.issued.value,
      'issued_date': DateTime.now().toIso8601String().split('T')[0],
    });
  }

  Future<IssuedCertificate> revokeCertificate(
    String certId, {
    required String reason,
  }) async {
    return updateCertificate(certId, {
      'status': CertificateStatus.revoked.value,
      'revoked_reason': reason,
    });
  }

  Future<void> deleteCertificate(String certId) async {
    await client.from('issued_certificates').delete().eq('id', certId);
  }

  // ============================================
  // VERIFICATION
  // ============================================

  Future<IssuedCertificate?> verifyCertificate(
      String certificateNumber) async {
    return getCertificateByNumber(certificateNumber);
  }

  // ============================================
  // STATS
  // ============================================

  Future<CertificateStats> getCertificateStats() async {
    final certsResponse = await client
        .from('issued_certificates')
        .select('status, certificate_templates(type)')
        .eq('tenant_id', requireTenantId);

    final certs = certsResponse as List;

    int drafts = 0;
    int issued = 0;
    int revoked = 0;
    final byType = <String, int>{};

    for (final cert in certs) {
      switch (cert['status']) {
        case 'draft':
          drafts++;
          break;
        case 'issued':
          issued++;
          break;
        case 'revoked':
          revoked++;
          break;
      }

      if (cert['certificate_templates'] != null) {
        final type =
            cert['certificate_templates']['type'] as String? ?? 'custom';
        byType[type] = (byType[type] ?? 0) + 1;
      }
    }

    final templatesResponse = await client
        .from('certificate_templates')
        .select('id')
        .eq('tenant_id', requireTenantId)
        .eq('is_active', true);

    return CertificateStats(
      totalIssued: certs.length,
      drafts: drafts,
      issued: issued,
      revoked: revoked,
      templatesCount: (templatesResponse as List).length,
      byType: byType,
    );
  }
}
