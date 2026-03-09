import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../data/models/homework.dart';
import '../../../homework/providers/homework_provider.dart';
import '../../../students/providers/students_provider.dart';
import '../../../../core/providers/supabase_provider.dart';

/// Parent view — shows all homework across subjects for their child.
class HomeworkTrackerScreen extends ConsumerStatefulWidget {
  const HomeworkTrackerScreen({super.key});

  @override
  ConsumerState<HomeworkTrackerScreen> createState() =>
      _HomeworkTrackerScreenState();
}

class _HomeworkTrackerScreenState
    extends ConsumerState<HomeworkTrackerScreen> {
  String _filter = 'All'; // All | Pending | Submitted | Overdue
  final List<String> _filters = ['All', 'Pending', 'Submitted', 'Overdue'];

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(supabaseProvider).auth.currentUser?.id;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    final childrenAsync = ref.watch(parentChildrenProvider(userId));
    final selectedChild = ref.watch(selectedChildProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Homework Tracker'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Child switcher in app bar
          childrenAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (children) {
              if (children.length <= 1) return const SizedBox.shrink();
              return PopupMenuButton<Map<String, dynamic>>(
                initialValue: selectedChild,
                icon: const Icon(Icons.person_outline, color: Colors.white),
                onSelected: (child) {
                  ref.read(selectedChildProvider.notifier).state = child;
                },
                itemBuilder: (_) => children.map((c) {
                  return PopupMenuItem<Map<String, dynamic>>(
                    value: c,
                    child: Text(c['student_name'] ?? 'Student'),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
      body: childrenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (children) {
          if (children.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.child_care, size: 64, color: AppColors.grey300),
                    SizedBox(height: 16),
                    Text('No children linked to this account.',
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          // Auto-select first child
          final active = selectedChild ?? children.first;
          final studentId = active['student_id'] as String? ?? '';
          final studentName = active['student_name'] as String? ?? 'Your Child';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Child name banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppColors.primaryLight,
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      studentName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '· ${active['class_name'] ?? ''} ${active['section_name'] ?? ''}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.grey500),
                    ),
                  ],
                ),
              ),

              // Filter chips
              _FilterRow(
                selected: _filter,
                filters: _filters,
                onSelected: (v) => setState(() => _filter = v),
              ),

              // List
              Expanded(
                child: _HomeworkList(
                  studentId: studentId,
                  filter: _filter,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter Row
// ---------------------------------------------------------------------------

class _FilterRow extends StatelessWidget {
  final String selected;
  final List<String> filters;
  final ValueChanged<String> onSelected;

  const _FilterRow({
    required this.selected,
    required this.filters,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: filters.length,
        itemBuilder: (context, i) {
          final f = filters[i];
          final isActive = f == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f),
              selected: isActive,
              onSelected: (_) => onSelected(f),
              backgroundColor: AppColors.grey100,
              selectedColor: AppColors.primaryLight,
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isActive ? AppColors.primary : AppColors.grey600,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
              side: BorderSide(
                color: isActive ? AppColors.primary : AppColors.grey200,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Homework list widget
// ---------------------------------------------------------------------------

class _HomeworkList extends ConsumerWidget {
  final String studentId;
  final String filter;

  const _HomeworkList({required this.studentId, required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeworkAsync =
        ref.watch(studentHomeworkProvider(studentId));

    return homeworkAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(studentHomeworkProvider(studentId)),
      ),
      data: (allHomework) {
        final now = DateTime.now();
        final filtered = allHomework.where((hw) {
          if (hw.status != HomeworkStatus.published) return false;
          switch (filter) {
            case 'Pending':
              return hw.dueDate.isAfter(now);
            case 'Submitted':
              // We don't have per-student submission here; show closed
              return hw.status == HomeworkStatus.closed;
            case 'Overdue':
              return hw.dueDate.isBefore(now) &&
                  hw.status == HomeworkStatus.published;
            default:
              return true;
          }
        }).toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.assignment_outlined,
                      size: 56, color: AppColors.grey300),
                  const SizedBox(height: 16),
                  Text(
                    filter == 'All'
                        ? 'No homework assigned'
                        : 'No $filter homework',
                    style: const TextStyle(color: AppColors.grey500),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: filtered.length,
          itemBuilder: (context, i) => _HomeworkItem(
            homework: filtered[i],
            onTap: () => context.push(
              AppRoutes.homeworkDetail
                  .replaceAll(':homeworkId', filtered[i].id),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Individual homework item
// ---------------------------------------------------------------------------

class _HomeworkItem extends StatelessWidget {
  final Homework homework;
  final VoidCallback onTap;

  const _HomeworkItem({required this.homework, required this.onTap});

  static const List<Color> _subjectColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
  ];

  Color _subjectColor() {
    final index = homework.subjectId.hashCode.abs() % _subjectColors.length;
    return _subjectColors[index];
  }

  bool get _isOverdue =>
      homework.dueDate.isBefore(DateTime.now()) &&
      homework.status == HomeworkStatus.published;

  @override
  Widget build(BuildContext context) {
    final subjectColor = _subjectColor();
    final dueText = DateFormat('MMM d, yyyy').format(homework.dueDate);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(
              color: _isOverdue ? AppColors.error : subjectColor,
              width: 4,
            ),
            top: const BorderSide(color: AppColors.grey200),
            right: const BorderSide(color: AppColors.grey200),
            bottom: const BorderSide(color: AppColors.grey200),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject dot
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: subjectColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          homework.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          homework.subjectName ?? 'Subject',
                          style: TextStyle(
                            fontSize: 12,
                            color: subjectColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _HomeworkStatusChip(
                      isOverdue: _isOverdue, status: homework.status),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: AppColors.grey400),
                  const SizedBox(width: 4),
                  Text(
                    'Due $dueText',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          _isOverdue ? AppColors.error : AppColors.grey500,
                      fontWeight:
                          _isOverdue ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  if (homework.assignedByName != null) ...[
                    const Icon(Icons.person_outline,
                        size: 13, color: AppColors.grey400),
                    const SizedBox(width: 4),
                    Text(
                      homework.assignedByName!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.grey500),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeworkStatusChip extends StatelessWidget {
  final bool isOverdue;
  final HomeworkStatus status;

  const _HomeworkStatusChip(
      {required this.isOverdue, required this.status});

  @override
  Widget build(BuildContext context) {
    if (isOverdue) return StatusChip.fromString('overdue');
    switch (status) {
      case HomeworkStatus.closed:
        return StatusChip.fromString('submitted');
      case HomeworkStatus.published:
        return StatusChip.fromString('pending');
      default:
        return StatusChip.fromString(status.label);
    }
  }
}
