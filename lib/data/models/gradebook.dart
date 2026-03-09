import 'dart:math' as math;

/// A grading category (e.g. Homework 20%, Quizzes 30%, Exams 50%).
class GradingCategory {
  final String id;
  final String tenantId;
  final String? classSubjectId;
  final String name;
  final double weight;
  final int dropLowest;
  final DateTime createdAt;
  final List<GradeEntry> entries;

  const GradingCategory({
    required this.id,
    required this.tenantId,
    this.classSubjectId,
    required this.name,
    required this.weight,
    this.dropLowest = 0,
    required this.createdAt,
    this.entries = const [],
  });

  factory GradingCategory.fromJson(Map<String, dynamic> json) {
    return GradingCategory(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      classSubjectId: json['class_subject_id'] as String?,
      name: json['name'] as String,
      weight: (json['weight'] as num).toDouble(),
      dropLowest: (json['drop_lowest'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      if (classSubjectId != null) 'class_subject_id': classSubjectId,
      'name': name,
      'weight': weight,
      'drop_lowest': dropLowest,
    };
  }

  GradingCategory copyWith({
    String? id,
    String? tenantId,
    String? classSubjectId,
    String? name,
    double? weight,
    int? dropLowest,
    DateTime? createdAt,
    List<GradeEntry>? entries,
  }) {
    return GradingCategory(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      classSubjectId: classSubjectId ?? this.classSubjectId,
      name: name ?? this.name,
      weight: weight ?? this.weight,
      dropLowest: dropLowest ?? this.dropLowest,
      createdAt: createdAt ?? this.createdAt,
      entries: entries ?? this.entries,
    );
  }

  /// Earned points for a specific student in this category,
  /// applying drop-lowest logic.
  double earnedPointsForStudent(String studentId) {
    final studentEntries = entries
        .where((e) => e.studentId == studentId && e.pointsEarned != null)
        .toList();

    if (studentEntries.isEmpty) return 0;

    if (dropLowest > 0 && studentEntries.length > dropLowest) {
      final sorted = [...studentEntries]
        ..sort((a, b) {
          final aScore = a.pointsEarned! / a.pointsPossible;
          final bScore = b.pointsEarned! / b.pointsPossible;
          return aScore.compareTo(bScore);
        });
      final kept = sorted.sublist(math.min(dropLowest, sorted.length - 1));
      return kept.fold(0.0, (sum, e) => sum + e.pointsEarned!);
    }

    return studentEntries.fold(0.0, (sum, e) => sum + e.pointsEarned!);
  }

  /// Max possible points for a specific student after drop-lowest.
  double maxPointsForStudent(String studentId) {
    final studentEntries = entries
        .where((e) => e.studentId == studentId)
        .toList();

    if (studentEntries.isEmpty) return 0;

    if (dropLowest > 0 && studentEntries.length > dropLowest) {
      final sorted = [...studentEntries]
        ..sort((a, b) {
          final aScore =
              a.pointsEarned != null ? a.pointsEarned! / a.pointsPossible : 0;
          final bScore =
              b.pointsEarned != null ? b.pointsEarned! / b.pointsPossible : 0;
          return aScore.compareTo(bScore);
        });
      final kept = sorted.sublist(math.min(dropLowest, sorted.length - 1));
      return kept.fold(0.0, (sum, e) => sum + e.pointsPossible);
    }

    return studentEntries.fold(0.0, (sum, e) => sum + e.pointsPossible);
  }

  /// Raw percentage for a specific student in this category.
  double percentageForStudent(String studentId) {
    final max = maxPointsForStudent(studentId);
    if (max <= 0) return 0;
    return (earnedPointsForStudent(studentId) / max * 100).clamp(0, 100);
  }
}

/// A single grade entry for one student on one assessment/assignment.
class GradeEntry {
  final String id;
  final String tenantId;
  final String categoryId;
  final String studentId;
  final String title;
  final double? pointsEarned;
  final double pointsPossible;
  final DateTime gradedAt;
  final String? notes;
  final DateTime createdAt;

  const GradeEntry({
    required this.id,
    required this.tenantId,
    required this.categoryId,
    required this.studentId,
    required this.title,
    this.pointsEarned,
    required this.pointsPossible,
    required this.gradedAt,
    this.notes,
    required this.createdAt,
  });

  factory GradeEntry.fromJson(Map<String, dynamic> json) {
    return GradeEntry(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      categoryId: json['category_id'] as String,
      studentId: json['student_id'] as String,
      title: json['title'] as String,
      pointsEarned: json['points_earned'] != null
          ? (json['points_earned'] as num).toDouble()
          : null,
      pointsPossible: (json['points_possible'] as num).toDouble(),
      gradedAt: json['graded_at'] != null
          ? DateTime.parse(json['graded_at'] as String)
          : DateTime.now(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'category_id': categoryId,
      'student_id': studentId,
      'title': title,
      if (pointsEarned != null) 'points_earned': pointsEarned,
      'points_possible': pointsPossible,
      'graded_at':
          '${gradedAt.year}-${gradedAt.month.toString().padLeft(2, '0')}-${gradedAt.day.toString().padLeft(2, '0')}',
      if (notes != null) 'notes': notes,
    };
  }

  GradeEntry copyWith({
    String? id,
    String? tenantId,
    String? categoryId,
    String? studentId,
    String? title,
    double? pointsEarned,
    double? pointsPossible,
    DateTime? gradedAt,
    String? notes,
    DateTime? createdAt,
  }) {
    return GradeEntry(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      categoryId: categoryId ?? this.categoryId,
      studentId: studentId ?? this.studentId,
      title: title ?? this.title,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      pointsPossible: pointsPossible ?? this.pointsPossible,
      gradedAt: gradedAt ?? this.gradedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Raw percentage for this entry (null if not yet graded).
  double? get percentage =>
      pointsEarned != null ? (pointsEarned! / pointsPossible * 100) : null;

  /// Letter grade derived from percentage.
  String get letterGrade {
    final pct = percentage;
    if (pct == null) return '-';
    if (pct >= 90) return 'A';
    if (pct >= 80) return 'B';
    if (pct >= 70) return 'C';
    if (pct >= 60) return 'D';
    return 'F';
  }
}

/// Aggregated grade for one student across all weighted categories.
class StudentGrade {
  final String studentId;
  final String studentName;
  final String? admissionNumber;

  /// Category id → raw percentage (0–100) for that student in that category.
  final Map<String, double> categoryPercentages;

  /// Final weighted average (0–100).
  final double weightedAverage;

  const StudentGrade({
    required this.studentId,
    required this.studentName,
    this.admissionNumber,
    required this.categoryPercentages,
    required this.weightedAverage,
  });

  /// Letter grade from weighted average.
  String get letterGrade {
    if (weightedAverage >= 90) return 'A';
    if (weightedAverage >= 80) return 'B';
    if (weightedAverage >= 70) return 'C';
    if (weightedAverage >= 60) return 'D';
    return 'F';
  }

  /// Build a [StudentGrade] from all categories.
  ///
  /// Total weight of categories determines the denominator so partial sets
  /// (e.g. only homework + quiz, no exam yet) still compute correctly.
  static StudentGrade calculate(
    String studentId,
    String studentName,
    List<GradingCategory> categories, {
    String? admissionNumber,
  }) {
    final categoryPercentages = <String, double>{};
    double weightedSum = 0;
    double totalWeight = 0;

    for (final category in categories) {
      final pct = category.percentageForStudent(studentId);
      categoryPercentages[category.id] = pct;
      weightedSum += pct * category.weight;
      totalWeight += category.weight;
    }

    final weightedAverage =
        totalWeight > 0 ? (weightedSum / totalWeight) : 0.0;

    return StudentGrade(
      studentId: studentId,
      studentName: studentName,
      admissionNumber: admissionNumber,
      categoryPercentages: categoryPercentages,
      weightedAverage: weightedAverage,
    );
  }
}

/// Summary stats for a single assignment title across all students.
class AssignmentSummary {
  final String title;
  final String categoryId;
  final String categoryName;
  final DateTime gradedAt;
  final double pointsPossible;
  final double averageScore;
  final double highestScore;
  final double lowestScore;
  final int gradedCount;
  final int totalStudents;

  const AssignmentSummary({
    required this.title,
    required this.categoryId,
    required this.categoryName,
    required this.gradedAt,
    required this.pointsPossible,
    required this.averageScore,
    required this.highestScore,
    required this.lowestScore,
    required this.gradedCount,
    required this.totalStudents,
  });

  double get averagePercentage =>
      pointsPossible > 0 ? (averageScore / pointsPossible * 100) : 0;
}
