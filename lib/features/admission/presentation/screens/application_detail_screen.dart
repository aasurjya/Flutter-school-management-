import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/admission.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/admission_provider.dart';
import '../widgets/application_status_badge.dart';
import '../widgets/document_checklist_widget.dart';

class ApplicationDetailScreen extends ConsumerWidget {
  final String applicationId;

  const ApplicationDetailScreen({
    super.key,
    required this.applicationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appAsync = ref.watch(applicationByIdProvider(applicationId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
        actions: [
          appAsync.whenOrNull(
                data: (app) {
                  if (app == null) return null;
                  return PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleAction(context, ref, app, value),
                    itemBuilder: (context) => [
                      if (app.status == ApplicationStatus.submitted ||
                          app.status == ApplicationStatus.underReview)
                        const PopupMenuItem(
                          value: 'review',
                          child: ListTile(
                            leading: Icon(Icons.rate_review),
                            title: Text('Mark Under Review'),
                            dense: true,
                          ),
                        ),
                      if (app.status != ApplicationStatus.accepted &&
                          app.status != ApplicationStatus.enrolled)
                        const PopupMenuItem(
                          value: 'accept',
                          child: ListTile(
                            leading:
                                Icon(Icons.check_circle, color: AppColors.success),
                            title: Text('Accept'),
                            dense: true,
                          ),
                        ),
                      if (app.status != ApplicationStatus.rejected &&
                          app.status != ApplicationStatus.enrolled)
                        const PopupMenuItem(
                          value: 'reject',
                          child: ListTile(
                            leading: Icon(Icons.cancel, color: AppColors.error),
                            title: Text('Reject'),
                            dense: true,
                          ),
                        ),
                      if (app.status != ApplicationStatus.waitlisted &&
                          app.status != ApplicationStatus.enrolled)
                        const PopupMenuItem(
                          value: 'waitlist',
                          child: ListTile(
                            leading:
                                Icon(Icons.hourglass_empty, color: AppColors.warning),
                            title: Text('Waitlist'),
                            dense: true,
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'interview',
                        child: ListTile(
                          leading: Icon(Icons.event),
                          title: Text('Schedule Interview'),
                          dense: true,
                        ),
                      ),
                    ],
                  );
                },
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: appAsync.when(
        data: (app) {
          if (app == null) {
            return const Center(child: Text('Application not found'));
          }
          return _buildContent(context, ref, app, isDark);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref,
      AdmissionApplication app, bool isDark) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(applicationByIdProvider(applicationId));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    app.studentName.isNotEmpty
                        ? app.studentName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  app.studentName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  app.applicationNumber ?? 'Draft',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 12),
                ApplicationStatusBadge(status: app.status, large: true),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Status timeline
          _buildStatusTimeline(context, app, isDark),
          const SizedBox(height: 16),

          // Student info
          _buildInfoSection(
            context,
            'Student Information',
            Icons.person,
            [
              _InfoRow('Name', app.studentName),
              _InfoRow('Date of Birth', dateFormat.format(app.dateOfBirth)),
              _InfoRow('Age', '${app.age} years'),
              _InfoRow('Gender', app.gender),
              _InfoRow('Applying for', app.className ?? 'N/A'),
              if (app.previousSchool != null)
                _InfoRow('Previous School', app.previousSchool!),
              if (app.previousClass != null)
                _InfoRow('Previous Class', app.previousClass!),
            ],
            isDark,
          ),
          const SizedBox(height: 16),

          // Parent info
          _buildInfoSection(
            context,
            'Parent Information',
            Icons.family_restroom,
            [
              if (app.parentInfo.fatherName != null)
                _InfoRow('Father', app.parentInfo.fatherName!),
              if (app.parentInfo.fatherPhone != null)
                _InfoRow('Father Phone', app.parentInfo.fatherPhone!),
              if (app.parentInfo.fatherEmail != null)
                _InfoRow('Father Email', app.parentInfo.fatherEmail!),
              if (app.parentInfo.fatherOccupation != null)
                _InfoRow('Father Occupation', app.parentInfo.fatherOccupation!),
              if (app.parentInfo.motherName != null)
                _InfoRow('Mother', app.parentInfo.motherName!),
              if (app.parentInfo.motherPhone != null)
                _InfoRow('Mother Phone', app.parentInfo.motherPhone!),
              if (app.parentInfo.motherEmail != null)
                _InfoRow('Mother Email', app.parentInfo.motherEmail!),
              if (app.parentInfo.motherOccupation != null)
                _InfoRow('Mother Occupation', app.parentInfo.motherOccupation!),
              if (app.parentInfo.guardianName != null)
                _InfoRow('Guardian', app.parentInfo.guardianName!),
              if (app.parentInfo.guardianPhone != null)
                _InfoRow('Guardian Phone', app.parentInfo.guardianPhone!),
            ],
            isDark,
          ),
          const SizedBox(height: 16),

          // Address
          if (app.address != null || app.city != null)
            _buildInfoSection(
              context,
              'Address',
              Icons.location_on,
              [_InfoRow('Address', app.fullAddress)],
              isDark,
            ),
          if (app.address != null || app.city != null)
            const SizedBox(height: 16),

          // Documents
          DocumentChecklistWidget(
            documents: app.applicationDocuments ?? [],
            requiredDocTypes: const [
              'birth_certificate',
              'report_card',
              'address_proof',
              'photo',
            ],
            canVerify: true,
            onVerify: (doc, status) async {
              try {
                final repo = ref.read(admissionRepositoryProvider);
                await repo.verifyDocument(doc.id, status: status);
                ref.invalidate(applicationByIdProvider(applicationId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Document ${status.label.toLowerCase()}'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 16),

          // Interviews
          if (app.interviews != null && app.interviews!.isNotEmpty) ...[
            _buildInterviewsSection(context, app.interviews!, isDark),
            const SizedBox(height: 16),
          ],

          // Status notes
          if (app.statusNotes != null && app.statusNotes!.isNotEmpty)
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notes,
                          size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Review Notes',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(app.statusNotes!),
                ],
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(
      BuildContext context, AdmissionApplication app, bool isDark) {
    final theme = Theme.of(context);
    final allStatuses = [
      ApplicationStatus.draft,
      ApplicationStatus.submitted,
      ApplicationStatus.underReview,
      ApplicationStatus.interviewScheduled,
      ApplicationStatus.accepted,
      ApplicationStatus.enrolled,
    ];

    final currentIndex = allStatuses.indexOf(app.status);
    final isTerminal =
        app.status == ApplicationStatus.rejected ||
        app.status == ApplicationStatus.withdrawn ||
        app.status == ApplicationStatus.waitlisted;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Application Timeline',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: Row(
              children: List.generate(allStatuses.length, (i) {
                final isPast = i <= currentIndex && !isTerminal;
                final isCurrent = allStatuses[i] == app.status;
                final color =
                    isPast || isCurrent ? AppColors.primary : AppColors.borderLight;

                return Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (i > 0)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: isPast ? AppColors.primary : AppColors.borderLight,
                              ),
                            ),
                          Container(
                            width: isCurrent ? 24 : 16,
                            height: isCurrent ? 24 : 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPast || isCurrent
                                  ? color
                                  : Colors.transparent,
                              border: Border.all(color: color, width: 2),
                            ),
                            child: isPast && !isCurrent
                                ? const Icon(Icons.check,
                                    size: 10, color: Colors.white)
                                : null,
                          ),
                          if (i < allStatuses.length - 1)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: isPast && i < currentIndex
                                    ? AppColors.primary
                                    : AppColors.borderLight,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        allStatuses[i].label,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isPast || isCurrent
                              ? (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight)
                              : AppColors.textTertiaryLight,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          if (isTerminal)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ApplicationStatusBadge(status: app.status, large: true),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, IconData icon,
      List<_InfoRow> rows, bool isDark) {
    final theme = Theme.of(context);
    if (rows.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(
                        row.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildInterviewsSection(
      BuildContext context, List<AdmissionInterview> interviews, bool isDark) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Interviews',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...interviews.map((interview) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dateFormat.format(interview.scheduledAt),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        InterviewStatusBadge(status: interview.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (interview.interviewerName != null)
                      Text(
                        'Interviewer: ${interview.interviewerName}',
                        style: theme.textTheme.bodySmall,
                      ),
                    if (interview.location != null)
                      Text(
                        'Location: ${interview.location}',
                        style: theme.textTheme.bodySmall,
                      ),
                    if (interview.score != null)
                      Text(
                        'Score: ${interview.score}/100',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (interview.feedback != null &&
                        interview.feedback!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        interview.feedback!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              )),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref,
      AdmissionApplication app, String action) {
    switch (action) {
      case 'review':
        _updateStatus(context, ref, app.id, ApplicationStatus.underReview);
        break;
      case 'accept':
        _showConfirmDialog(
            context, ref, app.id, ApplicationStatus.accepted, 'Accept');
        break;
      case 'reject':
        _showConfirmDialog(
            context, ref, app.id, ApplicationStatus.rejected, 'Reject');
        break;
      case 'waitlist':
        _showConfirmDialog(
            context, ref, app.id, ApplicationStatus.waitlisted, 'Waitlist');
        break;
      case 'interview':
        context.push(
          '${AppRoutes.admissionInterviews}?applicationId=${app.id}',
        );
        break;
    }
  }

  void _showConfirmDialog(BuildContext context, WidgetRef ref,
      String appId, ApplicationStatus status, String action) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action Application?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to $action this application?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus(
                context,
                ref,
                appId,
                status,
                notes: notesController.text.trim().isNotEmpty
                    ? notesController.text.trim()
                    : null,
              );
            },
            child: Text(action),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String appId,
    ApplicationStatus status, {
    String? notes,
  }) async {
    try {
      final repo = ref.read(admissionRepositoryProvider);
      await repo.updateApplicationStatus(
        appId,
        status: status,
        statusNotes: notes,
      );
      ref.invalidate(applicationByIdProvider(applicationId));
      ref.invalidate(admissionNotifierProvider);
      ref.invalidate(currentAdmissionStatsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application ${status.label.toLowerCase()}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _InfoRow {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
}
