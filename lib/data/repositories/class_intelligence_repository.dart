import '../models/class_intelligence.dart';
import 'base_repository.dart';

class ClassIntelligenceRepository extends BaseRepository {
  ClassIntelligenceRepository(super.client);

  Future<ClassIntelligence> getClassIntelligence({
    required String sectionId,
    required String academicYearId,
  }) async {
    // For now, return mock data.
    // In production, aggregate from v_class_exam_stats,
    // v_section_daily_attendance, and student_risk_scores.
    return ClassIntelligence(
      sectionId: sectionId,
      sectionName: 'Section A',
      className: 'Class 10',
      totalStudents: 42,
      averageAttendance: 91.5,
      averageExamScore: 74.2,
      passRate: 88.0,
      subjectStats: [
        const SubjectStats(
          subjectName: 'Mathematics',
          averagePercentage: 72.5,
          passRate: 85.0,
          highestScore: 98,
          lowestScore: 32,
        ),
        const SubjectStats(
          subjectName: 'Science',
          averagePercentage: 78.3,
          passRate: 90.0,
          highestScore: 96,
          lowestScore: 40,
        ),
        const SubjectStats(
          subjectName: 'English',
          averagePercentage: 81.0,
          passRate: 95.0,
          highestScore: 97,
          lowestScore: 48,
        ),
        const SubjectStats(
          subjectName: 'Social Studies',
          averagePercentage: 69.8,
          passRate: 80.0,
          highestScore: 92,
          lowestScore: 28,
        ),
        const SubjectStats(
          subjectName: 'Hindi',
          averagePercentage: 76.4,
          passRate: 88.0,
          highestScore: 95,
          lowestScore: 35,
        ),
      ],
      riskDistribution: {'low': 28, 'medium': 8, 'high': 4, 'critical': 2},
    );
  }
}
