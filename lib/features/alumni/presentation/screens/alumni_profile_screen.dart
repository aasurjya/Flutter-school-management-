import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/alumni_provider.dart';

class AlumniProfileScreen extends ConsumerWidget {
  final String alumniId;

  const AlumniProfileScreen({
    super.key,
    required this.alumniId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(alumniProfileByIdProvider(alumniId));

    return Scaffold(
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Alumni not found'));
          }

          return CustomScrollView(
            slivers: [
              // Profile header
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            backgroundImage:
                                profile.profilePhotoUrl != null
                                    ? NetworkImage(
                                        profile.profilePhotoUrl!)
                                    : null,
                            child: profile.profilePhotoUrl == null
                                ? Text(
                                    profile.initials,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                profile.fullName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (profile.isVerified) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified,
                                    size: 20, color: Colors.white),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Class of ${profile.graduationYear}${profile.className != null ? ' | ${profile.className}' : ''}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Career info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Career',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.business,
                          label: 'Company',
                          value: profile.currentCompany ?? 'Not specified',
                        ),
                        _InfoRow(
                          icon: Icons.work_outline,
                          label: 'Designation',
                          value: profile.currentDesignation ?? 'Not specified',
                        ),
                        _InfoRow(
                          icon: Icons.category_outlined,
                          label: 'Industry',
                          value: profile.industry ?? 'Not specified',
                        ),
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Location',
                          value: profile.locationDisplay,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Contact info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (profile.email != null)
                          _InfoRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: profile.email!,
                          ),
                        if (profile.phone != null)
                          _InfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: profile.phone!,
                          ),
                        if (profile.linkedinUrl != null)
                          _InfoRow(
                            icon: Icons.link,
                            label: 'LinkedIn',
                            value: profile.linkedinUrl!,
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bio
              if (profile.bio != null && profile.bio!.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            profile.bio!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Skills
              if (profile.skills.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Skills & Expertise',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: profile.skills.map((skill) {
                              return Chip(
                                label: Text(skill),
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.08),
                                labelStyle:
                                    theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.primary,
                                ),
                                side: BorderSide.none,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Mentor badge
              if (profile.isMentor)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      gradient: AppColors.secondaryGradient,
                      backgroundColor: Colors.transparent,
                      child: Row(
                        children: [
                          const Icon(Icons.psychology,
                              color: Colors.white, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Available as Mentor',
                                  style:
                                      theme.textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Open to mentoring current students',
                                  style:
                                      theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 8),
              Text('Error: $e'),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textTertiaryLight),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
