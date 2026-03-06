import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/lms.dart';
import '../../providers/lms_provider.dart';
import '../widgets/content_viewer.dart';

class ModuleContentScreen extends ConsumerStatefulWidget {
  final String enrollmentId;
  final String moduleId;
  final String contentId;

  const ModuleContentScreen({
    super.key,
    required this.enrollmentId,
    required this.moduleId,
    required this.contentId,
  });

  @override
  ConsumerState<ModuleContentScreen> createState() =>
      _ModuleContentScreenState();
}

class _ModuleContentScreenState extends ConsumerState<ModuleContentScreen> {
  ModuleContent? _content;
  ContentProgressStatus _progressStatus = ContentProgressStatus.notStarted;
  bool _isLoading = true;
  bool _isMarking = false;
  List<ModuleContent> _allContents = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(lmsRepositoryProvider);

      // Load all content for this module
      final contents = await repo.getContents(widget.moduleId);
      _allContents = contents;
      _currentIndex =
          contents.indexWhere((c) => c.id == widget.contentId);
      if (_currentIndex < 0) _currentIndex = 0;

      _content =
          _currentIndex < contents.length ? contents[_currentIndex] : null;

      // Load progress
      final progressList =
          await repo.getContentProgress(widget.enrollmentId);
      final contentProgress =
          progressList.where((p) => p.contentId == widget.contentId);
      if (contentProgress.isNotEmpty) {
        _progressStatus = contentProgress.first.status;
      }

      // Mark as in_progress if not started
      if (_progressStatus == ContentProgressStatus.notStarted) {
        await repo.upsertContentProgress(
          enrollmentId: widget.enrollmentId,
          contentId: widget.contentId,
          status: ContentProgressStatus.inProgress,
        );
        _progressStatus = ContentProgressStatus.inProgress;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading content: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markComplete() async {
    setState(() => _isMarking = true);
    try {
      final repo = ref.read(lmsRepositoryProvider);
      await repo.upsertContentProgress(
        enrollmentId: widget.enrollmentId,
        contentId: widget.contentId,
        status: ContentProgressStatus.completed,
      );

      // Recalculate course progress
      await repo.recalculateProgress(widget.enrollmentId);

      setState(
          () => _progressStatus = ContentProgressStatus.completed);

      ref.invalidate(contentProgressProvider);
      ref.invalidate(allMyEnrollmentsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content completed!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isMarking = false);
    }
  }

  void _navigateToContent(int index) {
    if (index >= 0 && index < _allContents.length) {
      setState(() {
        _currentIndex = index;
        _content = _allContents[index];
        _progressStatus = ContentProgressStatus.notStarted;
      });
      _loadContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_content?.title ?? 'Content'),
        actions: [
          if (_progressStatus == ContentProgressStatus.completed)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.check_circle,
                  color: AppColors.success),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _content == null
              ? const Center(child: Text('Content not found'))
              : Column(
                  children: [
                    // Progress indicator
                    if (_allContents.length > 1)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              '${_currentIndex + 1} of ${_allContents.length}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: (_currentIndex + 1) /
                                      _allContents.length,
                                  backgroundColor: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.2),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          AppColors.primary),
                                  minHeight: 4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: ContentViewer(
                          content: _content!,
                          onCompleted: _progressStatus !=
                                      ContentProgressStatus.completed &&
                                  !_isMarking
                              ? _markComplete
                              : null,
                        ),
                      ),
                    ),
                    // Navigation bar
                    if (_allContents.length > 1)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight,
                          border: Border(
                            top: BorderSide(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (_currentIndex > 0)
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _navigateToContent(_currentIndex - 1),
                                icon: const Icon(Icons.arrow_back, size: 18),
                                label: const Text('Previous'),
                              )
                            else
                              const SizedBox.shrink(),
                            const Spacer(),
                            if (_currentIndex < _allContents.length - 1)
                              FilledButton.icon(
                                onPressed: () =>
                                    _navigateToContent(_currentIndex + 1),
                                icon: const Icon(Icons.arrow_forward,
                                    size: 18),
                                label: const Text('Next'),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}
