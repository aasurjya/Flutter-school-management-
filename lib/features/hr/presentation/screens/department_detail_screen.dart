import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/hr_provider.dart';
import '../widgets/staff_card.dart';

class DepartmentDetailScreen extends ConsumerWidget {
  final String departmentId;

  const DepartmentDetailScreen({super.key, required this.departmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptAsync = ref.watch(departmentByIdProvider(departmentId));
    final designationsAsync = ref.watch(designationsProvider(departmentId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: deptAsync.when(
          data: (dept) => Text(dept.name),
          loading: () => const Text('Department'),
          error: (_, __) => const Text('Department'),
        ),
      ),
      body: deptAsync.when(
        data: (dept) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Department Info Card
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              dept.initials,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dept.name,
                                style:
                                    theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (dept.hodName != null)
                                Row(
                                  children: [
                                    const Icon(Icons.person,
                                        size: 16,
                                        color: AppColors.textSecondaryLight),
                                    const SizedBox(width: 4),
                                    Text(
                                      'HOD: ${dept.hodName}',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        color: AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (dept.description != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        dept.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Designations in this department
              Text(
                'Designations',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              designationsAsync.when(
                data: (designations) {
                  if (designations.isEmpty) {
                    return const GlassCard(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('No designations in this department'),
                      ),
                    );
                  }

                  return Column(
                    children: designations.map((des) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.info.withAlpha(20),
                            child: Text(
                              'L${des.level}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.info,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(
                            des.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                          subtitle: des.payGrade != null
                              ? Text('Pay Grade: ${des.payGrade}')
                              : null,
                          trailing: des.isActive
                              ? const Icon(Icons.check_circle,
                                  color: AppColors.success, size: 20)
                              : const Icon(Icons.cancel,
                                  color: AppColors.error, size: 20),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => AppErrorWidget(message: error.toString()),
              ),

              const SizedBox(height: 24),

              // Staff in Department placeholder
              Text(
                'Staff Members',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // In a full implementation, you'd filter staff by department
              StaffCard(
                name: dept.hodName ?? 'Head of Department',
                designation: 'HOD',
                department: dept.name,
                onTap: () {},
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorWidget(message: error.toString()),
      ),
    );
  }
}
