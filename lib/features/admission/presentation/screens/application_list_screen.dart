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

class ApplicationListScreen extends ConsumerStatefulWidget {
  const ApplicationListScreen({super.key});

  @override
  ConsumerState<ApplicationListScreen> createState() =>
      _ApplicationListScreenState();
}

class _ApplicationListScreenState extends ConsumerState<ApplicationListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    ('All', null),
    ('Submitted', 'submitted'),
    ('Review', 'under_review'),
    ('Interview', 'interview_scheduled'),
    ('Accepted', 'accepted'),
    ('Rejected', 'rejected'),
    ('Waitlisted', 'waitlisted'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    Future.microtask(() {
      ref.read(admissionNotifierProvider.notifier).loadApplications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final applicationsState = ref.watch(admissionNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Applications'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((t) => Tab(text: t.$1)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) {
          return applicationsState.when(
            data: (apps) {
              final filtered = tab.$2 == null
                  ? apps
                  : apps.where((a) => a.status.value == tab.$2).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description,
                          size: 64, color: AppColors.textTertiaryLight),
                      const SizedBox(height: 16),
                      Text(
                        'No ${tab.$2 ?? ""} applications',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await ref
                      .read(admissionNotifierProvider.notifier)
                      .loadApplications();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildApplicationCard(
                        context, filtered[index], isDark);
                  },
                ),
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text('Error: $e'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => ref
                        .read(admissionNotifierProvider.notifier)
                        .loadApplications(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.admissionApplicationForm),
        icon: const Icon(Icons.add),
        label: const Text('New Application'),
      ),
    );
  }

  Widget _buildApplicationCard(
      BuildContext context, AdmissionApplication app, bool isDark) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      onTap: () => context.push(
        AppRoutes.admissionApplicationDetail
            .replaceAll(':applicationId', app.id),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  app.studentName.isNotEmpty
                      ? app.studentName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.studentName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      app.applicationNumber ?? 'Draft',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              ApplicationStatusBadge(status: app.status),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoChip(Icons.class_, app.className ?? 'N/A', isDark),
              const SizedBox(width: 12),
              _infoChip(Icons.cake, '${app.age} yrs', isDark),
              const SizedBox(width: 12),
              _infoChip(Icons.person, app.gender, isDark),
              const Spacer(),
              Text(
                dateFormat.format(app.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),
          if (app.previousSchool != null && app.previousSchool!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.school,
                    size: 14, color: AppColors.textTertiaryLight),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'From: ${app.previousSchool}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiaryLight),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
