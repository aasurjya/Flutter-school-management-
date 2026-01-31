import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/transport_provider.dart';

class RouteDetailScreen extends ConsumerWidget {
  final String routeId;

  const RouteDetailScreen({super.key, required this.routeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeAsync = ref.watch(routeByIdProvider(routeId));
    final studentsAsync = ref.watch(studentsByRouteProvider(routeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Details'),
      ),
      body: routeAsync.when(
        data: (route) {
          if (route == null) {
            return const Center(child: Text('Route not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route header
                Card(
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
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.directions_bus,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    route.name,
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  if (route.code != null)
                                    Text(
                                      'Route Code: ${route.code}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        if (route.vehicleNumber != null)
                          _InfoRow(
                            icon: Icons.local_shipping_outlined,
                            label: 'Vehicle Number',
                            value: route.vehicleNumber!,
                          ),
                        if (route.capacity != null)
                          _InfoRow(
                            icon: Icons.people_outline,
                            label: 'Capacity',
                            value: '${route.capacity} students',
                          ),
                        if (route.farePerMonth != null)
                          _InfoRow(
                            icon: Icons.payments_outlined,
                            label: 'Monthly Fare',
                            value: route.fareFormatted,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Driver & Helper
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crew',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        if (route.driverName != null)
                          _CrewTile(
                            name: route.driverName!,
                            role: 'Driver',
                            phone: route.driverPhone,
                          ),
                        if (route.helperName != null) ...[
                          const Divider(),
                          _CrewTile(
                            name: route.helperName!,
                            role: 'Helper',
                            phone: route.helperPhone,
                          ),
                        ],
                        if (route.driverName == null && route.helperName == null)
                          const Text('No crew assigned'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Stops
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stops (${route.stops?.length ?? 0})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        if (route.stops != null && route.stops!.isNotEmpty)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: route.stops!.length,
                            itemBuilder: (context, index) {
                              final stop = route.stops![index];
                              final isFirst = index == 0;
                              final isLast = index == route.stops!.length - 1;

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isFirst || isLast
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                                          border: Border.all(
                                            color: Theme.of(context).colorScheme.primary,
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isFirst || isLast
                                                  ? Theme.of(context).colorScheme.onPrimary
                                                  : Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (!isLast)
                                        Container(
                                          width: 2,
                                          height: 40,
                                          color: Theme.of(context).colorScheme.outlineVariant,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            stop.name,
                                            style: Theme.of(context).textTheme.titleSmall,
                                          ),
                                          if (stop.pickupTime != null || stop.dropTime != null)
                                            Text(
                                              [
                                                if (stop.pickupTime != null) 'Pickup: ${stop.pickupTime}',
                                                if (stop.dropTime != null) 'Drop: ${stop.dropTime}',
                                              ].join(' | '),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
                        else
                          const Text('No stops defined'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Students on this route
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Students',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        studentsAsync.when(
                          data: (students) {
                            if (students.isEmpty) {
                              return const Text('No students assigned');
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: students.length,
                              itemBuilder: (context, index) {
                                final student = students[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    child: Text(
                                      student.studentName?[0].toUpperCase() ?? 'S',
                                    ),
                                  ),
                                  title: Text(student.studentName ?? 'Unknown'),
                                  subtitle: Text(student.stop?.name ?? 'Unknown stop'),
                                  trailing: Text(
                                    student.serviceType,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, _) => Text('Error: $error'),
                        ),
                      ],
                    ),
                  ),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _CrewTile extends StatelessWidget {
  final String name;
  final String role;
  final String? phone;

  const _CrewTile({
    required this.name,
    required this.role,
    this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          child: Icon(
            role == 'Driver' ? Icons.drive_eta : Icons.person,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                role,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        if (phone != null)
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () async {
              final uri = Uri.parse('tel:$phone');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
      ],
    );
  }
}
