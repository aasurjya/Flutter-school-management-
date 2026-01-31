import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/quiz.dart';
import '../../providers/assessment_provider.dart';

class QuizzesScreen extends ConsumerStatefulWidget {
  const QuizzesScreen({super.key});

  @override
  ConsumerState<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends ConsumerState<QuizzesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedStatus;

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
        title: const Text('Online Assessments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Quizzes'),
            Tab(text: 'My Quizzes'),
            Tab(text: 'Question Bank'),
          ],
        ),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _selectedStatus = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Status'),
              ),
              const PopupMenuItem(
                value: 'draft',
                child: Text('Draft'),
              ),
              const PopupMenuItem(
                value: 'published',
                child: Text('Published'),
              ),
              const PopupMenuItem(
                value: 'closed',
                child: Text('Closed'),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AllQuizzesTab(status: _selectedStatus),
          _MyQuizzesTab(status: _selectedStatus),
          const _QuestionBankTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/assessments/create'),
        icon: const Icon(Icons.add),
        label: const Text('Create Quiz'),
      ),
    );
  }
}

class _AllQuizzesTab extends ConsumerWidget {
  final String? status;

  const _AllQuizzesTab({this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzesAsync = ref.watch(
      quizzesProvider(QuizzesFilter(status: status)),
    );

    return quizzesAsync.when(
      data: (quizzes) {
        if (quizzes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No quizzes found'),
                SizedBox(height: 8),
                Text('Create your first quiz to get started'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: quizzes.length,
          itemBuilder: (context, index) => _QuizCard(quiz: quizzes[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _MyQuizzesTab extends ConsumerWidget {
  final String? status;

  const _MyQuizzesTab({this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real app, you'd get the current user ID
    final quizzesAsync = ref.watch(
      quizzesProvider(QuizzesFilter(status: status)),
    );

    return quizzesAsync.when(
      data: (quizzes) {
        if (quizzes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('You haven\'t created any quizzes yet'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: quizzes.length,
          itemBuilder: (context, index) => _QuizCard(quiz: quizzes[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _QuestionBankTab extends ConsumerStatefulWidget {
  const _QuestionBankTab();

  @override
  ConsumerState<_QuestionBankTab> createState() => _QuestionBankTabState();
}

class _QuestionBankTabState extends ConsumerState<_QuestionBankTab> {
  String? _selectedSubject;
  String? _selectedType;
  String? _selectedDifficulty;

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(
      questionBankProvider(QuestionBankFilter(
        subjectId: _selectedSubject,
        questionType: _selectedType,
        difficulty: _selectedDifficulty,
      )),
    );

    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: Text(_selectedType ?? 'All Types'),
                  selected: _selectedType != null,
                  onSelected: (_) => _showTypeFilter(),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(_selectedDifficulty ?? 'All Difficulty'),
                  selected: _selectedDifficulty != null,
                  onSelected: (_) => _showDifficultyFilter(),
                ),
                const SizedBox(width: 8),
                if (_selectedType != null || _selectedDifficulty != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedType = null;
                        _selectedDifficulty = null;
                      });
                    },
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: questionsAsync.when(
            data: (questions) {
              if (questions.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.help_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No questions in the bank'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: questions.length,
                itemBuilder: (context, index) =>
                    _QuestionCard(question: questions[index]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        ),
      ],
    );
  }

  void _showTypeFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('All Types'),
            onTap: () {
              setState(() => _selectedType = null);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_box),
            title: const Text('Multiple Choice'),
            onTap: () {
              setState(() => _selectedType = 'mcq');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.toggle_on),
            title: const Text('True/False'),
            onTap: () {
              setState(() => _selectedType = 'true_false');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.short_text),
            title: const Text('Short Answer'),
            onTap: () {
              setState(() => _selectedType = 'short_answer');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showDifficultyFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('All Difficulty'),
            onTap: () {
              setState(() => _selectedDifficulty = null);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.circle, color: Colors.green[300]),
            title: const Text('Easy'),
            onTap: () {
              setState(() => _selectedDifficulty = 'easy');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.circle, color: Colors.orange[300]),
            title: const Text('Medium'),
            onTap: () {
              setState(() => _selectedDifficulty = 'medium');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.circle, color: Colors.red[300]),
            title: const Text('Hard'),
            onTap: () {
              setState(() => _selectedDifficulty = 'hard');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final Quiz quiz;

  const _QuizCard({required this.quiz});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/assessments/${quiz.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quiz.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _StatusChip(status: quiz.status),
                ],
              ),
              if (quiz.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  quiz.description!,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.school,
                    label: quiz.subjectName ?? 'Unknown',
                  ),
                  _InfoChip(
                    icon: Icons.class_,
                    label:
                        '${quiz.className ?? ''} - ${quiz.sectionName ?? ''}'.trim(),
                  ),
                  _InfoChip(
                    icon: Icons.timer,
                    label: '${quiz.durationMinutes} min',
                  ),
                  _InfoChip(
                    icon: Icons.score,
                    label: '${quiz.totalMarks} marks',
                  ),
                ],
              ),
              if (quiz.startTime != null || quiz.endTime != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatSchedule(quiz),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatSchedule(Quiz quiz) {
    final parts = <String>[];
    if (quiz.startTime != null) {
      parts.add('Starts: ${_formatDateTime(quiz.startTime!)}');
    }
    if (quiz.endTime != null) {
      parts.add('Ends: ${_formatDateTime(quiz.endTime!)}');
    }
    return parts.join(' | ');
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'draft':
        color = Colors.grey;
        break;
      case 'published':
        color = Colors.green;
        break;
      case 'closed':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final QuestionBank question;

  const _QuestionCard({required this.question});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _QuestionTypeIcon(type: question.questionType),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question.questionText,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(question.subjectName ?? 'Unknown'),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  labelStyle: const TextStyle(fontSize: 10),
                ),
                Chip(
                  label: Text(question.difficultyDisplay),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  labelStyle: const TextStyle(fontSize: 10),
                  backgroundColor: _getDifficultyColor(question.difficulty),
                ),
                Chip(
                  label: Text('${question.marks} marks'),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  labelStyle: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green.shade100;
      case 'medium':
        return Colors.orange.shade100;
      case 'hard':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}

class _QuestionTypeIcon extends StatelessWidget {
  final String type;

  const _QuestionTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (type) {
      case 'mcq':
        icon = Icons.check_box;
        color = Colors.blue;
        break;
      case 'true_false':
        icon = Icons.toggle_on;
        color = Colors.purple;
        break;
      case 'short_answer':
        icon = Icons.short_text;
        color = Colors.orange;
        break;
      case 'long_answer':
        icon = Icons.notes;
        color = Colors.teal;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
