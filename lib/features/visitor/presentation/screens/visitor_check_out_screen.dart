import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/visitor.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/visitor_provider.dart';

class VisitorCheckOutScreen extends ConsumerStatefulWidget {
  const VisitorCheckOutScreen({super.key});

  @override
  ConsumerState<VisitorCheckOutScreen> createState() =>
      _VisitorCheckOutScreenState();
}

class _VisitorCheckOutScreenState
    extends ConsumerState<VisitorCheckOutScreen> {
  final _badgeController = TextEditingController();
  final _searchController = TextEditingController();
  VisitorLog? _foundLog;
  bool _isSearching = false;
  bool _isCheckingOut = false;

  Future<void> _searchByBadge() async {
    final badge = _badgeController.text.trim();
    if (badge.isEmpty) return;

    setState(() {
      _isSearching = true;
      _foundLog = null;
    });
    try {
      final repo = ref.read(visitorRepositoryProvider);
      final log = await repo.findLogByBadge(badge);
      if (mounted) {
        setState(() => _foundLog = log);
        if (log == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No active check-in found for this badge'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _checkOut() async {
    if (_foundLog == null) return;

    setState(() => _isCheckingOut = true);
    try {
      await ref
          .read(visitorLogNotifierProvider.notifier)
          .checkOut(_foundLog!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visitor checked out successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(visitorStatsProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  @override
  void dispose() {
    _badgeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat.jm();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Out Visitor'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search by badge
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find by Badge Number',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _badgeController,
                        decoration: const InputDecoration(
                          labelText: 'Badge Number',
                          prefixIcon: Icon(Icons.badge),
                          hintText: 'Enter badge number',
                        ),
                        onFieldSubmitted: (_) => _searchByBadge(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSearching ? null : _searchByBadge,
                      child: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Find'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Or select from checked-in list
          Text(
            'Or Select from Currently Checked-In',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // Show checked-in visitors
          Consumer(
            builder: (context, ref, _) {
              final todayLogs = ref.watch(todayLogsProvider);
              return todayLogs.when(
                data: (logs) {
                  final checkedIn = logs
                      .where(
                          (l) => l.status == VisitorLogStatus.checkedIn)
                      .toList();

                  if (checkedIn.isEmpty) {
                    return GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No visitors currently checked in',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: checkedIn.length,
                    itemBuilder: (context, index) {
                      final log = checkedIn[index];
                      final isSelected = _foundLog?.id == log.id;

                      return GlassCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        borderColor: isSelected
                            ? AppColors.primary
                            : null,
                        borderWidth: isSelected ? 2 : 1.5,
                        onTap: () =>
                            setState(() => _foundLog = log),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  AppColors.success.withValues(alpha: 0.1),
                              child: Text(
                                log.visitor?.initials ?? '?',
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.visitor?.fullName ?? 'Visitor',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${log.purpose.label} - In: ${timeFormat.format(log.checkInTime)}${log.badgeNumber != null ? ' | Badge: ${log.badgeNumber}' : ''}',
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle,
                                  color: AppColors.primary),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                    child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              );
            },
          ),
          const SizedBox(height: 24),

          // Found visitor details & checkout button
          if (_foundLog != null) ...[
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderColor: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Visitor',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _detailRow('Name',
                      _foundLog!.visitor?.fullName ?? 'Unknown'),
                  _detailRow('Purpose', _foundLog!.purpose.label),
                  _detailRow('Check-in',
                      timeFormat.format(_foundLog!.checkInTime)),
                  if (_foundLog!.badgeNumber != null)
                    _detailRow('Badge', _foundLog!.badgeNumber!),
                  if (_foundLog!.vehicleNumber != null)
                    _detailRow('Vehicle', _foundLog!.vehicleNumber!),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isCheckingOut ? null : _checkOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _isCheckingOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.logout),
                label: Text(
                  _isCheckingOut ? 'Checking out...' : 'Check Out',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
