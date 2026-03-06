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

class InquiryListScreen extends ConsumerStatefulWidget {
  const InquiryListScreen({super.key});

  @override
  ConsumerState<InquiryListScreen> createState() => _InquiryListScreenState();
}

class _InquiryListScreenState extends ConsumerState<InquiryListScreen> {
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(inquiryNotifierProvider.notifier).loadInquiries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inquiriesState = ref.watch(inquiryNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admission Inquiries'),
      ),
      body: Column(
        children: [
          // Status filter chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildFilterChip('All', null),
                _buildFilterChip('New', 'new'),
                _buildFilterChip('Contacted', 'contacted'),
                _buildFilterChip('Visit Scheduled', 'visit_scheduled'),
                _buildFilterChip('Converted', 'converted'),
                _buildFilterChip('Lost', 'lost'),
              ],
            ),
          ),
          Expanded(
            child: inquiriesState.when(
              data: (inquiries) {
                final filtered = _selectedStatus == null
                    ? inquiries
                    : inquiries
                        .where((i) => i.status.value == _selectedStatus)
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.contact_mail,
                            size: 64, color: AppColors.textTertiaryLight),
                        const SizedBox(height: 16),
                        Text(
                          'No inquiries found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a new inquiry to get started',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiaryLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(inquiryNotifierProvider.notifier)
                        .loadInquiries();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildInquiryTile(
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
                          .read(inquiryNotifierProvider.notifier)
                          .loadInquiries(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.admissionInquiryForm),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedStatus = selected ? status : null;
          });
        },
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primary,
      ),
    );
  }

  Widget _buildInquiryTile(
      BuildContext context, AdmissionInquiry inquiry, bool isDark) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: () => context.push(
        AppRoutes.admissionInquiryForm,
        extra: inquiry,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  inquiry.studentName.isNotEmpty
                      ? inquiry.studentName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inquiry.studentName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Parent: ${inquiry.parentName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              InquiryStatusBadge(status: inquiry.status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.phone, size: 14, color: AppColors.textTertiaryLight),
              const SizedBox(width: 4),
              Text(
                inquiry.phone,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: 16),
              Icon(Icons.source, size: 14, color: AppColors.textTertiaryLight),
              const SizedBox(width: 4),
              Text(
                inquiry.source.label,
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                dateFormat.format(inquiry.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),
          if (inquiry.nextFollowupDate != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule,
                      size: 12, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    'Follow-up: ${dateFormat.format(inquiry.nextFollowupDate!)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
