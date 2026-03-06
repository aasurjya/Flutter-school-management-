import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/lms.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/lms_provider.dart';
import '../widgets/module_list_widget.dart';
import '../widgets/progress_tracker.dart';

class CourseProgressScreen extends ConsumerStatefulWidget {
  final String enrollmentId;

  const CourseProgressScreen({super.key, required this.enrollmentId});

  @override
  ConsumerState<CourseProgressScreen> createState() =>
      _CourseProgressScreenState();
}

class _CourseProgressScreenState
    extends ConsumerState<CourseProgressScreen> {
  CourseEnrollment? _enrollment;
  Course? _course;
  Map<String, ContentProgressStatus> _progressMap = {};
  List<ContentProgress> _progressList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(lmsRepositoryProvider);

      // Load enrollment with course data
      final enrollments = await repo.getEnrollments(
        studentId: repo.currentUserId,
      );
      _enrollment =
          enrollments.where((e) => e.id == widget.enrollmentId).firstOrNull;

      if (_enrollment != null) {
        _course = _enrollment!.course ??
            await repo.getCourseById(_enrollment!.courseId);

        // Load progress data
        _progressList =
            await repo.getContentProgress(widget.enrollmentId);
        _progressMap = {
          for (final p in _progressList) p.contentId: p.status,
        };
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading progress: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_course?.title ?? 'Course Progress'),
        actions: [
          if (_course != null)
            IconButton(
              icon: const Icon(Icons.forum_outlined),
              tooltip: 'Discussions',
              onPressed: () => context.push(
                AppRoutes.lmsDiscussionForum
                    .replaceAll(':courseId', _course!.id),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _enrollment == null
              ? const Center(child: Text('Enrollment not found'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Progress tracker card
                      _buildProgressTracker(),
                      const SizedBox(height: 20),

                      // Certificate section
                      if (_enrollment!.status ==
                          EnrollmentStatus.completed) ...[
                        _buildCompletedBanner(),
                        const SizedBox(height: 16),
                      ],

                      // Modules with progress
                      Text(
                        'Course Content',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ModuleListWidget(
                        modules: _course?.modules ?? [],
                        contentProgressMap: _progressMap,
                        onContentTap: (content, module) {
                          context.push(
                            AppRoutes.lmsModuleContent
                                .replaceAll(
                                    ':enrollmentId', widget.enrollmentId)
                                .replaceAll(':moduleId', module.id)
                                .replaceAll(':contentId', content.id),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProgressTracker() {
    final allContent = _course?.modules
            ?.expand((m) => m.contents ?? <ModuleContent>[])
            .toList() ??
        [];
    final totalContent = allContent.length;
    final completedContent = _progressList
        .where((p) => p.status == ContentProgressStatus.completed)
        .length;
    final inProgressContent = _progressList
        .where((p) => p.status == ContentProgressStatus.inProgress)
        .length;
    final notStartedContent =
        totalContent - completedContent - inProgressContent;

    // Module completion
    final totalModules = _course?.modules?.length ?? 0;
    int completedModules = 0;
    for (final module in _course?.modules ?? <CourseModule>[]) {
      final moduleContents = module.contents ?? [];
      if (moduleContents.isEmpty) continue;
      final allCompleted = moduleContents.every((c) =>
          _progressMap[c.id] == ContentProgressStatus.completed);
      if (allCompleted) completedModules++;
    }

    final totalTimeSpent = _progressList.fold<int>(
        0, (sum, p) => sum + p.timeSpentSeconds);

    return ProgressTrackerCard(
      totalContent: totalContent,
      completedContent: completedContent,
      inProgressContent: inProgressContent,
      notStartedContent: notStartedContent.clamp(0, totalContent),
      totalModules: totalModules,
      completedModules: completedModules,
      timeSpentSeconds: totalTimeSpent,
    );
  }

  Widget _buildCompletedBanner() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderColor: AppColors.success.withValues(alpha: 0.5),
      child: Column(
        children: [
          const Icon(Icons.celebration,
              size: 48, color: AppColors.success),
          const SizedBox(height: 12),
          Text(
            'Congratulations!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'You have completed this course',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push(
              AppRoutes.lmsCertificate
                  .replaceAll(':enrollmentId', widget.enrollmentId),
            ),
            icon: const Icon(Icons.workspace_premium),
            label: const Text('View Certificate'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
