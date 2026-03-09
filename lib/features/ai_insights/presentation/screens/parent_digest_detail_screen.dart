import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/parent_digest_provider.dart';

class ParentDigestDetailScreen extends ConsumerWidget {
  final String digestId;

  const ParentDigestDetailScreen({
    super.key,
    required this.digestId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digestAsync = ref.watch(digestDetailProvider(digestId));

    return Scaffold(
      body: digestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (digest) {
          if (digest == null) {
            return const Center(child: Text('Digest not found'));
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    digest.weekLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.sunriseGradient,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Title
                    Text(
                      digest.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Summary
                    if (digest.summary != null &&
                        digest.summary!.isNotEmpty) ...[
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          digest.summary!,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Attendance overview
                    if (digest.attendance.total > 0) ...[
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 18, color: AppColors.primary),
                                SizedBox(width: 8),
                                Text(
                                  'Attendance This Week',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                              children: [
                                _AttStat(
                                  'Present',
                                  '${digest.attendance.present}',
                                  AppColors.success,
                                ),
                                _AttStat(
                                  'Absent',
                                  '${digest.attendance.absent}',
                                  AppColors.error,
                                ),
                                _AttStat(
                                  'Late',
                                  '${digest.attendance.late}',
                                  AppColors.warning,
                                ),
                                _AttStat(
                                  'Rate',
                                  '${digest.attendance.percentage.round()}%',
                                  AppColors.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Highlights
                    if (digest.highlights.isNotEmpty) ...[
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.star_outline,
                                    size: 18, color: AppColors.accent),
                                SizedBox(width: 8),
                                Text(
                                  'Academic Highlights',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            ...digest.highlights.map((h) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check_circle,
                                          size: 16,
                                          color: AppColors.success),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          h.description,
                                          style: const TextStyle(
                                              fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Upcoming events
                    if (digest.events.isNotEmpty) ...[
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.event,
                                    size: 18, color: AppColors.info),
                                SizedBox(width: 8),
                                Text(
                                  'Upcoming Events',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            ...digest.events.map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${e.date.day}/${e.date.month}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          color: AppColors.info,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          e.title,
                                          style: const TextStyle(
                                              fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Sections from template engine
                    ...digest.sections.map((section) {
                      Color sectionColor;
                      switch (section.urgency) {
                        case 'urgent':
                          sectionColor = AppColors.error;
                          break;
                        case 'attention':
                          sectionColor = AppColors.warning;
                          break;
                        default:
                          sectionColor = AppColors.primary;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.circle,
                                      size: 10, color: sectionColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    section.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: sectionColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                section.content,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AttStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AttStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
