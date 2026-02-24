/// Named lists of Riverpod overrides for use in ProviderScope during tests.
library provider_overrides;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_management/features/substitution/providers/substitution_provider.dart';
import 'package:school_management/features/fees/providers/fees_provider.dart';
import 'package:school_management/features/question_paper/providers/question_paper_provider.dart';

import 'fake_repositories.dart';

List<Override> substitutionOverrides(FakeSubstitutionRepository repo) => [
      substitutionRepositoryProvider.overrideWithValue(repo),
    ];

List<Override> feeOverrides(FakeFeeRepository repo) => [
      feeRepositoryProvider.overrideWithValue(repo),
    ];

List<Override> questionPaperOverrides(FakeQuestionPaperRepository repo) => [
      questionPaperRepositoryProvider.overrideWithValue(repo),
    ];
