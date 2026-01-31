import '../models/report_card.dart';
import 'base_repository.dart';

class ReportCardRepository extends BaseRepository {
  ReportCardRepository(super.client);

  Future<List<ReportCard>> getReportCards({
    String? academicYearId,
    String? termId,
    String? classId,
    String? sectionId,
    String? studentId,
    String? status,
  }) async {
    var query = client
        .from('report_cards')
        .select('''
          *,
          student:students(
            roll_number,
            user:users(full_name),
            section:sections(
              name,
              class:classes(name)
            )
          ),
          academic_year:academic_years(name),
          term:terms(name)
        ''')
        .eq('tenant_id', tenantId!);

    if (academicYearId != null) {
      query = query.eq('academic_year_id', academicYearId);
    }
    if (termId != null) {
      query = query.eq('term_id', termId);
    }
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('created_at', ascending: false);

    List<ReportCard> results = (response as List)
        .map((json) => ReportCard.fromJson(json))
        .toList();

    // Filter by class/section if needed (since these are nested)
    if (classId != null || sectionId != null) {
      results = results.where((r) {
        if (sectionId != null && r.sectionName != sectionId) return false;
        if (classId != null && r.className != classId) return false;
        return true;
      }).toList();
    }

    return results;
  }

  Future<ReportCard?> getReportCardById(String id) async {
    final response = await client
        .from('report_cards')
        .select('''
          *,
          student:students(
            roll_number,
            user:users(full_name),
            section:sections(
              name,
              class:classes(name)
            )
          ),
          academic_year:academic_years(name),
          term:terms(name)
        ''')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return ReportCard.fromJson(response);
  }

  Future<ReportCard?> getStudentReportCard({
    required String studentId,
    required String academicYearId,
    required String termId,
  }) async {
    final response = await client
        .from('report_cards')
        .select('''
          *,
          student:students(
            roll_number,
            user:users(full_name),
            section:sections(
              name,
              class:classes(name)
            )
          ),
          academic_year:academic_years(name),
          term:terms(name)
        ''')
        .eq('student_id', studentId)
        .eq('academic_year_id', academicYearId)
        .eq('term_id', termId)
        .maybeSingle();

    if (response == null) return null;
    return ReportCard.fromJson(response);
  }

  Future<ReportCardData> generateReportCardData({
    required String studentId,
    required String academicYearId,
    required String termId,
  }) async {
    // Get student info
    final studentResponse = await client
        .from('students')
        .select('''
          id,
          roll_number,
          photo_url,
          user:users(full_name),
          section:sections(
            id,
            name,
            class:classes(id, name)
          )
        ''')
        .eq('id', studentId)
        .single();

    // Get academic year and term info
    final academicYearResponse = await client
        .from('academic_years')
        .select('name')
        .eq('id', academicYearId)
        .single();

    final termResponse = await client
        .from('terms')
        .select('name')
        .eq('id', termId)
        .single();

    // Get exam results for this student
    final examsResponse = await client
        .from('exam_results')
        .select('''
          marks_obtained,
          exam:exams(
            id,
            max_marks,
            subject:subjects(id, name)
          )
        ''')
        .eq('student_id', studentId)
        .eq('tenant_id', tenantId!);

    // Get attendance
    final attendanceResponse = await client
        .from('attendance')
        .select('status')
        .eq('student_id', studentId)
        .eq('tenant_id', tenantId!);

    // Process grades by subject
    final subjectGrades = <String, SubjectGrade>{};
    double totalMarks = 0;
    double totalMaxMarks = 0;

    for (final result in examsResponse as List) {
      final exam = result['exam'];
      final subject = exam['subject'];
      final subjectId = subject['id'];
      final subjectName = subject['name'];
      final marksObtained = (result['marks_obtained'] as num?)?.toDouble() ?? 0;
      final maxMarks = (exam['max_marks'] as num?)?.toDouble() ?? 100;

      if (subjectGrades.containsKey(subjectId)) {
        // Aggregate marks for same subject across exams
        final existing = subjectGrades[subjectId]!;
        final newMarks = (existing.marksObtained ?? 0) + marksObtained;
        final newMax = (existing.maxMarks ?? 0) + maxMarks;
        subjectGrades[subjectId] = SubjectGrade(
          subjectId: subjectId,
          subjectName: subjectName,
          marksObtained: newMarks,
          maxMarks: newMax,
          percentage: (newMarks / newMax) * 100,
          grade: _calculateGrade((newMarks / newMax) * 100),
        );
      } else {
        subjectGrades[subjectId] = SubjectGrade(
          subjectId: subjectId,
          subjectName: subjectName,
          marksObtained: marksObtained,
          maxMarks: maxMarks,
          percentage: (marksObtained / maxMarks) * 100,
          grade: _calculateGrade((marksObtained / maxMarks) * 100),
        );
      }

      totalMarks += marksObtained;
      totalMaxMarks += maxMarks;
    }

    // Calculate attendance
    int present = 0;
    int total = (attendanceResponse as List).length;
    for (final att in attendanceResponse) {
      if (att['status'] == 'present') present++;
    }

    final overallPercentage =
        totalMaxMarks > 0 ? (totalMarks / totalMaxMarks) * 100 : 0.0;
    final attendancePercentage = total > 0 ? (present / total) * 100 : 0.0;

    final section = studentResponse['section'];
    final studentClass = section?['class'];

    return ReportCardData(
      studentId: studentId,
      studentName: studentResponse['user']?['full_name'] ?? 'Unknown',
      studentPhoto: studentResponse['photo_url'],
      rollNumber: studentResponse['roll_number'] ?? '',
      className: studentClass?['name'] ?? '',
      sectionName: section?['name'] ?? '',
      academicYear: academicYearResponse['name'],
      term: termResponse['name'],
      grades: subjectGrades.values.toList(),
      overallPercentage: overallPercentage,
      overallGrade: _calculateGrade(overallPercentage),
      rank: 0, // Would need to calculate based on class
      totalStudents: 0,
      attendancePercentage: attendancePercentage,
      daysPresent: present,
      totalDays: total,
    );
  }

  String _calculateGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B+';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C';
    if (percentage >= 40) return 'D';
    return 'F';
  }

  Future<ReportCard> createReportCard({
    required String studentId,
    required String academicYearId,
    required String termId,
    required String templateId,
    required Map<String, dynamic> data,
  }) async {
    final response = await client
        .from('report_cards')
        .insert({
          'tenant_id': tenantId,
          'student_id': studentId,
          'academic_year_id': academicYearId,
          'term_id': termId,
          'template_id': templateId,
          'data': data,
          'status': 'draft',
        })
        .select()
        .single();

    return ReportCard.fromJson(response);
  }

  Future<void> updateReportCard(
    String id, {
    Map<String, dynamic>? data,
    String? status,
    String? pdfUrl,
  }) async {
    final updates = <String, dynamic>{};

    if (data != null) updates['data'] = data;
    if (status != null) {
      updates['status'] = status;
      if (status == 'generated') {
        updates['generated_at'] = DateTime.now().toIso8601String();
      }
      if (status == 'published') {
        updates['published_at'] = DateTime.now().toIso8601String();
      }
    }
    if (pdfUrl != null) updates['pdf_url'] = pdfUrl;

    await client.from('report_cards').update(updates).eq('id', id);
  }

  Future<void> deleteReportCard(String id) async {
    await client.from('report_cards').delete().eq('id', id);
  }

  // Bulk operations
  Future<List<ReportCard>> generateBulkReportCards({
    required String sectionId,
    required String academicYearId,
    required String termId,
    required String templateId,
  }) async {
    // Get all students in the section
    final studentsResponse = await client
        .from('students')
        .select('id')
        .eq('section_id', sectionId)
        .eq('tenant_id', tenantId!);

    final reports = <ReportCard>[];

    for (final student in studentsResponse as List) {
      final studentId = student['id'];

      // Check if report already exists
      final existing = await getStudentReportCard(
        studentId: studentId,
        academicYearId: academicYearId,
        termId: termId,
      );

      if (existing != null) {
        reports.add(existing);
        continue;
      }

      // Generate report data
      final data = await generateReportCardData(
        studentId: studentId,
        academicYearId: academicYearId,
        termId: termId,
      );

      // Create report card
      final report = await createReportCard(
        studentId: studentId,
        academicYearId: academicYearId,
        termId: termId,
        templateId: templateId,
        data: data.toJson(),
      );

      reports.add(report);
    }

    return reports;
  }

  Future<void> publishBulkReportCards(List<String> reportIds) async {
    await client
        .from('report_cards')
        .update({
          'status': 'published',
          'published_at': DateTime.now().toIso8601String(),
        })
        .inFilter('id', reportIds);
  }

  // Templates
  Future<List<ReportCardTemplate>> getTemplates() async {
    final response = await client
        .from('report_card_templates')
        .select()
        .eq('tenant_id', tenantId!)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ReportCardTemplate.fromJson(json))
        .toList();
  }

  Future<ReportCardTemplate?> getTemplateById(String id) async {
    final response = await client
        .from('report_card_templates')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return ReportCardTemplate.fromJson(response);
  }

  Future<ReportCardTemplate?> getDefaultTemplate() async {
    final response = await client
        .from('report_card_templates')
        .select()
        .eq('tenant_id', tenantId!)
        .eq('is_default', true)
        .maybeSingle();

    if (response == null) return null;
    return ReportCardTemplate.fromJson(response);
  }

  Future<ReportCardTemplate> createTemplate({
    required String name,
    String? description,
    required Map<String, dynamic> layout,
    required Map<String, dynamic> styling,
    required List<String> sections,
    bool includesAttendance = true,
    bool includesGrades = true,
    bool includesRemarks = true,
    bool includesBehavior = false,
    bool isDefault = false,
  }) async {
    // If this is default, unset other defaults
    if (isDefault) {
      await client
          .from('report_card_templates')
          .update({'is_default': false})
          .eq('tenant_id', tenantId!)
          .eq('is_default', true);
    }

    final response = await client
        .from('report_card_templates')
        .insert({
          'tenant_id': tenantId,
          'name': name,
          'description': description,
          'layout': layout,
          'styling': styling,
          'sections': sections,
          'includes_attendance': includesAttendance,
          'includes_grades': includesGrades,
          'includes_remarks': includesRemarks,
          'includes_behavior': includesBehavior,
          'is_default': isDefault,
        })
        .select()
        .single();

    return ReportCardTemplate.fromJson(response);
  }

  Future<void> updateTemplate(
    String id, {
    String? name,
    String? description,
    Map<String, dynamic>? layout,
    Map<String, dynamic>? styling,
    List<String>? sections,
    bool? isDefault,
  }) async {
    // If setting as default, unset other defaults first
    if (isDefault == true) {
      await client
          .from('report_card_templates')
          .update({'is_default': false})
          .eq('tenant_id', tenantId!)
          .eq('is_default', true);
    }

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (layout != null) updates['layout'] = layout;
    if (styling != null) updates['styling'] = styling;
    if (sections != null) updates['sections'] = sections;
    if (isDefault != null) updates['is_default'] = isDefault;

    await client.from('report_card_templates').update(updates).eq('id', id);
  }

  Future<void> deleteTemplate(String id) async {
    await client.from('report_card_templates').delete().eq('id', id);
  }
}
