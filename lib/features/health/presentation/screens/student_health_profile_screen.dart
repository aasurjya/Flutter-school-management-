import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/health_provider.dart';

class StudentHealthProfileScreen extends ConsumerWidget {
  final String studentId;

  const StudentHealthProfileScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthRecordAsync = ref.watch(healthRecordProvider(studentId));
    final incidentsAsync = ref.watch(
      incidentsProvider(IncidentFilter(studentId: studentId)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/health/edit/$studentId'),
          ),
        ],
      ),
      body: healthRecordAsync.when(
        data: (record) {
          if (record == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_information_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  const Text('No health record found'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => context.push('/health/edit/$studentId'),
                    child: const Text('Add Health Record'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Info Card
                _SectionCard(
                  title: 'Basic Information',
                  icon: Icons.person,
                  children: [
                    _InfoRow(
                      label: 'Blood Group',
                      value: record.bloodGroup ?? 'Not specified',
                      icon: Icons.water_drop,
                      iconColor: Colors.red,
                    ),
                    if (record.heightCm != null)
                      _InfoRow(
                        label: 'Height',
                        value: '${record.heightCm} cm',
                        icon: Icons.height,
                      ),
                    if (record.weightKg != null)
                      _InfoRow(
                        label: 'Weight',
                        value: '${record.weightKg} kg',
                        icon: Icons.monitor_weight,
                      ),
                    if (record.bmi != null)
                      _InfoRow(
                        label: 'BMI',
                        value: '${record.bmi!.toStringAsFixed(1)} (${record.bmiCategory})',
                        icon: Icons.speed,
                      ),
                    if (record.lastCheckupDate != null)
                      _InfoRow(
                        label: 'Last Checkup',
                        value: DateFormat('dd MMM yyyy').format(record.lastCheckupDate!),
                        icon: Icons.calendar_today,
                      ),
                  ],
                ),

                // Allergies & Conditions
                if (record.hasAllergies || record.hasChronicConditions) ...[
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Medical Conditions',
                    icon: Icons.warning_amber,
                    iconColor: Colors.orange,
                    children: [
                      if (record.hasAllergies) ...[
                        Text(
                          'Allergies',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: record.allergies
                              .map((a) => Chip(
                                    label: Text(a),
                                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                                    labelStyle: const TextStyle(color: Colors.red),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (record.hasChronicConditions) ...[
                        Text(
                          'Chronic Conditions',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: record.chronicConditions
                              .map((c) => Chip(
                                    label: Text(c),
                                    backgroundColor: Colors.orange.withValues(alpha: 0.1),
                                    labelStyle: const TextStyle(color: Colors.orange),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ],

                // Medications
                if (record.hasMedications) ...[
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Current Medications',
                    icon: Icons.medication,
                    iconColor: Colors.blue,
                    children: [
                      ...record.currentMedications.map((med) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.medication_liquid),
                            title: Text(med['name'] ?? 'Medication'),
                            subtitle: Text(med['dosage'] ?? ''),
                            trailing: Text(med['frequency'] ?? ''),
                          )),
                    ],
                  ),
                ],

                // Vision & Hearing
                if (record.visionLeft != null ||
                    record.visionRight != null ||
                    record.hearingStatus != null) ...[
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Vision & Hearing',
                    icon: Icons.visibility,
                    children: [
                      if (record.visionLeft != null || record.visionRight != null)
                        _InfoRow(
                          label: 'Vision',
                          value:
                              'L: ${record.visionLeft ?? 'N/A'} | R: ${record.visionRight ?? 'N/A'}',
                          icon: Icons.remove_red_eye,
                        ),
                      if (record.hearingStatus != null)
                        _InfoRow(
                          label: 'Hearing',
                          value: record.hearingStatus!,
                          icon: Icons.hearing,
                        ),
                    ],
                  ),
                ],

                // Emergency Contact
                if (record.emergencyContactName != null) ...[
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Emergency Contact',
                    icon: Icons.emergency,
                    iconColor: Colors.red,
                    children: [
                      _InfoRow(
                        label: 'Name',
                        value: record.emergencyContactName!,
                        icon: Icons.person,
                      ),
                      if (record.emergencyContactPhone != null)
                        _InfoRow(
                          label: 'Phone',
                          value: record.emergencyContactPhone!,
                          icon: Icons.phone,
                        ),
                      if (record.emergencyContactRelation != null)
                        _InfoRow(
                          label: 'Relation',
                          value: record.emergencyContactRelation!,
                          icon: Icons.family_restroom,
                        ),
                    ],
                  ),
                ],

                // Doctor Info
                if (record.familyDoctorName != null) ...[
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Family Doctor',
                    icon: Icons.local_hospital,
                    iconColor: Colors.green,
                    children: [
                      _InfoRow(
                        label: 'Name',
                        value: record.familyDoctorName!,
                        icon: Icons.person,
                      ),
                      if (record.familyDoctorPhone != null)
                        _InfoRow(
                          label: 'Phone',
                          value: record.familyDoctorPhone!,
                          icon: Icons.phone,
                        ),
                    ],
                  ),
                ],

                // Insurance
                if (record.insuranceProvider != null) ...[
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Insurance',
                    icon: Icons.health_and_safety,
                    iconColor: Colors.teal,
                    children: [
                      _InfoRow(
                        label: 'Provider',
                        value: record.insuranceProvider!,
                        icon: Icons.business,
                      ),
                      if (record.insurancePolicyNumber != null)
                        _InfoRow(
                          label: 'Policy Number',
                          value: record.insurancePolicyNumber!,
                          icon: Icons.numbers,
                        ),
                    ],
                  ),
                ],

                // Incidents
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Health Incidents',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton.icon(
                      onPressed: () => context.push('/health/incidents/$studentId'),
                      icon: const Icon(Icons.add),
                      label: const Text('Log Incident'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                incidentsAsync.when(
                  data: (incidents) {
                    if (incidents.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No incidents recorded'),
                        ),
                      );
                    }

                    return Column(
                      children: incidents.take(5).map((incident) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: _SeverityIcon(severity: incident.severity),
                            title: Text(incident.description),
                            subtitle: Text(
                              DateFormat('dd MMM yyyy').format(incident.incidentDate),
                            ),
                            trailing: incident.followUpRequired
                                ? const Icon(Icons.schedule, color: Colors.orange)
                                : null,
                          ),
                        );
                      }).toList(),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeverityIcon extends StatelessWidget {
  final String severity;

  const _SeverityIcon({required this.severity});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (severity) {
      case 'minor':
        color = Colors.green;
        icon = Icons.info_outline;
        break;
      case 'moderate':
        color = Colors.orange;
        icon = Icons.warning_amber_outlined;
        break;
      case 'serious':
        color = Colors.deepOrange;
        icon = Icons.warning_outlined;
        break;
      case 'critical':
        color = Colors.red;
        icon = Icons.error_outline;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color),
    );
  }
}
