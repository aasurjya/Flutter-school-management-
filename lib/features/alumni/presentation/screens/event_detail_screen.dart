import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/alumni.dart';
import '../../providers/alumni_provider.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final eventAsync = ref.watch(alumniEventByIdProvider(eventId));
    final registrationsAsync =
        ref.watch(eventRegistrationsProvider(eventId));
    final myProfileAsync = ref.watch(myAlumniProfileProvider);

    return Scaffold(
      body: eventAsync.when(
        data: (event) {
          if (event == null) {
            return const Center(child: Text('Event not found'));
          }

          final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');
          final timeFormat = DateFormat('hh:mm a');

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    event.title,
                    style: const TextStyle(fontSize: 16),
                  ),
                  background: event.imageUrl != null
                      ? Image.network(
                          event.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: const BoxDecoration(
                              gradient: AppColors.primaryGradient,
                            ),
                          ),
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                          ),
                          child: const Center(
                            child: Icon(Icons.event,
                                size: 64, color: Colors.white54),
                          ),
                        ),
                ),
              ),

              // Event details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status and type
                      Row(
                        children: [
                          _StatusChip(
                            label: event.status.label,
                            color: _statusColor(event.status),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(
                            label: event.eventType.label,
                            color: AppColors.primary,
                          ),
                          if (event.isVirtual) ...[
                            const SizedBox(width: 8),
                            const _StatusChip(
                              label: 'Virtual',
                              color: AppColors.info,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Date & time
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _DetailRow(
                              icon: Icons.calendar_today,
                              label: 'Date',
                              value: dateFormat.format(event.date),
                            ),
                            const SizedBox(height: 8),
                            _DetailRow(
                              icon: Icons.access_time,
                              label: 'Time',
                              value: timeFormat.format(event.date),
                            ),
                            if (event.endDate != null) ...[
                              const SizedBox(height: 8),
                              _DetailRow(
                                icon: Icons.access_time_filled,
                                label: 'Ends',
                                value:
                                    '${dateFormat.format(event.endDate!)} at ${timeFormat.format(event.endDate!)}',
                              ),
                            ],
                            const SizedBox(height: 8),
                            _DetailRow(
                              icon: event.isVirtual
                                  ? Icons.videocam
                                  : Icons.location_on,
                              label: event.isVirtual
                                  ? 'Platform'
                                  : 'Location',
                              value: event.isVirtual
                                  ? (event.virtualLink ?? 'Link will be shared')
                                  : (event.location ?? 'TBD'),
                            ),
                            if (event.maxAttendees != null) ...[
                              const SizedBox(height: 8),
                              _DetailRow(
                                icon: Icons.people,
                                label: 'Capacity',
                                value:
                                    '${event.registrationCount ?? 0} / ${event.maxAttendees} registered',
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      if (event.description != null &&
                          event.description!.isNotEmpty) ...[
                        Text(
                          'About',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            event.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Organizer
                      if (event.organizer != null) ...[
                        Text(
                          'Organized by',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.1),
                                child: Text(
                                  event.organizer!.initials,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.organizer!.fullName,
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Class of ${event.organizer!.graduationYear}',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Attendees
                      Text(
                        'Attendees',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // Attendee list
              registrationsAsync.when(
                data: (registrations) {
                  if (registrations.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: GlassCard(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                                'No registrations yet. Be the first!'),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final reg = registrations[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 2),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                reg.alumni?.initials ?? '?',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              reg.alumni?.fullName ?? 'Alumni',
                              style: theme.textTheme.bodyMedium,
                            ),
                            subtitle: Text(
                              reg.status.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textTertiaryLight,
                              ),
                            ),
                            dense: true,
                          ),
                        );
                      },
                      childCount: registrations.length,
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Text('Error: $e'),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),

      // Register button
      bottomNavigationBar: eventAsync.when(
        data: (event) {
          if (event == null ||
              event.status == AlumniEventStatus.cancelled ||
              event.status == AlumniEventStatus.completed) {
            return const SizedBox.shrink();
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: myProfileAsync.when(
                data: (myProfile) {
                  if (myProfile == null) {
                    return FilledButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Register as Alumni first'),
                    );
                  }
                  return FilledButton.icon(
                    onPressed: event.hasCapacity
                        ? () async {
                            try {
                              final repo =
                                  ref.read(alumniRepositoryProvider);
                              await repo.registerForEvent({
                                'event_id': event.id,
                                'alumni_id': myProfile.id,
                                'status': 'registered',
                              });
                              ref.invalidate(
                                  eventRegistrationsProvider(eventId));
                              ref.invalidate(
                                  alumniEventByIdProvider(eventId));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Registered successfully!'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Error: ${e.toString().contains('duplicate') ? 'Already registered' : e}'),
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    icon: const Icon(Icons.how_to_reg),
                    label: Text(
                        event.hasCapacity ? 'Register' : 'Event Full'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Color _statusColor(AlumniEventStatus status) {
    switch (status) {
      case AlumniEventStatus.upcoming:
        return AppColors.info;
      case AlumniEventStatus.ongoing:
        return AppColors.success;
      case AlumniEventStatus.completed:
        return AppColors.textSecondaryLight;
      case AlumniEventStatus.cancelled:
        return AppColors.error;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}
