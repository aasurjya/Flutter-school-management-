import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/core/widgets/apple_sheet.dart';

void main() {
  group('showAppleSheet', () {
    testWidgets('renders title and dismisses on barrier tap', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              capturedContext = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      ));

      final future = showAppleSheet<String>(
        capturedContext,
        title: 'Pick a class',
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Body content'),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('result'),
              child: const Text('Pick'),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Pick a class'), findsOneWidget);
      expect(find.text('Body content'), findsOneWidget);

      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();
      expect(await future, 'result');
    });
  });

  group('showAppleActionSheet', () {
    testWidgets('returns index of tapped action', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              capturedContext = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      ));

      final future = showAppleActionSheet(
        capturedContext,
        title: 'Delete this?',
        actions: const [
          AppleSheetAction('Keep'),
          AppleSheetAction('Delete', destructive: true),
        ],
      );

      await tester.pumpAndSettle();
      expect(find.text('Delete this?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(await future, 1);
    });

    testWidgets('Cancel returns null', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              capturedContext = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      ));

      final future = showAppleActionSheet(
        capturedContext,
        actions: const [AppleSheetAction('Confirm')],
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await future, isNull);
    });
  });
}
