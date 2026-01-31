import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';

class ExamManagementScreen extends ConsumerStatefulWidget {
  const ExamManagementScreen({super.key});

  @override
  ConsumerState<ExamManagementScreen> createState() => _ExamManagementScreenState();
}

class _ExamManagementScreenState extends ConsumerState<ExamManagementScreen>
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

  // Mock exam data
  final List<Map<String, dynamic>> _exams = [
    {'id': '1', 'name': 'Mid Term Examination', 'type': 'mid_term', 'startDate': DateTime(2024, 10, 15), 'endDate': DateTime(2024, 10, 25), 'status': 'completed', 'classesCount': 12, 'resultsPublished': true},
    {'id': '2', 'name': 'Unit Test 3', 'type': 'unit_test', 'startDate': DateTime(2024, 11, 20), 'endDate': DateTime(2024, 11, 22), 'status': 'completed', 'classesCount': 12, 'resultsPublished': false},
    {'id': '3', 'name': 'Pre-Board Examination', 'type': 'pre_board', 'startDate': DateTime(2025, 1, 10), 'endDate': DateTime(2025, 1, 25), 'status': 'upcoming', 'classesCount': 2, 'resultsPublished': false},
    {'id': '4', 'name': 'Annual Examination', 'type': 'annual', 'startDate': DateTime(2025, 3, 1), 'endDate': DateTime(2025, 3, 15), 'status': 'draft', 'classesCount': 12, 'resultsPublished': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Exams'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Results'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExamsList(_exams),
          _buildExamsList(_exams.where((e) => e['status'] == 'upcoming' || e['status'] == 'draft').toList()),
          _buildResultsList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateExamDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Create Exam'),
      ),
    );
  }

  Widget _buildExamsList(List<Map<String, dynamic>> exams) {
    if (exams.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No exams found'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exams.length,
      itemBuilder: (context, index) {
        final exam = exams[index];
        return _ExamCard(
          exam: exam,
          onTap: () => _showExamDetail(exam),
        );
      },
    );
  }

  Widget _buildResultsList() {
    final completedExams = _exams.where((e) => e['status'] == 'completed').toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completedExams.length,
      itemBuilder: (context, index) {
        final exam = completedExams[index];
        return GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exam['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '${exam['classesCount']} classes',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (exam['resultsPublished'])
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: AppColors.success),
                      SizedBox(width: 4),
                      Text('Published', style: TextStyle(color: AppColors.success, fontSize: 12)),
                    ],
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () => _publishResults(exam),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Publish'),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showExamDetail(Map<String, dynamic> exam) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExamDetailSheet(exam: exam),
    );
  }

  void _showCreateExamDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateExamSheet(),
    );
  }

  void _publishResults(Map<String, dynamic> exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Results'),
        content: Text('Are you sure you want to publish results for "${exam['name']}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Results published successfully'), backgroundColor: AppColors.success),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final Map<String, dynamic> exam;
  final VoidCallback onTap;

  const _ExamCard({required this.exam, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = exam['status'] as String;
    final startDate = exam['startDate'] as DateTime;
    final endDate = exam['endDate'] as DateTime;

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
                  Expanded(
                    child: Text(
                      exam['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusLabel(status),
                      style: TextStyle(
                        fontSize: 11,
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d, yyyy').format(endDate)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.class_, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    '${exam['classesCount']} classes',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getExamTypeLabel(exam['type']),
                      style: const TextStyle(fontSize: 11, color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return AppColors.success;
      case 'upcoming': return AppColors.info;
      case 'ongoing': return AppColors.warning;
      case 'draft': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'completed': return 'Completed';
      case 'upcoming': return 'Upcoming';
      case 'ongoing': return 'Ongoing';
      case 'draft': return 'Draft';
      default: return status;
    }
  }

  String _getExamTypeLabel(String type) {
    switch (type) {
      case 'unit_test': return 'Unit Test';
      case 'mid_term': return 'Mid Term';
      case 'annual': return 'Annual';
      case 'pre_board': return 'Pre-Board';
      default: return type;
    }
  }
}

class _ExamDetailSheet extends StatelessWidget {
  final Map<String, dynamic> exam;

  const _ExamDetailSheet({required this.exam});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam['name'],
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${DateFormat('MMM d').format(exam['startDate'])} - ${DateFormat('MMM d, yyyy').format(exam['endDate'])}',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit, color: AppColors.primary),
                    title: const Text('Edit Exam'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_month, color: AppColors.secondary),
                    title: const Text('Exam Schedule'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.subject, color: AppColors.accent),
                    title: const Text('Configure Subjects'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.grade, color: AppColors.info),
                    title: const Text('Enter Marks'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.analytics, color: AppColors.warning),
                    title: const Text('View Analytics'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: const Text('Generate Report Cards'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: AppColors.error),
                    title: const Text('Delete Exam', style: TextStyle(color: AppColors.error)),
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

class _CreateExamSheet extends ConsumerStatefulWidget {
  const _CreateExamSheet();

  @override
  ConsumerState<_CreateExamSheet> createState() => _CreateExamSheetState();
}

class _CreateExamSheetState extends ConsumerState<_CreateExamSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _examType = 'unit_test';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
                const Text('Create Exam', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Exam Name *', border: OutlineInputBorder()),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _examType,
                      decoration: const InputDecoration(labelText: 'Exam Type', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'unit_test', child: Text('Unit Test')),
                        DropdownMenuItem(value: 'mid_term', child: Text('Mid Term')),
                        DropdownMenuItem(value: 'annual', child: Text('Annual')),
                        DropdownMenuItem(value: 'pre_board', child: Text('Pre-Board')),
                      ],
                      onChanged: (v) => setState(() => _examType = v!),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().add(const Duration(days: 7)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) setState(() => _startDate = date);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Start Date *', border: OutlineInputBorder()),
                              child: Text(_startDate != null ? DateFormat('MMM d, yyyy').format(_startDate!) : 'Select'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _startDate?.add(const Duration(days: 7)) ?? DateTime.now().add(const Duration(days: 14)),
                                firstDate: _startDate ?? DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) setState(() => _endDate = date);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'End Date *', border: OutlineInputBorder()),
                              child: Text(_endDate != null ? DateFormat('MMM d, yyyy').format(_endDate!) : 'Select'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: _isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Create Exam'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select dates')));
      return;
    }
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exam created successfully'), backgroundColor: AppColors.success),
      );
    }
  }
}
