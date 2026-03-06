import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/alumni.dart';
import '../../../../shared/widgets/glass_card.dart';

class StoryCard extends StatelessWidget {
  final AlumniSuccessStory story;
  final VoidCallback? onTap;

  const StoryCard({
    super.key,
    required this.story,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (story.imageUrl != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                story.imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  color: AppColors.primary.withValues(alpha: 0.08),
                  child: const Center(
                    child: Icon(Icons.image_outlined,
                        size: 40, color: AppColors.textTertiaryLight),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (story.isFeatured)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star,
                              size: 14, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            'Featured',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Text(
                  story.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  story.storyText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                if (story.alumni != null)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage:
                            story.alumni!.profilePhotoUrl != null
                                ? NetworkImage(
                                    story.alumni!.profilePhotoUrl!)
                                : null,
                        child: story.alumni!.profilePhotoUrl == null
                            ? Text(
                                story.alumni!.initials,
                                style:
                                    theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story.alumni!.fullName,
                              style:
                                  theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Class of ${story.alumni!.graduationYear}',
                              style:
                                  theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.textTertiaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.textTertiaryLight,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
