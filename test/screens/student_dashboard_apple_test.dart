import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_management/data/models/student.dart';
import 'package:school_management/data/models/user.dart';
import 'package:school_management/features/auth/providers/auth_provider.dart';
import 'package:school_management/features/dashboard/presentation/screens/student_dashboard_screen.dart';
import 'package:school_management/features/students/providers/students_provider.dart';

final _fakeStudent = AppUser(
  id: 'stu-1',
  email: 'aarav@example.com',
  fullName: 'Aarav Kumar',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

// No currentEnrollment → the live timetable/assignment sections (which need
// network providers) are skipped, leaving the greeting + academic record.
final _fakeStudentRecord = Student(
  id: 'stu-1',
  tenantId: 't-1',
  admissionNumber: 'ADM-1',
  firstName: 'Aarav',
  dateOfBirth: DateTime(2010, 1, 1),
  admissionDate: DateTime(2020, 1, 1),
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(_fakeStudent),
        currentStudentProvider.overrideWith((_) async => _fakeStudentRecord),
      ],
      child: const MaterialApp(home: StudentDashboardScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('StudentDashboardScreen v2', () {
    testWidgets('renders the "Academy" large title', (tester) async {
      await _pump(tester);
      expect(find.text('Academy'), findsOneWidget);
    });

    testWidgets('greeting uses the student first name', (tester) async {
      await _pump(tester);
      expect(find.text('Good morning, Aarav.'), findsOneWidget);
      expect(find.text('Enrollment active · Welcome to class'), findsOneWidget);
    });

    testWidgets('academic record section present with its canonical cells', (tester) async {
      await _pump(tester);
      expect(find.text('ACADEMIC RECORD', skipOffstage: false), findsOneWidget);
      expect(find.text('Attendance Ledger', skipOffstage: false), findsOneWidget);
      expect(find.text('Academic Results', skipOffstage: false), findsOneWidget);
      expect(find.text('Financial Statements', skipOffstage: false), findsOneWidget);
    });

    testWidgets('no cold-tone copy on the home tab', (tester) async {
      await _pump(tester);
      expect(find.textContaining('Failed'), findsNothing);
      expect(find.textContaining('Error'), findsNothing);
      expect(find.textContaining('Oops'), findsNothing);
    });
  });
}
