import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/online_exam.dart';
import '../../providers/online_exam_provider.dart';
import '../widgets/exam_card.dart';

class ExamDashboardScreen extends ConsumerStatefulWidget {
  const ExamDashboardScreen({super.key});

  @override
  ConsumerState<ExamDashboardScreen> createState() =>
      _ExamDashboardScreenState();
}

class _ExamDashboardScreenState extends ConsumerState<ExamDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedStatus;

  final _tabs = const [
    Tab(text: 'All'),
    Tab(text: 'Live'),
    Tab(text: 'Upcoming'),
    Tab(text: 'Completed'),
    Tab(text: 'Drafts'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _selectedStatus = null;
        case 1:
          _selectedStatus = 'live';
        case 2:
          _selectedStatus = 'scheduled';
        case 3:
          _selectedStatus = 'completed';
        case 4:
          _selectedStatus = 'draft';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = OnlineExamFilter(status: _selectedStatus);
    final examsAsync = ref.watch(onlineExamsProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Exams'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(onlineExamsProvider(filter)),
          ),
        ],
      ),
      body: examsAsync.when(
        data: (exams) {
          if (exams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    _selectedStatus == null
                        ? 'No exams yet'
                        : 'No ${OnlineExamStatus.fromString(_selectedStatus!).label.toLowerCase()} exams',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first online exam',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(onlineExamsProvider(filter));
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: exams.length,
              itemBuilder: (context, index) {
                final exam = exams[index];
                return ExamCard(
                  exam: exam,
                  onTap: () => context.push('/online-exams/${exam.id}'),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 8),
              Text('Error: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(onlineExamsProvider(filter)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/online-exams/create'),
        icon: const Icon(Icons.add),
        label: const Text('Create Exam'),
      ),
    );
  }
}
