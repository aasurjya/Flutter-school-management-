import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/glass_card.dart';

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Teachers'),
            Tab(text: 'Admins'),
            Tab(text: 'Other Staff'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary.withValues(alpha: 0.05),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search staff by name or ID...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _StaffList(role: 'teacher', searchQuery: _searchController.text),
                _StaffList(role: 'admin', searchQuery: _searchController.text),
                _StaffList(role: 'other', searchQuery: _searchController.text),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStaffSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Staff'),
      ),
    );
  }

  void _showAddStaffSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddStaffSheet(),
    );
  }
}

class _StaffList extends StatelessWidget {
  final String role;
  final String searchQuery;

  const _StaffList({
    required this.role,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    // Mock staff data
    final staffList = _getMockStaff(role).where((s) {
      if (searchQuery.isEmpty) return true;
      final query = searchQuery.toLowerCase();
      return s['name'].toLowerCase().contains(query) ||
          s['id'].toLowerCase().contains(query);
    }).toList();

    if (staffList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty ? 'No results found' : 'No staff members',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: staffList.length,
      itemBuilder: (context, index) {
        final staff = staffList[index];
        return _StaffCard(
          staff: staff,
          onTap: () => _showStaffDetail(context, staff),
          onEdit: () => _showEditSheet(context, staff),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getMockStaff(String role) {
    switch (role) {
      case 'teacher':
        return [
          {'id': 'T001', 'name': 'Dr. Rajesh Kumar', 'email': 'rajesh@school.edu', 'phone': '9876543210', 'department': 'Mathematics', 'subjects': ['Math', 'Physics'], 'classes': ['10-A', '10-B', '11-A'], 'joinDate': '2020-06-15', 'isActive': true},
          {'id': 'T002', 'name': 'Mrs. Priya Sharma', 'email': 'priya@school.edu', 'phone': '9876543211', 'department': 'Science', 'subjects': ['Biology', 'Chemistry'], 'classes': ['9-A', '9-B', '10-A'], 'joinDate': '2019-08-01', 'isActive': true},
          {'id': 'T003', 'name': 'Mr. Amit Patel', 'email': 'amit@school.edu', 'phone': '9876543212', 'department': 'English', 'subjects': ['English'], 'classes': ['8-A', '8-B', '9-A'], 'joinDate': '2021-01-10', 'isActive': true},
          {'id': 'T004', 'name': 'Ms. Sunita Verma', 'email': 'sunita@school.edu', 'phone': '9876543213', 'department': 'Hindi', 'subjects': ['Hindi', 'Sanskrit'], 'classes': ['7-A', '7-B', '8-A'], 'joinDate': '2018-04-20', 'isActive': true},
          {'id': 'T005', 'name': 'Mr. Vikram Singh', 'email': 'vikram@school.edu', 'phone': '9876543214', 'department': 'Computer Science', 'subjects': ['Computer'], 'classes': ['10-A', '11-A', '12-A'], 'joinDate': '2022-07-01', 'isActive': false},
        ];
      case 'admin':
        return [
          {'id': 'A001', 'name': 'Mr. Suresh Gupta', 'email': 'suresh@school.edu', 'phone': '9876543220', 'role': 'Principal', 'department': 'Administration', 'joinDate': '2015-06-01', 'isActive': true},
          {'id': 'A002', 'name': 'Mrs. Meera Joshi', 'email': 'meera@school.edu', 'phone': '9876543221', 'role': 'Vice Principal', 'department': 'Administration', 'joinDate': '2017-03-15', 'isActive': true},
          {'id': 'A003', 'name': 'Mr. Rakesh Agarwal', 'email': 'rakesh@school.edu', 'phone': '9876543222', 'role': 'Admin Manager', 'department': 'Administration', 'joinDate': '2019-09-01', 'isActive': true},
        ];
      default:
        return [
          {'id': 'S001', 'name': 'Mr. Ramesh', 'email': 'ramesh@school.edu', 'phone': '9876543230', 'role': 'Accountant', 'department': 'Finance', 'joinDate': '2018-02-01', 'isActive': true},
          {'id': 'S002', 'name': 'Mrs. Kavita', 'email': 'kavita@school.edu', 'phone': '9876543231', 'role': 'Librarian', 'department': 'Library', 'joinDate': '2016-07-15', 'isActive': true},
          {'id': 'S003', 'name': 'Mr. Mohan', 'email': 'mohan@school.edu', 'phone': '9876543232', 'role': 'Lab Assistant', 'department': 'Science Lab', 'joinDate': '2020-01-10', 'isActive': true},
        ];
    }
  }

  void _showStaffDetail(BuildContext context, Map<String, dynamic> staff) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StaffDetailSheet(staff: staff),
    );
  }

  void _showEditSheet(BuildContext context, Map<String, dynamic> staff) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditStaffSheet(staff: staff),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final Map<String, dynamic> staff;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _StaffCard({
    required this.staff,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = staff['isActive'] as bool;
    final subjects = staff['subjects'] as List<dynamic>?;
    final classes = staff['classes'] as List<dynamic>?;

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
                backgroundColor: isActive 
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                child: Text(
                  staff['name'].split(' ').map((n) => n[0]).take(2).join(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppColors.primary : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            staff['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (!isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Inactive',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${staff['id']} • ${staff['department'] ?? staff['role'] ?? ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (subjects != null && subjects.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: subjects.take(3).map((s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(fontSize: 10, color: AppColors.info),
                          ),
                        )).toList(),
                      ),
                    ],
                    if (classes != null && classes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Classes: ${classes.join(", ")}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'assign':
                      _showAssignDialog(context);
                      break;
                    case 'deactivate':
                      _showDeactivateDialog(context);
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
                  if (staff['subjects'] != null)
                    const PopupMenuItem(
                      value: 'assign',
                      child: Row(
                        children: [
                          Icon(Icons.assignment, size: 18),
                          SizedBox(width: 8),
                          Text('Assign Classes'),
                        ],
                      ),
                    ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'deactivate',
                    child: Row(
                      children: [
                        Icon(
                          isActive ? Icons.block : Icons.check_circle,
                          size: 18,
                          color: isActive ? AppColors.error : AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isActive ? 'Deactivate' : 'Activate',
                          style: TextStyle(
                            color: isActive ? AppColors.error : AppColors.success,
                          ),
                        ),
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

  void _showAssignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Classes'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Class assignment coming soon'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDialog(BuildContext context) {
    final isActive = staff['isActive'] as bool;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isActive ? 'Deactivate Staff' : 'Activate Staff'),
        content: Text(
          isActive
              ? 'Are you sure you want to deactivate ${staff['name']}?'
              : 'Are you sure you want to activate ${staff['name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.showSuccessSnackBar('Staff ${isActive ? 'deactivated' : 'activated'}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? AppColors.error : AppColors.success,
            ),
            child: Text(isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }
}

class _StaffDetailSheet extends StatelessWidget {
  final Map<String, dynamic> staff;

  const _StaffDetailSheet({required this.staff});

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
                  child: Text(
                    staff['name'].split(' ').map((n) => n[0]).take(2).join(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${staff['id']} • ${staff['department'] ?? staff['role'] ?? ''}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
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
                  _DetailRow(label: 'Email', value: staff['email']),
                  _DetailRow(label: 'Phone', value: staff['phone']),
                  if (staff['department'] != null)
                    _DetailRow(label: 'Department', value: staff['department']),
                  if (staff['role'] != null)
                    _DetailRow(label: 'Role', value: staff['role']),
                  _DetailRow(label: 'Join Date', value: staff['joinDate']),
                  _DetailRow(
                    label: 'Status',
                    value: staff['isActive'] ? 'Active' : 'Inactive',
                    valueColor: staff['isActive'] ? AppColors.success : Colors.grey,
                  ),
                  if (staff['subjects'] != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Subjects',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (staff['subjects'] as List).map((s) => Chip(
                        label: Text(s),
                        backgroundColor: AppColors.info.withValues(alpha: 0.1),
                      )).toList(),
                    ),
                  ],
                  if (staff['classes'] != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Assigned Classes',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (staff['classes'] as List).map((c) => Chip(
                        label: Text(c),
                        backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                      )).toList(),
                    ),
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
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddStaffSheet extends ConsumerStatefulWidget {
  const _AddStaffSheet();

  @override
  ConsumerState<_AddStaffSheet> createState() => _AddStaffSheetState();
}

class _AddStaffSheetState extends ConsumerState<_AddStaffSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRole = 'teacher';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
                  'Add New Staff',
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
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Required';
                        if (!v!.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(value: 'accountant', child: Text('Accountant')),
                        DropdownMenuItem(value: 'librarian', child: Text('Librarian')),
                        DropdownMenuItem(value: 'other', child: Text('Other Staff')),
                      ],
                      onChanged: (v) => setState(() => _selectedRole = v!),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
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
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Add Staff'),
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

    setState(() => _isSubmitting = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.pop(context);
      context.showSuccessSnackBar('Staff member added successfully');
    }
  }
}

class _EditStaffSheet extends StatefulWidget {
  final Map<String, dynamic> staff;

  const _EditStaffSheet({required this.staff});

  @override
  State<_EditStaffSheet> createState() => _EditStaffSheetState();
}

class _EditStaffSheetState extends State<_EditStaffSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.staff['name']);
    _emailController = TextEditingController(text: widget.staff['email']);
    _phoneController = TextEditingController(text: widget.staff['phone']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
                const Text(
                  'Edit Staff',
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
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Save Changes'),
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

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.pop(context);
      context.showSuccessSnackBar('Staff updated successfully');
    }
  }
}
