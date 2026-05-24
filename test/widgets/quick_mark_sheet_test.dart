import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/features/attendance/presentation/widgets/quick_mark_sheet.dart';
import 'package:school_management/features/attendance/providers/quick_mark_provider.dart';

NextClassTarget _target({int size = 3}) {
  return NextClassTarget(
    sectionId: 'sec-1',
    sectionLabel: '10-A · Mathematics',
    roomNumber: '204',
    startTime: '09:30',
    endTime: '10:15',
    isNow: false,
    minutesUntilStart: 14,
    roster: List.generate(
      size,
      (i) => RosterStudent(
        studentId: 'stu-$i',
        name: 'Student $i',
        rollNumber: '${i + 1}',
        photoUrl: null,
      ),
    ),
  );
}

Future<void> _openSheet(WidgetTester tester, List<Override> overrides) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: TextButton(
                onPressed: () => showQuickMarkSheet(ctx),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  group('QuickMarkSheet', () {
    testWidgets('renders class label and "Save N present" with all defaults', (tester) async {
      await _openSheet(tester, [
        quickMarkTargetProvider.overrideWith((_) async => _target(size: 3)),
      ]);

      expect(find.text('10-A · Mathematics'), findsOneWidget);
      expect(find.textContaining('all marked present'), findsOneWidget);
      expect(find.text('Save 3 present'), findsOneWidget);
      // 3 roster rows.
      expect(find.text('Student 0'), findsOneWidget);
      expect(find.text('Student 1'), findsOneWidget);
      expect(find.text('Student 2'), findsOneWidget);
    });

    testWidgets('tapping a name toggles to Absent and updates the save label live', (tester) async {
      await _openSheet(tester, [
        quickMarkTargetProvider.overrideWith((_) async => _target(size: 4)),
      ]);

      // Initially everyone is present.
      expect(find.text('Save 4 present'), findsOneWidget);
      expect(find.text('Absent'), findsNothing);

      await tester.tap(find.text('Student 1'));
      await tester.pumpAndSettle();

      // Footer relabels live; one Absent row appears.
      expect(find.text('Save 3 present, 1 absent'), findsOneWidget);
      expect(find.text('Absent'), findsOneWidget);

      // Tapping the same name again toggles back to Present.
      await tester.tap(find.text('Student 1'));
      await tester.pumpAndSettle();
      expect(find.text('Save 4 present'), findsOneWidget);
    });

    testWidgets('shows a friendly empty-state when no class is teachable', (tester) async {
      await _openSheet(tester, [
        quickMarkTargetProvider.overrideWith((_) async => null),
      ]);

      expect(find.text('No class right now.'), findsOneWidget);
      // No save button when there's nothing to save.
      expect(find.textContaining('Save '), findsNothing);
    });

    testWidgets('shows a friendly load-failure message on provider error', (tester) async {
      await _openSheet(tester, [
        quickMarkTargetProvider.overrideWith((_) async => throw Exception('net')),
      ]);

      // Should NOT show raw "Exception: net"; should show the warm copy.
      expect(find.textContaining("Couldn't load"), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
    });
  });
}
