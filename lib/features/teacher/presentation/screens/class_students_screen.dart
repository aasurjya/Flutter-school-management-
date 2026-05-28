import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/copy/warm_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/student.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../attendance/providers/attendance_provider.dart';
import '../../../exams/providers/exams_provider.dart';
import '../../../students/providers/students_provider.dart';

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

  // Map a real Student into the rendering shape this screen consumes.
  // attendance% comes from a bulk section query; lastExamScore comes from a
  // section-scoped overall-ranks lookup. Either may be missing (loading,
  // error, or no data for that student) — cards render "—" gracefully.
  Map<String, dynamic> _mapStudent(
    Student s, {
    Map<String, double>? attendance,
    Map<String, double>? scores,
  }) {
    final last = (s.lastName ?? '').trim();
    final full = ('${s.firstName} $last').trim();
    final att = attendance?[s.id];
    final score = scores?[s.id];
    return {
      'id': s.id,
      'name': full.isEmpty ? 'Student' : full,
      'rollNo': s.rollNumber ?? '',
      'attendance': att,
      'lastExamScore': score?.round(),
      'photoUrl': s.photoUrl,
    };
  }

  List<Map<String, dynamic>> _filterAndSort(List<Map<String, dynamic>> source) {
    final q = _searchQuery.toLowerCase();
    final students = source.where((s) {
      if (q.isEmpty) return true;
      final name = (s['name'] as String).toLowerCase();
      final roll = s['rollNo'] as String;
      return name.contains(q) || roll.contains(_searchQuery);
    }).toList();

    int cmpNullableNum(num? a, num? b) {
      if (a == null && b == null) return 0;
      if (a == null) return 1; // nulls last
      if (b == null) return -1;
      return b.compareTo(a); // descending
    }

    switch (_sortBy) {
      case 'name':
        students.sort((a, b) =>
            (a['name'] as String).compareTo(b['name'] as String));
        break;
      case 'roll':
        students.sort((a, b) =>
            (a['rollNo'] as String).compareTo(b['rollNo'] as String));
        break;
      case 'attendance':
        students.sort((a, b) =>
            cmpNullableNum(a['attendance'] as double?, b['attendance'] as double?));
        break;
      case 'performance':
        students.sort((a, b) =>
            cmpNullableNum(a['lastExamScore'] as int?, b['lastExamScore'] as int?));
        break;
    }
    return students;
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync =
        ref.watch(studentsBySectionProvider(widget.sectionId));
    // Optional enrichments — failures or pending states fall back to "—".
    final attendanceMap = ref
        .watch(sectionAttendancePercentsProvider(widget.sectionId))
        .maybeWhen(data: (m) => m, orElse: () => const <String, double>{});
    final scoresMap = ref
        .watch(sectionLatestExamScoresProvider(widget.sectionId))
        .maybeWhen(data: (m) => m, orElse: () => const <String, double>{});

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
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(WarmCopy.loadFailed('students'))),
        data: (real) {
          final filtered = _filterAndSort(real
              .map((s) => _mapStudent(s,
                  attendance: attendanceMap, scores: scoresMap))
              .toList());
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.primary.withValues(alpha: 0.05),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search students...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} student${filtered.length == 1 ? '' : 's'}',
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
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            real.isEmpty
                                ? 'No students enrolled in this section yet.'
                                : 'No students match your search.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final student = filtered[index];
                          return _StudentCard(
                            student: student,
                            onTap: () => _showStudentDetail(student),
                          );
                        },
                      ),
              ),
            ],
          );
        },
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
    final attendance = student['attendance'] as double?;
    final score = student['lastExamScore'] as int?;
    final isLowAttendance = attendance != null && attendance < 75;
    final isWeakPerformance = score != null && score < 40;

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
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
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
                        color: attendance == null
                            ? Colors.grey
                            : (isLowAttendance ? AppColors.error : AppColors.success),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        attendance == null
                            ? '— %'
                            : '${attendance.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: attendance == null
                              ? Colors.grey[600]
                              : (isLowAttendance ? AppColors.error : AppColors.success),
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
                        color: score == null
                            ? Colors.grey
                            : (isWeakPerformance ? AppColors.warning : AppColors.info),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        score == null ? '—/100' : '$score/100',
                        style: TextStyle(
                          fontSize: 12,
                          color: score == null
                              ? Colors.grey[600]
                              : (isWeakPerformance ? AppColors.warning : AppColors.info),
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
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Close',
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
                          value: () {
                            final a = student['attendance'] as double?;
                            return a == null ? '— %' : '${a.toStringAsFixed(1)}%';
                          }(),
                          icon: Icons.calendar_today,
                          color: () {
                            final a = student['attendance'] as double?;
                            if (a == null) return Colors.grey;
                            return a >= 75 ? AppColors.success : AppColors.error;
                          }(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Last Exam',
                          value: () {
                            final s = student['lastExamScore'] as int?;
                            return s == null ? '—/100' : '$s/100';
                          }(),
                          icon: Icons.grade,
                          color: () {
                            final s = student['lastExamScore'] as int?;
                            if (s == null) return Colors.grey;
                            return s >= 40 ? AppColors.info : AppColors.warning;
                          }(),
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
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.messages);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.history, color: AppColors.secondary),
                    title: const Text('View Attendance History'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.attendance);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.assignment, color: AppColors.accent),
                    title: const Text('View Assignments'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.assignments);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.analytics, color: AppColors.info),
                    title: const Text('Performance Report'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      final studentId = student['id'] as String;
                      context.push(AppRoutes.childInsights.replaceFirst(':studentId', studentId));
                    },
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
