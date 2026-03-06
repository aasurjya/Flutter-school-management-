import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/alumni.dart';
import '../../providers/alumni_provider.dart';
import '../widgets/event_card.dart';

class AlumniEventsScreen extends ConsumerStatefulWidget {
  const AlumniEventsScreen({super.key});

  @override
  ConsumerState<AlumniEventsScreen> createState() =>
      _AlumniEventsScreenState();
}

class _AlumniEventsScreenState extends ConsumerState<AlumniEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AlumniEventType? _selectedType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Alumni Events'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Ongoing'),
            Tab(text: 'Past'),
          ],
        ),
        actions: [
          if (_selectedType != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              onPressed: () => setState(() => _selectedType = null),
            ),
          PopupMenuButton<AlumniEventType?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (type) => setState(() => _selectedType = type),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Types'),
              ),
              ...AlumniEventType.values.map(
                (type) => PopupMenuItem(
                  value: type,
                  child: Text(type.label),
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _EventList(
            status: 'upcoming',
            eventType: _selectedType,
          ),
          _EventList(
            status: 'ongoing',
            eventType: _selectedType,
          ),
          _EventList(
            status: 'completed',
            eventType: _selectedType,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Show create event dialog
          _showCreateEventDialog(context, ref);
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Event'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showCreateEventDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    AlumniEventType selectedType = AlumniEventType.meetup;
    bool isVirtual = false;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AlumniEventType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Event Type',
                    border: OutlineInputBorder(),
                  ),
                  items: AlumniEventType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.label),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedType = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Event Date'),
                  subtitle: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Virtual Event'),
                  value: isVirtual,
                  onChanged: (val) =>
                      setDialogState(() => isVirtual = val),
                ),
                if (!isVirtual)
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
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
                if (titleController.text.isEmpty) return;
                try {
                  final notifier =
                      ref.read(alumniEventNotifierProvider.notifier);
                  await notifier.createEvent({
                    'title': titleController.text,
                    'description': descriptionController.text.isEmpty
                        ? null
                        : descriptionController.text,
                    'event_type': selectedType.value,
                    'date': selectedDate.toIso8601String(),
                    'is_virtual': isVirtual,
                    'location': isVirtual
                        ? null
                        : locationController.text.isEmpty
                            ? null
                            : locationController.text,
                    'status': 'upcoming',
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Event created successfully')),
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
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventList extends ConsumerWidget {
  final String status;
  final AlumniEventType? eventType;

  const _EventList({
    required this.status,
    this.eventType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(alumniEventsProvider(
      AlumniEventFilter(status: status, eventType: eventType),
    ));

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_busy,
                    size: 64, color: AppColors.textTertiaryLight),
                const SizedBox(height: 16),
                Text(
                  'No $status events',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(alumniEventsProvider(
              AlumniEventFilter(status: status, eventType: eventType),
            ));
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return AlumniEventCard(
                event: event,
                onTap: () => context.push(
                  AppRoutes.alumniEventDetail
                      .replaceAll(':eventId', event.id),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
