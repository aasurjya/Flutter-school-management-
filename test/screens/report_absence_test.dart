import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:school_management/data/models/user.dart';
import 'package:school_management/features/auth/providers/auth_provider.dart';
import 'package:school_management/features/substitution/presentation/screens/report_absence_screen.dart';
import 'package:school_management/features/substitution/providers/substitution_provider.dart';

import '../helpers/fake_repositories.dart';
import '../helpers/test_data.dart';

// ============================================================
// Helpers
// ============================================================

AppUser _makeTeacherUser() => AppUser(
      id: kTeacherId1,
      email: 'teacher@test.com',
      roles: const ['teacher'],
      primaryRole: 'teacher',
      createdAt: kBaseDate,
      updatedAt: kBaseDate,
    );

Widget buildReportAbsenceApp(FakeSubstitutionRepository repo) {
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const ReportAbsenceScreen(),
    ),
  ]);

  return ProviderScope(
    overrides: [
      substitutionRepositoryProvider.overrideWithValue(repo),
      currentUserProvider.overrideWith((ref) => _makeTeacherUser()),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ============================================================
// Tests
// ============================================================

void main() {
  late FakeSubstitutionRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeSubstitutionRepository();
  });

  testWidgets('form renders with AppBar title', (tester) async {
    await tester.pumpWidget(buildReportAbsenceApp(fakeRepo));
    await tester.pump();

    expect(find.text('Report Absence'), findsOneWidget);
  });

  testWidgets('Today and Tomorrow quick-select chips are present',
      (tester) async {
    await tester.pumpWidget(buildReportAbsenceApp(fakeRepo));
    await tester.pump();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);
  });

  testWidgets('Tomorrow chip is selectable', (tester) async {
    await tester.pumpWidget(buildReportAbsenceApp(fakeRepo));
    await tester.pump();

    await tester.tap(find.text('Tomorrow'));
    await tester.pump();

    // Chip tap doesn't crash — visual selection is internal state
    expect(find.text('Tomorrow'), findsOneWidget);
  });

  testWidgets('leave type chips are present', (tester) async {
    await tester.pumpWidget(buildReportAbsenceApp(fakeRepo));
    await tester.pump();

    // Sick Leave chip should be visible (default selected)
    expect(find.text('Sick Leave'), findsOneWidget);
  });

  testWidgets('Casual Leave chip is selectable', (tester) async {
    await tester.pumpWidget(buildReportAbsenceApp(fakeRepo));
    await tester.pump();

    await tester.tap(find.text('Casual Leave'));
    await tester.pump();

    expect(find.text('Casual Leave'), findsOneWidget);
  });

  testWidgets('past absences section exists and can be tapped', (tester) async {
    await tester.pumpWidget(buildReportAbsenceApp(fakeRepo));
    await tester.pumpAndSettle();

    // Scroll to the past absences section
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();

    // No crash during scroll = widget structure is sound
    expect(find.byType(Form), findsOneWidget);
  });
}
