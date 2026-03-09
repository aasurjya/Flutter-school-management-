import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/report_card.dart';
import '../../../../data/models/report_card_full.dart';
import '../../providers/report_card_provider.dart';
import '../widgets/grade_table_widget.dart';
import '../widgets/attendance_summary_widget.dart';
import '../widgets/skills_radar_chart.dart';
import '../widgets/report_card_pdf_builder.dart';

class ReportCardDetailScreen extends ConsumerWidget {
  final String reportId;

  const ReportCardDetailScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(rcByIdProvider(reportId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Card'),
        actions: [
          IconButton(
            icon: const Icon(Icons.comment_outlined),
            onPressed: () =>
                context.push('/report-cards/comments/$reportId'),
            tooltip: 'Add Comments',
          ),
          IconButton(
            icon: const Icon(Icons.star_outline),
            onPressed: () =>
                context.push('/report-cards/skills/$reportId'),
            tooltip: 'Rate Skills',
          ),
          PopupMenuButton(
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'preview',
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf),
                  title: Text('PDF Preview'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'print',
                child: ListTile(
                  leading: Icon(Icons.print),
                  title: Text('Print'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'review',
                child: ListTile(
                  leading: Icon(Icons.check_circle_outline),
                  title: Text('Mark as Reviewed'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'publish',
                child: ListTile(
                  leading: Icon(Icons.publish),
                  title: Text('Publish'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (value) => _handleAction(context, ref, value),
          ),
        ],
      ),
      body: reportAsync.when(
        data: (report) {
          if (report == null) {
            return const Center(child: Text('Report not found'));
          }
          return _ReportCardDetailContent(report: report);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: reportAsync.whenOrNull(
        data: (report) {
          if (report == null) return null;
          return FloatingActionButton.extended(
            onPressed: () => _previewPdf(context, report),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('PDF Preview'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          );
        },
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) async {
    final repo = ref.read(rcFullRepositoryProvider);

    switch (action) {
      case 'preview':
        final report = ref.read(rcByIdProvider(reportId)).valueOrNull;
        if (report != null) _previewPdf(context, report);
        break;
      case 'print':
        final report = ref.read(rcByIdProvider(reportId)).valueOrNull;
        if (report != null) {
          final data = report.data.isNotEmpty
              ? ReportCardData.fromJson(report.data)
              : null;
          if (data != null) {
            final pdfBytes = await ReportCardPdfBuilder.build(
              data: data,
              comments: report.comments,
              skills: report.skills,
              activities: report.activities,
            );
            await Printing.layoutPdf(onLayout: (_) => pdfBytes);
          }
        }
        break;
      case 'review':
        try {
          await repo.reviewReportCard(reportId);
          ref.invalidate(rcByIdProvider(reportId));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Marked as reviewed'),
                  backgroundColor: AppColors.success),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: AppColors.error),
            );
          }
        }
        break;
      case 'publish':
        try {
          await repo.publishReportCards([reportId]);
          ref.invalidate(rcByIdProvider(reportId));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Report card published'),
                  backgroundColor: AppColors.success),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: AppColors.error),
            );
          }
        }
        break;
    }
  }

  void _previewPdf(BuildContext context, ReportCardFull report) {
    context.push('/report-cards/preview/$reportId');
  }
}

class _ReportCardDetailContent extends StatelessWidget {
  final ReportCardFull report;

  const _ReportCardDetailContent({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = report.data.isNotEmpty
        ? ReportCardData.fromJson(report.data)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Bar
              _StatusBar(report: report),
              const SizedBox(height: 16),

              // Student Info Card
              _StudentInfoCard(report: report, data: data),
              const SizedBox(height: 16),

              // Academic Performance (Grades Table)
              if (data != null && data.grades.isNotEmpty) ...[
                Text(
                  'Academic Performance',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GradeTableWidget(
                  grades: data.grades,
                  overallPercentage: data.overallPercentage,
                  overallGrade: data.overallGrade,
                  rank: data.rank,
                  totalStudents: data.totalStudents,
                ),
                const SizedBox(height: 24),
              ],

              // Attendance
              if (data != null) ...[
                Text(
                  'Attendance Summary',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                AttendanceSummaryWidget(
                  daysPresent: data.daysPresent,
                  totalDays: data.totalDays,
                  attendancePercentage: data.attendancePercentage,
                ),
                const SizedBox(height: 24),
              ],

              // Skills Radar
              if (report.skills.isNotEmpty) ...[
                Text(
                  'Co-Scholastic Skills',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SkillsRadarChart(skills: report.skills),
                const SizedBox(height: 24),
              ],

              // Activities
              if (report.activities.isNotEmpty) ...[
                Text(
                  'Activities & Achievements',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _ActivitiesSection(activities: report.activities),
                const SizedBox(height: 24),
              ],

              // Comments
              if (report.comments.isNotEmpty) ...[
                Text(
                  'Remarks',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _CommentsSection(comments: report.comments),
                const SizedBox(height: 24),
              ],

              // Signature Section
              _SignaturesSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final ReportCardFull report;
  const _StatusBar({required this.report});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _StatusDot(report.status),
          const SizedBox(width: 8),
          Text(
            'Status: ${report.statusDisplay}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (report.generatedAt != null)
            Text(
              'Generated: ${_formatDate(report.generatedAt!)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          if (report.publishedAt != null) ...[
            const SizedBox(width: 16),
            Text(
              'Published: ${_formatDate(report.publishedAt!)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
}

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'draft':
        color = Colors.orange;
      case 'generated':
        color = AppColors.info;
      case 'reviewed':
        color = AppColors.accent;
      case 'published':
        color = AppColors.success;
      case 'sent':
        color = AppColors.primary;
      default:
        color = Colors.grey;
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _StudentInfoCard extends StatelessWidget {
  final ReportCardFull report;
  final ReportCardData? data;

  const _StudentInfoCard({required this.report, this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary,
            child: Text(
              (data?.studentName ?? report.studentName ?? 'S')[0]
                  .toUpperCase(),
              style: const TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data?.studentName ?? report.studentDisplayName,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _InfoChip(
                      'Roll: ${data?.rollNumber ?? report.rollNumber ?? "N/A"}',
                      Icons.numbers,
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(
                      data?.className ?? report.className ?? '',
                      Icons.class_,
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(
                      data?.sectionName ?? report.sectionName ?? '',
                      Icons.group,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${data?.academicYear ?? report.academicYearName ?? ""} | ${data?.term ?? report.termName ?? ""}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (data != null && data!.rank > 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.emoji_events,
                      color: Colors.amber, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    '#${data!.rank}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.amber,
                    ),
                  ),
                  Text(
                    'of ${data!.totalStudents}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  final IconData icon;
  const _InfoChip(this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

class _ActivitiesSection extends StatelessWidget {
  final List<ReportCardActivity> activities;
  const _ActivitiesSection({required this.activities});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: activities.map((a) {
          IconData icon;
          switch (a.activityType) {
            case 'sports':
              icon = Icons.sports_soccer;
            case 'arts':
              icon = Icons.palette;
            case 'clubs':
              icon = Icons.groups;
            case 'community_service':
              icon = Icons.volunteer_activism;
            default:
              icon = Icons.star;
          }

          return ListTile(
            leading: Icon(icon, color: AppColors.primary),
            title: Text(a.activityName),
            subtitle: a.achievement != null
                ? Text(a.achievement!)
                : null,
            trailing: a.grade != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gradeColor(a.grade!)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      a.grade!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.gradeColor(a.grade!),
                      ),
                    ),
                  )
                : null,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ),
    );
  }
}

class _CommentsSection extends StatelessWidget {
  final List<ReportCardComment> comments;
  const _CommentsSection({required this.comments});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: comments.map((c) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      c.commentTypeDisplay,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                    if (c.isAiGenerated) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  c.commentText,
                  style: theme.textTheme.bodyMedium,
                ),
                if (comments.last != c) const Divider(height: 16),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SignaturesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SignatureBlock('Class Teacher'),
          _SignatureBlock('Principal'),
          _SignatureBlock('Parent/Guardian'),
        ],
      ),
    );
  }
}

class _SignatureBlock extends StatelessWidget {
  final String label;
  const _SignatureBlock(this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(width: 100, height: 1, color: Colors.grey),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
