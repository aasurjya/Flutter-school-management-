import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_management/core/preferences/ai_minimal_mode_provider.dart';
import 'package:school_management/data/models/user.dart';
import 'package:school_management/features/auth/providers/auth_provider.dart';
import 'package:school_management/features/dashboard/presentation/screens/admin_dashboard_screen.dart';

final _fakeAdmin = AppUser(
  id: 'admin-1',
  email: 'admin@example.com',
  fullName: 'Priya Sharma',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

Future<void> _pump(WidgetTester tester, {bool minimal = false}) async {
  // Tall viewport so all four sections of the SliverList are built and
  // their cells are present in the widget tree (slivers lazy-build).
  await tester.binding.setSurfaceSize(const Size(400, 2200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  SharedPreferences.setMockInitialValues(
    minimal ? {aiMinimalModePrefsKey: true} : {},
  );
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(_fakeAdmin),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(home: AdminDashboardScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AdminDashboardScreen v2', () {
    testWidgets('renders the "Console" large title', (tester) async {
      await _pump(tester);
      expect(find.text('Console'), findsOneWidget);
    });

    testWidgets('greeting uses the admin first name', (tester) async {
      await _pump(tester);
      expect(find.text('Welcome back, Priya.'), findsOneWidget);
      expect(
        find.text('Institution Operational Console · Active Session'),
        findsOneWidget,
      );
    });

    testWidgets('four sections appear with their canonical cells', (tester) async {
      await _pump(tester);
      // People management
      expect(find.text('PEOPLE MANAGEMENT', skipOffstage: false), findsOneWidget);
      expect(find.text('Student Registrar', skipOffstage: false), findsOneWidget);
      expect(find.text('Faculty & Staff Registry', skipOffstage: false), findsOneWidget);
      expect(find.text('Admissions Panel', skipOffstage: false), findsOneWidget);
      // Academic operations
      expect(find.text('ACADEMIC OPERATIONS', skipOffstage: false), findsOneWidget);
      expect(find.text('Class & Section Structure', skipOffstage: false), findsOneWidget);
      expect(find.text('Master Timetable Grid', skipOffstage: false), findsOneWidget);
      expect(find.text('Examination Scheduling', skipOffstage: false), findsOneWidget);
      // Operations & stats
      expect(find.text('OPERATIONS & STATS', skipOffstage: false), findsOneWidget);
      expect(find.text('Financial Fee Accounts', skipOffstage: false), findsOneWidget);
      expect(find.text('School-Wide Announcements', skipOffstage: false), findsOneWidget);
      expect(find.text('Early Warning AI Insights', skipOffstage: false), findsOneWidget);
      // Infrastructure config
      expect(find.text('INFRASTRUCTURE CONFIG', skipOffstage: false), findsOneWidget);
      expect(find.text('Portal Custom Branding', skipOffstage: false), findsOneWidget);
      expect(find.text('Merchant Gateways', skipOffstage: false), findsOneWidget);
    });

    testWidgets('no cold-tone copy on the home tab', (tester) async {
      await _pump(tester);
      expect(find.textContaining('Failed'), findsNothing);
      expect(find.textContaining('Error'), findsNothing);
      expect(find.textContaining('Oops'), findsNothing);
    });

    testWidgets('AI insights row hides when AI minimal mode is enabled', (tester) async {
      // Default: the Early Warning AI Insights cell is present.
      await _pump(tester);
      expect(find.text('Early Warning AI Insights', skipOffstage: false), findsOneWidget);

      // With minimal mode on, the cell is gone — every other operations cell stays.
      await _pump(tester, minimal: true);
      expect(find.text('Early Warning AI Insights', skipOffstage: false), findsNothing);
      expect(find.text('Financial Fee Accounts', skipOffstage: false), findsOneWidget);
      expect(find.text('School-Wide Announcements', skipOffstage: false), findsOneWidget);
      expect(find.text('Institutional Analytics', skipOffstage: false), findsOneWidget);
    });
  });
}
