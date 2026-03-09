import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/bus_tracking.dart';
import '../../providers/bus_tracking_provider.dart';

class GeofenceListScreen extends ConsumerStatefulWidget {
  const GeofenceListScreen({super.key});

  @override
  ConsumerState<GeofenceListScreen> createState() => _GeofenceListScreenState();
}

class _GeofenceListScreenState extends ConsumerState<GeofenceListScreen> {
  @override
  Widget build(BuildContext context) {
    final geofencesAsync = ref.watch(busGeofencesProvider(false));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geofence Zones'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGeofenceDialog(context),
        child: const Icon(Icons.add),
      ),
      body: geofencesAsync.when(
        data: (geofences) {
          if (geofences.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fence_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No geofence zones configured',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create zones around your school, stops, and restricted areas',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => _showAddGeofenceDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Zone'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(busGeofencesProvider(false)),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: geofences.length,
              itemBuilder: (context, index) {
                return _GeofenceCard(
                  geofence: geofences[index],
                  onToggle: () => _toggleGeofence(geofences[index]),
                  onDelete: () => _deleteGeofence(geofences[index]),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _showAddGeofenceDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();
    final radiusController = TextEditingController(text: '200');
    String zoneType = 'school';
    final messenger = ScaffoldMessenger.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Geofence Zone'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Zone Name *',
                    hintText: 'e.g., School Campus',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: zoneType,
                  decoration: const InputDecoration(labelText: 'Zone Type'),
                  items: const [
                    DropdownMenuItem(value: 'school', child: Text('School')),
                    DropdownMenuItem(value: 'stop', child: Text('Bus Stop')),
                    DropdownMenuItem(
                        value: 'restricted', child: Text('Restricted')),
                    DropdownMenuItem(value: 'custom', child: Text('Custom')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => zoneType = v ?? 'school'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: latController,
                  decoration: const InputDecoration(
                    labelText: 'Latitude *',
                    hintText: 'e.g., 12.9716',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lngController,
                  decoration: const InputDecoration(
                    labelText: 'Longitude *',
                    hintText: 'e.g., 77.5946',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: radiusController,
                  decoration: const InputDecoration(
                    labelText: 'Radius (meters)',
                    suffixText: 'm',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final name = nameController.text.trim();
      final lat = double.tryParse(latController.text.trim());
      final lng = double.tryParse(lngController.text.trim());
      final radius = double.tryParse(radiusController.text.trim()) ?? 200;

      if (name.isEmpty || lat == null || lng == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Name, latitude, and longitude are required'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      try {
        final repo = ref.read(busTrackingRepositoryProvider);
        await repo.createGeofence({
          'name': name,
          'zone_type': zoneType,
          'latitude': lat,
          'longitude': lng,
          'radius_meters': radius,
        });
        ref.invalidate(busGeofencesProvider(false));
        ref.invalidate(busGeofencesProvider(true));
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Geofence zone created'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }

    nameController.dispose();
    latController.dispose();
    lngController.dispose();
    radiusController.dispose();
  }

  Future<void> _toggleGeofence(BusGeofence geofence) async {
    try {
      final repo = ref.read(busTrackingRepositoryProvider);
      await repo.updateGeofence(geofence.id, {
        'is_active': !geofence.isActive,
      });
      ref.invalidate(busGeofencesProvider(false));
      ref.invalidate(busGeofencesProvider(true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteGeofence(BusGeofence geofence) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Geofence'),
        content: Text('Delete "${geofence.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(busTrackingRepositoryProvider);
        await repo.deleteGeofence(geofence.id);
        ref.invalidate(busGeofencesProvider(false));
        ref.invalidate(busGeofencesProvider(true));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }
}

class _GeofenceCard extends StatelessWidget {
  final BusGeofence geofence;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _GeofenceCard({
    required this.geofence,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _zoneColor(geofence.zoneType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _zoneIcon(geofence.zoneType),
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        geofence.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${geofence.zoneLabel} - ${geofence.radiusMeters.toStringAsFixed(0)}m radius',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: geofence.isActive,
                  onChanged: (_) => onToggle(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${geofence.latitude.toStringAsFixed(4)}, ${geofence.longitude.toStringAsFixed(4)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (geofence.notifyOnEnter)
                  const _AlertChip(label: 'Enter', color: AppColors.success),
                const SizedBox(width: 4),
                if (geofence.notifyOnExit)
                  const _AlertChip(label: 'Exit', color: AppColors.warning),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                  color: AppColors.error,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _zoneColor(String type) {
    switch (type) {
      case 'school':
        return AppColors.success;
      case 'stop':
        return AppColors.info;
      case 'restricted':
        return AppColors.error;
      default:
        return AppColors.accent;
    }
  }

  IconData _zoneIcon(String type) {
    switch (type) {
      case 'school':
        return Icons.school;
      case 'stop':
        return Icons.place;
      case 'restricted':
        return Icons.block;
      default:
        return Icons.fence;
    }
  }
}

class _AlertChip extends StatelessWidget {
  final String label;
  final Color color;

  const _AlertChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
