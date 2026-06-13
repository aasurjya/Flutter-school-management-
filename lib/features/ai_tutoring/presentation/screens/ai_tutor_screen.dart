import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../students/providers/students_provider.dart';
import '../../providers/ai_tutor_provider.dart';

/// Entry screen for the AI Tutor: lists a student's past/active sessions and
/// lets them start a new one. Student-facing.
class AiTutorScreen extends ConsumerWidget {
  const AiTutorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(currentStudentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, size: 20),
            SizedBox(width: 8),
            Text('AI Tutor'),
          ],
        ),
      ),
      body: studentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _Centered(
          icon: Icons.error_outline,
          text: 'Could not load your profile.',
        ),
        data: (student) {
          if (student == null) {
            return const _Centered(
              icon: Icons.person_off_outlined,
              text: 'The AI Tutor is available to students only.',
            );
          }
          final sessionsAsync = ref.watch(tutorSessionsProvider(student.id));
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(tutorSessionsProvider(student.id)),
            child: sessionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => ListView(
                children: const [
                  SizedBox(height: 120),
                  _Centered(
                    icon: Icons.error_outline,
                    text: 'Could not load your sessions.',
                  ),
                ],
              ),
              data: (sessions) {
                if (sessions.isEmpty) {
                  return ListView(
                    children: const [
                      SizedBox(height: 100),
                      _Centered(
                        icon: Icons.auto_stories_outlined,
                        text: 'No sessions yet.\nTap + to ask the tutor anything.',
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final s = sessions[i];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppColors.grey200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.chat_bubble_outline,
                              color: AppColors.primary, size: 20),
                        ),
                        title: Text(
                          s.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${s.messagesCount} messages · ${s.difficultyLevel}'
                          '${s.isActive ? '' : ' · ${s.status}'}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openChat(context, s.id, s.displayTitle),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: studentAsync.maybeWhen(
        data: (student) => student == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _startSession(context, ref, student.id),
                icon: const Icon(Icons.add),
                label: const Text('New session'),
              ),
        orElse: () => null,
      ),
    );
  }

  void _openChat(BuildContext context, String sessionId, String topic) {
    context.push('${AppRoutes.aiTutor}/$sessionId?topic=${Uri.encodeQueryComponent(topic)}');
  }

  Future<void> _startSession(
    BuildContext context,
    WidgetRef ref,
    String studentId,
  ) async {
    final created = await showModalBottomSheet<_NewSessionResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _NewSessionSheet(),
    );
    if (created == null) return;

    try {
      final session = await ref.read(aiTutorRepositoryProvider).createSession(
            studentId: studentId,
            topic: created.topic,
            difficulty: created.difficulty,
          );
      ref.invalidate(tutorSessionsProvider(studentId));
      if (!context.mounted) return;
      _openChat(context, session.id, session.displayTitle);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start a session. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _NewSessionResult {
  final String topic;
  final String difficulty;
  const _NewSessionResult(this.topic, this.difficulty);
}

class _NewSessionSheet extends StatefulWidget {
  const _NewSessionSheet();

  @override
  State<_NewSessionSheet> createState() => _NewSessionSheetState();
}

class _NewSessionSheetState extends State<_NewSessionSheet> {
  final _controller = TextEditingController();
  String _difficulty = 'intermediate';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What do you want help with?',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'e.g. Quadratic equations, Photosynthesis…',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _difficulty,
            decoration: InputDecoration(
              labelText: 'Difficulty',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: const [
              DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
              DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
              DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
            ],
            onChanged: (v) => setState(() => _difficulty = v ?? 'intermediate'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Start'),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    Navigator.of(context).pop(_NewSessionResult(_controller.text.trim(), _difficulty));
  }
}

class _Centered extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Centered({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.grey400),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.grey700)),
          ],
        ),
      ),
    );
  }
}
