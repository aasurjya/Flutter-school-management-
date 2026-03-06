import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/discipline_provider.dart';
import '../widgets/behavior_score_widget.dart';
import '../widgets/incident_card.dart';
import '../widgets/recognition_card.dart';

class StudentBehaviorProfileScreen extends ConsumerWidget {
  final String studentId;

  const StudentBehaviorProfileScreen({
    super.key,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(studentBehaviorScoreProvider(studentId));
    final historyAsync =
        ref.watch(studentBehaviorHistoryProvider(studentId));
    final recognitionsAsync =
        ref.watch(positiveRecognitionsProvider(studentId));
    final plansAsync = ref.watch(behaviorPlansProvider(studentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Behavior Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_add),
            onPressed: () => context.push('/discipline/plans'),
            tooltip: 'Create Plan',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Score ──
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: scoreAsync.when(
                data: (score) => BehaviorScoreWidget(score: score),
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox(
                  height: 100,
                  child: Center(child: Text('Score unavailable')),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Active Plans ──
            plansAsync.when(
              data: (plans) {
                final active = plans
                    .where((p) => p.status.name == 'active')
                    .toList();
                if (active.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active Behavior Plans',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...active.map((plan) => GlassCard(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.info.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.assignment_outlined,
                                  color: AppColors.info,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plan.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${plan.goals.length} goals',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // ── Incident History ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Incident History',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/discipline/incidents'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            historyAsync.when(
              data: (incidents) {
                if (incidents.isEmpty) {
                  return _EmptySection(
                    icon: Icons.check_circle_outline,
                    text: 'No incidents recorded',
                  );
                }
                return Column(
                  children: incidents
                      .take(5)
                      .map((inc) => IncidentCard(
                            incident: inc,
                            onTap: () => context
                                .push('/discipline/incidents/${inc.id}'),
                          ))
                      .toList(),
                );
              },
              loading: () => const SizedBox(
                height: 60,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const Text('Failed to load incidents'),
            ),
            const SizedBox(height: 24),

            // ── Recognitions ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recognitions',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      context.push('/discipline/recognitions'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            recognitionsAsync.when(
              data: (recs) {
                if (recs.isEmpty) {
                  return _EmptySection(
                    icon: Icons.star_outline,
                    text: 'No recognitions yet',
                  );
                }
                return Column(
                  children: recs
                      .take(5)
                      .map((r) => RecognitionCard(recognition: r))
                      .toList(),
                );
              },
              loading: () => const SizedBox(
                height: 60,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) =>
                  const Text('Failed to load recognitions'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptySection({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
