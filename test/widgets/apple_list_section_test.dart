import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/core/widgets/apple_list_section.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AppleListSection', () {
    testWidgets('renders header, footer, and cells', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppleListSection(
          header: 'Account',
          footer: 'You can change this later.',
          children: [
            AppleListCell(title: 'Name', value: 'Aasurjya'),
            AppleListCell(title: 'Email', value: 'a@example.com'),
          ],
        ),
      ));

      // Header is upper-cased visually but stored input is preserved on Text.
      expect(find.text('ACCOUNT'), findsOneWidget);
      expect(find.text('You can change this later.'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Aasurjya'), findsOneWidget);
    });

    testWidgets('AppleListCell invokes onTap and shows chevron', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_wrap(
        AppleListSection(
          children: [
            AppleListCell(
              title: 'Open',
              showChevron: true,
              onTap: () => tapped++,
            ),
          ],
        ),
      ));

      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      await tester.tap(find.text('Open'));
      expect(tapped, 1);
    });

    testWidgets('destructive cell renders in error color', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppleListSection(
          children: [
            AppleListCell(title: 'Delete account', destructive: true),
          ],
        ),
      ));

      final textWidget = tester.widget<Text>(find.text('Delete account'));
      expect(textWidget.style?.color, isNotNull);
      // Destructive text should not equal default label color (#000000 on light).
      expect(textWidget.style?.color, isNot(equals(const Color(0xFF000000))));
    });

    testWidgets('AppleListSwitchCell forwards value/onChanged', (tester) async {
      var current = false;
      await tester.pumpWidget(_wrap(
        StatefulBuilder(
          builder: (context, setState) => AppleListSection(
            children: [
              AppleListSwitchCell(
                title: 'Notifications',
                value: current,
                onChanged: (v) => setState(() => current = v),
              ),
            ],
          ),
        ),
      ));

      expect(find.byType(Switch), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(current, isTrue);
    });
  });
}
