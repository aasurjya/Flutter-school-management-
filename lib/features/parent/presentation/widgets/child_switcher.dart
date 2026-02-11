import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../students/providers/students_provider.dart';

class ChildSwitcher extends ConsumerWidget {
  final void Function(Map<String, dynamic> child)? onChildSelected;

  const ChildSwitcher({super.key, this.onChildSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(supabaseProvider).auth.currentUser?.id;
    if (userId == null) {
      return const SizedBox.shrink();
    }

    final childrenAsync = ref.watch(parentChildrenProvider(userId));
    final selectedChild = ref.watch(selectedChildProvider);

    return childrenAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        child: Center(child: Text('Error loading children: $e')),
      ),
      data: (children) {
        if (children.isEmpty) {
          return Container(
            height: 80,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('No children linked to your account'),
            ),
          );
        }

        // Auto-select first child if none selected
        if (selectedChild == null && children.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedChildProvider.notifier).state = children.first;
            onChildSelected?.call(children.first);
          });
        }

        return SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: children.length,
            itemBuilder: (context, index) {
              final child = children[index];
              final isSelected = selectedChild?['student_id'] == child['student_id'];

              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 8,
                  right: index == children.length - 1 ? 0 : 8,
                ),
                child: _ChildCard(
                  name: child['student_name'] ?? 'Unknown',
                  className: '${child['class_name']} - ${child['section_name']}',
                  photoUrl: child['photo_url'],
                  relation: child['relation'] ?? 'Parent',
                  isSelected: isSelected,
                  onTap: () {
                    ref.read(selectedChildProvider.notifier).state = child;
                    onChildSelected?.call(child);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ChildCard extends StatelessWidget {
  final String name;
  final String className;
  final String? photoUrl;
  final String relation;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ChildCard({
    required this.name,
    required this.className,
    this.photoUrl,
    required this.relation,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withValues(alpha: 0.1) 
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                image: photoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(photoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: photoUrl == null
                  ? Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isSelected ? AppColors.primary : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  className,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  relation,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ChildSwitcherCompact extends ConsumerWidget {
  const ChildSwitcherCompact({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(supabaseProvider).auth.currentUser?.id;
    if (userId == null) {
      return const SizedBox.shrink();
    }

    final childrenAsync = ref.watch(parentChildrenProvider(userId));
    final selectedChild = ref.watch(selectedChildProvider);

    return childrenAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (children) {
        if (children.isEmpty || children.length == 1) {
          return const SizedBox.shrink();
        }

        return PopupMenuButton<Map<String, dynamic>>(
          initialValue: selectedChild,
          onSelected: (child) {
            ref.read(selectedChildProvider.notifier).state = child;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedChild?['student_name'] ?? 'Select Child',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: Colors.white),
              ],
            ),
          ),
          itemBuilder: (context) {
            return children.map((child) {
              return PopupMenuItem<Map<String, dynamic>>(
                value: child,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: child['photo_url'] != null
                          ? NetworkImage(child['photo_url'])
                          : null,
                      child: child['photo_url'] == null
                          ? Text(
                              child['student_name']?[0] ?? '?',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child['student_name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${child['class_name']} - ${child['section_name']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList();
          },
        );
      },
    );
  }
}
