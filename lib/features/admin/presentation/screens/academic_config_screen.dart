import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';

class AcademicConfigScreen extends ConsumerStatefulWidget {
  const AcademicConfigScreen({super.key});

  @override
  ConsumerState<AcademicConfigScreen> createState() => _AcademicConfigScreenState();
}

class _AcademicConfigScreenState extends ConsumerState<AcademicConfigScreen> {
  int _selectedIndex = 0;

  final List<_ConfigItem> _configItems = [
    _ConfigItem(
      title: 'Academic Years',
      icon: Icons.calendar_today,
      description: 'Manage academic years and sessions',
    ),
    _ConfigItem(
      title: 'Terms',
      icon: Icons.date_range,
      description: 'Configure terms and semesters',
    ),
    _ConfigItem(
      title: 'Classes',
      icon: Icons.class_,
      description: 'Manage class levels',
    ),
    _ConfigItem(
      title: 'Sections',
      icon: Icons.grid_view,
      description: 'Configure sections per class',
    ),
    _ConfigItem(
      title: 'Subjects',
      icon: Icons.book,
      description: 'Manage subjects curriculum',
    ),
    _ConfigItem(
      title: 'Grading Scales',
      icon: Icons.grade,
      description: 'Configure grading systems',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Configuration'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // Side Navigation
          Container(
            width: 220,
            color: Colors.grey[100],
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _configItems.length,
              itemBuilder: (context, index) {
                final item = _configItems[index];
                final isSelected = _selectedIndex == index;
                return ListTile(
                  leading: Icon(
                    item.icon,
                    color: isSelected ? AppColors.primary : Colors.grey[600],
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primary : Colors.grey[800],
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: () => setState(() => _selectedIndex = index),
                );
              },
            ),
          ),
          // Content Area
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const _AcademicYearsConfig();
      case 1:
        return const _TermsConfig();
      case 2:
        return const _ClassesConfig();
      case 3:
        return const _SectionsConfig();
      case 4:
        return const _SubjectsConfig();
      case 5:
        return const _GradingScalesConfig();
      default:
        return const Center(child: Text('Select a configuration'));
    }
  }
}

class _ConfigItem {
  final String title;
  final IconData icon;
  final String description;

  _ConfigItem({
    required this.title,
    required this.icon,
    required this.description,
  });
}

// Academic Years Configuration
class _AcademicYearsConfig extends StatelessWidget {
  const _AcademicYearsConfig();

  @override
  Widget build(BuildContext context) {
    final years = [
      {'id': '1', 'name': '2024-2025', 'startDate': '2024-04-01', 'endDate': '2025-03-31', 'isCurrent': true},
      {'id': '2', 'name': '2023-2024', 'startDate': '2023-04-01', 'endDate': '2024-03-31', 'isCurrent': false},
      {'id': '3', 'name': '2022-2023', 'startDate': '2022-04-01', 'endDate': '2023-03-31', 'isCurrent': false},
    ];

    return _ConfigListView(
      title: 'Academic Years',
      description: 'Manage academic years and set the current active year.',
      items: years,
      itemBuilder: (item) => ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: item['isCurrent'] == true 
                ? AppColors.success.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.calendar_today,
            color: item['isCurrent'] == true ? AppColors.success : Colors.grey,
          ),
        ),
        title: Text(
          item['name'] as String,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('${item['startDate']} to ${item['endDate']}'),
        trailing: item['isCurrent'] == true
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'CURRENT',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            : TextButton(
                onPressed: () {},
                child: const Text('Set as Current'),
              ),
      ),
      onAdd: () => _showAddDialog(context, 'Academic Year'),
    );
  }

  void _showAddDialog(BuildContext context, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      border: OutlineInputBorder(),
                    ),
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      border: OutlineInputBorder(),
                    ),
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Add')),
        ],
      ),
    );
  }
}

// Terms Configuration
class _TermsConfig extends StatelessWidget {
  const _TermsConfig();

  @override
  Widget build(BuildContext context) {
    final terms = [
      {'id': '1', 'name': 'Term 1', 'startDate': '2024-04-01', 'endDate': '2024-07-31'},
      {'id': '2', 'name': 'Term 2', 'startDate': '2024-08-01', 'endDate': '2024-11-30'},
      {'id': '3', 'name': 'Term 3', 'startDate': '2024-12-01', 'endDate': '2025-03-31'},
    ];

    return _ConfigListView(
      title: 'Terms',
      description: 'Configure terms/semesters for the academic year.',
      items: terms,
      itemBuilder: (item) => ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.info.withValues(alpha: 0.1),
          child: const Icon(Icons.date_range, color: AppColors.info),
        ),
        title: Text(item['name'] as String),
        subtitle: Text('${item['startDate']} to ${item['endDate']}'),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {},
        ),
      ),
      onAdd: () {},
    );
  }
}

// Classes Configuration
class _ClassesConfig extends StatelessWidget {
  const _ClassesConfig();

  @override
  Widget build(BuildContext context) {
    final classes = [
      {'id': '1', 'name': 'Class 1', 'displayOrder': 1, 'sectionsCount': 3},
      {'id': '2', 'name': 'Class 2', 'displayOrder': 2, 'sectionsCount': 3},
      {'id': '3', 'name': 'Class 3', 'displayOrder': 3, 'sectionsCount': 2},
      {'id': '4', 'name': 'Class 4', 'displayOrder': 4, 'sectionsCount': 2},
      {'id': '5', 'name': 'Class 5', 'displayOrder': 5, 'sectionsCount': 2},
      {'id': '6', 'name': 'Class 6', 'displayOrder': 6, 'sectionsCount': 3},
      {'id': '7', 'name': 'Class 7', 'displayOrder': 7, 'sectionsCount': 3},
      {'id': '8', 'name': 'Class 8', 'displayOrder': 8, 'sectionsCount': 3},
      {'id': '9', 'name': 'Class 9', 'displayOrder': 9, 'sectionsCount': 4},
      {'id': '10', 'name': 'Class 10', 'displayOrder': 10, 'sectionsCount': 4},
      {'id': '11', 'name': 'Class 11', 'displayOrder': 11, 'sectionsCount': 2},
      {'id': '12', 'name': 'Class 12', 'displayOrder': 12, 'sectionsCount': 2},
    ];

    return _ConfigListView(
      title: 'Classes',
      description: 'Manage class levels in your school.',
      items: classes,
      itemBuilder: (item) => ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            '${item['displayOrder']}',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(item['name'] as String),
        subtitle: Text('${item['sectionsCount']} sections'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
            IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error), onPressed: () {}),
          ],
        ),
      ),
      onAdd: () {},
    );
  }
}

// Sections Configuration
class _SectionsConfig extends StatelessWidget {
  const _SectionsConfig();

  @override
  Widget build(BuildContext context) {
    final sections = [
      {'id': '1', 'name': 'Section A', 'className': 'Class 10', 'capacity': 40, 'currentStrength': 38},
      {'id': '2', 'name': 'Section B', 'className': 'Class 10', 'capacity': 40, 'currentStrength': 35},
      {'id': '3', 'name': 'Section C', 'className': 'Class 10', 'capacity': 40, 'currentStrength': 40},
      {'id': '4', 'name': 'Section D', 'className': 'Class 10', 'capacity': 40, 'currentStrength': 32},
      {'id': '5', 'name': 'Section A', 'className': 'Class 9', 'capacity': 40, 'currentStrength': 36},
      {'id': '6', 'name': 'Section B', 'className': 'Class 9', 'capacity': 40, 'currentStrength': 38},
    ];

    return _ConfigListView(
      title: 'Sections',
      description: 'Configure sections for each class.',
      items: sections,
      itemBuilder: (item) {
        final strength = item['currentStrength'] as int;
        final capacity = item['capacity'] as int;
        final isFull = strength >= capacity;
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isFull 
                ? AppColors.warning.withValues(alpha: 0.1)
                : AppColors.success.withValues(alpha: 0.1),
            child: Text(
              (item['name'] as String).split(' ').last,
              style: TextStyle(
                color: isFull ? AppColors.warning : AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text('${item['className']} - ${item['name']}'),
          subtitle: Row(
            children: [
              Text('$strength / $capacity students'),
              const SizedBox(width: 8),
              if (isFull)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'FULL',
                    style: TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
        );
      },
      onAdd: () {},
    );
  }
}

// Subjects Configuration
class _SubjectsConfig extends StatelessWidget {
  const _SubjectsConfig();

  @override
  Widget build(BuildContext context) {
    final subjects = [
      {'id': '1', 'name': 'Mathematics', 'code': 'MATH', 'type': 'Core', 'classes': ['1-12']},
      {'id': '2', 'name': 'English', 'code': 'ENG', 'type': 'Core', 'classes': ['1-12']},
      {'id': '3', 'name': 'Hindi', 'code': 'HIN', 'type': 'Core', 'classes': ['1-12']},
      {'id': '4', 'name': 'Science', 'code': 'SCI', 'type': 'Core', 'classes': ['1-10']},
      {'id': '5', 'name': 'Social Studies', 'code': 'SST', 'type': 'Core', 'classes': ['1-10']},
      {'id': '6', 'name': 'Physics', 'code': 'PHY', 'type': 'Elective', 'classes': ['11-12']},
      {'id': '7', 'name': 'Chemistry', 'code': 'CHEM', 'type': 'Elective', 'classes': ['11-12']},
      {'id': '8', 'name': 'Biology', 'code': 'BIO', 'type': 'Elective', 'classes': ['11-12']},
      {'id': '9', 'name': 'Computer Science', 'code': 'CS', 'type': 'Elective', 'classes': ['9-12']},
      {'id': '10', 'name': 'Physical Education', 'code': 'PE', 'type': 'Extra', 'classes': ['1-12']},
    ];

    return _ConfigListView(
      title: 'Subjects',
      description: 'Manage subjects in the curriculum.',
      items: subjects,
      itemBuilder: (item) => ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getSubjectColor(item['type'] as String).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            item['code'] as String,
            style: TextStyle(
              color: _getSubjectColor(item['type'] as String),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(item['name'] as String),
        subtitle: Text('${item['type']} • Classes ${(item['classes'] as List).join(", ")}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getSubjectColor(item['type'] as String).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item['type'] as String,
                style: TextStyle(
                  fontSize: 11,
                  color: _getSubjectColor(item['type'] as String),
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
          ],
        ),
      ),
      onAdd: () {},
    );
  }

  Color _getSubjectColor(String type) {
    switch (type) {
      case 'Core':
        return AppColors.primary;
      case 'Elective':
        return AppColors.secondary;
      case 'Extra':
        return AppColors.accent;
      default:
        return Colors.grey;
    }
  }
}

// Grading Scales Configuration
class _GradingScalesConfig extends StatelessWidget {
  const _GradingScalesConfig();

  @override
  Widget build(BuildContext context) {
    final grades = [
      {'grade': 'A+', 'minPercentage': 90, 'maxPercentage': 100, 'gradePoints': 10.0},
      {'grade': 'A', 'minPercentage': 80, 'maxPercentage': 89, 'gradePoints': 9.0},
      {'grade': 'B+', 'minPercentage': 70, 'maxPercentage': 79, 'gradePoints': 8.0},
      {'grade': 'B', 'minPercentage': 60, 'maxPercentage': 69, 'gradePoints': 7.0},
      {'grade': 'C+', 'minPercentage': 50, 'maxPercentage': 59, 'gradePoints': 6.0},
      {'grade': 'C', 'minPercentage': 40, 'maxPercentage': 49, 'gradePoints': 5.0},
      {'grade': 'D', 'minPercentage': 33, 'maxPercentage': 39, 'gradePoints': 4.0},
      {'grade': 'F', 'minPercentage': 0, 'maxPercentage': 32, 'gradePoints': 0.0},
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grading Scale',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Configure the grading system for exam results.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add Grade'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GlassCard(
              padding: EdgeInsets.zero,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Min %', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Max %', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Grade Points', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: grades.map((g) => DataRow(
                    cells: [
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getGradeColor(g['grade'] as String).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            g['grade'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getGradeColor(g['grade'] as String),
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text('${g['minPercentage']}%')),
                      DataCell(Text('${g['maxPercentage']}%')),
                      DataCell(Text('${g['gradePoints']}')),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  )).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return AppColors.success;
      case 'B+':
      case 'B':
        return AppColors.info;
      case 'C+':
      case 'C':
        return AppColors.warning;
      case 'D':
        return Colors.orange;
      default:
        return AppColors.error;
    }
  }
}

// Reusable Config List View
class _ConfigListView extends StatelessWidget {
  final String title;
  final String description;
  final List<Map<String, dynamic>> items;
  final Widget Function(Map<String, dynamic>) itemBuilder;
  final VoidCallback onAdd;

  const _ConfigListView({
    required this.title,
    required this.description,
    required this.items,
    required this.itemBuilder,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: Text('Add $title'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GlassCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) => itemBuilder(items[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
