import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';

class StudentDetailScreen extends ConsumerWidget {
  final String studentId;

  const StudentDetailScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Fetch student data using studentId
    final student = _mockStudent;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          child: Text(
                            student['initials'] as String,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          student['name'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${student['class'] as String} • Roll No: ${student['rollNo'] as String}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick Stats
                _buildQuickStats(context, student),
                const SizedBox(height: 24),

                // Personal Information
                _buildSection(
                  context,
                  'Personal Information',
                  Icons.person_outline,
                  [
                    _InfoRow('Admission No', student['admissionNo'] as String),
                    _InfoRow('Date of Birth', student['dob'] as String),
                    _InfoRow('Gender', student['gender'] as String),
                    _InfoRow('Blood Group', student['bloodGroup'] as String),
                  ],
                ),
                const SizedBox(height: 16),

                // Contact Information
                _buildSection(
                  context,
                  'Contact Information',
                  Icons.phone_outlined,
                  [
                    _InfoRow('Phone', student['phone'] as String),
                    _InfoRow('Email', student['email'] as String),
                    _InfoRow('Address', student['address'] as String),
                  ],
                ),
                const SizedBox(height: 16),

                // Guardian Information
                _buildSection(
                  context,
                  'Guardian Information',
                  Icons.family_restroom,
                  [
                    _InfoRow('Father', student['fatherName'] as String),
                    _InfoRow("Father's Phone", student['fatherPhone'] as String),
                    _InfoRow('Mother', student['motherName'] as String),
                    _InfoRow("Mother's Phone", student['motherPhone'] as String),
                  ],
                ),
                const SizedBox(height: 16),

                // Academic Information
                _buildSection(
                  context,
                  'Academic Information',
                  Icons.school_outlined,
                  [
                    _InfoRow('Class', student['class'] as String),
                    _InfoRow('Section', student['section'] as String),
                    _InfoRow('Roll Number', student['rollNo'] as String),
                    _InfoRow('Academic Year', '2024-25'),
                  ],
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.fact_check),
                        label: const Text('Attendance'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.assignment),
                        label: const Text('Results'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.payment),
                        label: const Text('Fees'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.message),
                        label: const Text('Message'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, Map<String, dynamic> student) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Attendance',
            value: '${student['attendance']}%',
            icon: Icons.calendar_today,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Avg Score',
            value: '${student['avgScore']}%',
            icon: Icons.trending_up,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Rank',
            value: '#${student['rank']}',
            icon: Icons.emoji_events,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<_InfoRow> rows,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        row.label,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;

  _InfoRow(this.label, this.value);
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// Mock data
final _mockStudent = {
  'id': '1',
  'name': 'Arjun Kumar',
  'initials': 'AK',
  'class': 'Class 10',
  'section': 'A',
  'rollNo': '15',
  'admissionNo': 'ADM2024001',
  'dob': '15 March 2009',
  'gender': 'Male',
  'bloodGroup': 'O+',
  'phone': '+91 98765 43210',
  'email': 'arjun.kumar@email.com',
  'address': '123, ABC Colony, City - 560001',
  'fatherName': 'Rajesh Kumar',
  'fatherPhone': '+91 98765 43200',
  'motherName': 'Sunita Kumar',
  'motherPhone': '+91 98765 43201',
  'attendance': 94,
  'avgScore': 87,
  'rank': 5,
};
