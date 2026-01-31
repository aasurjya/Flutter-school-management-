import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/transport_provider.dart';

class MyTransportScreen extends ConsumerWidget {
  const MyTransportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transportAsync = ref.watch(myTransportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Transport'),
      ),
      body: transportAsync.when(
        data: (transport) {
          if (transport == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_bus_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  const Text('No transport assigned'),
                  const SizedBox(height: 8),
                  Text(
                    'Contact the school office for transport allocation',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          final route = transport.route;
          final stop = transport.stop;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Main card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.directions_bus,
                            size: 48,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          route?.name ?? 'Unknown Route',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (route?.code != null)
                          Text(
                            'Route: ${route!.code}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            transport.serviceType,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Stop info
                Card(
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                    ),
                    title: const Text('Pickup/Drop Stop'),
                    subtitle: Text(stop?.name ?? 'Unknown'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (stop?.pickupTime != null)
                          Text(
                            'Pickup: ${stop!.pickupTime}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (stop?.dropTime != null)
                          Text(
                            'Drop: ${stop!.dropTime}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Vehicle info
                if (route?.vehicleNumber != null)
                  Card(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.local_shipping_outlined),
                      ),
                      title: const Text('Vehicle'),
                      subtitle: Text(route!.vehicleNumber!),
                    ),
                  ),
                const SizedBox(height: 16),
                // Driver info
                if (route?.driverName != null)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(route!.driverName![0].toUpperCase()),
                      ),
                      title: Text(route.driverName!),
                      subtitle: const Text('Driver'),
                      trailing: route.driverPhone != null
                          ? IconButton(
                              icon: const Icon(Icons.phone),
                              onPressed: () async {
                                final uri = Uri.parse('tel:${route.driverPhone}');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                            )
                          : null,
                    ),
                  ),
                const SizedBox(height: 16),
                // Helper info
                if (route?.helperName != null)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(route!.helperName![0].toUpperCase()),
                      ),
                      title: Text(route.helperName!),
                      subtitle: const Text('Helper'),
                      trailing: route.helperPhone != null
                          ? IconButton(
                              icon: const Icon(Icons.phone),
                              onPressed: () async {
                                final uri = Uri.parse('tel:${route.helperPhone}');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                            )
                          : null,
                    ),
                  ),
                const SizedBox(height: 16),
                // View full route
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/transport/route/${route?.id}'),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('View Full Route'),
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
