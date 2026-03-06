import '../models/admission.dart';
import 'base_repository.dart';

class AdmissionRepository extends BaseRepository {
  AdmissionRepository(super.client);

  // ============================================
  // INQUIRIES
  // ============================================

  Future<List<AdmissionInquiry>> getInquiries({
    String? status,
    String? classId,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('admission_inquiries_v2')
        .select('''
          *,
          classes:applying_for_class_id(id, name),
          users:assigned_to(id, full_name)
        ''')
        .eq('tenant_id', requireTenantId);

    if (status != null) {
      query = query.eq('status', status);
    }
    if (classId != null) {
      query = query.eq('applying_for_class_id', classId);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => AdmissionInquiry.fromJson(json))
        .toList();
  }

  Future<AdmissionInquiry> createInquiry(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;

    final response = await client
        .from('admission_inquiries_v2')
        .insert(data)
        .select('''
          *,
          classes:applying_for_class_id(id, name),
          users:assigned_to(id, full_name)
        ''')
        .single();

    return AdmissionInquiry.fromJson(response);
  }

  Future<AdmissionInquiry> updateInquiry(
      String inquiryId, Map<String, dynamic> data) async {
    final response = await client
        .from('admission_inquiries_v2')
        .update(data)
        .eq('id', inquiryId)
        .select('''
          *,
          classes:applying_for_class_id(id, name),
          users:assigned_to(id, full_name)
        ''')
        .single();

    return AdmissionInquiry.fromJson(response);
  }

  Future<void> deleteInquiry(String inquiryId) async {
    await client.from('admission_inquiries_v2').delete().eq('id', inquiryId);
  }

  Future<int> getInquiryCount({String? status}) async {
    try {
      var query = client
          .from('admission_inquiries_v2')
          .select('id')
          .eq('tenant_id', requireTenantId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query;
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // ============================================
  // APPLICATIONS
  // ============================================

  Future<List<AdmissionApplication>> getApplications({
    String? status,
    String? classId,
    String? academicYearId,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('admission_applications_v2')
        .select('''
          *,
          classes:applying_for_class_id(id, name),
          academic_years:academic_year_id(id, name)
        ''')
        .eq('tenant_id', requireTenantId);

    if (status != null) {
      query = query.eq('status', status);
    }
    if (classId != null) {
      query = query.eq('applying_for_class_id', classId);
    }
    if (academicYearId != null) {
      query = query.eq('academic_year_id', academicYearId);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => AdmissionApplication.fromJson(json))
        .toList();
  }

  Future<AdmissionApplication?> getApplicationById(
      String applicationId) async {
    final response = await client
        .from('admission_applications_v2')
        .select('''
          *,
          classes:applying_for_class_id(id, name),
          academic_years:academic_year_id(id, name),
          admission_interviews_v2(
            *,
            users:interviewer_id(id, full_name)
          ),
          admission_documents_v2(*)
        ''')
        .eq('id', applicationId)
        .maybeSingle();

    if (response == null) return null;
    return AdmissionApplication.fromJson(response);
  }

  Future<AdmissionApplication> createApplication(
      Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;

    final response = await client
        .from('admission_applications_v2')
        .insert(data)
        .select('''
          *,
          classes:applying_for_class_id(id, name),
          academic_years:academic_year_id(id, name)
        ''')
        .single();

    return AdmissionApplication.fromJson(response);
  }

  Future<AdmissionApplication> updateApplication(
      String applicationId, Map<String, dynamic> data) async {
    final response = await client
        .from('admission_applications_v2')
        .update(data)
        .eq('id', applicationId)
        .select('''
          *,
          classes:applying_for_class_id(id, name),
          academic_years:academic_year_id(id, name)
        ''')
        .single();

    return AdmissionApplication.fromJson(response);
  }

  Future<AdmissionApplication> submitApplication(
      String applicationId) async {
    return updateApplication(applicationId, {
      'status': ApplicationStatus.submitted.value,
    });
  }

  Future<AdmissionApplication> updateApplicationStatus(
    String applicationId, {
    required ApplicationStatus status,
    String? statusNotes,
  }) async {
    final data = <String, dynamic>{
      'status': status.value,
      'reviewed_by': currentUserId,
      'reviewed_at': DateTime.now().toIso8601String(),
    };
    if (statusNotes != null) {
      data['status_notes'] = statusNotes;
    }
    return updateApplication(applicationId, data);
  }

  Future<void> deleteApplication(String applicationId) async {
    await client
        .from('admission_applications_v2')
        .delete()
        .eq('id', applicationId);
  }

  // ============================================
  // INTERVIEWS
  // ============================================

  Future<List<AdmissionInterview>> getInterviews({
    String? applicationId,
    String? interviewerId,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = client
        .from('admission_interviews_v2')
        .select('''
          *,
          users:interviewer_id(id, full_name),
          admission_applications_v2:application_id(id, student_name, application_number)
        ''')
        .eq('tenant_id', requireTenantId);

    if (applicationId != null) {
      query = query.eq('application_id', applicationId);
    }
    if (interviewerId != null) {
      query = query.eq('interviewer_id', interviewerId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    if (fromDate != null) {
      query = query.gte('scheduled_at', fromDate.toIso8601String());
    }
    if (toDate != null) {
      query = query.lte('scheduled_at', toDate.toIso8601String());
    }

    final response = await query
        .order('scheduled_at', ascending: true)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => AdmissionInterview.fromJson(json))
        .toList();
  }

  Future<AdmissionInterview> scheduleInterview(
      Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;

    final response = await client
        .from('admission_interviews_v2')
        .insert(data)
        .select('''
          *,
          users:interviewer_id(id, full_name),
          admission_applications_v2:application_id(id, student_name, application_number)
        ''')
        .single();

    // Also update the application status
    await client
        .from('admission_applications_v2')
        .update({'status': ApplicationStatus.interviewScheduled.value})
        .eq('id', data['application_id']);

    return AdmissionInterview.fromJson(response);
  }

  Future<AdmissionInterview> updateInterview(
      String interviewId, Map<String, dynamic> data) async {
    final response = await client
        .from('admission_interviews_v2')
        .update(data)
        .eq('id', interviewId)
        .select('''
          *,
          users:interviewer_id(id, full_name),
          admission_applications_v2:application_id(id, student_name, application_number)
        ''')
        .single();

    return AdmissionInterview.fromJson(response);
  }

  Future<void> deleteInterview(String interviewId) async {
    await client
        .from('admission_interviews_v2')
        .delete()
        .eq('id', interviewId);
  }

  // ============================================
  // DOCUMENTS
  // ============================================

  Future<List<AdmissionDocument>> getDocuments(String applicationId) async {
    final response = await client
        .from('admission_documents_v2')
        .select('*')
        .eq('application_id', applicationId)
        .order('created_at');

    return (response as List)
        .map((json) => AdmissionDocument.fromJson(json))
        .toList();
  }

  Future<AdmissionDocument> uploadDocument(Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;

    final response = await client
        .from('admission_documents_v2')
        .insert(data)
        .select()
        .single();

    return AdmissionDocument.fromJson(response);
  }

  Future<AdmissionDocument> verifyDocument(
    String documentId, {
    required DocumentStatus status,
    String? rejectionReason,
  }) async {
    final data = <String, dynamic>{
      'status': status.value,
      'verified_by': currentUserId,
      'verified_at': DateTime.now().toIso8601String(),
    };
    if (rejectionReason != null) {
      data['rejection_reason'] = rejectionReason;
    }

    final response = await client
        .from('admission_documents_v2')
        .update(data)
        .eq('id', documentId)
        .select()
        .single();

    return AdmissionDocument.fromJson(response);
  }

  Future<void> deleteDocument(String documentId) async {
    await client
        .from('admission_documents_v2')
        .delete()
        .eq('id', documentId);
  }

  // ============================================
  // SETTINGS
  // ============================================

  Future<List<AdmissionSettings>> getSettings({
    String? academicYearId,
    String? classId,
  }) async {
    var query = client
        .from('admission_settings_v2')
        .select('''
          *,
          classes:class_id(id, name),
          academic_years:academic_year_id(id, name)
        ''')
        .eq('tenant_id', requireTenantId);

    if (academicYearId != null) {
      query = query.eq('academic_year_id', academicYearId);
    }
    if (classId != null) {
      query = query.eq('class_id', classId);
    }

    final response = await query.order('created_at');

    return (response as List)
        .map((json) => AdmissionSettings.fromJson(json))
        .toList();
  }

  Future<AdmissionSettings> createOrUpdateSettings(
      Map<String, dynamic> data) async {
    data['tenant_id'] = requireTenantId;

    final response = await client
        .from('admission_settings_v2')
        .upsert(
          data,
          onConflict: 'tenant_id,academic_year_id,class_id',
        )
        .select('''
          *,
          classes:class_id(id, name),
          academic_years:academic_year_id(id, name)
        ''')
        .single();

    return AdmissionSettings.fromJson(response);
  }

  Future<void> deleteSettings(String settingsId) async {
    await client
        .from('admission_settings_v2')
        .delete()
        .eq('id', settingsId);
  }

  // ============================================
  // STATS
  // ============================================

  Future<AdmissionStats> getAdmissionStats({
    String? academicYearId,
  }) async {
    // Get application counts by status
    var appQuery = client
        .from('admission_applications_v2')
        .select('status')
        .eq('tenant_id', requireTenantId);

    if (academicYearId != null) {
      appQuery = appQuery.eq('academic_year_id', academicYearId);
    }

    final appResponse = await appQuery;
    final apps = appResponse as List;

    int submitted = 0;
    int underReview = 0;
    int interviewScheduled = 0;
    int accepted = 0;
    int rejected = 0;
    int waitlisted = 0;
    int enrolled = 0;
    int withdrawn = 0;
    int draft = 0;

    for (final app in apps) {
      switch (app['status']) {
        case 'submitted':
          submitted++;
          break;
        case 'under_review':
          underReview++;
          break;
        case 'interview_scheduled':
          interviewScheduled++;
          break;
        case 'accepted':
          accepted++;
          break;
        case 'rejected':
          rejected++;
          break;
        case 'waitlisted':
          waitlisted++;
          break;
        case 'enrolled':
          enrolled++;
          break;
        case 'withdrawn':
          withdrawn++;
          break;
        case 'draft':
          draft++;
          break;
      }
    }

    // Get inquiry counts
    final inquiryResponse = await client
        .from('admission_inquiries_v2')
        .select('status')
        .eq('tenant_id', requireTenantId);

    final inquiries = inquiryResponse as List;
    final openInquiries = inquiries.where((i) =>
        i['status'] != 'converted' && i['status'] != 'lost').length;

    return AdmissionStats(
      totalApplications: apps.length,
      submitted: submitted,
      underReview: underReview,
      interviewScheduled: interviewScheduled,
      accepted: accepted,
      rejected: rejected,
      waitlisted: waitlisted,
      enrolled: enrolled,
      withdrawn: withdrawn,
      draft: draft,
      totalInquiries: inquiries.length,
      openInquiries: openInquiries,
    );
  }
}
