import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/core/theme/app_colors.dart';
import 'package:school_management/core/theme/motion.dart';
import 'package:school_management/core/theme/spacing.dart';

void main() {
  group('AppSpacing — 4-point grid invariants', () {
    test('every constant is a multiple of 4', () {
      final tokens = [
        AppSpacing.xxs,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ];
      for (final t in tokens) {
        expect(t % 4, 0, reason: 'spacing token $t breaks the 4-point grid');
      }
    });

    test('scale is strictly ascending', () {
      expect(AppSpacing.xxs, lessThan(AppSpacing.xs));
      expect(AppSpacing.xs,  lessThan(AppSpacing.sm));
      expect(AppSpacing.sm,  lessThan(AppSpacing.md));
      expect(AppSpacing.md,  lessThan(AppSpacing.lg));
      expect(AppSpacing.lg,  lessThan(AppSpacing.xl));
      expect(AppSpacing.xl,  lessThan(AppSpacing.xxl));
    });
  });

  group('Motion — Apple HIG durations', () {
    test('tap < subtle < transition < deliberate', () {
      expect(Motion.tap.inMilliseconds,        lessThan(Motion.subtle.inMilliseconds));
      expect(Motion.subtle.inMilliseconds,     lessThan(Motion.transition.inMilliseconds));
      expect(Motion.transition.inMilliseconds, lessThan(Motion.deliberate.inMilliseconds));
    });

    test('transition uses Apple standard curve', () {
      expect(Motion.standard, isA<Cubic>());
    });
  });

  group('AppColors — Apple label hierarchy', () {
    test('labelFor returns 4 distinct opacities on light brightness', () {
      final tier1 = AppColors.labelFor(Brightness.light, tier: 1);
      final tier2 = AppColors.labelFor(Brightness.light, tier: 2);
      final tier3 = AppColors.labelFor(Brightness.light, tier: 3);
      final tier4 = AppColors.labelFor(Brightness.light, tier: 4);
      // ignore: deprecated_member_use, deprecated_member_use_from_same_package
      expect({tier1.value, tier2.value, tier3.value, tier4.value}.length, 4);
    });

    test('groupedBackgroundFor returns correct token per brightness', () {
      expect(AppColors.groupedBackgroundFor(Brightness.light),
          AppColors.systemGroupedBackground);
      expect(AppColors.groupedBackgroundFor(Brightness.dark),
          AppColors.systemGroupedBackgroundDark);
    });
  });
}
