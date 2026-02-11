import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/hostel.dart';
import '../../providers/hostel_provider.dart';

class HostelScreen extends ConsumerWidget {
  const HostelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hostelsAsync = ref.watch(hostelsProvider(true));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hostel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bed_outlined),
            onPressed: () => context.push('/hostel/my-room'),
            tooltip: 'My Room',
          ),
        ],
      ),
      body: hostelsAsync.when(
        data: (hostels) {
          if (hostels.isEmpty) {
            return const Center(
              child: Text('No hostels available'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: hostels.length,
            itemBuilder: (context, index) {
              return _HostelCard(hostel: hostels[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _HostelCard extends StatelessWidget {
  final Hostel hostel;

  const _HostelCard({required this.hostel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/hostel/${hostel.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hostel.type == 'boys'
                          ? Colors.blue.withValues(alpha: 0.1)
                          : Colors.pink.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      hostel.type == 'boys' ? Icons.male : Icons.female,
                      color: hostel.type == 'boys' ? Colors.blue : Colors.pink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hostel.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          hostel.typeDisplay,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hostel.feePerMonth != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        hostel.feeFormatted,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Stats row
              Row(
                children: [
                  _StatChip(
                    icon: Icons.door_front_door_outlined,
                    label: '${hostel.totalRooms} Rooms',
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    icon: Icons.bed_outlined,
                    label: '${hostel.totalCapacity} Beds',
                  ),
                  const Spacer(),
                  _OccupancyIndicator(
                    occupied: hostel.occupiedCount ?? 0,
                    total: hostel.totalCapacity,
                  ),
                ],
              ),
              // Warden info
              if (hostel.wardenName != null) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Warden: ${hostel.wardenName}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (hostel.contactNumber != null) ...[
                      const Spacer(),
                      Icon(
                        Icons.phone_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hostel.contactNumber!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _OccupancyIndicator extends StatelessWidget {
  final int occupied;
  final int total;

  const _OccupancyIndicator({required this.occupied, required this.total});

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? occupied / total : 0.0;
    final color = percentage >= 0.9
        ? Colors.red
        : percentage >= 0.7
            ? Colors.orange
            : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$occupied/$total',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
