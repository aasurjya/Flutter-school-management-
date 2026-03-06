import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/alumni.dart';
import '../../providers/alumni_provider.dart';
import '../widgets/story_card.dart';

class SuccessStoriesScreen extends ConsumerStatefulWidget {
  const SuccessStoriesScreen({super.key});

  @override
  ConsumerState<SuccessStoriesScreen> createState() =>
      _SuccessStoriesScreenState();
}

class _SuccessStoriesScreenState extends ConsumerState<SuccessStoriesScreen> {
  bool _showFeaturedOnly = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final storiesAsync = ref.watch(alumniSuccessStoriesProvider(
      AlumniStoryFilter(
        status: 'published',
        isFeatured: _showFeaturedOnly ? true : null,
      ),
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Success Stories'),
        actions: [
          FilterChip(
            label: const Text('Featured'),
            selected: _showFeaturedOnly,
            onSelected: (val) =>
                setState(() => _showFeaturedOnly = val),
            selectedColor: AppColors.accent.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: storiesAsync.when(
        data: (stories) {
          if (stories.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_stories,
                      size: 64, color: AppColors.textTertiaryLight),
                  const SizedBox(height: 16),
                  Text(
                    'No stories published yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share your journey and inspire others!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(alumniSuccessStoriesProvider(
                AlumniStoryFilter(
                  status: 'published',
                  isFeatured: _showFeaturedOnly ? true : null,
                ),
              ));
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: stories.length,
              itemBuilder: (context, index) {
                final story = stories[index];
                return StoryCard(
                  story: story,
                  onTap: () => _showStoryDetail(context, story),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubmitStoryDialog(context, ref),
        icon: const Icon(Icons.edit),
        label: const Text('Share Story'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showStoryDetail(BuildContext context, AlumniSuccessStory story) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiaryLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (story.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      story.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (story.isFeatured)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.star,
                            size: 16, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          'Featured Story',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  story.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (story.alumni != null)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          story.alumni!.initials,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.alumni!.fullName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${story.alumni!.careerDisplay} | Class of ${story.alumni!.graduationYear}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                const Divider(height: 32),
                Text(
                  story.storyText,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.7,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSubmitStoryDialog(BuildContext context, WidgetRef ref) {
    final myProfile = ref.read(myAlumniProfileProvider).valueOrNull;
    if (myProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Register as alumni first')),
      );
      return;
    }

    final titleController = TextEditingController();
    final storyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Your Story'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., From Classroom to Silicon Valley',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: storyController,
                decoration: const InputDecoration(
                  labelText: 'Your Story *',
                  border: OutlineInputBorder(),
                  hintText: 'Share your journey...',
                ),
                maxLines: 8,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (titleController.text.isEmpty ||
                  storyController.text.isEmpty) {
                return;
              }
              try {
                final repo = ref.read(alumniRepositoryProvider);
                await repo.createSuccessStory({
                  'alumni_id': myProfile.id,
                  'title': titleController.text,
                  'story_text': storyController.text,
                  'status': 'draft',
                });
                ref.invalidate(publishedStoriesProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Story submitted! It will be reviewed by admin.'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
