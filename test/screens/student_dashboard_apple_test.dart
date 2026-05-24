import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(_fakeStudent),
        currentStudentProvider.overrideWith((_) async => null),
      ],
      child: const MaterialApp(home: StudentDashboardScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('StudentDashboardScreen v2', () {
    testWidgets('renders the "Today" large title without a gradient hero', (tester) async {
      await _pump(tester);
      expect(find.text('Today'), findsOneWidget);
      final gradients = find.byWidgetPredicate((w) {
        if (w is DecoratedBox) {
          final dec = w.decoration;
          if (dec is BoxDecoration && dec.gradient is LinearGradient) {
            return true;
          }
        }
        return false;
      });
      expect(gradients, findsNothing);
    });

    testWidgets('greeting uses the student first name', (tester) async {
      await _pump(tester);
      expect(find.text('Hi Aarav.'), findsOneWidget);
      expect(find.text('Here is what your day looks like.'), findsOneWidget);
    });

    testWidgets('three sections present with their canonical cells', (tester) async {
      await _pump(tester);
      // Today
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('Homework'), findsOneWidget);
      expect(find.text('My timetable'), findsOneWidget);
      // School
      expect(find.text('SCHOOL'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Results'), findsOneWidget);
      expect(find.text('Fees'), findsOneWidget);
      // Coming up (may be below the fold in a 600pt viewport)
      expect(find.text('COMING UP', skipOffstage: false), findsOneWidget);
      expect(find.text('Assignments', skipOffstage: false), findsOneWidget);
      expect(find.text('Exams', skipOffstage: false), findsOneWidget);
    });

    testWidgets('no cold-tone copy on the home tab', (tester) async {
      await _pump(tester);
      expect(find.textContaining('Failed'), findsNothing);
      expect(find.textContaining('Error'), findsNothing);
      expect(find.textContaining('Oops'), findsNothing);
    });
  });
}
