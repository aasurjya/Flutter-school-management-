import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/parent_digest_provider.dart';
import '../widgets/digest_card.dart';

class ParentDigestListScreen extends ConsumerWidget {
  final String parentId;
  final String? studentId;

  const ParentDigestListScreen({
    super.key,
    required this.parentId,
    this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digestsAsync = ref.watch(parentDigestsProvider(
      ParentDigestFilter(
        parentId: parentId,
        studentId: studentId,
      ),
    ));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Weekly Digests',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.sunriseGradient,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: digestsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SliverFillRemaining(
                child: Center(child: Text('Failed to load digests')),
              ),
              data: (digests) {
                if (digests.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.summarize_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No weekly digests yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Digests will appear here once generated',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final digest = digests[index];
                      return DigestCard(
                        digest: digest,
                        onTap: () {
                          context.push(
                            '${AppRoutes.parentDigests}/${digest.id}',
                          );
                          // Mark as read
                          ref
                              .read(parentDigestRepositoryProvider)
                              .markAsRead(digest.id);
                        },
                      );
                    },
                    childCount: digests.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
