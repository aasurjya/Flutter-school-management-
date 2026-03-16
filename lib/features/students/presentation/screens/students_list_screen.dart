import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/students_provider.dart';

class StudentsListScreen extends ConsumerStatefulWidget {
  const StudentsListScreen({super.key});

  @override
  ConsumerState<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends ConsumerState<StudentsListScreen> {
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  // Active filter state
  String? _selectedClassId;
  String? _selectedSectionId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paginatedStudentsProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 300) {
      ref.read(paginatedStudentsProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(paginatedStudentsProvider.notifier).loadInitial(
            searchQuery: query.isEmpty ? null : query,
            classId: _selectedClassId,
            sectionId: _selectedSectionId,
          );
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchDebounce?.cancel();
    ref.read(paginatedStudentsProvider.notifier).loadInitial(
          classId: _selectedClassId,
          sectionId: _selectedSectionId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final paginatedState = ref.watch(paginatedStudentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add student coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear',
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.grey700
                    : AppColors.grey100,
              ),
            ),
          ),

          // Students count
          if (!paginatedState.isLoading && paginatedState.error == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${paginatedState.students.length}'
                    '${paginatedState.hasMore ? '+' : ''}'
                    ' student${paginatedState.students.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          // List body
          Expanded(
            child: _buildBody(paginatedState),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add student coming soon')),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Student'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildBody(PaginatedStudentsState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Failed to load students: ${state.error}'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  ref.read(paginatedStudentsProvider.notifier).loadInitial(
                        searchQuery: _searchController.text.isEmpty
                            ? null
                            : _searchController.text,
                        classId: _selectedClassId,
                        sectionId: _selectedSectionId,
                      ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No students found'
                  : 'No students match "${_searchController.text}"',
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.students.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.students.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final student = state.students[index];
        return _StudentCard(
          key: ValueKey(student.id),
          student: student,
          onTap: () => context.push('/students/${student.id}'),
        );
      },
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Students',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text('Status', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                      label: const Text('Active'),
                      onSelected: (_) {},
                      selected: true),
                  FilterChip(label: const Text('Inactive'), onSelected: (_) {}),
                  FilterChip(label: const Text('Alumni'), onSelected: (_) {}),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Gender', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                      label: const Text('All'),
                      onSelected: (_) {},
                      selected: true),
                  FilterChip(label: const Text('Male'), onSelected: (_) {}),
                  FilterChip(label: const Text('Female'), onSelected: (_) {}),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Apply Filters',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StudentCard extends StatelessWidget {
  final dynamic student;
  final VoidCallback onTap;

  const _StudentCard({
    required this.student,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final enrollment = student.currentEnrollment;
    final classLabel = enrollment != null
        ? '${enrollment.className ?? ''}${enrollment.sectionName != null ? ' - ${enrollment.sectionName}' : ''}'
        : '';
    final rollLabel =
        student.rollNumber != null ? 'Roll: ${student.rollNumber}' : '';
    final subtitle =
        [classLabel, rollLabel].where((s) => s.isNotEmpty).join(' • ');

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              student.initials,
              style: const TextStyle(
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
                  student.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
                if (student.phone != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone,
                          size: 14, color: AppColors.grey500),
                      const SizedBox(width: 4),
                      Text(
                        student.phone!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.grey400),
        ],
      ),
    );
  }
}
