import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../students/providers/students_provider.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../providers/parent_engagement_provider.dart';

/// Parent view — list of teachers for their child's class.
/// Tapping a teacher opens the messages screen (with teacher pre-selected).
/// "Schedule Meeting" navigates to PTM booking.
class TeacherMessageScreen extends ConsumerWidget {
  const TeacherMessageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(supabaseProvider).auth.currentUser?.id;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final childrenAsync = ref.watch(parentChildrenProvider(userId));
    final selectedChild = ref.watch(selectedChildProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Message Teachers'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          childrenAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (children) {
              if (children.length <= 1) return const SizedBox.shrink();
              return PopupMenuButton<Map<String, dynamic>>(
                icon:
                    const Icon(Icons.person_outline, color: Colors.white),
                initialValue: selectedChild,
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
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (children) {
          if (children.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No children linked to this account.'),
              ),
            );
          }

          final active = selectedChild ?? children.first;
          final studentId = active['student_id'] as String? ?? '';
          final studentName =
              active['student_name'] as String? ?? 'Your Child';

          return Column(
            children: [
              // Child banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                color: AppColors.primaryLight,
                child: Row(
                  children: [
                    const Icon(Icons.person,
                        size: 16, color: AppColors.primary),
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

              Expanded(
                child: _TeacherList(studentId: studentId),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Teacher List
// ---------------------------------------------------------------------------

class _TeacherList extends ConsumerWidget {
  final String studentId;

  const _TeacherList({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachersAsync = ref.watch(childTeachersProvider(studentId));

    return teachersAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () =>
            ref.invalidate(childTeachersProvider(studentId)),
      ),
      data: (teachers) {
        if (teachers.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school_outlined,
                      size: 56, color: AppColors.grey300),
                  SizedBox(height: 16),
                  Text(
                    'No teachers found for your child\'s class.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.grey500),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: teachers.length,
          itemBuilder: (context, i) =>
              _TeacherCard(teacher: teachers[i]),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Individual Teacher Card
// ---------------------------------------------------------------------------

class _TeacherCard extends StatelessWidget {
  final TeacherContact teacher;

  const _TeacherCard({required this.teacher});

  String get _initials {
    final parts = teacher.name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return teacher.name.isNotEmpty
        ? teacher.name[0].toUpperCase()
        : 'T';
  }

  Color get _avatarColor {
    const colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
    ];
    return colors[teacher.userId.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with initials
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _avatarColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: _avatarColor.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _avatarColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _avatarColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          teacher.subjectName,
                          style: TextStyle(
                            fontSize: 12,
                            color: _avatarColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openChat(context),
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _scheduleMeeting(context),
                  icon: const Icon(Icons.event_outlined, size: 16),
                  label: const Text('Meeting'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openChat(BuildContext context) {
    // Navigate to messages screen with teacher pre-selected via query param
    context.push(
      '${AppRoutes.messages}?recipientId=${teacher.userId}&recipientName=${Uri.encodeComponent(teacher.name)}',
    );
  }

  void _scheduleMeeting(BuildContext context) {
    // Navigate to PTM scheduler
    context.push(AppRoutes.ptm);
  }
}
