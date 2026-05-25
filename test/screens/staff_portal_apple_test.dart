import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_management/data/models/user.dart';
import 'package:school_management/features/auth/providers/auth_provider.dart';
import 'package:school_management/features/staff_portal/presentation/screens/accountant_dashboard_screen.dart';
import 'package:school_management/features/staff_portal/presentation/screens/canteen_staff_dashboard_screen.dart';
import 'package:school_management/features/staff_portal/presentation/screens/hostel_warden_dashboard_screen.dart';
import 'package:school_management/features/staff_portal/presentation/screens/librarian_dashboard_screen.dart';
import 'package:school_management/features/staff_portal/presentation/screens/receptionist_dashboard_screen.dart';
import 'package:school_management/features/staff_portal/presentation/screens/transport_manager_dashboard_screen.dart';

/// Each staff portal must render the calm Apple shape with the same invariants:
///   • "Today" large title
///   • No LinearGradient in the visible tree
///   • Greeting "Hi {firstName}." present
///   • Role-specific section header (uppercased)
///   • No cold-tone copy ("Error", "Failed", "Oops")
///
/// One parametric test covers all six portals so we don't carry six near-identical files.
void main() {
  final fakeStaff = AppUser(
    id: 'staff-1',
    email: 'staff@example.com',
    fullName: 'Sam Staff',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final portals = <({String name, Widget screen, String expectedHeader})>[
    (
      name: 'Receptionist',
      screen: const ReceptionistDashboardScreen(),
      expectedHeader: 'VISITORS',
    ),
    (
      name: 'Accountant',
      screen: const AccountantDashboardScreen(),
      expectedHeader: 'FEES',
    ),
    (
      name: 'Canteen staff',
      screen: const CanteenStaffDashboardScreen(),
      expectedHeader: 'CANTEEN',
    ),
    (
      name: 'Hostel warden',
      screen: const HostelWardenDashboardScreen(),
      expectedHeader: 'HOSTEL',
    ),
    (
      name: 'Librarian',
      screen: const LibrarianDashboardScreen(),
      expectedHeader: 'LIBRARY',
    ),
    (
      name: 'Transport manager',
      screen: const TransportManagerDashboardScreen(),
      expectedHeader: 'TRANSPORT',
    ),
  ];

  for (final portal in portals) {
    testWidgets('${portal.name} portal — Apple shape invariants', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(fakeStaff),
          ],
          child: MaterialApp(home: portal.screen),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget,
          reason: '${portal.name} should have "Today" large title');
      expect(find.text('Hi Sam.'), findsOneWidget,
          reason: '${portal.name} should greet by first name');
      expect(find.text(portal.expectedHeader, skipOffstage: false), findsOneWidget,
          reason: '${portal.name} should expose its primary section');
      expect(find.text('My ID card', skipOffstage: false), findsOneWidget,
          reason: '${portal.name} should keep the staff ID-card affordance');

      // No gradient.
      final gradients = find.byWidgetPredicate((w) {
        if (w is DecoratedBox) {
          final dec = w.decoration;
          if (dec is BoxDecoration && dec.gradient is LinearGradient) {
            return true;
          }
        }
        return false;
      });
      expect(gradients, findsNothing,
          reason: '${portal.name} must not render a gradient hero');

      // No cold tone.
      expect(find.textContaining('Failed'), findsNothing);
      expect(find.textContaining('Error'), findsNothing);
      expect(find.textContaining('Oops'), findsNothing);
    });
  }
}
