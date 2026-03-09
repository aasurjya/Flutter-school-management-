import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/alumni_provider.dart';
import '../widgets/alumni_card.dart';

class AlumniDirectoryScreen extends ConsumerStatefulWidget {
  const AlumniDirectoryScreen({super.key});

  @override
  ConsumerState<AlumniDirectoryScreen> createState() =>
      _AlumniDirectoryScreenState();
}

class _AlumniDirectoryScreenState
    extends ConsumerState<AlumniDirectoryScreen> {
  final _searchController = TextEditingController();
  String? _selectedIndustry;
  int? _selectedYear;
  bool? _mentorOnly;

  AlumniFilter get _currentFilter => AlumniFilter(
        search: _searchController.text.isEmpty
            ? null
            : _searchController.text,
        graduationYear: _selectedYear,
        industry: _selectedIndustry,
        isMentor: _mentorOnly,
      );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profilesAsync = ref.watch(alumniProfilesProvider(_currentFilter));
    final industriesAsync = ref.watch(alumniIndustriesProvider);
    final yearsAsync = ref.watch(alumniGraduationYearsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alumni Directory'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, company...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.inputFillLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Industry filter
                industriesAsync.when(
                  data: (industries) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: DropdownButtonHideUnderline(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedIndustry != null
                                ? AppColors.primary
                                : AppColors.borderLight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: DropdownButton<String?>(
                          value: _selectedIndustry,
                          hint: const Text('Industry'),
                          isDense: true,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Industries'),
                            ),
                            ...industries.map((i) => DropdownMenuItem(
                                  value: i,
                                  child: Text(i),
                                )),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedIndustry = val),
                        ),
                      ),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // Year filter
                yearsAsync.when(
                  data: (years) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: DropdownButtonHideUnderline(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedYear != null
                                ? AppColors.primary
                                : AppColors.borderLight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: DropdownButton<int?>(
                          value: _selectedYear,
                          hint: const Text('Batch'),
                          isDense: true,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Batches'),
                            ),
                            ...years.map((y) => DropdownMenuItem(
                                  value: y,
                                  child: Text('$y'),
                                )),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedYear = val),
                        ),
                      ),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // Mentor filter
                FilterChip(
                  label: const Text('Mentors'),
                  selected: _mentorOnly == true,
                  onSelected: (selected) {
                    setState(() {
                      _mentorOnly = selected ? true : null;
                    });
                  },
                  selectedColor: AppColors.secondary.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.secondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Results
          Expanded(
            child: profilesAsync.when(
              data: (profiles) {
                if (profiles.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 64,
                          color: AppColors.textTertiaryLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No alumni found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try adjusting your filters',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiaryLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: profiles.length,
                  itemBuilder: (context, index) {
                    final alumni = profiles[index];
                    return AlumniCard(
                      alumni: alumni,
                      onTap: () => context.push(
                        AppRoutes.alumniProfile
                            .replaceAll(':alumniId', alumni.id),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 8),
                    Text('Error: $e'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(
                          alumniProfilesProvider(_currentFilter)),
                      child: const Text('Retry'),
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
}
