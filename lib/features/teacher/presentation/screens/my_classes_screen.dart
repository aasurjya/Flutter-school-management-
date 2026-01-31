import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/repositories/timetable_repository.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../timetable/providers/timetable_provider.dart';

class MyClassesScreen extends ConsumerWidget {
  const MyClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }

    final classesAsync = ref.watch(teacherClassesProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(teacherClassesProvider(userId)),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: classesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(teacherClassesProvider(userId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (classes) {
          if (classes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.class_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No classes assigned yet'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(teacherClassesProvider(userId)),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final classInfo = classes[index];
                return _ClassCard(
                  classInfo: classInfo,
                  onTap: () => _showClassOptions(context, classInfo),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showClassOptions(BuildContext context, TeacherClassInfo classInfo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${classInfo.className} - ${classInfo.sectionName}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(classInfo.subjectName ?? 'No subject', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.people, color: AppColors.primary),
              title: const Text('View Students'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/teacher/class/${classInfo.sectionId}/students');
              },
            ),
            ListTile(
              leading: const Icon(Icons.fact_check, color: AppColors.secondary),
              title: const Text('Mark Attendance'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/attendance/mark/${classInfo.sectionId}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment, color: AppColors.accent),
              title: const Text('Assignments'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/teacher/assignments');
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: AppColors.info),
              title: const Text('Class Analytics'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/teacher/class-analytics/${classInfo.sectionId}?name=${classInfo.className}-${classInfo.sectionName}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.grade, color: AppColors.warning),
              title: const Text('Enter Marks'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/exams');
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final TeacherClassInfo classInfo;
  final VoidCallback onTap;

  const _ClassCard({required this.classInfo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Extract class number from className for display
    final classLabel = classInfo.className.replaceAll('Class ', '');

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$classLabel${classInfo.sectionName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${classInfo.className} - ${classInfo.sectionName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          classInfo.subjectName ?? 'No subject',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (classInfo.subjectCode != null)
                    _buildStatChip(Icons.book, classInfo.subjectCode!),
                  const SizedBox(width: 8),
                  _buildStatChip(Icons.class_, 'Section ${classInfo.sectionName}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, {Color color = AppColors.primary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
