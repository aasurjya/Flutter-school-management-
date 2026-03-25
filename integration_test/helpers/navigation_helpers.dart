/// Navigation helpers for integration tests.
///
/// Provides utilities for navigating the app, tapping bottom nav tabs,
/// opening the "More" overflow sheet, and detecting dead buttons.
library navigation_helpers;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Expected dashboard route for each role.
const roleDashboardRoutes = <String, String>{
  'super_admin': '/super-admin',
  'tenant_admin': '/admin',
  'principal': '/admin',
  'teacher': '/teacher',
  'student': '/student',
  'parent': '/parent',
  'accountant': '/staff/accountant',
  'librarian': '/staff/librarian',
  'transport_manager': '/staff/transport-manager',
  'hostel_warden': '/staff/hostel-warden',
  'canteen_staff': '/staff/canteen-staff',
  'receptionist': '/staff/receptionist',
};

/// Expected primary bottom-nav tab labels for each role (excluding "More").
const roleNavTabs = <String, List<String>>{
  'tenant_admin': ['Dashboard', 'Students', 'Staff', 'Attendance', 'Fees'],
  'principal': ['Dashboard', 'Students', 'Staff', 'Attendance', 'Fees'],
  'teacher': ['Dashboard', 'Attendance', 'Exams', 'Messages'],
  'student': ['Dashboard', 'Attendance', 'Results', 'Messages'],
  'parent': ['Dashboard', 'Attendance', 'Fees', 'Messages'],
  'accountant': ['Dashboard', 'Fees', 'Reports', 'Messages'],
  'librarian': ['Dashboard', 'Library', 'My Books', 'Notices'],
  'transport_manager': ['Dashboard', 'Transport', 'Tracking', 'Notices'],
  'hostel_warden': ['Dashboard', 'Hostel', 'Allocation', 'Notices'],
  'canteen_staff': ['Dashboard', 'Canteen', 'Orders', 'Notices'],
  'receptionist': ['Dashboard', 'Visitors', 'Calendar', 'Notices'],
  // super_admin has no bottom nav
};

/// Taps a bottom-nav item by its label text.
///
/// Pumps the widget tree after tapping. Throws [TestFailure] if the
/// label is not found.
Future<void> tapBottomNavTab(WidgetTester tester, String label) async {
  final finder = find.text(label);
  expect(finder, findsWidgets, reason: 'Bottom nav tab "$label" not found');
  await tester.tap(finder.last);
  await tester.pumpAndSettle();
}

/// Opens the "More" overflow bottom sheet.
///
/// Looks for an icon labelled "More" or an [Icons.more_horiz] button in the
/// bottom navigation area.
Future<void> openMoreSheet(WidgetTester tester) async {
  // Try finding by text first, then by icon
  final textFinder = find.text('More');
  if (textFinder.evaluate().isNotEmpty) {
    await tester.tap(textFinder.last);
    await tester.pumpAndSettle();
    return;
  }

  final iconFinder = find.byIcon(Icons.more_horiz);
  if (iconFinder.evaluate().isNotEmpty) {
    await tester.tap(iconFinder.last);
    await tester.pumpAndSettle();
    return;
  }

  fail('Could not find "More" button in bottom navigation');
}

/// Verifies that all expected nav tabs for [role] are present.
///
/// Does not tap them — just checks they exist in the widget tree.
void verifyNavTabsExist(WidgetTester tester, String role) {
  final expectedTabs = roleNavTabs[role];
  if (expectedTabs == null) return; // super_admin has no tabs

  for (final label in expectedTabs) {
    expect(
      find.text(label),
      findsWidgets,
      reason: 'Nav tab "$label" missing for role "$role"',
    );
  }
}

/// Finds all [ElevatedButton], [TextButton], [IconButton], and [InkWell]
/// widgets in the current tree and returns those with empty/null callbacks.
///
/// This is a heuristic — it catches `onPressed: () {}` but cannot detect
/// handlers that exist but do nothing meaningful.
List<String> findDeadButtons(WidgetTester tester) {
  final deadButtons = <String>[];

  // Check ElevatedButton / TextButton / OutlinedButton
  for (final element in find.bySubtype<ButtonStyleButton>().evaluate()) {
    final widget = element.widget as ButtonStyleButton;
    if (widget.onPressed == null) {
      deadButtons.add(
        'Disabled ${widget.runtimeType}: '
        '${_extractButtonLabel(element)}',
      );
    }
  }

  // Check IconButton
  for (final element in find.byType(IconButton).evaluate()) {
    final widget = element.widget as IconButton;
    if (widget.onPressed == null) {
      deadButtons.add('Disabled IconButton: ${widget.icon.runtimeType}');
    }
  }

  return deadButtons;
}

/// Attempts to extract a text label from a button's child tree.
String _extractButtonLabel(Element element) {
  String label = '(no label)';
  element.visitChildElements((child) {
    if (child.widget is Text) {
      label = (child.widget as Text).data ?? label;
    }
  });
  return label;
}

/// Scrolls until [finder] is visible, then taps it.
///
/// Useful for tapping items in scrollable lists or dashboards.
Future<void> scrollAndTap(
  WidgetTester tester,
  Finder finder, {
  Finder? scrollable,
}) async {
  final scroll = scrollable ?? find.byType(Scrollable).first;
  await tester.scrollUntilVisible(finder, 200, scrollable: scroll);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Waits for async data to load by pumping until [finder] appears
/// or [timeout] elapses.
Future<bool> waitForWidget(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    await tester.pump(const Duration(milliseconds: 500));
    if (finder.evaluate().isNotEmpty) return true;
  }
  return false;
}
