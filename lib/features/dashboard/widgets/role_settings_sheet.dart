import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Bottom-sheet menu used by every role's settings/profile affordance.
///
/// Each row is a [SettingsAction] — title, subtitle, icon, tap. The four
/// dashboards previously re-implemented this with subtly different paddings,
/// icons, and colors. This primitive enforces consistency.
///
/// Use via [showRoleSettingsSheet] rather than constructing directly.
class RoleSettingsSheet extends StatelessWidget {
  final List<SettingsAction> actions;

  const RoleSettingsSheet({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    // Material (rather than a decorated Container) so the ListTiles below
    // have a proper Material ancestor for ink splashes and background
    // painting. Without this, Flutter's debug-mode assertion fires:
    // "ListTile background color or ink splashes may be invisible."
    return SafeArea(
      child: Material(
        color: Theme.of(context).cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ...actions.map((a) => ListTile(
                    leading: Icon(a.icon, color: a.iconColor),
                    title: Text(a.title),
                    subtitle:
                        a.subtitle == null ? null : Text(a.subtitle!),
                    onTap: () {
                      Navigator.of(context).pop();
                      a.onTap();
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsAction {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const SettingsAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconColor = AppColors.primary,
  });
}

Future<void> showRoleSettingsSheet(
  BuildContext context, {
  required List<SettingsAction> actions,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => RoleSettingsSheet(actions: actions),
  );
}
