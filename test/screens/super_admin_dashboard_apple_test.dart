import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_management/data/models/user.dart';
import 'package:school_management/features/auth/providers/auth_provider.dart';
import 'package:school_management/features/super_admin/presentation/screens/super_admin_dashboard_screen.dart';
import 'package:school_management/features/super_admin/providers/tenant_provider.dart';

final _fakeOperator = AppUser(
  id: 'sa-1',
  email: 'ops@platform.example',
  fullName: 'Rita Operator',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

Future<void> _pump(
  WidgetTester tester, {
  Map<String, dynamic>? stats,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(_fakeOperator),
        platformStatsProvider.overrideWith((_) async => stats ?? {'tenants': 7, 'users': 1240}),
      ],
      child: const MaterialApp(home: SuperAdminDashboardScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('SuperAdminDashboardScreen v2', () {
    testWidgets('renders "Platform" large title without a gradient hero', (tester) async {
      await _pump(tester);
      expect(find.text('Platform'), findsOneWidget);
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

    testWidgets('greeting uses the operator first name', (tester) async {
      await _pump(tester);
      expect(find.text('Hi Rita.'), findsOneWidget);
      expect(find.text('Platform overview.'), findsOneWidget);
    });

    testWidgets('platform stats show schools + users from the provider', (tester) async {
      await _pump(tester, stats: {'tenants': 3, 'users': 47});
      expect(find.text('3'), findsOneWidget);
      expect(find.text('47'), findsOneWidget);
      expect(find.text('Schools'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
    });

    testWidgets('Tenants + Platform sections appear with their canonical cells', (tester) async {
      await _pump(tester);
      expect(find.text('TENANTS', skipOffstage: false), findsOneWidget);
      expect(find.text('All schools', skipOffstage: false), findsOneWidget);
      expect(find.text('New school', skipOffstage: false), findsOneWidget);
      expect(find.text('PLATFORM', skipOffstage: false), findsOneWidget);
      expect(find.text('Settings', skipOffstage: false), findsOneWidget);
      expect(find.text('Notifications', skipOffstage: false), findsOneWidget);
    });
  });
}
