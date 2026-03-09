import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/communication.dart';

class AudiencePicker extends StatefulWidget {
  final CampaignTargetType selectedTargetType;
  final Map<String, dynamic> targetFilter;
  final ValueChanged<CampaignTargetType> onTargetTypeChanged;
  final ValueChanged<Map<String, dynamic>> onFilterChanged;

  const AudiencePicker({
    super.key,
    required this.selectedTargetType,
    required this.targetFilter,
    required this.onTargetTypeChanged,
    required this.onFilterChanged,
  });

  @override
  State<AudiencePicker> createState() => _AudiencePickerState();
}

class _AudiencePickerState extends State<AudiencePicker> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _selectedUserIds = [];

  @override
  void initState() {
    super.initState();
    final existing = widget.targetFilter['user_ids'];
    if (existing is List) {
      _selectedUserIds.addAll(existing.cast<String>());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Audience',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Target type grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.5,
          children: CampaignTargetType.values.map((type) {
            final isSelected = widget.selectedTargetType == type;
            return _TargetTypeCard(
              type: type,
              isSelected: isSelected,
              onTap: () {
                widget.onTargetTypeChanged(type);
                widget.onFilterChanged({});
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Conditional filter UI based on target type
        _buildFilterUI(theme),
      ],
    );
  }

  Widget _buildFilterUI(ThemeData theme) {
    switch (widget.selectedTargetType) {
      case CampaignTargetType.all:
      case CampaignTargetType.parents:
      case CampaignTargetType.teachers:
      case CampaignTargetType.staff:
        return _buildEstimateCard(theme);

      case CampaignTargetType.classTarget:
        return _buildClassFilter(theme);

      case CampaignTargetType.section:
        return _buildSectionFilter(theme);

      case CampaignTargetType.individual:
        return _buildIndividualFilter(theme);

      case CampaignTargetType.custom:
        return _buildCustomFilter(theme);
    }
  }

  Widget _buildEstimateCard(ThemeData theme) {
    final typeLabel = widget.selectedTargetType.label;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.group_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target: $typeLabel',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This will send to all $typeLabel in your school.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Classes',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(12, (index) {
            final className = 'Class ${index + 1}';
            final classId = 'class_${index + 1}';
            final selectedIds =
                (widget.targetFilter['class_ids'] as List?)?.cast<String>() ??
                    [];
            final isSelected = selectedIds.contains(classId);

            return FilterChip(
              label: Text(className),
              selected: isSelected,
              onSelected: (selected) {
                final newIds = List<String>.from(selectedIds);
                if (selected) {
                  newIds.add(classId);
                } else {
                  newIds.remove(classId);
                }
                widget.onFilterChanged({'class_ids': newIds});
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSectionFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Sections',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          'Choose specific class sections to target.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        // Sample sections
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['10-A', '10-B', '9-A', '9-B', '8-A', '8-B'].map(
            (section) {
              final sectionId = 'section_$section';
              final selectedIds =
                  (widget.targetFilter['section_ids'] as List?)
                          ?.cast<String>() ??
                      [];
              final isSelected = selectedIds.contains(sectionId);

              return FilterChip(
                label: Text(section),
                selected: isSelected,
                onSelected: (selected) {
                  final newIds = List<String>.from(selectedIds);
                  if (selected) {
                    newIds.add(sectionId);
                  } else {
                    newIds.remove(sectionId);
                  }
                  widget.onFilterChanged({'section_ids': newIds});
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
              );
            },
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildIndividualFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Search Recipients',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by name or email...',
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
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        if (_selectedUserIds.isNotEmpty) ...[
          Text(
            '${_selectedUserIds.length} recipient(s) selected',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: _selectedUserIds.map((id) {
              return Chip(
                label: Text(id, style: const TextStyle(fontSize: 12)),
                onDeleted: () {
                  setState(() {
                    _selectedUserIds.remove(id);
                  });
                  widget.onFilterChanged({'user_ids': _selectedUserIds});
                },
                deleteIconColor: AppColors.error,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildCustomFilter(ThemeData theme) {
    final selectedRoles =
        (widget.targetFilter['roles'] as List?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Roles',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'student',
            'parent',
            'teacher',
            'accountant',
            'librarian',
            'transport_manager',
            'hostel_warden',
            'canteen_staff',
            'receptionist'
          ].map((role) {
            final isSelected = selectedRoles.contains(role);
            return FilterChip(
              label: Text(_formatRole(role)),
              selected: isSelected,
              onSelected: (selected) {
                final newRoles = List<String>.from(selectedRoles);
                if (selected) {
                  newRoles.add(role);
                } else {
                  newRoles.remove(role);
                }
                widget.onFilterChanged({'roles': newRoles});
              },
              selectedColor: AppColors.roleColor(role).withValues(alpha: 0.2),
              checkmarkColor: AppColors.roleColor(role),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatRole(String role) {
    return role
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

class _TargetTypeCard extends StatelessWidget {
  final CampaignTargetType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _TargetTypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    switch (type) {
      case CampaignTargetType.all:
        return Icons.groups_outlined;
      case CampaignTargetType.classTarget:
        return Icons.class_outlined;
      case CampaignTargetType.section:
        return Icons.dashboard_outlined;
      case CampaignTargetType.individual:
        return Icons.person_outlined;
      case CampaignTargetType.parents:
        return Icons.family_restroom_outlined;
      case CampaignTargetType.teachers:
        return Icons.school_outlined;
      case CampaignTargetType.staff:
        return Icons.badge_outlined;
      case CampaignTargetType.custom:
        return Icons.tune_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.borderLight,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
