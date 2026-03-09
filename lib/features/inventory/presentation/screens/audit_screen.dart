import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/inventory.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/inventory_provider.dart';

class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key});

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Asset Audits'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Audit History'),
            Tab(text: 'New Audit'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AuditHistoryTab(),
          _NewAuditTab(
            onComplete: () {
              _tabController.animateTo(0);
              ref.invalidate(assetAuditsProvider);
            },
          ),
        ],
      ),
    );
  }
}

class _AuditHistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditsAsync = ref.watch(assetAuditsProvider);
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return auditsAsync.when(
      data: (audits) {
        if (audits.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fact_check_outlined,
                    size: 64, color: AppColors.textTertiaryLight),
                const SizedBox(height: 16),
                Text(
                  'No audits conducted yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start an audit to verify your asset inventory',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: audits.length,
          itemBuilder: (context, index) {
            final audit = audits[index];
            final statusColor = _auditStatusColor(audit.status);

            return GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.fact_check, color: statusColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateFormat.format(audit.auditDate),
                              style:
                                  theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'By ${audit.conductedByName ?? "Unknown"}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          audit.status.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress bar
                  if (audit.totalAssets > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Verification Progress',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        Text(
                          '${audit.verificationPercentage.toStringAsFixed(0)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: audit.verificationPercentage / 100,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        color: AppColors.primary,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Stats grid
                  Row(
                    children: [
                      _AuditStat(
                        label: 'Total',
                        value: '${audit.totalAssets}',
                        color: AppColors.info,
                      ),
                      _AuditStat(
                        label: 'Verified',
                        value: '${audit.verifiedCount}',
                        color: AppColors.success,
                      ),
                      _AuditStat(
                        label: 'Missing',
                        value: '${audit.missingCount}',
                        color: AppColors.error,
                      ),
                      _AuditStat(
                        label: 'Damaged',
                        value: '${audit.damagedCount}',
                        color: AppColors.warning,
                      ),
                    ],
                  ),

                  if (audit.notes != null && audit.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      audit.notes!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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

  Color _auditStatusColor(AuditStatus status) {
    switch (status) {
      case AuditStatus.planned:
        return AppColors.info;
      case AuditStatus.inProgress:
        return AppColors.warning;
      case AuditStatus.completed:
        return AppColors.success;
    }
  }
}

class _AuditStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AuditStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiaryLight,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}

class _NewAuditTab extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const _NewAuditTab({required this.onComplete});

  @override
  ConsumerState<_NewAuditTab> createState() => _NewAuditTabState();
}

class _NewAuditTabState extends ConsumerState<_NewAuditTab> {
  bool _isAuditing = false;
  AssetAudit? _currentAudit;
  int _verifiedCount = 0;
  int _missingCount = 0;
  int _damagedCount = 0;
  final Set<String> _scannedAssetIds = {};
  final _notesController = TextEditingController();
  bool _isScanning = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_isAuditing) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fact_check_outlined,
                  size: 64,
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Start an Asset Audit',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan through your assets using QR codes to verify their presence and condition.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _startAudit,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_arrow),
                label: const Text('Start Audit'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Active audit view
    return Column(
      children: [
        // Stats bar
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.primary.withValues(alpha: 0.05),
          child: Row(
            children: [
              _LiveStat(
                label: 'Total',
                value: '${_currentAudit?.totalAssets ?? 0}',
                color: AppColors.info,
              ),
              _LiveStat(
                label: 'Verified',
                value: '$_verifiedCount',
                color: AppColors.success,
              ),
              _LiveStat(
                label: 'Missing',
                value: '$_missingCount',
                color: AppColors.error,
              ),
              _LiveStat(
                label: 'Damaged',
                value: '$_damagedCount',
                color: AppColors.warning,
              ),
            ],
          ),
        ),

        // Progress
        if (_currentAudit != null && _currentAudit!.totalAssets > 0)
          LinearProgressIndicator(
            value:
                (_verifiedCount + _missingCount + _damagedCount) /
                    _currentAudit!.totalAssets,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            color: AppColors.primary,
            minHeight: 4,
          ),

        // Scan button area
        Expanded(
          child: _isScanning
              ? _buildScanner()
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${_scannedAssetIds.length} assets scanned',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () =>
                            setState(() => _isScanning = true),
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan Asset'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _markMissing(),
                            icon: const Icon(Icons.search_off,
                                color: AppColors.error),
                            label: const Text('Mark Missing'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () => _markDamaged(),
                            icon: const Icon(Icons.broken_image_outlined,
                                color: AppColors.warning),
                            label: const Text('Mark Damaged'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),

        // Bottom bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    hintText: 'Audit notes...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _completeAudit,
                child: const Text('Finish Audit'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          onDetect: (capture) {
            final barcode = capture.barcodes.firstOrNull;
            if (barcode?.rawValue != null) {
              _onAssetScanned(barcode!.rawValue!);
            }
          },
        ),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: FilledButton.icon(
              onPressed: () => setState(() => _isScanning = false),
              icon: const Icon(Icons.close),
              label: const Text('Stop Scanning'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _startAudit() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final audit = await repo.createAudit({
        'audit_date':
            DateTime.now().toIso8601String().split('T')[0],
        'status': 'in_progress',
      });
      setState(() {
        _currentAudit = audit;
        _isAuditing = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting audit: $e')),
        );
      }
    }
  }

  Future<void> _onAssetScanned(String code) async {
    final repo = ref.read(inventoryRepositoryProvider);

    try {
      Asset? asset = await repo.getAssetByQrCode(code);
      if (asset == null && code.startsWith('ASSET:')) {
        final parts = code.split(':');
        if (parts.length >= 3) {
          asset = await repo.getAssetByCode(parts[2]);
        }
      }
      asset ??= await repo.getAssetByCode(code);

      if (asset != null && !_scannedAssetIds.contains(asset.id)) {
        setState(() {
          _scannedAssetIds.add(asset!.id);
          _verifiedCount++;
          _isScanning = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verified: ${asset.name}'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else if (asset != null) {
        setState(() => _isScanning = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Asset already scanned'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      // Silently continue scanning
    }
  }

  void _markMissing() {
    setState(() => _missingCount++);
  }

  void _markDamaged() {
    setState(() => _damagedCount++);
  }

  Future<void> _completeAudit() async {
    if (_currentAudit == null) return;

    try {
      final repo = ref.read(inventoryRepositoryProvider);
      await repo.updateAudit(_currentAudit!.id, {
        'verified_count': _verifiedCount,
        'missing_count': _missingCount,
        'damaged_count': _damagedCount,
        'notes': _notesController.text.isEmpty
            ? null
            : _notesController.text.trim(),
        'status': 'completed',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audit completed')),
        );
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _LiveStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LiveStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
          ),
        ],
      ),
    );
  }
}
