import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/lms_provider.dart';
import '../widgets/course_card.dart';

class CourseCatalogScreen extends ConsumerStatefulWidget {
  const CourseCatalogScreen({super.key});

  @override
  ConsumerState<CourseCatalogScreen> createState() =>
      _CourseCatalogScreenState();
}

class _CourseCatalogScreenState extends ConsumerState<CourseCatalogScreen> {
  final _searchController = TextEditingController();
  String? _selectedClassId;
  String? _selectedSubjectId;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  CatalogFilter get _filter => CatalogFilter(
        classId: _selectedClassId,
        subjectId: _selectedSubjectId,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(publishedCoursesProvider(_filter));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Catalog'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? AppColors.inputFillDark
                    : AppColors.inputFillLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          const SizedBox(height: 8),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Classes'),
                  selected: _selectedClassId == null,
                  onSelected: (_) => setState(() => _selectedClassId = null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('All Subjects'),
                  selected: _selectedSubjectId == null,
                  onSelected: (_) =>
                      setState(() => _selectedSubjectId = null),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Course list
          Expanded(
            child: coursesAsync.when(
              data: (courses) {
                if (courses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined,
                            size: 64,
                            color: AppColors.textTertiaryLight),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No courses match your search'
                              : 'No courses available',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(publishedCoursesProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return CourseCard(
                        course: course,
                        onTap: () => context.push(
                          AppRoutes.lmsCourseDetail
                              .replaceAll(':courseId', course.id),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Center(
                child: GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text('Error: $e'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () =>
                            ref.invalidate(publishedCoursesProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
