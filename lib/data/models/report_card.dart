// Report Card Model

class ReportCard {
  final String id;
  final String tenantId;
  final String studentId;
  final String academicYearId;
  final String termId;
  final String templateId;
  final Map<String, dynamic> data;
  final String? pdfUrl;
  final String status; // draft, generated, published
  final DateTime? generatedAt;
  final DateTime? publishedAt;
  final DateTime createdAt;

  // Joined data
  final String? studentName;
  final String? studentRollNumber;
  final String? className;
  final String? sectionName;
  final String? academicYearName;
  final String? termName;

  const ReportCard({
    required this.id,
    required this.tenantId,
    required this.studentId,
    required this.academicYearId,
    required this.termId,
    required this.templateId,
    required this.data,
    this.pdfUrl,
    required this.status,
    this.generatedAt,
    this.publishedAt,
    required this.createdAt,
    this.studentName,
    this.studentRollNumber,
    this.className,
    this.sectionName,
    this.academicYearName,
    this.termName,
  });

  factory ReportCard.fromJson(Map<String, dynamic> json) {
    return ReportCard(
      id: json['id'],
      tenantId: json['tenant_id'],
      studentId: json['student_id'],
      academicYearId: json['academic_year_id'],
      termId: json['term_id'],
      templateId: json['template_id'],
      data: json['data'] ?? {},
      pdfUrl: json['pdf_url'],
      status: json['status'] ?? 'draft',
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'])
          : null,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      studentName: json['student']?['user']?['full_name'] ??
          json['student']?['full_name'] ??
          json['student_name'],
      studentRollNumber:
          json['student']?['roll_number'] ?? json['student_roll_number'],
      className: json['student']?['section']?['class']?['name'] ??
          json['class_name'],
      sectionName:
          json['student']?['section']?['name'] ?? json['section_name'],
      academicYearName:
          json['academic_year']?['name'] ?? json['academic_year_name'],
      termName: json['term']?['name'] ?? json['term_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'student_id': studentId,
      'academic_year_id': academicYearId,
      'term_id': termId,
      'template_id': templateId,
      'data': data,
      'status': status,
    };
  }

  bool get isDraft => status == 'draft';
  bool get isGenerated => status == 'generated';
  bool get isPublished => status == 'published';

  String get statusDisplay {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'generated':
        return 'Generated';
      case 'published':
        return 'Published';
      default:
        return status;
    }
  }
}

class ReportCardTemplate {
  final String id;
  final String tenantId;
  final String name;
  final String? description;
  final Map<String, dynamic> layout;
  final Map<String, dynamic> styling;
  final List<String> sections;
  final bool includesAttendance;
  final bool includesGrades;
  final bool includesRemarks;
  final bool includesBehavior;
  final bool isDefault;
  final DateTime createdAt;

  const ReportCardTemplate({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description,
    required this.layout,
    required this.styling,
    required this.sections,
    this.includesAttendance = true,
    this.includesGrades = true,
    this.includesRemarks = true,
    this.includesBehavior = false,
    this.isDefault = false,
    required this.createdAt,
  });

  factory ReportCardTemplate.fromJson(Map<String, dynamic> json) {
    return ReportCardTemplate(
      id: json['id'],
      tenantId: json['tenant_id'],
      name: json['name'],
      description: json['description'],
      layout: json['layout'] ?? {},
      styling: json['styling'] ?? {},
      sections: List<String>.from(json['sections'] ?? []),
      includesAttendance: json['includes_attendance'] ?? true,
      includesGrades: json['includes_grades'] ?? true,
      includesRemarks: json['includes_remarks'] ?? true,
      includesBehavior: json['includes_behavior'] ?? false,
      isDefault: json['is_default'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
    };
  }
}

class SubjectGrade {
  final String subjectId;
  final String subjectName;
  final double? marksObtained;
  final double? maxMarks;
  final double? percentage;
  final String? grade;
  final String? remarks;

  const SubjectGrade({
    required this.subjectId,
    required this.subjectName,
    this.marksObtained,
    this.maxMarks,
    this.percentage,
    this.grade,
    this.remarks,
  });

  factory SubjectGrade.fromJson(Map<String, dynamic> json) {
    return SubjectGrade(
      subjectId: json['subject_id'],
      subjectName: json['subject_name'],
      marksObtained: (json['marks_obtained'] as num?)?.toDouble(),
      maxMarks: (json['max_marks'] as num?)?.toDouble(),
      percentage: (json['percentage'] as num?)?.toDouble(),
      grade: json['grade'],
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject_id': subjectId,
      'subject_name': subjectName,
      'marks_obtained': marksObtained,
      'max_marks': maxMarks,
      'percentage': percentage,
      'grade': grade,
      'remarks': remarks,
    };
  }
}

class ReportCardData {
  final String studentId;
  final String studentName;
  final String? studentPhoto;
  final String rollNumber;
  final String className;
  final String sectionName;
  final String academicYear;
  final String term;
  final List<SubjectGrade> grades;
  final double overallPercentage;
  final String overallGrade;
  final int rank;
  final int totalStudents;
  final double attendancePercentage;
  final int daysPresent;
  final int totalDays;
  final String? principalRemarks;
  final String? classTeacherRemarks;
  final Map<String, String> behaviorRatings;
  final Map<String, String> coScholasticGrades;

  const ReportCardData({
    required this.studentId,
    required this.studentName,
    this.studentPhoto,
    required this.rollNumber,
    required this.className,
    required this.sectionName,
    required this.academicYear,
    required this.term,
    required this.grades,
    required this.overallPercentage,
    required this.overallGrade,
    required this.rank,
    required this.totalStudents,
    required this.attendancePercentage,
    required this.daysPresent,
    required this.totalDays,
    this.principalRemarks,
    this.classTeacherRemarks,
    this.behaviorRatings = const {},
    this.coScholasticGrades = const {},
  });

  factory ReportCardData.fromJson(Map<String, dynamic> json) {
    return ReportCardData(
      studentId: json['student_id'],
      studentName: json['student_name'],
      studentPhoto: json['student_photo'],
      rollNumber: json['roll_number'],
      className: json['class_name'],
      sectionName: json['section_name'],
      academicYear: json['academic_year'],
      term: json['term'],
      grades: (json['grades'] as List?)
              ?.map((g) => SubjectGrade.fromJson(g))
              .toList() ??
          [],
      overallPercentage: (json['overall_percentage'] as num?)?.toDouble() ?? 0,
      overallGrade: json['overall_grade'] ?? '',
      rank: json['rank'] ?? 0,
      totalStudents: json['total_students'] ?? 0,
      attendancePercentage:
          (json['attendance_percentage'] as num?)?.toDouble() ?? 0,
      daysPresent: json['days_present'] ?? 0,
      totalDays: json['total_days'] ?? 0,
      principalRemarks: json['principal_remarks'],
      classTeacherRemarks: json['class_teacher_remarks'],
      behaviorRatings:
          Map<String, String>.from(json['behavior_ratings'] ?? {}),
      coScholasticGrades:
          Map<String, String>.from(json['co_scholastic_grades'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'student_name': studentName,
      'student_photo': studentPhoto,
      'roll_number': rollNumber,
      'class_name': className,
      'section_name': sectionName,
      'academic_year': academicYear,
      'term': term,
      'grades': grades.map((g) => g.toJson()).toList(),
      'overall_percentage': overallPercentage,
      'overall_grade': overallGrade,
      'rank': rank,
      'total_students': totalStudents,
      'attendance_percentage': attendancePercentage,
      'days_present': daysPresent,
      'total_days': totalDays,
      'principal_remarks': principalRemarks,
      'class_teacher_remarks': classTeacherRemarks,
      'behavior_ratings': behaviorRatings,
      'co_scholastic_grades': coScholasticGrades,
    };
  }
}

class ReportCardFilter {
  final String? academicYearId;
  final String? termId;
  final String? classId;
  final String? sectionId;
  final String? studentId;
  final String? status;

  const ReportCardFilter({
    this.academicYearId,
    this.termId,
    this.classId,
    this.sectionId,
    this.studentId,
    this.status,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportCardFilter &&
          other.academicYearId == academicYearId &&
          other.termId == termId &&
          other.classId == classId &&
          other.sectionId == sectionId &&
          other.studentId == studentId &&
          other.status == status;

  @override
  int get hashCode => Object.hash(
        academicYearId,
        termId,
        classId,
        sectionId,
        studentId,
        status,
      );
}
