import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/emergency.dart';
import '../../providers/emergency_provider.dart';

class EmergencyDashboardScreen extends ConsumerWidget {
  const EmergencyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAlertAsync = ref.watch(activeAlertProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Emergency Center',
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Active alert banner
          activeAlertAsync.when(
            data: (alert) {
              if (alert == null) {
                return _NoActiveAlertBanner();
              }
              return _ActiveAlertBanner(alert: alert);
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, __) => Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.errorLight,
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Could not load alert status: $error',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Quick Actions'),
                      Tab(text: 'History'),
                      Tab(text: 'Contacts'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _QuickActionsTab(),
                        _HistoryTab(),
                        _ContactsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoActiveAlertBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.successLight,
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.success),
          SizedBox(width: 12),
          Text(
            'All Clear - No Active Emergencies',
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveAlertBanner extends StatelessWidget {
  final EmergencyAlert alert;

  const _ActiveAlertBanner({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = _getSeverityColor(alert.severity);

    return Container(
      padding: const EdgeInsets.all(16),
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: AppColors.background, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE ALERT: ${alert.title}',
                      style: const TextStyle(
                        color: AppColors.background,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      alert.message,
                      style: const TextStyle(color: AppColors.background),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.tonal(
                onPressed: () => _respondSafe(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.background,
                  foregroundColor: AppColors.success,
                ),
                child: const Text("I'm Safe"),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () => _respondNeedHelp(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.background,
                  foregroundColor: AppColors.error,
                ),
                child: const Text('Need Help'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return AppColors.error;
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.warning;
      default:
        return AppColors.error;
    }
  }

  void _respondSafe(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Response recorded: Safe'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _respondNeedHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Help'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please provide your location:'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Location',
                hintText: 'e.g., Room 203, Building B',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Additional Notes',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help request sent!'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Send Help Request'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _EmergencyActionCard(
          icon: Icons.local_fire_department,
          label: 'Fire',
          color: AppColors.warning,
          onTap: () => _initiateAlert(context, 'fire', 'Fire Emergency'),
        ),
        _EmergencyActionCard(
          icon: Icons.lock,
          label: 'Lockdown',
          color: AppColors.error,
          onTap: () => _initiateAlert(context, 'lockdown', 'Lockdown Alert'),
        ),
        _EmergencyActionCard(
          icon: Icons.medical_services,
          label: 'Medical',
          color: AppColors.primary,
          onTap: () => _initiateAlert(context, 'medical', 'Medical Emergency'),
        ),
        _EmergencyActionCard(
          icon: Icons.cloud,
          label: 'Weather',
          color: AppColors.info,
          onTap: () => _initiateAlert(context, 'weather', 'Severe Weather Alert'),
        ),
        _EmergencyActionCard(
          icon: Icons.vibration,
          label: 'Earthquake',
          color: AppColors.grey600,
          onTap: () => _initiateAlert(context, 'earthquake', 'Earthquake Alert'),
        ),
        _EmergencyActionCard(
          icon: Icons.assignment,
          label: 'Start Drill',
          color: AppColors.success,
          onTap: () => _startDrill(context),
        ),
      ],
    );
  }

  void _initiateAlert(BuildContext context, String type, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Initiate $title?'),
        content: const Text(
          'This will send an emergency alert to all staff, teachers, and parents. '
          'Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title initiated!'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _startDrill(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Emergency Drill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select drill type:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.local_fire_department, color: AppColors.warning),
              title: const Text('Fire Drill'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fire Drill started')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock, color: AppColors.error),
              title: const Text('Lockdown Drill'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lockdown Drill started')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.vibration, color: AppColors.grey600),
              title: const Text('Earthquake Drill'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Earthquake Drill started')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _EmergencyActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(
      alertsProvider(const AlertsFilter(limit: 20)),
    );

    return alertsAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) {
          return const Center(child: Text('No emergency alerts in history'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: alerts.length,
          itemBuilder: (context, index) => _AlertHistoryCard(alert: alerts[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _AlertHistoryCard extends StatelessWidget {
  final EmergencyAlert alert;

  const _AlertHistoryCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: alert.isActive
                ? AppColors.error.withAlpha(30)
                : AppColors.grey400.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getAlertIcon(alert.alertType),
            color: alert.isActive ? AppColors.error : AppColors.grey400,
          ),
        ),
        title: Text(
          alert.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${alert.initiatedAt.day}/${alert.initiatedAt.month}/${alert.initiatedAt.year}',
        ),
        trailing: Chip(
          label: Text(
            alert.isActive ? 'ACTIVE' : 'RESOLVED',
            style: TextStyle(
              color: alert.isActive ? AppColors.background : AppColors.grey500,
              fontSize: 10,
            ),
          ),
          backgroundColor: alert.isActive ? AppColors.error : AppColors.grey200,
        ),
      ),
    );
  }

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'fire':
        return Icons.local_fire_department;
      case 'lockdown':
        return Icons.lock;
      case 'medical':
        return Icons.medical_services;
      case 'weather':
        return Icons.cloud;
      case 'earthquake':
        return Icons.vibration;
      default:
        return Icons.warning;
    }
  }
}

class _ContactsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(
      emergencyContactsProvider(const ContactsFilter()),
    );

    return contactsAsync.when(
      data: (contacts) {
        if (contacts.isEmpty) {
          return const Center(child: Text('No emergency contacts configured'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contacts.length,
          itemBuilder: (context, index) =>
              _ContactCard(contact: contacts[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final EmergencyContact contact;

  const _ContactCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.errorLight,
          child: Icon(
            _getContactIcon(contact.contactType),
            color: AppColors.error,
          ),
        ),
        title: Text(contact.name),
        subtitle: Text(contact.contactTypeDisplay),
        trailing: IconButton(
          icon: const Icon(Icons.call, color: AppColors.success),
          tooltip: 'Call',
          onPressed: () {
            // In a real app, launch phone dialer
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Calling ${contact.phone}...')),
            );
          },
        ),
      ),
    );
  }

  IconData _getContactIcon(String type) {
    switch (type) {
      case 'emergency_services':
        return Icons.emergency;
      case 'hospital':
        return Icons.local_hospital;
      case 'police':
        return Icons.local_police;
      case 'fire':
        return Icons.local_fire_department;
      default:
        return Icons.phone;
    }
  }
}
