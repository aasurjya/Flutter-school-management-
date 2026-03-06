import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/alumni.dart';
import '../../../../shared/widgets/glass_card.dart';

class AlumniCard extends StatelessWidget {
  final AlumniProfile alumni;
  final VoidCallback? onTap;

  const AlumniCard({
    super.key,
    required this.alumni,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: alumni.profilePhotoUrl != null
                ? NetworkImage(alumni.profilePhotoUrl!)
                : null,
            child: alumni.profilePhotoUrl == null
                ? Text(
                    alumni.initials,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alumni.fullName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (alumni.isVerified)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.verified,
                          size: 16,
                          color: AppColors.info,
                        ),
                      ),
                    if (alumni.isMentor)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Mentor',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (alumni.currentDesignation != null ||
                    alumni.currentCompany != null)
                  Text(
                    alumni.careerDisplay,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 14,
                      color: AppColors.textTertiaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Class of ${alumni.graduationYear}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                    if (alumni.locationCity != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textTertiaryLight,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          alumni.locationDisplay,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            color: AppColors.textTertiaryLight,
          ),
        ],
      ),
    );
  }
}
