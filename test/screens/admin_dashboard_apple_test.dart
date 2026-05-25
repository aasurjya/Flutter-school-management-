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
    testWidgets('renders "Today" large title without a gradient hero', (tester) async {
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

    testWidgets('greeting uses the admin first name', (tester) async {
      await _pump(tester);
      expect(find.text('Hi Priya.'), findsOneWidget);
      expect(find.text('Manage your school from here.'), findsOneWidget);
    });

    testWidgets('four sections appear with their canonical cells', (tester) async {
      await _pump(tester);
      // People
      expect(find.text('PEOPLE', skipOffstage: false), findsOneWidget);
      expect(find.text('Students', skipOffstage: false), findsOneWidget);
      expect(find.text('Staff', skipOffstage: false), findsOneWidget);
      expect(find.text('Admissions', skipOffstage: false), findsOneWidget);
      // Academic
      expect(find.text('ACADEMIC', skipOffstage: false), findsOneWidget);
      expect(find.text('Classes', skipOffstage: false), findsOneWidget);
      expect(find.text('Timetable', skipOffstage: false), findsOneWidget);
      expect(find.text('Exams', skipOffstage: false), findsOneWidget);
      // Operations
      expect(find.text('OPERATIONS', skipOffstage: false), findsOneWidget);
      expect(find.text('Fees', skipOffstage: false), findsOneWidget);
      expect(find.text('Announcements', skipOffstage: false), findsOneWidget);
      expect(find.text('AI insights', skipOffstage: false), findsOneWidget);
      // School
      expect(find.text('SCHOOL', skipOffstage: false), findsOneWidget);
      expect(find.text('School branding', skipOffstage: false), findsOneWidget);
      expect(find.text('Payment gateways', skipOffstage: false), findsOneWidget);
    });

    testWidgets('no cold-tone copy on the home tab', (tester) async {
      await _pump(tester);
      expect(find.textContaining('Failed'), findsNothing);
      expect(find.textContaining('Error'), findsNothing);
      expect(find.textContaining('Oops'), findsNothing);
    });

    testWidgets('AI insights row hides when AI minimal mode is enabled', (tester) async {
      // Default: AI insights cell is present.
      await _pump(tester);
      expect(find.text('AI insights', skipOffstage: false), findsOneWidget);

      // With minimal mode on, the cell is gone — every other operations cell stays.
      await _pump(tester, minimal: true);
      expect(find.text('AI insights', skipOffstage: false), findsNothing);
      expect(find.text('Fees', skipOffstage: false), findsOneWidget);
      expect(find.text('Announcements', skipOffstage: false), findsOneWidget);
      expect(find.text('Reports', skipOffstage: false), findsOneWidget);
    });
  });
}
