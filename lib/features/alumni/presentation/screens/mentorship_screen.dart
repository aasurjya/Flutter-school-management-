import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/alumni.dart';
import '../../providers/alumni_provider.dart';
import '../widgets/mentorship_card.dart';

class MentorshipScreen extends ConsumerStatefulWidget {
  const MentorshipScreen({super.key});

  @override
  ConsumerState<MentorshipScreen> createState() => _MentorshipScreenState();
}

class _MentorshipScreenState extends ConsumerState<MentorshipScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentorship'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Open'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ProgramList(status: 'open'),
          _ProgramList(status: 'in_progress'),
          _ProgramList(status: 'completed'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateProgramDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Offer Mentorship'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showCreateProgramDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final myProfileAsync = ref.read(myAlumniProfileProvider);
    final myProfile = myProfileAsync.valueOrNull;

    if (myProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Register as alumni first')),
      );
      return;
    }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final skillController = TextEditingController();
    int menteeLimit = 5;
    final List<String> skills = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Offer Mentorship'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Program Title *',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Software Engineering Career Guide',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: skillController,
                        decoration: const InputDecoration(
                          labelText: 'Add Skill',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        if (skillController.text.isNotEmpty) {
                          setDialogState(() {
                            skills.add(skillController.text.trim());
                            skillController.clear();
                          });
                        }
                      },
                      icon: const Icon(Icons.add_circle),
                      color: AppColors.primary,
                    ),
                  ],
                ),
                if (skills.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: skills.map((s) {
                      return Chip(
                        label: Text(s),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => setDialogState(
                            () => skills.remove(s)),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Max Mentees: '),
                    IconButton(
                      onPressed: menteeLimit > 1
                          ? () => setDialogState(() => menteeLimit--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$menteeLimit',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: menteeLimit < 20
                          ? () => setDialogState(() => menteeLimit++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleController.text.isEmpty) return;
                try {
                  final repo = ref.read(alumniRepositoryProvider);
                  await repo.createMentorshipProgram({
                    'title': titleController.text,
                    'description': descriptionController.text.isEmpty
                        ? null
                        : descriptionController.text,
                    'mentor_id': myProfile.id,
                    'mentee_count_limit': menteeLimit,
                    'skills_offered': skills,
                    'status': 'open',
                  });
                  ref.invalidate(allMentorshipProgramsProvider);
                  ref.invalidate(openMentorshipProgramsProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Mentorship program created!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramList extends ConsumerWidget {
  final String status;

  const _ProgramList({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsAsync = ref.watch(
      mentorshipProgramsProvider(MentorshipFilter(status: status)),
    );

    return programsAsync.when(
      data: (programs) {
        if (programs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.psychology_outlined,
                    size: 64, color: AppColors.textTertiaryLight),
                const SizedBox(height: 16),
                Text(
                  'No ${MentorshipProgramStatus.fromString(status).label.toLowerCase()} programs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(
              mentorshipProgramsProvider(MentorshipFilter(status: status)),
            );
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: programs.length,
            itemBuilder: (context, index) {
              final program = programs[index];
              return MentorshipCard(
                program: program,
                onApply: program.status == MentorshipProgramStatus.open
                    ? () => _showApplyDialog(
                        context, ref, program)
                    : null,
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showApplyDialog(
    BuildContext context,
    WidgetRef ref,
    MentorshipProgram program,
  ) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Apply for "${program.title}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (program.mentor != null)
              Text('Mentor: ${program.mentor!.fullName}'),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Why do you want this mentorship?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final repo = ref.read(alumniRepositoryProvider);
                // Use a placeholder student_id; in practice this would come from the logged-in user
                await repo.createMentorshipRequest({
                  'program_id': program.id,
                  'student_id': repo.currentUserId ?? '',
                  'message': messageController.text.isEmpty
                      ? null
                      : messageController.text,
                  'status': 'pending',
                });
                ref.invalidate(allMentorshipProgramsProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Application submitted!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
