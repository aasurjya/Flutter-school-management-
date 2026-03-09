import '../models/report_card.dart';
import '../models/report_card_full.dart';
import 'base_repository.dart';

class ReportCardFullRepository extends BaseRepository {
  ReportCardFullRepository(super.client);

  // ==========================================================================
  // GRADING SCALES
  // ==========================================================================

  Future<List<GradingScale>> getGradingScales() async {
    final response = await client
        .from('grading_scales')
        .select()
        .eq('tenant_id', requireTenantId)
        .order('name');

    return (response as List)
        .map((json) => GradingScale.fromJson(json))
        .toList();
  }

  Future<GradingScale> createGradingScale(GradingScale scale) async {
    final response = await client
        .from('grading_scales')
        .insert(scale.toJson())
        .select()
        .single();
    return GradingScale.fromJson(response);
  }

  Future<GradingScale> updateGradingScale(
      String id, Map<String, dynamic> data) async {
    final response = await client
        .from('grading_scales')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return GradingScale.fromJson(response);
  }

  Future<void> deleteGradingScale(String id) async {
    await client.from('grading_scales').delete().eq('id', id);
  }

  // ==========================================================================
  // TEMPLATES
  // ==========================================================================

  Future<List<ReportCardTemplateFull>> getTemplates() async {
    final response = await client
        .from('report_card_templates')
        .select('*, grading_scale:grading_scales(*)')
        .eq('tenant_id', requireTenantId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ReportCardTemplateFull.fromJson(json))
        .toList();
  }

  Future<ReportCardTemplateFull?> getTemplateById(String id) async {
    final response = await client
        .from('report_card_templates')
        .select('*, grading_scale:grading_scales(*)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return ReportCardTemplateFull.fromJson(response);
  }

  Future<ReportCardTemplateFull?> getDefaultTemplate() async {
    final response = await client
        .from('report_card_templates')
        .select('*, grading_scale:grading_scales(*)')
        .eq('tenant_id', requireTenantId)
        .eq('is_default', true)
        .maybeSingle();

    if (response == null) return null;
    return ReportCardTemplateFull.fromJson(response);
  }

  Future<ReportCardTemplateFull> createTemplate(
      ReportCardTemplateFull template) async {
    if (template.isDefault) {
      await _unsetDefaultTemplates();
    }

    final response = await client
        .from('report_card_templates')
        .insert(template.toJson())
        .select('*, grading_scale:grading_scales(*)')
        .single();

    return ReportCardTemplateFull.fromJson(response);
  }

  Future<ReportCardTemplateFull> updateTemplate(
      String id, Map<String, dynamic> data) async {
    if (data['is_default'] == true) {
      await _unsetDefaultTemplates();
    }

    final response = await client
        .from('report_card_templates')
        .update(data)
        .eq('id', id)
        .select('*, grading_scale:grading_scales(*)')
        .single();

    return ReportCardTemplateFull.fromJson(response);
  }

  Future<void> deleteTemplate(String id) async {
    await client.from('report_card_templates').delete().eq('id', id);
  }

  Future<void> _unsetDefaultTemplates() async {
    await client
        .from('report_card_templates')
        .update({'is_default': false})
        .eq('tenant_id', requireTenantId)
        .eq('is_default', true);
  }

  // ==========================================================================
  // REPORT CARDS (CRUD + GENERATION)
  // ==========================================================================

  static const _reportCardSelect = '''
    *,
    student:students(
      id, admission_number, roll_number,
      user:users(full_name)
    ),
    academic_year:academic_years(name),
    term:terms(name),
    template:report_card_templates(name),
    report_card_comments(*, commenter:users!commented_by(full_name)),
    report_card_skills(*),
    report_card_activities(*)
  ''';

  Future<List<ReportCardFull>> getReportCards(
      ReportCardFullFilter filter) async {
    var query = client
        .from('report_cards')
        .select(_reportCardSelect)
        .eq('tenant_id', requireTenantId);

    if (filter.academicYearId != null) {
      query = query.eq('academic_year_id', filter.academicYearId!);
    }
    if (filter.termId != null) {
      query = query.eq('term_id', filter.termId!);
    }
    if (filter.studentId != null) {
      query = query.eq('student_id', filter.studentId!);
    }
    if (filter.status != null) {
      query = query.eq('status', filter.status!);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(filter.offset, filter.offset + filter.limit - 1);

    return (response as List)
        .map((json) => ReportCardFull.fromJson(json))
        .toList();
  }

  Future<ReportCardFull?> getReportCardById(String id) async {
    final response = await client
        .from('report_cards')
        .select(_reportCardSelect)
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return ReportCardFull.fromJson(response);
  }

  Future<List<ReportCardFull>> getStudentReportCards(String studentId) async {
    final response = await client
        .from('report_cards')
        .select(_reportCardSelect)
        .eq('student_id', studentId)
        .eq('tenant_id', requireTenantId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ReportCardFull.fromJson(json))
        .toList();
  }

  /// Generate a single report card: pulls marks, attendance, assembles data.
  Future<ReportCardFull> generateReportCard({
    required String studentId,
    required String academicYearId,
    required String termId,
    required String templateId,
    required List<String> examIds,
  }) async {
    // 1. Get student details
    final studentResp = await client
        .from('students')
        .select('''
          id, admission_number, roll_number, photo_url,
          user:users(full_name),
          student_enrollments!inner(
            section_id, roll_number,
            section:sections(id, name, class:classes(id, name))
          )
        ''')
        .eq('id', studentId)
        .eq('student_enrollments.academic_year_id', academicYearId)
        .single();

    final studentUser = studentResp['user'] as Map<String, dynamic>?;
    final enrollments = studentResp['student_enrollments'] as List?;
    final enrollment =
        enrollments?.isNotEmpty == true ? enrollments!.first : null;
    final section = enrollment?['section'] as Map<String, dynamic>?;
    final cls = section?['class'] as Map<String, dynamic>?;

    // 2. Get academic year + term names
    final ayResp = await client
        .from('academic_years')
        .select('name')
        .eq('id', academicYearId)
        .single();
    final termResp = await client
        .from('terms')
        .select('name')
        .eq('id', termId)
        .single();

    // 3. Get grading scale from template
    final template = await getTemplateById(templateId);
    GradingScale? gradingScale = template?.gradingScale;
    if (gradingScale == null && template?.gradingScaleId != null) {
      final scaleResp = await client
          .from('grading_scales')
          .select()
          .eq('id', template!.gradingScaleId!)
          .maybeSingle();
      if (scaleResp != null) {
        gradingScale = GradingScale.fromJson(scaleResp);
      }
    }

    // 4. Pull marks for the selected exams
    final marksResp = await client
        .from('marks')
        .select('''
          id, marks_obtained, is_absent, remarks,
          exam_subject:exam_subjects(
            id, exam_id, max_marks, passing_marks, weightage,
            subject:subjects(id, name, code)
          )
        ''')
        .eq('student_id', studentId)
        .eq('tenant_id', requireTenantId);

    // Filter marks by exam IDs
    final allMarks = marksResp as List;
    final relevantMarks = examIds.isEmpty
        ? allMarks
        : allMarks.where((m) {
            final es = m['exam_subject'] as Map<String, dynamic>?;
            final eid = es?['exam_id'] as String?;
            return eid != null && examIds.contains(eid);
          }).toList();

    // 5. Aggregate subject grades
    final subjectAgg = <String, _SubjectAgg>{};
    for (final m in relevantMarks) {
      final es = m['exam_subject'] as Map<String, dynamic>?;
      if (es == null) continue;
      final subj = es['subject'] as Map<String, dynamic>?;
      if (subj == null) continue;
      final sid = subj['id'] as String;
      final sName = subj['name'] as String;
      final sCode = subj['code'] as String?;
      final marks = (m['marks_obtained'] as num?)?.toDouble();
      final maxM = (es['max_marks'] as num?)?.toDouble() ?? 100;
      final passM = (es['passing_marks'] as num?)?.toDouble() ?? 33;
      final isAbsent = m['is_absent'] as bool? ?? false;

      subjectAgg.putIfAbsent(
          sid,
          () => _SubjectAgg(
                subjectId: sid,
                subjectName: sName,
                subjectCode: sCode,
              ));
      subjectAgg[sid]!.addMarks(
        marks: isAbsent ? 0 : (marks ?? 0),
        maxMarks: maxM,
        passingMarks: passM,
        isAbsent: isAbsent,
      );
    }

    final grades = subjectAgg.values.map((a) {
      final pct = a.maxMarks > 0 ? (a.totalMarks / a.maxMarks) * 100 : 0.0;
      final grade = gradingScale?.gradeFor(pct) ?? _defaultGrade(pct);
      return SubjectGrade(
        subjectId: a.subjectId,
        subjectName: a.subjectName,
        marksObtained: a.totalMarks,
        maxMarks: a.maxMarks,
        percentage: pct,
        grade: grade,
        remarks: a.isAbsent ? 'Absent' : null,
      );
    }).toList();

    final double totalObtained =
        grades.fold(0, (s, g) => s + (g.marksObtained ?? 0));
    final double totalMax = grades.fold(0, (s, g) => s + (g.maxMarks ?? 0));
    final double overallPct = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0;
    final String overallGrade =
        gradingScale?.gradeFor(overallPct) ?? _defaultGrade(overallPct);

    // 6. Pull attendance for the term period
    final termDates = await client
        .from('terms')
        .select('start_date, end_date')
        .eq('id', termId)
        .single();

    int daysPresent = 0;
    int totalDays = 0;
    if (termDates['start_date'] != null && termDates['end_date'] != null) {
      final attResp = await client
          .from('attendance')
          .select('status')
          .eq('student_id', studentId)
          .eq('tenant_id', requireTenantId)
          .gte('date', termDates['start_date'])
          .lte('date', termDates['end_date']);

      totalDays = (attResp as List).length;
      daysPresent = attResp
          .where((a) =>
              a['status'] == 'present' ||
              a['status'] == 'late' ||
              a['status'] == 'half_day')
          .length;
    }

    final double attendancePct = totalDays > 0 ? (daysPresent / totalDays) * 100 : 0;

    // 7. Calculate rank (by total percentage within the same section)
    int rank = 0;
    int totalStudents = 0;
    if (enrollment?['section_id'] != null) {
      // Get all students in the section
      final sectionStudents = await client
          .from('student_enrollments')
          .select('student_id')
          .eq('section_id', enrollment!['section_id'])
          .eq('academic_year_id', academicYearId);

      totalStudents = (sectionStudents as List).length;

      // Simplified rank: count students with higher percentage
      // In production, this would use the mv_student_performance view
      rank = 1; // Placeholder; full ranking requires class-wide marks query
    }

    // 8. Assemble data snapshot
    final dataSnapshot = ReportCardData(
      studentId: studentId,
      studentName: studentUser?['full_name'] ?? 'Unknown',
      studentPhoto: studentResp['photo_url'] as String?,
      rollNumber:
          enrollment?['roll_number'] ?? studentResp['roll_number'] ?? '',
      className: cls?['name'] ?? '',
      sectionName: section?['name'] ?? '',
      academicYear: ayResp['name'] as String,
      term: termResp['name'] as String,
      grades: grades,
      overallPercentage: overallPct,
      overallGrade: overallGrade,
      rank: rank,
      totalStudents: totalStudents,
      attendancePercentage: attendancePct,
      daysPresent: daysPresent,
      totalDays: totalDays,
    );

    // 9. Upsert the report card record
    final response = await client
        .from('report_cards')
        .upsert(
          {
            'tenant_id': requireTenantId,
            'student_id': studentId,
            'academic_year_id': academicYearId,
            'term_id': termId,
            'template_id': templateId,
            'exam_ids': examIds,
            'data': dataSnapshot.toJson(),
            'status': 'generated',
            'generated_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'tenant_id,student_id,academic_year_id,term_id',
        )
        .select(_reportCardSelect)
        .single();

    return ReportCardFull.fromJson(response);
  }

  /// Bulk generate for all students in a section.
  Future<List<ReportCardFull>> bulkGenerateForClass({
    required String sectionId,
    required String academicYearId,
    required String termId,
    required String templateId,
    required List<String> examIds,
    void Function(int current, int total, String? studentName)? onProgress,
  }) async {
    // Get students in section
    final enrollResp = await client
        .from('student_enrollments')
        .select('''
          student_id,
          student:students(id, user:users(full_name))
        ''')
        .eq('section_id', sectionId)
        .eq('academic_year_id', academicYearId);

    final enrollments = enrollResp as List;
    final reports = <ReportCardFull>[];

    for (var i = 0; i < enrollments.length; i++) {
      final studentId = enrollments[i]['student_id'] as String;
      final student = enrollments[i]['student'] as Map<String, dynamic>?;
      final user = student?['user'] as Map<String, dynamic>?;
      final name = user?['full_name'] as String?;

      onProgress?.call(i + 1, enrollments.length, name);

      try {
        final report = await generateReportCard(
          studentId: studentId,
          academicYearId: academicYearId,
          termId: termId,
          templateId: templateId,
          examIds: examIds,
        );
        reports.add(report);
      } catch (e) {
        // Continue with next student on error
        continue;
      }
    }

    return reports;
  }

  /// Publish report cards (change status to published)
  Future<void> publishReportCards(List<String> reportIds) async {
    await client
        .from('report_cards')
        .update({
          'status': 'published',
          'published_at': DateTime.now().toIso8601String(),
        })
        .inFilter('id', reportIds);
  }

  /// Mark as reviewed
  Future<void> reviewReportCard(String reportId) async {
    await client.from('report_cards').update({
      'status': 'reviewed',
      'reviewed_by': requireUserId,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', reportId);
  }

  /// Update PDF URL after generation
  Future<void> updatePdfUrl(String reportId, String pdfUrl) async {
    await client
        .from('report_cards')
        .update({'pdf_url': pdfUrl})
        .eq('id', reportId);
  }

  Future<void> deleteReportCard(String id) async {
    await client.from('report_cards').delete().eq('id', id);
  }

  // ==========================================================================
  // COMMENTS
  // ==========================================================================

  Future<ReportCardComment> upsertComment({
    required String reportCardId,
    required String commentType,
    required String commentText,
    bool isAiGenerated = false,
  }) async {
    final response = await client
        .from('report_card_comments')
        .upsert(
          {
            'report_card_id': reportCardId,
            'comment_type': commentType,
            'commented_by': requireUserId,
            'comment_text': commentText,
            'is_ai_generated': isAiGenerated,
          },
          onConflict: 'report_card_id,comment_type',
        )
        .select()
        .single();
    return ReportCardComment.fromJson(response);
  }

  Future<void> deleteComment(String id) async {
    await client.from('report_card_comments').delete().eq('id', id);
  }

  // ==========================================================================
  // SKILLS
  // ==========================================================================

  Future<ReportCardSkill> upsertSkill({
    required String reportCardId,
    required String skillCategory,
    required int rating,
    String? comments,
  }) async {
    final response = await client
        .from('report_card_skills')
        .upsert(
          {
            'report_card_id': reportCardId,
            'skill_category': skillCategory,
            'rating': rating,
            'comments': comments,
          },
          onConflict: 'report_card_id,skill_category',
        )
        .select()
        .single();
    return ReportCardSkill.fromJson(response);
  }

  Future<void> bulkUpsertSkills(
      String reportCardId, List<Map<String, dynamic>> skills) async {
    final records = skills.map((s) => {
          ...s,
          'report_card_id': reportCardId,
        }).toList();

    await client
        .from('report_card_skills')
        .upsert(records, onConflict: 'report_card_id,skill_category');
  }

  // ==========================================================================
  // ACTIVITIES
  // ==========================================================================

  Future<ReportCardActivity> addActivity({
    required String reportCardId,
    required String activityType,
    required String activityName,
    String? achievement,
    String? grade,
  }) async {
    final response = await client
        .from('report_card_activities')
        .insert({
          'report_card_id': reportCardId,
          'activity_type': activityType,
          'activity_name': activityName,
          'achievement': achievement,
          'grade': grade,
        })
        .select()
        .single();
    return ReportCardActivity.fromJson(response);
  }

  Future<void> updateActivity(
      String id, Map<String, dynamic> data) async {
    await client.from('report_card_activities').update(data).eq('id', id);
  }

  Future<void> deleteActivity(String id) async {
    await client.from('report_card_activities').delete().eq('id', id);
  }

  // ==========================================================================
  // DASHBOARD SUMMARY
  // ==========================================================================

  Future<List<ReportCardSummary>> getDashboardSummary({
    required String academicYearId,
    required String termId,
  }) async {
    final response = await client
        .from('v_report_card_summary')
        .select()
        .eq('tenant_id', requireTenantId)
        .eq('academic_year_id', academicYearId)
        .eq('term_id', termId)
        .order('class_name');

    return (response as List)
        .map((json) => ReportCardSummary.fromJson(json))
        .toList();
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  String _defaultGrade(double percentage) {
    if (percentage >= 91) return 'A1';
    if (percentage >= 81) return 'A2';
    if (percentage >= 71) return 'B1';
    if (percentage >= 61) return 'B2';
    if (percentage >= 51) return 'C1';
    if (percentage >= 41) return 'C2';
    if (percentage >= 33) return 'D';
    return 'E';
  }
}

/// Internal aggregator for subject marks across multiple exams.
class _SubjectAgg {
  final String subjectId;
  final String subjectName;
  final String? subjectCode;
  double totalMarks = 0;
  double maxMarks = 0;
  double passingMarks = 0;
  bool isAbsent = false;
  int examCount = 0;

  _SubjectAgg({
    required this.subjectId,
    required this.subjectName,
    this.subjectCode,
  });

  void addMarks({
    required double marks,
    required double maxMarks,
    required double passingMarks,
    required bool isAbsent,
  }) {
    totalMarks += marks;
    this.maxMarks += maxMarks;
    this.passingMarks += passingMarks;
    if (isAbsent) this.isAbsent = true;
    examCount++;
  }
}
