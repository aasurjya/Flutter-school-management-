import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/academic.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../academic/providers/academic_provider.dart';
import '../../../students/providers/students_provider.dart';

class StudentManagementScreen extends ConsumerStatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  ConsumerState<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends ConsumerState<StudentManagementScreen> {
  final _searchController = TextEditingController();
  String? _selectedClassId;
  String? _selectedSectionId;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  void _loadStudents() {
    ref.read(studentsNotifierProvider.notifier).loadStudents(
      sectionId: _selectedSectionId,
      classId: _selectedClassId,
      searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary.withOpacity(0.05),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or admission number...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadStudents();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: (_) => _loadStudents(),
            ),
          ),
          Expanded(
            child: studentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('Error: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadStudents,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (students) {
                if (students.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No students found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _showAddStudentDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Student'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadStudents(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return _StudentCard(
                        student: student,
                        onTap: () => _showStudentDetail(student),
                        onEdit: () => _showEditStudentDialog(student),
                        onChangeSection: () => _showChangeSectionDialog(student),
                        onDeactivate: () => _confirmDeactivate(student),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStudentDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Student'),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Students'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Class dropdown would go here
            // Section dropdown would go here
            const Text('Filter options coming soon'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedClassId = null;
                _selectedSectionId = null;
              });
              _loadStudents();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              _loadStudents();
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showAddStudentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddStudentSheet(),
    );
  }

  void _showEditStudentDialog(dynamic student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditStudentSheet(student: student),
    );
  }

  void _showStudentDetail(dynamic student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StudentDetailSheet(student: student),
    );
  }

  void _showChangeSectionDialog(dynamic student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Section'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Section change coming soon'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _confirmDeactivate(dynamic student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Student'),
        content: Text(
          'Are you sure you want to deactivate ${student.firstName} ${student.lastName ?? ''}? This action can be reversed later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(studentsNotifierProvider.notifier).deactivateStudent(student.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Student deactivated'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final dynamic student;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onChangeSection;
  final VoidCallback onDeactivate;

  const _StudentCard({
    required this.student,
    required this.onTap,
    required this.onEdit,
    required this.onChangeSection,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: student.photoUrl != null
                    ? NetworkImage(student.photoUrl)
                    : null,
                child: student.photoUrl == null
                    ? Text(
                        student.firstName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${student.firstName} ${student.lastName ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.badge, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          student.admissionNumber,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 12),
                        if (student.currentEnrollment != null) ...[
                          Icon(Icons.class_, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            '${student.currentEnrollment.className} - ${student.currentEnrollment.sectionName}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'section':
                      onChangeSection();
                      break;
                    case 'deactivate':
                      onDeactivate();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'section',
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz, size: 18),
                        SizedBox(width: 8),
                        Text('Change Section'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'deactivate',
                    child: Row(
                      children: [
                        Icon(Icons.block, size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Deactivate', style: TextStyle(color: AppColors.error)),
                      ],
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
}

class _StudentDetailSheet extends StatelessWidget {
  final dynamic student;

  const _StudentDetailSheet({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
                  radius: 35,
                  backgroundColor: Colors.white,
                  backgroundImage: student.photoUrl != null
                      ? NetworkImage(student.photoUrl)
                      : null,
                  child: student.photoUrl == null
                      ? Text(
                          student.firstName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${student.firstName} ${student.lastName ?? ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Admission No: ${student.admissionNumber}',
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
                  _DetailRow(label: 'Date of Birth', value: student.dateOfBirth != null
                      ? DateFormat('MMM d, yyyy').format(student.dateOfBirth)
                      : 'N/A'),
                  _DetailRow(label: 'Gender', value: student.gender ?? 'N/A'),
                  _DetailRow(label: 'Blood Group', value: student.bloodGroup ?? 'N/A'),
                  _DetailRow(label: 'Nationality', value: student.nationality ?? 'Indian'),
                  _DetailRow(label: 'Religion', value: student.religion ?? 'N/A'),
                  _DetailRow(label: 'Mother Tongue', value: student.motherTongue ?? 'N/A'),
                  const Divider(height: 32),
                  _DetailRow(label: 'Address', value: student.address ?? 'N/A'),
                  _DetailRow(label: 'City', value: student.city ?? 'N/A'),
                  _DetailRow(label: 'State', value: student.state ?? 'N/A'),
                  _DetailRow(label: 'Pincode', value: student.pincode ?? 'N/A'),
                  const Divider(height: 32),
                  _DetailRow(label: 'Admission Date', value: student.admissionDate != null
                      ? DateFormat('MMM d, yyyy').format(student.admissionDate)
                      : 'N/A'),
                  _DetailRow(label: 'Previous School', value: student.previousSchool ?? 'N/A'),
                  if (student.medicalConditions != null) ...[
                    const Divider(height: 32),
                    _DetailRow(label: 'Medical Conditions', value: student.medicalConditions),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddStudentSheet extends ConsumerStatefulWidget {
  const _AddStudentSheet();

  @override
  ConsumerState<_AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends ConsumerState<_AddStudentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _admissionNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _paymentAmountController = TextEditingController();
  DateTime? _dateOfBirth;
  DateTime _admissionDate = DateTime.now();
  String? _gender;
  String? _selectedClassId;
  String? _selectedSectionId;
  String _paymentStatus = 'pending';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _admissionNumberController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _paymentAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesProvider);
    final currentYearAsync = ref.watch(currentAcademicYearProvider);
    final AsyncValue<List<Section>>? sectionsAsync = _selectedClassId != null
        ? ref.watch(sectionsByClassProvider(_selectedClassId!))
        : null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                const Text(
                  'Add New Student',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'First Name *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Last Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _admissionNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Admission Number *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Phone is required';
                        }
                        if (value.trim().length < 6) {
                          return 'Enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                                firstDate: DateTime(1990),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() => _dateOfBirth = date);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date of Birth *',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _dateOfBirth != null
                                    ? DateFormat('MMM d, yyyy').format(_dateOfBirth!)
                                    : 'Select date',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _gender,
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              border: OutlineInputBorder(),
                            ),
                            items: ['Male', 'Female', 'Other'].map((g) {
                              return DropdownMenuItem(value: g, child: Text(g));
                            }).toList(),
                            onChanged: (v) => setState(() => _gender = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address *',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Address is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _admissionDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (date != null) {
                          setState(() => _admissionDate = date);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Admission Date *',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(DateFormat('MMM d, yyyy').format(_admissionDate)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    classesAsync.when(
                      data: (classes) {
                        if (classes.isEmpty) {
                          return const Text('Please create classes first');
                        }
                        return DropdownButtonFormField<String>(
                          value: _selectedClassId,
                          decoration: const InputDecoration(
                            labelText: 'Class *',
                            border: OutlineInputBorder(),
                          ),
                          items: classes
                              .map((schoolClass) => DropdownMenuItem(
                                    value: schoolClass.id,
                                    child: Text(schoolClass.name),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedClassId = value;
                              _selectedSectionId = null;
                            });
                          },
                          validator: (value) => value == null ? 'Select class' : null,
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Error loading classes: $e'),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedClassId != null)
                      sectionsAsync!.when(
                        data: (sections) {
                          if (sections.isEmpty) {
                            return const Text('No sections found for this class');
                          }
                          return DropdownButtonFormField<String>(
                            value: _selectedSectionId,
                            decoration: const InputDecoration(
                              labelText: 'Section *',
                              border: OutlineInputBorder(),
                            ),
                            items: sections
                                .map((section) => DropdownMenuItem(
                                      value: section.id,
                                      child: Text(section.displayName),
                                    ))
                                .toList(),
                            onChanged: (value) => setState(() => _selectedSectionId = value),
                            validator: (value) => value == null ? 'Select section' : null,
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Error loading sections: $e'),
                      ),
                    if (_selectedClassId == null)
                      Text(
                        'Select a class to choose section & enroll the student',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _paymentStatus,
                      decoration: const InputDecoration(
                        labelText: 'Payment Status *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'paid', child: Text('Paid')),
                        DropdownMenuItem(value: 'partial', child: Text('Partial')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _paymentStatus = value;
                            if (_paymentStatus != 'partial') {
                              _paymentAmountController.clear();
                            }
                          });
                        }
                      },
                    ),
                    if (_paymentStatus == 'partial') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _paymentAmountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount Paid *',
                          border: OutlineInputBorder(),
                          prefixText: '\u20B9 ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (_paymentStatus != 'partial') return null;
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter the amount received';
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    currentYearAsync.when(
                      data: (year) => Text(
                        year != null
                            ? 'Enrollment Academic Year: ${year.name}'
                            : 'No academic year configured – please add one.',
                        style: TextStyle(
                          color: year != null ? Colors.grey[700] : AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Error loading academic year: $e'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Add Student',
                                style: TextStyle(color: Colors.white),
                              ),
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date of birth')),
      );
      return;
    }
    if (_selectedClassId == null || _selectedSectionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select class and section')),
      );
      return;
    }

    double? paymentAmount;
    if (_paymentStatus == 'partial') {
      paymentAmount = double.tryParse(_paymentAmountController.text.trim());
      if (paymentAmount == null || paymentAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid partial payment amount')),
        );
        return;
      }
    }

    final academicYearAsync = ref.read(currentAcademicYearProvider);
    final AcademicYear? academicYear = academicYearAsync.maybeWhen(
      data: (year) => year,
      orElse: () => null,
    );

    if (academicYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please configure an academic year before enrolling students')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final studentsNotifier = ref.read(studentsNotifierProvider.notifier);
      final studentRepo = ref.read(studentRepositoryProvider);
      final student = await studentsNotifier.createStudent({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim().isNotEmpty
            ? _lastNameController.text.trim()
            : null,
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'admission_number': _admissionNumberController.text.trim(),
        'date_of_birth': _dateOfBirth!.toIso8601String().split('T')[0],
        'gender': _gender,
        'address': _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        'admission_date': _admissionDate.toIso8601String().split('T')[0],
        'payment_status': _paymentStatus,
        'payment_amount': paymentAmount,
      });

      final rollNumber = await studentRepo.getNextRollNumber(
        sectionId: _selectedSectionId!,
        academicYearId: academicYear.id,
      );

      await studentsNotifier.enrollStudent(
        studentId: student.id,
        sectionId: _selectedSectionId!,
        academicYearId: academicYear.id,
        rollNumber: rollNumber.toString(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student added and enrolled successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _EditStudentSheet extends ConsumerStatefulWidget {
  final dynamic student;

  const _EditStudentSheet({required this.student});

  @override
  ConsumerState<_EditStudentSheet> createState() => _EditStudentSheetState();
}

class _EditStudentSheetState extends ConsumerState<_EditStudentSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  String? _gender;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.student.firstName);
    _lastNameController = TextEditingController(text: widget.student.lastName ?? '');
    _phoneController = TextEditingController(text: widget.student.phone ?? '');
    _addressController = TextEditingController(text: widget.student.address ?? '');
    _gender = widget.student.gender;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                const Text(
                  'Edit Student',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
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
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'First Name *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Last Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Male', 'Female', 'Other'].map((g) {
                        return DropdownMenuItem(value: g, child: Text(g));
                      }).toList(),
                      onChanged: (v) => setState(() => _gender = v),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(color: Colors.white),
                              ),
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(studentsNotifierProvider.notifier).updateStudent(
        widget.student.id,
        {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim().isNotEmpty
              ? _lastNameController.text.trim()
              : null,
          'gender': _gender,
          'address': _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : null,
        },
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
