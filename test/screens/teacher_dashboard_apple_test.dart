import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_management/features/attendance/providers/quick_mark_provider.dart';
import 'package:school_management/features/auth/providers/auth_provider.dart';
import 'package:school_management/features/dashboard/presentation/screens/teacher_dashboard_screen.dart';

NextClassTarget _target() => const NextClassTarget(
      sectionId: 'sec-1',
      sectionLabel: '10-A · Mathematics',
      roomNumber: '204',
      startTime: '09:30',
      endTime: '10:15',
      isNow: false,
      minutesUntilStart: 14,
      roster: [
        RosterStudent(
          studentId: 'stu-1',
          name: 'Student 1',
          rollNumber: '1',
          photoUrl: null,
        ),
      ],
    );

Future<void> _pump(WidgetTester tester, {NextClassTarget? target}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(null),
        quickMarkTargetProvider.overrideWith((_) async => target),
      ],
      child: const MaterialApp(home: TeacherDashboardScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('TeacherDashboardScreen v2', () {
    testWidgets('renders the "Faculty" large title', (tester) async {
      await _pump(tester, target: _target());
      expect(find.text('Faculty'), findsOneWidget);
    });

    testWidgets('NextUp card surfaces the "Mark all N present" CTA', (tester) async {
      await _pump(tester, target: _target());
      expect(find.text('Mark all 1 present'), findsOneWidget);
    });

    testWidgets('NextUp card shows a calm empty state when no class is teachable', (tester) async {
      await _pump(tester, target: null);
      expect(find.text('All classes resolved.'), findsOneWidget);
      // Empty state never offers the destructive-looking CTA.
      expect(find.textContaining('Mark all'), findsNothing);
    });

    testWidgets('dashboard surface uses the grouped background, not pure white', (tester) async {
      await _pump(tester, target: _target());
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, isNotNull);
      // F2F2F7 (light grouped) — not pure white.
      expect(scaffold.backgroundColor, isNot(const Color(0xFFFFFFFF)));
    });
  });
}
