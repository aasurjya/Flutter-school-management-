import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:school_management/data/models/user.dart';
import 'package:school_management/features/auth/providers/auth_provider.dart';
import 'package:school_management/features/question_paper/presentation/screens/question_paper_generator_screen.dart';
import 'package:school_management/features/question_paper/providers/question_paper_provider.dart';

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

Widget buildGeneratorApp(FakeQuestionPaperRepository repo) {
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const QuestionPaperGeneratorScreen(),
    ),
    GoRoute(
      path: '/question-papers/:id',
      builder: (_, __) =>
          const Scaffold(body: Center(child: Text('Paper Detail'))),
    ),
  ]);

  return ProviderScope(
    overrides: [
      questionPaperRepositoryProvider.overrideWithValue(repo),
      currentUserProvider.overrideWith((ref) => _makeTeacherUser()),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ============================================================
// Tests
// ============================================================

void main() {
  late FakeQuestionPaperRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeQuestionPaperRepository();
  });

  testWidgets('config step renders AppBar title', (tester) async {
    await tester.pumpWidget(buildGeneratorApp(fakeRepo));
    await tester.pump();

    expect(find.text('Question Paper Generator'), findsOneWidget);
  });

  testWidgets('subject field is visible and pre-filled', (tester) async {
    await tester.pumpWidget(buildGeneratorApp(fakeRepo));
    await tester.pump();

    // Subject text field should be visible
    final subjectField = find.widgetWithText(TextFormField, 'Mathematics');
    expect(subjectField, findsOneWidget);
  });

  testWidgets('class/grade field is visible', (tester) async {
    await tester.pumpWidget(buildGeneratorApp(fakeRepo));
    await tester.pump();

    expect(find.widgetWithText(TextFormField, 'Class 10'), findsOneWidget);
  });

  testWidgets('Generate Question Paper button is present on config step',
      (tester) async {
    await tester.pumpWidget(buildGeneratorApp(fakeRepo));
    await tester.pump();

    // Button is at the bottom of a long scrollable form.
    // Scroll to bring it into view, then verify it exists.
    final generateButton = find.textContaining('Generate');
    await tester.scrollUntilVisible(
      generateButton,
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(generateButton, findsWidgets);
  });

  testWidgets('exam type dropdown is present', (tester) async {
    await tester.pumpWidget(buildGeneratorApp(fakeRepo));
    await tester.pump();

    // Look for DropdownButton or dropdown-related widgets
    // The exam type is represented as a dropdown
    expect(find.byType(DropdownButton<String>), findsWidgets);
  });

  testWidgets('difficulty chips are present', (tester) async {
    await tester.pumpWidget(buildGeneratorApp(fakeRepo));
    await tester.pump();

    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);
  });

  testWidgets('selecting a difficulty chip does not crash', (tester) async {
    await tester.pumpWidget(buildGeneratorApp(fakeRepo));
    await tester.pump();

    // Scroll to bring difficulty chips into view
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();

    final mediumChip = find.text('Medium');
    if (mediumChip.evaluate().isNotEmpty) {
      await tester.tap(mediumChip.first, warnIfMissed: false);
      await tester.pump();
    }

    // Widget still alive = no crash
    expect(find.byType(QuestionPaperGeneratorScreen), findsOneWidget);
  });
}
