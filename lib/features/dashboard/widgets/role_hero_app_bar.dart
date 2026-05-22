import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Sliver app-bar used by every role dashboard.
///
/// Replaces ~80 lines of hand-rolled `SliverAppBar` + `FlexibleSpaceBar` +
/// `Stack` boilerplate that was copy-pasted across admin/teacher/parent/
/// student/super_admin dashboards. Pure layout — no business logic.
class RoleHeroAppBar extends StatelessWidget {
  /// Small caps label above the title (e.g. "Administrative Command Center").
  final String eyebrow;

  /// Big title (e.g. tenant name or user name).
  final String title;

  /// Optional pill below the title (e.g. today's date, role label).
  final String? pillText;

  /// Trailing action icons (typically [HeroActionButton]s).
  final List<Widget> actions;

  /// Two-stop gradient applied to the hero area. Defaults to primary→grey800.
  final List<Color>? gradientColors;

  /// Hero height. Defaults to 200 (admin) — bump to 220 if the title wraps.
  final double expandedHeight;

  const RoleHeroAppBar({
    super.key,
    required this.eyebrow,
    required this.title,
    this.pillText,
    this.actions = const [],
    this.gradientColors,
    this.expandedHeight = 200,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = gradientColors ??
        const [AppColors.primary, AppColors.grey800];
    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      elevation: 0,
      backgroundColor: colors.first,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
              ),
            ),
            Positioned(
              top: -40,
              right: -40,
              child: CircleAvatar(
                radius: 80,
                backgroundColor: Colors.white.withValues(alpha: 0.03),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      eyebrow,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (pillText != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          pillText!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact circular icon button suited to the hero header — consistent across
/// every dashboard's notifications/profile/settings affordances.
class HeroActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const HeroActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white.withValues(alpha: 0.15),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}
