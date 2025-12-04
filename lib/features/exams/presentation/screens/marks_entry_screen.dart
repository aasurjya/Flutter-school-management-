import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';

class MarksEntryScreen extends ConsumerStatefulWidget {
  final String examId;

  const MarksEntryScreen({super.key, required this.examId});

  @override
  ConsumerState<MarksEntryScreen> createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends ConsumerState<MarksEntryScreen> {
  String _selectedSubject = 'Mathematics';
  final List<TextEditingController> _controllers = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _controllers.clear();
    for (var _ in _mockStudents) {
      _controllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Marks'),
        actions: [
          TextButton.icon(
            onPressed: _saveAsDraft,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Draft'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Info
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black12
                : AppColors.primary.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mid Term Examination - Class 10-A',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                // Subject Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Mathematics', 'Physics', 'Chemistry', 'English']
                        .map((subject) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(subject),
                                selected: _selectedSubject == subject,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedSubject = subject);
                                  }
                                },
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: _selectedSubject == subject
                                      ? Colors.white
                                      : null,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.assignment,
                      label: 'Max Marks: 100',
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(
                      icon: Icons.check_circle_outline,
                      label: 'Pass: 35',
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(
                      icon: Icons.people,
                      label: '${_mockStudents.length} Students',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stats Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(label: 'Entered', value: '8', color: AppColors.success),
                _StatItem(label: 'Pending', value: '2', color: AppColors.warning),
                _StatItem(label: 'Absent', value: '1', color: AppColors.error),
                _StatItem(label: 'Average', value: '72.5', color: AppColors.info),
              ],
            ),
          ),

          // Student List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _mockStudents.length,
              itemBuilder: (context, index) {
                final student = _mockStudents[index];
                return _MarksEntryCard(
                  rollNo: student['rollNo'] as String,
                  name: student['name'] as String,
                  controller: _controllers[index],
                  maxMarks: 100,
                  onChanged: (value) {
                    setState(() {});
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saveAsDraft,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Draft'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitMarks,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Submit Marks',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveAsDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft saved successfully'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  Future<void> _submitMarks() async {
    // Validate all marks
    bool hasErrors = false;
    for (int i = 0; i < _controllers.length; i++) {
      final text = _controllers[i].text;
      if (text.isNotEmpty) {
        final marks = double.tryParse(text);
        if (marks == null || marks < 0 || marks > 100) {
          hasErrors = true;
          break;
        }
      }
    }

    if (hasErrors) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid marks (0-100)'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marks submitted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _MarksEntryCard extends StatelessWidget {
  final String rollNo;
  final String name;
  final TextEditingController controller;
  final int maxMarks;
  final ValueChanged<String> onChanged;

  const _MarksEntryCard({
    required this.rollNo,
    required this.name,
    required this.controller,
    required this.maxMarks,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final marks = double.tryParse(controller.text);
    final isValid = marks == null || (marks >= 0 && marks <= maxMarks);
    final isPassing = marks != null && marks >= 35;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Roll Number
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  rollNo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            // Marks Input
            SizedBox(
              width: 80,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '0',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isValid ? Colors.grey.shade300 : AppColors.error,
                    ),
                  ),
                  filled: true,
                  fillColor: controller.text.isEmpty
                      ? Colors.grey.withOpacity(0.05)
                      : isPassing
                          ? AppColors.success.withOpacity(0.05)
                          : AppColors.error.withOpacity(0.05),
                ),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '/ $maxMarks',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(width: 8),
            // Absent checkbox
            IconButton(
              icon: Icon(
                Icons.person_off_outlined,
                color: Colors.grey[400],
                size: 20,
              ),
              onPressed: () {
                controller.text = 'AB';
                onChanged('AB');
              },
              tooltip: 'Mark Absent',
            ),
          ],
        ),
      ),
    );
  }
}

// Mock data
final _mockStudents = [
  {'rollNo': '01', 'name': 'Arjun Kumar'},
  {'rollNo': '02', 'name': 'Priya Sharma'},
  {'rollNo': '03', 'name': 'Rahul Singh'},
  {'rollNo': '04', 'name': 'Sneha Patel'},
  {'rollNo': '05', 'name': 'Amit Gupta'},
  {'rollNo': '06', 'name': 'Neha Verma'},
  {'rollNo': '07', 'name': 'Vikram Joshi'},
  {'rollNo': '08', 'name': 'Kavita Reddy'},
  {'rollNo': '09', 'name': 'Rohan Mishra'},
  {'rollNo': '10', 'name': 'Ananya Das'},
];
