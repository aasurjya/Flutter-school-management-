class ClassIntelligence {
  final String sectionId;
  final String sectionName;
  final String className;
  final int totalStudents;
  final double averageAttendance;
  final double averageExamScore;
  final double passRate;
  final List<SubjectStats> subjectStats;
  final Map<String, int> riskDistribution; // {low: 20, medium: 5, high: 3, critical: 1}
  final String? aiNarrative;

  const ClassIntelligence({
    required this.sectionId,
    required this.sectionName,
    required this.className,
    required this.totalStudents,
    required this.averageAttendance,
    required this.averageExamScore,
    required this.passRate,
    required this.subjectStats,
    required this.riskDistribution,
    this.aiNarrative,
  });

  ClassIntelligence copyWith({String? aiNarrative}) {
    return ClassIntelligence(
      sectionId: sectionId,
      sectionName: sectionName,
      className: className,
      totalStudents: totalStudents,
      averageAttendance: averageAttendance,
      averageExamScore: averageExamScore,
      passRate: passRate,
      subjectStats: subjectStats,
      riskDistribution: riskDistribution,
      aiNarrative: aiNarrative ?? this.aiNarrative,
    );
  }
}

class SubjectStats {
  final String subjectName;
  final double averagePercentage;
  final double passRate;
  final double highestScore;
  final double lowestScore;

  const SubjectStats({
    required this.subjectName,
    required this.averagePercentage,
    required this.passRate,
    required this.highestScore,
    required this.lowestScore,
  });
}
