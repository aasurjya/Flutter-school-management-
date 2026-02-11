import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';

class StudentsListScreen extends ConsumerStatefulWidget {
  const StudentsListScreen({super.key});

  @override
  ConsumerState<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends ConsumerState<StudentsListScreen> {
  String _selectedClass = 'All';
  String _searchQuery = '';

  final _classes = ['All', 'Class 10-A', 'Class 10-B', 'Class 9-A', 'Class 9-B'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Navigate to add student
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
              ),
            ),
          ),

          // Class Filter Chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _classes.length,
              itemBuilder: (context, index) {
                final className = _classes[index];
                final isSelected = className == _selectedClass;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(className),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedClass = className);
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Students List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _mockStudents.length,
              itemBuilder: (context, index) {
                final student = _mockStudents[index];
                return _StudentCard(
                  student: student,
                  onTap: () => context.push('/students/${student['id']}'),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to add student
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Student'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Students',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text('Status', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(label: const Text('Active'), onSelected: (_) {}, selected: true),
                  FilterChip(label: const Text('Inactive'), onSelected: (_) {}),
                  FilterChip(label: const Text('Alumni'), onSelected: (_) {}),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Gender', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(label: const Text('All'), onSelected: (_) {}, selected: true),
                  FilterChip(label: const Text('Male'), onSelected: (_) {}),
                  FilterChip(label: const Text('Female'), onSelected: (_) {}),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Apply Filters', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final VoidCallback onTap;

  const _StudentCard({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              student['initials'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${student['class']} • Roll No: ${student['rollNo']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      student['phone'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: student['attendance'] >= 90
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${student['attendance']}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: student['attendance'] >= 90
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Mock data
final _mockStudents = [
  {'id': '1', 'name': 'Arjun Kumar', 'initials': 'AK', 'class': 'Class 10-A', 'rollNo': '15', 'phone': '+91 98765 43210', 'attendance': 94},
  {'id': '2', 'name': 'Priya Sharma', 'initials': 'PS', 'class': 'Class 10-A', 'rollNo': '16', 'phone': '+91 98765 43211', 'attendance': 98},
  {'id': '3', 'name': 'Rahul Singh', 'initials': 'RS', 'class': 'Class 10-B', 'rollNo': '12', 'phone': '+91 98765 43212', 'attendance': 85},
  {'id': '4', 'name': 'Sneha Patel', 'initials': 'SP', 'class': 'Class 10-A', 'rollNo': '18', 'phone': '+91 98765 43213', 'attendance': 92},
  {'id': '5', 'name': 'Amit Gupta', 'initials': 'AG', 'class': 'Class 9-A', 'rollNo': '8', 'phone': '+91 98765 43214', 'attendance': 96},
  {'id': '6', 'name': 'Neha Verma', 'initials': 'NV', 'class': 'Class 9-B', 'rollNo': '22', 'phone': '+91 98765 43215', 'attendance': 88},
  {'id': '7', 'name': 'Vikram Joshi', 'initials': 'VJ', 'class': 'Class 10-B', 'rollNo': '5', 'phone': '+91 98765 43216', 'attendance': 91},
  {'id': '8', 'name': 'Kavita Reddy', 'initials': 'KR', 'class': 'Class 9-A', 'rollNo': '14', 'phone': '+91 98765 43217', 'attendance': 97},
];
