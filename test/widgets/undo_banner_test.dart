import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/core/widgets/undo_banner.dart';

void main() {
  group('UndoBanner', () {
    testWidgets('shows message and Undo action', (tester) async {
      var undoTapped = 0;
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (c) {
            ctx = c;
            return const SizedBox.shrink();
          }),
        ),
      ));

      UndoBanner.show(
        ctx,
        message: 'Attendance saved.',
        onUndo: () => undoTapped++,
      );
      await tester.pump(); // start animation
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Attendance saved.'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(undoTapped, 1);
    });

    testWidgets('passes custom duration to the SnackBar widget', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (c) {
            ctx = c;
            return const SizedBox.shrink();
          }),
        ),
      ));

      UndoBanner.show(
        ctx,
        message: 'X',
        onUndo: () {},
        duration: const Duration(milliseconds: 1234),
      );
      await tester.pump();

      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snack.duration, const Duration(milliseconds: 1234));
      expect(snack.action, isNotNull);
      expect(snack.action!.label, 'Undo');
    });

    testWidgets('default duration is 6 seconds', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (c) {
            ctx = c;
            return const SizedBox.shrink();
          }),
        ),
      ));

      UndoBanner.show(ctx, message: 'X', onUndo: () {});
      await tester.pump();

      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snack.duration, const Duration(seconds: 6));
    });

    testWidgets('show() replaces a prior banner instead of stacking', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (c) {
            ctx = c;
            return const SizedBox.shrink();
          }),
        ),
      ));

      UndoBanner.show(ctx, message: 'First.', onUndo: () {});
      await tester.pump();
      UndoBanner.show(ctx, message: 'Second.', onUndo: () {});
      await tester.pumpAndSettle();

      expect(find.text('First.'), findsNothing);
      expect(find.text('Second.'), findsOneWidget);
    });
  });
}
