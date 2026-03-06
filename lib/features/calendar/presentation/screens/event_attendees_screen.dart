import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/school_event.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/calendar_provider.dart';

/// RSVP list and check-in management screen for an event
class EventAttendeesScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventAttendeesScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventAttendeesScreen> createState() =>
      _EventAttendeesScreenState();
}

class _EventAttendeesScreenState
    extends ConsumerState<EventAttendeesScreen>
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final attendeesAsync =
        ref.watch(eventAttendeesProvider(widget.eventId));

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Event Attendees'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Attending'),
            Tab(text: 'Maybe'),
            Tab(text: 'Declined'),
          ],
        ),
      ),
      body: attendeesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Failed to load attendees: $error'),
            ],
          ),
        ),
        data: (attendees) =>
            _buildContent(context, attendees),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, List<EventAttendee> attendees) {
    final theme = Theme.of(context);

    final all = attendees;
    final attending = attendees
        .where((a) => a.rsvpStatus == RsvpStatus.attending)
        .toList();
    final maybe = attendees
        .where((a) => a.rsvpStatus == RsvpStatus.maybe)
        .toList();
    final declined = attendees
        .where((a) => a.rsvpStatus == RsvpStatus.notAttending)
        .toList();

    return Column(
      children: [
        // Summary bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _CountChip(
                label: 'Total',
                count: all.length,
                color: AppColors.primary,
              ),
              _CountChip(
                label: 'Attending',
                count: attending.length,
                color: AppColors.success,
              ),
              _CountChip(
                label: 'Maybe',
                count: maybe.length,
                color: AppColors.warning,
              ),
              _CountChip(
                label: 'Declined',
                count: declined.length,
                color: AppColors.error,
              ),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAttendeeList(context, all),
              _buildAttendeeList(context, attending),
              _buildAttendeeList(context, maybe),
              _buildAttendeeList(context, declined),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendeeList(
      BuildContext context, List<EventAttendee> attendees) {
    final theme = Theme.of(context);

    if (attendees.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline,
                size: 48, color: AppColors.textTertiaryLight),
            const SizedBox(height: 12),
            Text(
              'No attendees in this category',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(eventAttendeesProvider(widget.eventId));
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: attendees.length,
        itemBuilder: (context, index) {
          final attendee = attendees[index];
          return _buildAttendeeCard(context, attendee);
        },
      ),
    );
  }

  Widget _buildAttendeeCard(
      BuildContext context, EventAttendee attendee) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color statusColor;
    IconData statusIcon;
    switch (attendee.rsvpStatus) {
      case RsvpStatus.attending:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case RsvpStatus.notAttending:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        break;
      case RsvpStatus.maybe:
        statusColor = AppColors.warning;
        statusIcon = Icons.help_outline;
        break;
      case RsvpStatus.pending:
        statusColor = AppColors.textSecondaryLight;
        statusIcon = Icons.schedule;
        break;
    }

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: statusColor.withValues(alpha: 0.1),
            child: Text(
              (attendee.userName ?? 'U')[0].toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name & email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendee.userName ?? 'Unknown User',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (attendee.userEmail != null)
                  Text(
                    attendee.userEmail!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
              ],
            ),
          ),

          // RSVP status
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),

          // Check-in button/status
          if (attendee.attended)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check,
                      size: 12, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    attendee.checkInTime != null
                        ? DateFormat('h:mm a')
                            .format(attendee.checkInTime!)
                        : 'Checked in',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 30,
              child: ElevatedButton(
                onPressed: () => _checkIn(attendee),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: const TextStyle(fontSize: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Check In'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _checkIn(EventAttendee attendee) async {
    try {
      final repo = ref.read(calendarRepositoryProvider);
      await repo.checkInAttendee(attendee.id);
      ref.invalidate(eventAttendeesProvider(widget.eventId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${attendee.userName ?? 'User'} checked in'),
          ),
        );
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

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
