import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/school_event.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/calendar_provider.dart';
import '../widgets/event_type_badge.dart';

/// Full event detail screen with RSVP, attendees, reminders, location
class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final rsvpAsync = ref.watch(userRsvpProvider(eventId));
    final remindersAsync = ref.watch(eventRemindersProvider(eventId));

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (event) {
          if (event == null) {
            return const Center(child: Text('Event not found'));
          }
          return _buildContent(
              context, ref, event, rsvpAsync, remindersAsync);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    SchoolEvent event,
    AsyncValue<EventAttendee?> rsvpAsync,
    AsyncValue<List<EventReminder>> remindersAsync,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final eventColor = _colorFromHex(
        event.colorHex ?? event.eventType.colorHex);

    return CustomScrollView(
      slivers: [
        // Header
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    eventColor,
                    eventColor.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      EventTypeBadge(eventType: event.eventType),
                      const SizedBox(height: 10),
                      Text(
                        event.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (event.status != EventStatus.scheduled) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            event.status.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              iconColor: Colors.white,
              onSelected: (value) => _handleMenuAction(
                  context, ref, value, event),
              itemBuilder: (context) => [
                const PopupMenuItem(
                    value: 'edit', child: Text('Edit Event')),
                const PopupMenuItem(
                    value: 'cancel', child: Text('Cancel Event')),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Event',
                        style: TextStyle(color: AppColors.error))),
              ],
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date & Time card
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.calendar_today,
                        iconColor: eventColor,
                        title: 'Date',
                        value: _formatDateRange(
                            event.startDate, event.endDate),
                      ),
                      if (!event.isAllDay) ...[
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.access_time,
                          iconColor: eventColor,
                          title: 'Time',
                          value: event.durationDisplay,
                        ),
                      ],
                      if (event.isAllDay) ...[
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.access_time,
                          iconColor: eventColor,
                          title: 'Duration',
                          value: event.durationDisplay,
                        ),
                      ],
                      if (event.location != null &&
                          event.location!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.location_on,
                          iconColor: eventColor,
                          title: 'Location',
                          value: event.location!,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Description
                if (event.description != null &&
                    event.description!.isNotEmpty) ...[
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Details card
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Details',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.visibility,
                        iconColor: AppColors.info,
                        title: 'Visibility',
                        value: event.visibility.label,
                      ),
                      const SizedBox(height: 10),
                      _DetailRow(
                        icon: Icons.flag,
                        iconColor: event.isMandatory
                            ? AppColors.error
                            : AppColors.success,
                        title: 'Mandatory',
                        value: event.isMandatory ? 'Yes' : 'No',
                      ),
                      if (event.isRecurring &&
                          event.recurrenceRule != null) ...[
                        const SizedBox(height: 10),
                        _DetailRow(
                          icon: Icons.repeat,
                          iconColor: AppColors.primaryLight,
                          title: 'Recurrence',
                          value:
                              'Every ${event.recurrenceRule!.interval > 1 ? '${event.recurrenceRule!.interval} ' : ''}${event.recurrenceRule!.frequency}',
                        ),
                      ],
                      if (event.createdByName != null) ...[
                        const SizedBox(height: 10),
                        _DetailRow(
                          icon: Icons.person,
                          iconColor: AppColors.textSecondaryLight,
                          title: 'Created by',
                          value: event.createdByName!,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // RSVP section
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'RSVP',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => context.push(
                                '/calendar/event/$eventId/attendees'),
                            icon: const Icon(Icons.people, size: 16),
                            label: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      rsvpAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, __) =>
                            const Text('Failed to load RSVP status'),
                        data: (rsvp) => _buildRsvpButtons(
                            context, ref, rsvp),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Reminders section
                remindersAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (reminders) {
                    if (reminders.isEmpty) return const SizedBox.shrink();
                    return GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reminders',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...reminders.map((r) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      r.reminderType == ReminderType.push
                                          ? Icons.notifications
                                          : r.reminderType ==
                                                  ReminderType.email
                                              ? Icons.email
                                              : Icons.sms,
                                      size: 16,
                                      color: AppColors.textSecondaryLight,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      r.displayLabel,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const Spacer(),
                                    if (r.sent)
                                      const Icon(Icons.check_circle,
                                          size: 16,
                                          color: AppColors.success),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRsvpButtons(
      BuildContext context, WidgetRef ref, EventAttendee? rsvp) {
    final currentStatus = rsvp?.rsvpStatus ?? RsvpStatus.pending;

    return Row(
      children: [
        _RsvpButton(
          label: 'Attending',
          icon: Icons.check_circle,
          color: AppColors.success,
          isSelected: currentStatus == RsvpStatus.attending,
          onTap: () => _updateRsvp(ref, RsvpStatus.attending),
        ),
        const SizedBox(width: 8),
        _RsvpButton(
          label: 'Maybe',
          icon: Icons.help_outline,
          color: AppColors.warning,
          isSelected: currentStatus == RsvpStatus.maybe,
          onTap: () => _updateRsvp(ref, RsvpStatus.maybe),
        ),
        const SizedBox(width: 8),
        _RsvpButton(
          label: 'Decline',
          icon: Icons.cancel,
          color: AppColors.error,
          isSelected: currentStatus == RsvpStatus.notAttending,
          onTap: () => _updateRsvp(ref, RsvpStatus.notAttending),
        ),
      ],
    );
  }

  Future<void> _updateRsvp(WidgetRef ref, RsvpStatus status) async {
    try {
      final repo = ref.read(calendarRepositoryProvider);
      await repo.rsvpEvent(eventId: eventId, rsvpStatus: status);
      ref.invalidate(userRsvpProvider(eventId));
      ref.invalidate(eventAttendeesProvider(eventId));
    } catch (e) {
      // Error silently handled; could add snackbar
    }
  }

  void _handleMenuAction(
      BuildContext context, WidgetRef ref, String action, SchoolEvent event) {
    switch (action) {
      case 'edit':
        context.push('/calendar/create', extra: event);
        break;
      case 'cancel':
        _updateStatus(context, ref, EventStatus.cancelled);
        break;
      case 'delete':
        _confirmDelete(context, ref);
        break;
    }
  }

  Future<void> _updateStatus(
      BuildContext context, WidgetRef ref, EventStatus status) async {
    try {
      final repo = ref.read(calendarRepositoryProvider);
      await repo.updateEventStatus(eventId, status);
      ref.invalidate(eventDetailProvider(eventId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event ${status.label.toLowerCase()}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text(
            'Are you sure you want to delete this event? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(calendarRepositoryProvider);
        await repo.deleteEvent(eventId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted')),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final fmt = DateFormat('EEEE, MMMM d, yyyy');
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return fmt.format(start);
    }
    return '${fmt.format(start)}\n${fmt.format(end)}';
  }

  Color _colorFromHex(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RsvpButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RsvpButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.borderLight,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : AppColors.textSecondaryLight, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : AppColors.textSecondaryLight,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
