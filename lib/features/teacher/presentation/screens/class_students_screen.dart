import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';

class ClassStudentsScreen extends ConsumerStatefulWidget {
  final String sectionId;
  final String? className;

  const ClassStudentsScreen({
    super.key,
    required this.sectionId,
    this.className,
  });

  @override
  ConsumerState<ClassStudentsScreen> createState() => _ClassStudentsScreenState();
}

class _ClassStudentsScreenState extends ConsumerState<ClassStudentsScreen> {
  String _searchQuery = '';
  String _sortBy = 'name';

  // Mock students data
  final List<Map<String, dynamic>> _students = [
    {'id': '1', 'name': 'Aarav Sharma', 'rollNo': '01', 'attendance': 92.5, 'lastExamScore': 85, 'photoUrl': null},
    {'id': '2', 'name': 'Aditi Patel', 'rollNo': '02', 'attendance': 88.0, 'lastExamScore': 92, 'photoUrl': null},
    {'id': '3', 'name': 'Arjun Kumar', 'rollNo': '03', 'attendance': 95.0, 'lastExamScore': 78, 'photoUrl': null},
    {'id': '4', 'name': 'Diya Singh', 'rollNo': '04', 'attendance': 78.5, 'lastExamScore': 88, 'photoUrl': null},
    {'id': '5', 'name': 'Ishaan Gupta', 'rollNo': '05', 'attendance': 90.0, 'lastExamScore': 72, 'photoUrl': null},
    {'id': '6', 'name': 'Kavya Reddy', 'rollNo': '06', 'attendance': 85.5, 'lastExamScore': 95, 'photoUrl': null},
    {'id': '7', 'name': 'Mihir Joshi', 'rollNo': '07', 'attendance': 68.0, 'lastExamScore': 65, 'photoUrl': null},
    {'id': '8', 'name': 'Nisha Agarwal', 'rollNo': '08', 'attendance': 94.0, 'lastExamScore': 89, 'photoUrl': null},
    {'id': '9', 'name': 'Pranav Verma', 'rollNo': '09', 'attendance': 91.5, 'lastExamScore': 82, 'photoUrl': null},
    {'id': '10', 'name': 'Riya Malhotra', 'rollNo': '10', 'attendance': 87.0, 'lastExamScore': 91, 'photoUrl': null},
  ];

  List<Map<String, dynamic>> get filteredStudents {
    var students = _students.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s['rollNo'].contains(_searchQuery);
    }).toList();

    switch (_sortBy) {
      case 'name':
        students.sort((a, b) => a['name'].compareTo(b['name']));
        break;
      case 'roll':
        students.sort((a, b) => a['rollNo'].compareTo(b['rollNo']));
        break;
      case 'attendance':
        students.sort((a, b) => (b['attendance'] as double).compareTo(a['attendance'] as double));
        break;
      case 'performance':
        students.sort((a, b) => (b['lastExamScore'] as int).compareTo(a['lastExamScore'] as int));
        break;
    }
    return students;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.className ?? 'Class Students'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              _buildSortMenuItem('name', 'Name'),
              _buildSortMenuItem('roll', 'Roll Number'),
              _buildSortMenuItem('attendance', 'Attendance'),
              _buildSortMenuItem('performance', 'Performance'),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary.withOpacity(0.05),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${filteredStudents.length} students',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Spacer(),
                Text(
                  'Sorted by: ${_getSortLabel()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredStudents.length,
              itemBuilder: (context, index) {
                final student = filteredStudents[index];
                return _StudentCard(
                  student: student,
                  onTap: () => _showStudentDetail(student),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(String value, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (_sortBy == value)
            const Icon(Icons.check, size: 18, color: AppColors.primary)
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'name': return 'Name';
      case 'roll': return 'Roll No';
      case 'attendance': return 'Attendance';
      case 'performance': return 'Performance';
      default: return _sortBy;
    }
  }

  void _showStudentDetail(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StudentDetailSheet(student: student),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final VoidCallback onTap;

  const _StudentCard({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final attendance = student['attendance'] as double;
    final score = student['lastExamScore'] as int;
    final isLowAttendance = attendance < 75;
    final isWeakPerformance = score < 40;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  student['name'].split(' ').map((n) => n[0]).take(2).join(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          student['name'],
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (isLowAttendance || isWeakPerformance) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.warning,
                            size: 14,
                            color: isLowAttendance ? AppColors.error : AppColors.warning,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Roll No: ${student['rollNo']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: isLowAttendance ? AppColors.error : AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${attendance.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: isLowAttendance ? AppColors.error : AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.grade,
                        size: 14,
                        color: isWeakPerformance ? AppColors.warning : AppColors.info,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$score/100',
                        style: TextStyle(
                          fontSize: 12,
                          color: isWeakPerformance ? AppColors.warning : AppColors.info,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentDetailSheet extends StatelessWidget {
  final Map<String, dynamic> student;

  const _StudentDetailSheet({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    student['name'].split(' ').map((n) => n[0]).take(2).join(),
                    style: const TextStyle(
                      fontSize: 20,
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
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Roll No: ${student['rollNo']}',
                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Attendance',
                          value: '${(student['attendance'] as double).toStringAsFixed(1)}%',
                          icon: Icons.calendar_today,
                          color: (student['attendance'] as double) >= 75
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Last Exam',
                          value: '${student['lastExamScore']}/100',
                          icon: Icons.grade,
                          color: (student['lastExamScore'] as int) >= 40
                              ? AppColors.info
                              : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.message, color: AppColors.primary),
                    title: const Text('Message Parent'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.history, color: AppColors.secondary),
                    title: const Text('View Attendance History'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.assignment, color: AppColors.accent),
                    title: const Text('View Assignments'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.analytics, color: AppColors.info),
                    title: const Text('Performance Report'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
