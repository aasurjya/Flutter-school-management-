import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/hostel.dart';
import '../../providers/hostel_provider.dart';

class HostelDetailScreen extends ConsumerWidget {
  final String hostelId;

  const HostelDetailScreen({super.key, required this.hostelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hostelAsync = ref.watch(hostelByIdProvider(hostelId));
    final roomsAsync = ref.watch(roomsProvider(RoomsFilter(hostelId: hostelId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hostel Details'),
      ),
      body: hostelAsync.when(
        data: (hostel) {
          if (hostel == null) {
            return const Center(child: Text('Hostel not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: hostel.type == 'boys'
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.pink.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            hostel.type == 'boys' ? Icons.male : Icons.female,
                            size: 48,
                            color: hostel.type == 'boys' ? Colors.blue : Colors.pink,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          hostel.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          hostel.typeDisplay,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatColumn(
                              value: hostel.totalRooms.toString(),
                              label: 'Rooms',
                            ),
                            _StatColumn(
                              value: hostel.totalCapacity.toString(),
                              label: 'Capacity',
                            ),
                            _StatColumn(
                              value: hostel.availableCapacity.toString(),
                              label: 'Available',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Contact info
                if (hostel.wardenName != null || hostel.address != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contact Information',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          if (hostel.wardenName != null)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                              title: Text(hostel.wardenName!),
                              subtitle: const Text('Warden'),
                              trailing: hostel.contactNumber != null
                                  ? IconButton(
                                      icon: const Icon(Icons.phone),
                                      onPressed: () {
                                        // TODO: Launch phone dialer
                                      },
                                    )
                                  : null,
                            ),
                          if (hostel.address != null) ...[
                            const Divider(),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(hostel.address!),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // Fee info
                if (hostel.feePerMonth != null)
                  Card(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.payments_outlined,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: const Text('Monthly Fee'),
                      trailing: Text(
                        hostel.feeFormatted,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // Rooms section
                Text(
                  'Rooms',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                roomsAsync.when(
                  data: (rooms) {
                    if (rooms.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No rooms configured'),
                        ),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        return _RoomCard(room: rooms[index]);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text('Error: $error'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _RoomCard extends StatelessWidget {
  final HostelRoom room;

  const _RoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final isFull = !room.hasVacancy;

    return Card(
      color: isFull
          ? Colors.red.withOpacity(0.1)
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: () => _showRoomDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.door_front_door,
              color: isFull
                  ? Colors.red
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              room.roomNumber,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              room.occupancyText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isFull ? Colors.red : null,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoomDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Room ${room.roomNumber}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _DetailRow(label: 'Floor', value: room.floorText.isEmpty ? 'N/A' : room.floorText),
            _DetailRow(label: 'Type', value: room.roomType ?? 'N/A'),
            _DetailRow(label: 'Capacity', value: '${room.capacity} beds'),
            _DetailRow(label: 'Occupied', value: '${room.occupied} beds'),
            _DetailRow(label: 'Available', value: '${room.availableBeds} beds'),
            if (room.amenities != null && room.amenities!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Amenities',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: room.amenities!
                    .map((a) => Chip(
                          label: Text(a),
                          padding: EdgeInsets.zero,
                        ))
                    .toList(),
              ),
            ],
            if (room.allocations != null && room.allocations!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Occupants',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...room.allocations!.map((a) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Text(a.studentName?[0].toUpperCase() ?? 'S'),
                    ),
                    title: Text(a.studentName ?? 'Unknown'),
                    trailing: a.bedNumber != null ? Text('Bed ${a.bedNumber}') : null,
                  )),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
