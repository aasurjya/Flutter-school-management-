import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/alumni.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/alumni_provider.dart';
import '../widgets/donation_progress.dart';

class DonationsScreen extends ConsumerStatefulWidget {
  const DonationsScreen({super.key});

  @override
  ConsumerState<DonationsScreen> createState() => _DonationsScreenState();
}

class _DonationsScreenState extends ConsumerState<DonationsScreen> {
  String? _purposeFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(donationSummaryProvider);
    final donationsAsync = ref.watch(alumniDonationsProvider(
      AlumniDonationFilter(purpose: _purposeFilter),
    ));
    final myProfileAsync = ref.watch(myAlumniProfileProvider);
    final currencyFormat = NumberFormat.currency(symbol: '\u20B9', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donations'),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (val) => setState(() => _purposeFilter = val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All')),
              ...AlumniDonationPurpose.values.map(
                (p) => PopupMenuItem(value: p.value, child: Text(p.label)),
              ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Summary cards
          SliverToBoxAdapter(
            child: summaryAsync.when(
              data: (summary) {
                final total = summary['total'] ?? 0.0;
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total banner
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        gradient: AppColors.primaryGradient,
                        backgroundColor: Colors.transparent,
                        child: Row(
                          children: [
                            const Icon(Icons.volunteer_activism,
                                color: Colors.white, size: 40),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Raised',
                                  style:
                                      theme.textTheme.bodyMedium?.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(total),
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'By Purpose',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Purpose breakdown
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.3,
                        children: summary.entries
                            .where((e) => e.key != 'total')
                            .map((entry) => DonationProgressCard(
                                  purpose: entry.key,
                                  raised: entry.value,
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $e'),
              ),
            ),
          ),

          // Recent donations header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Recent Donations',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Donation list
          donationsAsync.when(
            data: (donations) {
              if (donations.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No donations yet')),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final donation = donations[index];
                    return _DonationTile(donation: donation);
                  },
                  childCount: donations.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(child: Text('Error: $e')),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),

      // Donate button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDonateDialog(context, ref, myProfileAsync),
        icon: const Icon(Icons.favorite),
        label: const Text('Make Donation'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showDonateDialog(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<AlumniProfile?> myProfileAsync,
  ) {
    final myProfile = myProfileAsync.valueOrNull;
    if (myProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please register as alumni first'),
        ),
      );
      return;
    }

    final amountController = TextEditingController();
    final messageController = TextEditingController();
    AlumniDonationPurpose purpose = AlumniDonationPurpose.general;
    bool isAnonymous = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Make a Donation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (\u20B9) *',
                    border: OutlineInputBorder(),
                    prefixText: '\u20B9 ',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AlumniDonationPurpose>(
                  initialValue: purpose,
                  decoration: const InputDecoration(
                    labelText: 'Purpose',
                    border: OutlineInputBorder(),
                  ),
                  items: AlumniDonationPurpose.values
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.label),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => purpose = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Donate anonymously'),
                  value: isAnonymous,
                  onChanged: (val) =>
                      setDialogState(() => isAnonymous = val ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amount =
                    double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Enter a valid amount')),
                  );
                  return;
                }
                try {
                  final repo = ref.read(alumniRepositoryProvider);
                  await repo.createDonation({
                    'alumni_id': myProfile.id,
                    'amount': amount,
                    'currency': 'INR',
                    'purpose': purpose.value,
                    'message': messageController.text.isEmpty
                        ? null
                        : messageController.text,
                    'is_anonymous': isAnonymous,
                    'status': 'completed',
                    'donated_at': DateTime.now().toIso8601String(),
                  });
                  ref.invalidate(donationSummaryProvider);
                  ref.invalidate(alumniDonationsProvider(
                    AlumniDonationFilter(purpose: _purposeFilter),
                  ));
                  ref.invalidate(alumniStatsProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Thank you for your donation!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Donate'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonationTile extends StatelessWidget {
  final AlumniDonation donation;

  const _DonationTile({required this.donation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\u20B9', decimalDigits: 0);

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
            child: donation.isAnonymous
                ? const Icon(Icons.person_off,
                    size: 20, color: AppColors.textTertiaryLight)
                : Text(
                    donation.alumni?.initials ?? '?',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donation.isAnonymous
                      ? 'Anonymous'
                      : (donation.alumni?.fullName ?? 'Alumni'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${donation.purpose.label} - ${dateFormat.format(donation.donatedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
                if (donation.message != null)
                  Text(
                    donation.message!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            currencyFormat.format(donation.amount),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
