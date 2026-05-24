// Integration-style test for the "8:10 AM teacher" golden path.
//
// Goal: from a cold dashboard render, a teacher reaches the "Save N present"
// button in 1 tap, and the path NEVER shows a confirmation AlertDialog.
//
// Real Supabase repos are out of scope here — the providers under test are
// gated by `quickMarkTargetProvider`, which is deterministically overridden.
// What we ARE asserting:
//   • tap count is bounded
//   • no AlertDialog appears at any point in the path
//   • the WarmCopy footer label reflects the present/absent split live
//
// The full server-side save path is covered by the unit tests for
// `persistQuickMark` and `mark_attendance_undo_test.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_management/features/attendance/providers/quick_mark_provider.dart';
import 'package:school_management/features/auth/providers/auth_provider.dart';
import 'package:school_management/features/dashboard/presentation/screens/teacher_dashboard_screen.dart';

NextClassTarget _target28() {
  return NextClassTarget(
    sectionId: 'sec-10A-math',
    sectionLabel: '10-A · Mathematics',
    roomNumber: '204',
    startTime: '09:30',
    endTime: '10:15',
    isNow: false,
    minutesUntilStart: 14,
    roster: List.generate(
      28,
      (i) => RosterStudent(
        studentId: 'stu-$i',
        name: 'Student ${i + 1}',
        rollNumber: '${i + 1}',
        photoUrl: null,
      ),
    ),
  );
}

void main() {
  testWidgets('8:10 AM teacher golden path — dashboard to save button in 1 tap, no dialog', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(null),
          quickMarkTargetProvider.overrideWith((_) async => _target28()),
        ],
        child: const MaterialApp(home: TeacherDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // The hero CTA names the count from the resolved target.
    final cta = find.text('Mark all 28 present');
    expect(cta, findsOneWidget);

    // Tap 1: open the Quick Mark sheet.
    await tester.tap(cta);
    await tester.pumpAndSettle();

    // After tap 1, the save button must already be visible and pre-labeled.
    expect(find.text('Save 28 present'), findsOneWidget);

    // At NO point in this path did an AlertDialog appear — the prior
    // implementation required a confirm dialog before commit, which the
    // Apple redesign deletes in favor of the undo banner pattern.
    expect(find.byType(AlertDialog), findsNothing);

    // Exception path: 3 absent kids. Each tap toggles a row; the footer
    // re-labels live without an extra confirmation step.
    await tester.tap(find.text('Student 1'));
    await tester.tap(find.text('Student 2'));
    await tester.tap(find.text('Student 3'));
    await tester.pumpAndSettle();

    expect(find.text('Save 25 present, 3 absent'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
