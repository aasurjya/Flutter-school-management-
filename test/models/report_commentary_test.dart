import 'package:flutter_test/flutter_test.dart';

import 'package:school_management/data/models/report_commentary.dart';

void main() {
  group('ReportCommentary', () {
    test('creates with default values', () {
      const commentary = ReportCommentary(
        studentId: 'student-001',
        studentName: 'Aarav Sharma',
        remark: 'Good progress this term.',
      );

      expect(commentary.isEdited, isFalse);
      expect(commentary.isApproved, isFalse);
      expect(commentary.isLLMGenerated, isFalse);
    });

    test('copyWith creates immutable copy', () {
      const original = ReportCommentary(
        studentId: 'student-001',
        studentName: 'Aarav Sharma',
        remark: 'Original remark.',
      );

      final edited = original.copyWith(
        remark: 'Edited remark.',
        isEdited: true,
      );

      // Original is unchanged.
      expect(original.remark, 'Original remark.');
      expect(original.isEdited, isFalse);

      // Edited has new values.
      expect(edited.remark, 'Edited remark.');
      expect(edited.isEdited, isTrue);
      expect(edited.studentId, 'student-001');
      expect(edited.studentName, 'Aarav Sharma');
    });

    test('copyWith toggles approval', () {
      const commentary = ReportCommentary(
        studentId: 'student-001',
        studentName: 'Test',
        remark: 'Remark.',
      );

      final approved = commentary.copyWith(isApproved: true);
      expect(approved.isApproved, isTrue);

      final unapproved = approved.copyWith(isApproved: false);
      expect(unapproved.isApproved, isFalse);
    });

    test('copyWith preserves isLLMGenerated', () {
      const commentary = ReportCommentary(
        studentId: 'student-001',
        studentName: 'Test',
        remark: 'AI remark.',
        isLLMGenerated: true,
      );

      final edited = commentary.copyWith(remark: 'Manually edited.');
      expect(edited.isLLMGenerated, isTrue);
    });
  });
}
