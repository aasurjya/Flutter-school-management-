import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/discipline.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/discipline_provider.dart';
import '../widgets/recognition_card.dart';

class PositiveRecognitionScreen extends ConsumerStatefulWidget {
  const PositiveRecognitionScreen({super.key});

  @override
  ConsumerState<PositiveRecognitionScreen> createState() =>
      _PositiveRecognitionScreenState();
}

class _PositiveRecognitionScreenState
    extends ConsumerState<PositiveRecognitionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Positive Recognition'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Wall of Fame'),
            Tab(text: 'Leaderboard'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _WallOfFameTab(),
          _LeaderboardTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAwardDialog(context),
        icon: const Icon(Icons.star_outline),
        label: const Text('Award Points'),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAwardDialog(BuildContext context) {
    final studentIdController = TextEditingController();
    final descController = TextEditingController();
    int points = 5;
    String? categoryId;
    bool isPublic = true;

    final categoriesAsync =
        ref.read(behaviorCategoriesProvider(BehaviorCategoryType.positive));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.success, size: 28),
                        const SizedBox(width: 8),
                        const Text(
                          'Award Recognition',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: studentIdController,
                      decoration: const InputDecoration(
                        labelText: 'Student ID *',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category
                    categoriesAsync.when(
                      data: (cats) => DropdownButtonFormField<String>(
                        value: categoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: cats.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text('${c.name} (+${c.points} pts)'),
                          );
                        }).toList(),
                        onChanged: (v) {
                          setSheetState(() {
                            categoryId = v;
                            // Auto-set points from category
                            final cat =
                                cats.firstWhere((c) => c.id == v);
                            points = cat.points;
                          });
                        },
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) =>
                          const Text('Failed to load categories'),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Reason / Description *',
                        hintText: 'Why is this student being recognized?',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),

                    // Points slider
                    Row(
                      children: [
                        const Text('Points: ',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Expanded(
                          child: Slider(
                            value: points.toDouble(),
                            min: 1,
                            max: 50,
                            divisions: 49,
                            label: '$points',
                            activeColor: AppColors.success,
                            onChanged: (v) {
                              setSheetState(() => points = v.round());
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+$points',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    SwitchListTile(
                      title: const Text('Show on Wall of Fame'),
                      subtitle: const Text(
                        'Make this recognition visible to everyone',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: isPublic,
                      activeColor: AppColors.success,
                      onChanged: (v) => setSheetState(() => isPublic = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (studentIdController.text.trim().isEmpty ||
                              descController.text.trim().isEmpty) return;
                          Navigator.pop(ctx);
                          await _awardRecognition(
                            studentId: studentIdController.text.trim(),
                            description: descController.text.trim(),
                            categoryId: categoryId,
                            points: points,
                            isPublic: isPublic,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Award Recognition',
                          style: TextStyle(fontWeight: FontWeight.w600),
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
    );
  }

  Future<void> _awardRecognition({
    required String studentId,
    required String description,
    String? categoryId,
    required int points,
    required bool isPublic,
  }) async {
    try {
      final repo = ref.read(disciplineRepositoryProvider);
      final rec = PositiveRecognition(
        id: '',
        tenantId: repo.requireTenantId,
        studentId: studentId,
        recognizedBy: repo.requireUserId,
        categoryId: categoryId,
        description: description,
        pointsAwarded: points,
        isPublic: isPublic,
        createdAt: DateTime.now(),
      );
      await repo.createRecognition(rec);

      if (mounted) {
        context.showSuccessSnackBar('Recognition awarded!');
        ref.invalidate(publicRecognitionsProvider);
        ref.invalidate(topPositiveStudentsProvider);
        ref.invalidate(positiveRecognitionsProvider(null));
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed: $e');
      }
    }
  }
}

class _WallOfFameTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recsAsync = ref.watch(publicRecognitionsProvider);

    return recsAsync.when(
      data: (recs) {
        if (recs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_outline, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No recognitions yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Award positive recognition to students',
                  style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(publicRecognitionsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recs.length,
            itemBuilder: (context, idx) =>
                RecognitionCard(recognition: recs[idx]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _LeaderboardTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topAsync = ref.watch(topPositiveStudentsProvider);

    return topAsync.when(
      data: (students) {
        if (students.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.leaderboard_outlined,
                    size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Leaderboard is empty',
                  style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          itemBuilder: (context, idx) {
            final data = students[idx];
            final student = data['students'] as Map<String, dynamic>?;
            final name = student != null
                ? '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'
                    .trim()
                : 'Student';
            final posPoints = data['positive_points'] ?? 0;
            final negPoints = data['negative_points'] ?? 0;
            final netScore = data['net_score'] ?? 0;

            Color medalColor;
            IconData? medalIcon;
            if (idx == 0) {
              medalColor = const Color(0xFFFFD700);
              medalIcon = Icons.emoji_events;
            } else if (idx == 1) {
              medalColor = const Color(0xFFC0C0C0);
              medalIcon = Icons.emoji_events;
            } else if (idx == 2) {
              medalColor = const Color(0xFFCD7F32);
              medalIcon = Icons.emoji_events;
            } else {
              medalColor = Colors.grey;
              medalIcon = null;
            }

            return GlassCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: medalIcon != null
                        ? Icon(medalIcon, color: medalColor, size: 28)
                        : Text(
                            '#${idx + 1}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[500],
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: student?['photo_url'] != null
                        ? NetworkImage(student!['photo_url'])
                        : null,
                    child: student?['photo_url'] == null
                        ? Text(
                            name.isNotEmpty
                                ? name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Text(
                              '+$posPoints',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '-$negPoints',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: netScore >= 0
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$netScore pts',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: netScore >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
