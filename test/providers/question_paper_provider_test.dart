import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_management/data/models/question_paper.dart';
import 'package:school_management/features/question_paper/providers/question_paper_provider.dart';

import '../helpers/fake_repositories.dart';
import '../helpers/provider_overrides.dart';
import '../helpers/test_data.dart';

void main() {
  late FakeQuestionPaperRepository fakeRepo;
  late ProviderContainer container;

  setUp(() {
    fakeRepo = FakeQuestionPaperRepository();
    container = ProviderContainer(overrides: questionPaperOverrides(fakeRepo));
  });

  tearDown(() => container.dispose());

  group('questionPapersProvider', () {
    test('returns all papers with empty filter', () async {
      const filter = QuestionPaperFilter();
      final papers =
          await container.read(questionPapersProvider(filter).future);

      expect(papers, isA<List<QuestionPaper>>());
      expect(papers, isNotEmpty);
    });

    test('filters by status — draft returns only drafts', () async {
      final repo = FakeQuestionPaperRepository(papers: [
        makeQuestionPaper(id: 'draft-01', status: PaperStatus.draft),
        makeQuestionPaper(id: 'pub-01', status: PaperStatus.published),
      ]);
      final container2 = ProviderContainer(
          overrides: questionPaperOverrides(repo));
      addTearDown(container2.dispose);

      const filter = QuestionPaperFilter(status: PaperStatus.draft);
      final papers =
          await container2.read(questionPapersProvider(filter).future);

      expect(papers, hasLength(1));
      expect(papers.first.status, equals(PaperStatus.draft));
    });

    test('filter equality holds for same fields', () {
      const a = QuestionPaperFilter(classId: 'c1', status: PaperStatus.draft);
      const b = QuestionPaperFilter(classId: 'c1', status: PaperStatus.draft);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('QuestionPaperGeneratorNotifier step transitions', () {
    test('initial step is configure', () {
      final config = makeQuestionPaperConfig();
      final genProvider = questionPaperGeneratorProvider(config);
      final state = container.read(genProvider);

      expect(state.step, equals(GeneratorStep.configure));
      expect(state.generatedSections, isEmpty);
    });

    test('updateConfig changes the config', () {
      final config = makeQuestionPaperConfig();
      final genProvider = questionPaperGeneratorProvider(config);
      final notifier = container.read(genProvider.notifier);

      final newConfig = config.copyWith(totalMarks: 100);
      notifier.updateConfig(newConfig);

      final state = container.read(genProvider);
      expect(state.config.totalMarks, equals(100));
    });

    test('reset returns state to configure step', () {
      final config = makeQuestionPaperConfig();
      final genProvider = questionPaperGeneratorProvider(config);
      final notifier = container.read(genProvider.notifier);

      notifier.reset();
      final state = container.read(genProvider);
      expect(state.step, equals(GeneratorStep.configure));
      expect(state.generatedSections, isEmpty);
      expect(state.errorMessage, isNull);
    });
  });

  group('GeneratorState computed properties', () {
    test('totalQuestions counts questions across sections', () {
      final state = GeneratorState(
        config: makeQuestionPaperConfig(),
        generatedSections: [
          {
            'title': 'Section A',
            'questions': [
              {'marks': 1},
              {'marks': 1}
            ]
          },
          {
            'title': 'Section B',
            'questions': [
              {'marks': 5}
            ]
          },
        ],
      );

      expect(state.totalQuestions, equals(3));
    });

    test('totalMarksFromSections sums marks correctly', () {
      final state = GeneratorState(
        config: makeQuestionPaperConfig(),
        generatedSections: [
          {
            'title': 'Section A',
            'questions': [
              {'marks': 2},
              {'marks': 3}
            ]
          },
        ],
      );

      expect(state.totalMarksFromSections, closeTo(5.0, 0.001));
    });
  });
}
