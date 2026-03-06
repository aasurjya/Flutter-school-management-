import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/hr_payroll.dart';
import '../../providers/hr_provider.dart';
import '../widgets/attendance_calendar_widget.dart';
import '../widgets/contract_status_badge.dart';

class StaffProfileScreen extends ConsumerStatefulWidget {
  final String staffId;

  const StaffProfileScreen({super.key, required this.staffId});

  @override
  ConsumerState<StaffProfileScreen> createState() =>
      _StaffProfileScreenState();
}

class _StaffProfileScreenState extends ConsumerState<StaffProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Staff Profile'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Contract'),
            Tab(text: 'Attendance'),
            Tab(text: 'Documents'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(staffId: widget.staffId),
          _ContractTab(staffId: widget.staffId),
          _AttendanceTab(staffId: widget.staffId),
          _DocumentsTab(staffId: widget.staffId),
        ],
      ),
    );
  }
}

// Overview Tab
class _OverviewTab extends ConsumerWidget {
  final String staffId;
  const _OverviewTab({required this.staffId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractAsync = ref.watch(activeContractProvider(staffId));
    final theme = Theme.of(context);
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9');

    return contractAsync.when(
      data: (contract) {
        if (contract == null) {
          return const Center(child: Text('No active contract found'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header
              GlassCard(
                padding: const EdgeInsets.all(24),
                gradient: AppColors.primaryGradient,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withAlpha(50),
                      child: Text(
                        _getInitials(contract.staffName ?? '?'),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      contract.staffName ?? 'Unknown Staff',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contract.staffEmployeeId ?? '',
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ContractTypeBadge(type: contract.contractType),
                        const SizedBox(width: 8),
                        ContractStatusBadge(status: contract.status),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Salary Summary
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Salary Summary',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(
                        label: 'Basic Salary',
                        value: currencyFormat.format(contract.basicSalary)),
                    _InfoRow(
                        label: 'HRA',
                        value: currencyFormat.format(contract.hra)),
                    _InfoRow(
                        label: 'DA',
                        value: currencyFormat.format(contract.da)),
                    _InfoRow(
                        label: 'TA',
                        value: currencyFormat.format(contract.ta)),
                    const Divider(),
                    _InfoRow(
                      label: 'Gross Salary',
                      value: currencyFormat.format(contract.grossSalary),
                      isBold: true,
                      color: AppColors.info,
                    ),
                    _InfoRow(
                      label: 'Deductions',
                      value:
                          '- ${currencyFormat.format(contract.totalDeductions)}',
                      color: AppColors.error,
                    ),
                    const Divider(),
                    _InfoRow(
                      label: 'Net Salary',
                      value: currencyFormat.format(contract.netSalary),
                      isBold: true,
                      color: AppColors.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Contract Details
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contract Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(
                      label: 'Start Date',
                      value: DateFormat('dd MMM yyyy')
                          .format(contract.startDate),
                    ),
                    if (contract.endDate != null) ...[
                      _InfoRow(
                        label: 'End Date',
                        value: DateFormat('dd MMM yyyy')
                            .format(contract.endDate!),
                      ),
                      if (contract.isExpiringSoon)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.warningLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber,
                                    color: AppColors.warning, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Expires in ${contract.daysUntilExpiry} days',
                                  style: const TextStyle(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// Contract Tab
class _ContractTab extends ConsumerWidget {
  final String staffId;
  const _ContractTab({required this.staffId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractsAsync = ref.watch(
        staffContractsProvider(StaffContractFilter(staffId: staffId)));
    final theme = Theme.of(context);
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9');

    return contractsAsync.when(
      data: (contracts) {
        if (contracts.isEmpty) {
          return const Center(child: Text('No contracts found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contracts.length,
          itemBuilder: (context, index) {
            final c = contracts[index];
            return GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ContractTypeBadge(type: c.contractType),
                      const SizedBox(width: 8),
                      ContractStatusBadge(status: c.status, showIcon: true),
                      const Spacer(),
                      Text(
                        currencyFormat.format(c.netSalary),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${DateFormat('dd MMM yyyy').format(c.startDate)} - ${c.endDate != null ? DateFormat('dd MMM yyyy').format(c.endDate!) : 'Ongoing'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _MiniStat('Basic', currencyFormat.format(c.basicSalary)),
                      _MiniStat('HRA', currencyFormat.format(c.hra)),
                      _MiniStat('DA', currencyFormat.format(c.da)),
                      _MiniStat('TA', currencyFormat.format(c.ta)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

// Attendance Tab
class _AttendanceTab extends ConsumerWidget {
  final String staffId;
  const _AttendanceTab({required this.staffId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final summaryAsync = ref.watch(staffAttendanceSummaryProvider(
      StaffAttendanceSummaryFilter(
        staffId: staffId,
        month: now.month,
        year: now.year,
      ),
    ));
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance - ${DateFormat('MMMM yyyy').format(now)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          summaryAsync.when(
            data: (summary) => Column(
              children: [
                // Stats
                Row(
                  children: [
                    _StatChip('Present', '${summary['present'] ?? 0}',
                        AppColors.success),
                    _StatChip('Absent', '${summary['absent'] ?? 0}',
                        AppColors.error),
                    _StatChip('Half Day', '${summary['half_day'] ?? 0}',
                        AppColors.warning),
                    _StatChip('Leave', '${summary['on_leave'] ?? 0}',
                        AppColors.info),
                  ],
                ),
                const SizedBox(height: 16),
                // Calendar view (empty for now -- needs attendance records)
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: AttendanceCalendarWidget(
                    year: now.year,
                    month: now.month,
                    dayStatusMap: const {},
                  ),
                ),
              ],
            ),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Error: $error'),
          ),
        ],
      ),
    );
  }
}

// Documents Tab
class _DocumentsTab extends ConsumerWidget {
  final String staffId;
  const _DocumentsTab({required this.staffId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(staffDocumentsProvider(staffId));
    final theme = Theme.of(context);

    return docsAsync.when(
      data: (docs) {
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open,
                    size: 64, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 16),
                const Text('No documents uploaded'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _documentIcon(doc.documentType),
                    color: AppColors.primary,
                  ),
                ),
                title: Text(doc.documentTypeDisplay),
                subtitle: Text(
                  doc.fileName ?? 'Document',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: doc.verified
                    ? const Icon(Icons.verified,
                        color: AppColors.success, size: 20)
                    : const Icon(Icons.pending,
                        color: AppColors.warning, size: 20),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  IconData _documentIcon(StaffDocumentType type) {
    switch (type) {
      case StaffDocumentType.resume:
        return Icons.description;
      case StaffDocumentType.id_proof:
        return Icons.badge;
      case StaffDocumentType.address_proof:
        return Icons.home;
      case StaffDocumentType.qualification:
        return Icons.school;
      case StaffDocumentType.experience_letter:
        return Icons.work_history;
      case StaffDocumentType.offer_letter:
        return Icons.mail;
      case StaffDocumentType.contract:
        return Icons.gavel;
    }
  }
}

// Helpers
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textTertiaryLight)),
          Text(value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style:
                  TextStyle(fontSize: 10, color: color.withAlpha(180)),
            ),
          ],
        ),
      ),
    );
  }
}
