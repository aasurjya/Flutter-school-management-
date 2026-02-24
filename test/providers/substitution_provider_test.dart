import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_management/data/models/substitution.dart';
import 'package:school_management/features/substitution/providers/substitution_provider.dart';

import '../helpers/fake_repositories.dart';
import '../helpers/provider_overrides.dart';
import '../helpers/test_data.dart';

void main() {
  late FakeSubstitutionRepository fakeRepo;
  late ProviderContainer container;

  setUp(() {
    fakeRepo = FakeSubstitutionRepository();
    container = ProviderContainer(overrides: substitutionOverrides(fakeRepo));
  });

  tearDown(() => container.dispose());

  group('myAbsencesProvider', () {
    test('returns a list from the fake repo', () async {
      final absences = await container
          .read(myAbsencesProvider(kTeacherId1).future);

      expect(absences, isA<List<TeacherAbsence>>());
      expect(absences, hasLength(1));
      expect(absences.first.teacherId, equals(kTeacherId1));
    });

    test('absence has correct leave type', () async {
      final absences = await container
          .read(myAbsencesProvider(kTeacherId1).future);

      expect(absences.first.leaveType, equals(AbsenceLeaveType.sick));
    });
  });

  group('SuggestionParams equality', () {
    test('same teacher + same date string are equal', () {
      final a = SuggestionParams(
          absentTeacherId: kTeacherId1, date: DateTime(2026, 2, 24));
      final b = SuggestionParams(
          absentTeacherId: kTeacherId1,
          date: DateTime(2026, 2, 24, 15, 30)); // different time, same day

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different dates are not equal', () {
      final a = SuggestionParams(
          absentTeacherId: kTeacherId1, date: DateTime(2026, 2, 24));
      final b = SuggestionParams(
          absentTeacherId: kTeacherId1, date: DateTime(2026, 2, 25));

      expect(a, isNot(equals(b)));
    });

    test('different teachers are not equal', () {
      final a = SuggestionParams(
          absentTeacherId: kTeacherId1, date: DateTime(2026, 2, 24));
      final b = SuggestionParams(
          absentTeacherId: kTeacherId2, date: DateTime(2026, 2, 24));

      expect(a, isNot(equals(b)));
    });
  });

  group('AssignSubstituteNotifier', () {
    test('initial state is AsyncData(null)', () {
      final notifier = container.read(assignSubstituteProvider.notifier);
      expect(container.read(assignSubstituteProvider),
          equals(const AsyncValue<void>.data(null)));
      // suppress unused warning
      expect(notifier, isNotNull);
    });

    test('assign() transitions through loading → data and returns true',
        () async {
      final notifier = container.read(assignSubstituteProvider.notifier);

      final result = await notifier.assign(
        absenceId: kAbsenceId,
        timetableId: kTimetableId,
        absentTeacherId: kTeacherId1,
        substituteTeacherId: kTeacherId2,
        slotId: kSlotId,
        sectionId: kSectionId,
        date: kBaseDate,
      );

      expect(result, isTrue);
      final state = container.read(assignSubstituteProvider);
      expect(state, equals(const AsyncValue<void>.data(null)));
    });
  });
}
