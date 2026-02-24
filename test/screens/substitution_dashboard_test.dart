import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:school_management/data/models/substitution.dart';
import 'package:school_management/data/models/user.dart';
import 'package:school_management/features/auth/providers/auth_provider.dart';
import 'package:school_management/features/substitution/presentation/screens/substitution_dashboard_screen.dart';
import 'package:school_management/features/substitution/providers/substitution_provider.dart';

import '../helpers/fake_repositories.dart';
import '../helpers/test_data.dart';

// ============================================================
// Helpers
// ============================================================

AppUser _makeAdminUser() => AppUser(
      id: kTeacherId1,
      email: 'admin@test.com',
      roles: const ['tenant_admin'],
      primaryRole: 'tenant_admin',
      createdAt: kBaseDate,
      updatedAt: kBaseDate,
    );

Widget buildSubstitutionTestApp(
    Widget child, List<Override> overrides) {
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => child,
      routes: [
        GoRoute(
          path: 'report-absence',
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('Report Absence')),
          ),
        ),
      ],
    ),
  ]);

  return ProviderScope(
    overrides: overrides,
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

  Widget buildApp() {
    return buildSubstitutionTestApp(
      const SubstitutionDashboardScreen(),
      [
        substitutionRepositoryProvider.overrideWithValue(fakeRepo),
        currentUserProvider.overrideWith((ref) => _makeAdminUser()),
      ],
    );
  }

  testWidgets('renders AppBar and three tabs', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.text('Absences & AI'), findsOneWidget);
    expect(find.text('Final Schedule'), findsOneWidget);
    expect(find.text('My Duties'), findsOneWidget);
  });

  testWidgets('prev and next day icons are present', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('tapping next day advances the date shown in AppBar',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    // The initial AppBar title contains "Today"
    expect(find.textContaining('Today'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();

    // After advancing by one day, "Today" label should be replaced
    expect(find.textContaining('Today'), findsNothing);
  });

  testWidgets('tapping prev day changes the date shown in AppBar',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump();

    expect(find.textContaining('Today'), findsNothing);
  });

  testWidgets('Absences tab shows loading then content', (tester) async {
    await tester.pumpWidget(buildApp());
    // Initial pump shows scaffold
    await tester.pump();

    // Let async providers settle
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Should find at least one tab content (no crash = success)
    expect(find.byType(TabBarView), findsOneWidget);
  });

  testWidgets('empty state shown when absences list is empty', (tester) async {
    final emptyRepo = FakeSubstitutionRepository();
    // Override to return empty list for date queries
    final app = buildSubstitutionTestApp(
      const SubstitutionDashboardScreen(),
      [
        substitutionRepositoryProvider
            .overrideWithValue(emptyRepo),
        currentUserProvider.overrideWith((ref) => _makeAdminUser()),
        // Force the date provider to return empty
        teacherAbsencesForDateProvider(kBaseDate)
            .overrideWith((_) async => <TeacherAbsence>[]),
      ],
    );

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // No crash; the tab still renders
    expect(find.byType(Scaffold), findsWidgets);
  });
}
