import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_management/data/models/user.dart';
import 'package:school_management/features/auth/providers/auth_provider.dart';
import 'package:school_management/features/dashboard/presentation/screens/parent_dashboard_screen.dart';
import 'package:school_management/features/students/providers/students_provider.dart';

final _fakeParent = AppUser(
  id: 'parent-1',
  email: 'parent@example.com',
  fullName: 'Test Parent',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

Future<void> _pump(
  WidgetTester tester, {
  required List<Map<String, dynamic>> children,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(_fakeParent),
        parentChildrenProvider.overrideWith((_, __) async => children),
      ],
      child: const MaterialApp(home: ParentDashboardScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ParentDashboardScreen v2', () {
    testWidgets('renders the "Parent Portal" large title', (tester) async {
      await _pump(tester, children: const [
        {
          'id': 'stu-1',
          'first_name': 'Aarav',
          'last_name': 'Kumar',
          'student_enrollments': [
            {'section': {'name': '10-A'}}
          ],
        },
      ]);

      expect(find.text('Parent Portal'), findsOneWidget);
    });

    testWidgets('renders a child cell with name and section', (tester) async {
      await _pump(tester, children: const [
        {
          'id': 'stu-1',
          'first_name': 'Aarav',
          'last_name': 'Kumar',
          'student_enrollments': [
            {'section': {'name': '10-A'}}
          ],
        },
      ]);

      expect(find.text("YOUR CHILD'S DAILY LEDGER", skipOffstage: false), findsOneWidget);
      expect(find.text('Aarav Kumar', skipOffstage: false), findsOneWidget);
      expect(find.text('Grade 10-A', skipOffstage: false), findsOneWidget);
    });

    testWidgets('shows calm empty state when no child is linked', (tester) async {
      await _pump(tester, children: const []);
      expect(find.text('No student linked to this account.'), findsOneWidget);
      // Never accuse the user or use cold tone.
      expect(find.textContaining('Error'), findsNothing);
      expect(find.textContaining('Failed'), findsNothing);
    });

    testWidgets('action + tracking sections appear with their canonical cells', (tester) async {
      await _pump(tester, children: const [
        {
          'id': 'stu-1',
          'first_name': 'A',
          'last_name': 'B',
        },
      ]);
      expect(find.text('PARENTAL ACTION REQUIRED', skipOffstage: false), findsOneWidget);
      expect(find.text('Term 2 Tuition Fees', skipOffstage: false), findsOneWidget);
      expect(find.text('ACADEMIC TRACKING', skipOffstage: false), findsOneWidget);
      expect(find.text('Homework & Assignments', skipOffstage: false), findsOneWidget);
      expect(find.text('Classes & Timetables', skipOffstage: false), findsOneWidget);
    });
  });
}
