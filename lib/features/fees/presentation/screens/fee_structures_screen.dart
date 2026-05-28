import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/copy/warm_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../academic/providers/academic_provider.dart';
import '../../providers/fees_provider.dart';

/// Read-only listing of fee structures for the current academic year, grouped
/// by class. Replaces the "Fee Structure" snackbar stub on the Fees screen.
class FeeStructuresScreen extends ConsumerWidget {
  const FeeStructuresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearAsync = ref.watch(currentAcademicYearProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Fee Structure')),
      body: yearAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(WarmCopy.loadFailed('the academic year')),
        ),
        data: (year) {
          if (year == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'No active academic year is set. Ask an admin to mark one current.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final structuresAsync = ref.watch(
            feeStructuresProvider(FeeStructureFilter(academicYearId: year.id)),
          );
          return RefreshIndicator.adaptive(
            onRefresh: () async => ref.invalidate(feeStructuresProvider),
            child: structuresAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Text(WarmCopy.loadFailed('fee structures')),
                  ),
                ],
              ),
              data: (structures) {
                if (structures.isEmpty) {
                  return ListView(
                    children: const [
                      SizedBox(height: 80),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            'No fee structures configured for this year yet.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  );
                }
                // Group by class name. Items without a className join fall
                // into an "Unassigned" bucket.
                final grouped = <String, List>{};
                for (final s in structures) {
                  final key = (s.className ?? '').isEmpty
                      ? 'Unassigned'
                      : s.className!;
                  (grouped[key] ??= []).add(s);
                }
                final classKeys = grouped.keys.toList()..sort();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                  itemCount: classKeys.length,
                  itemBuilder: (context, i) {
                    final className = classKeys[i];
                    final rows = grouped[className]!;
                    final total = rows.fold<double>(
                      0,
                      (sum, r) => sum + (r.amount as double),
                    );
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: AppColors.textTertiaryLight
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListTile(
                              title: Text(
                                className,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${rows.length} item${rows.length == 1 ? '' : 's'} · '
                                '₹${total.toStringAsFixed(0)}',
                              ),
                            ),
                            const Divider(height: 1),
                            ...rows.map(
                              (s) => ListTile(
                                dense: true,
                                title: Text(s.feeHeadName ?? 'Fee head'),
                                subtitle: s.termName != null
                                    ? Text('Term: ${s.termName}')
                                    : null,
                                trailing: Text(
                                  '₹${(s.amount as double).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
