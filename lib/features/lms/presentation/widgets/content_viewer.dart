import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/lms.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Widget that renders different content types
class ContentViewer extends StatelessWidget {
  final ModuleContent content;
  final VoidCallback? onCompleted;

  const ContentViewer({
    super.key,
    required this.content,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    switch (content.contentType) {
      case ContentType.video:
        return _VideoContent(content: content, onCompleted: onCompleted);
      case ContentType.document:
      case ContentType.presentation:
        return _DocumentContent(content: content, onCompleted: onCompleted);
      case ContentType.link:
        return _LinkContent(content: content, onCompleted: onCompleted);
      case ContentType.text:
        return _TextContent(content: content, onCompleted: onCompleted);
      case ContentType.quiz:
        return _QuizContent(content: content, onCompleted: onCompleted);
      case ContentType.assignment:
        return _AssignmentContent(content: content, onCompleted: onCompleted);
    }
  }
}

class _VideoContent extends StatelessWidget {
  final ModuleContent content;
  final VoidCallback? onCompleted;

  const _VideoContent({required this.content, this.onCompleted});

  @override
  Widget build(BuildContext context) {
    final url = content.url;
    final duration = content.duration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video placeholder / thumbnail
        GlassCard(
          padding: EdgeInsets.zero,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow,
                          size: 40, color: Colors.white),
                    ),
                    if (duration != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (url != null)
          Center(
            child: FilledButton.icon(
              onPressed: () => _launchUrl(context, url),
              icon: const Icon(Icons.play_circle_outlined),
              label: const Text('Open Video'),
            ),
          ),
        const SizedBox(height: 12),
        if (onCompleted != null) _MarkCompleteButton(onCompleted: onCompleted!),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _DocumentContent extends StatelessWidget {
  final ModuleContent content;
  final VoidCallback? onCompleted;

  const _DocumentContent({required this.content, this.onCompleted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = content.url;
    final fileSize = content.fileSize;
    final isPresentation =
        content.contentType == ContentType.presentation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                isPresentation
                    ? Icons.slideshow_outlined
                    : Icons.description_outlined,
                size: 64,
                color: isPresentation
                    ? AppColors.warning
                    : AppColors.info,
              ),
              const SizedBox(height: 16),
              Text(
                content.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (fileSize != null) ...[
                const SizedBox(height: 8),
                Text(
                  _formatFileSize(fileSize),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (url != null)
                FilledButton.icon(
                  onPressed: () => _launchUrl(context, url),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(isPresentation
                      ? 'Open Presentation'
                      : 'Open Document'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (onCompleted != null) _MarkCompleteButton(onCompleted: onCompleted!),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _LinkContent extends StatelessWidget {
  final ModuleContent content;
  final VoidCallback? onCompleted;

  const _LinkContent({required this.content, this.onCompleted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = content.url;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(20),
          onTap: url != null ? () => _launchUrl(context, url) : null,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.link,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (url != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        url,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.info,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.open_in_new,
                  size: 18, color: AppColors.primary),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (onCompleted != null) _MarkCompleteButton(onCompleted: onCompleted!),
      ],
    );
  }
}

class _TextContent extends StatelessWidget {
  final ModuleContent content;
  final VoidCallback? onCompleted;

  const _TextContent({required this.content, this.onCompleted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = content.text ?? content.contentData['text'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                text.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (onCompleted != null) _MarkCompleteButton(onCompleted: onCompleted!),
      ],
    );
  }
}

class _QuizContent extends StatelessWidget {
  final ModuleContent content;
  final VoidCallback? onCompleted;

  const _QuizContent({required this.content, this.onCompleted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.quiz_outlined,
                    size: 32, color: AppColors.success),
              ),
              const SizedBox(height: 16),
              Text(
                content.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Complete this quiz to proceed',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  // Navigate to quiz if linked
                  final quizId = content.contentData['quiz_id'];
                  if (quizId != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening quiz...')),
                    );
                  }
                  onCompleted?.call();
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Quiz'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AssignmentContent extends StatelessWidget {
  final ModuleContent content;
  final VoidCallback? onCompleted;

  const _AssignmentContent({required this.content, this.onCompleted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.assignment_outlined,
                    size: 32, color: AppColors.warning),
              ),
              const SizedBox(height: 16),
              Text(
                content.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Complete this assignment to proceed',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  final assignmentId =
                      content.contentData['assignment_id'];
                  if (assignmentId != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Opening assignment...')),
                    );
                  }
                  onCompleted?.call();
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Start Assignment'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MarkCompleteButton extends StatelessWidget {
  final VoidCallback onCompleted;

  const _MarkCompleteButton({required this.onCompleted});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: onCompleted,
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Mark as Complete'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.success,
          side: const BorderSide(color: AppColors.success),
        ),
      ),
    );
  }
}

Future<void> _launchUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri != null && await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open: $url')),
      );
    }
  }
}
