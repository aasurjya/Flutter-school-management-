import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

/// One demo account row in the [DemoAccountsPanel].
@immutable
class DemoAccount {
  final String label;
  final String email;
  final String password;
  final String hint;
  final IconData icon;
  final Color accentColor;

  const DemoAccount({
    required this.label,
    required this.email,
    required this.password,
    required this.hint,
    required this.icon,
    required this.accentColor,
  });
}

/// The seven demo accounts surfaced on the login screen. Order matches
/// the typical "show me everything" demo flow: admin first, drill into
/// roles, finish on super_admin / production seed.
///
/// Password is shared (`Demo@2026`) for the demo tenant; the prod seed
/// has its own. See `README.md` §Demo Login Credentials.
const List<DemoAccount> kDemoAccounts = <DemoAccount>[
  DemoAccount(
    label: 'Tenant Admin',
    email: 'admin@demoschool.edu',
    password: 'Demo@2026',
    hint: 'Full school admin — every feature',
    icon: Icons.admin_panel_settings_outlined,
    accentColor: AppColors.primary,
  ),
  DemoAccount(
    label: 'Principal',
    email: 'principal@demoschool.edu',
    password: 'Demo@2026',
    hint: 'Digest, escalations, AI insights',
    icon: Icons.workspace_premium_outlined,
    accentColor: AppColors.info,
  ),
  DemoAccount(
    label: 'Teacher',
    email: 'teacher1@demoschool.edu',
    password: 'Demo@2026',
    hint: 'Class, gradebook, lesson plans',
    icon: Icons.school_outlined,
    accentColor: AppColors.success,
  ),
  DemoAccount(
    label: 'Student (Noah ⭐)',
    email: 'student4@demoschool.edu',
    password: 'Demo@2026',
    hint: 'High dropout-risk seed — test AI dashboards',
    icon: Icons.face_outlined,
    accentColor: AppColors.warning,
  ),
  DemoAccount(
    label: 'Parent',
    email: 'parent3@demoschool.edu',
    password: 'Demo@2026',
    hint: 'Multi-child view (Noah + Ava)',
    icon: Icons.family_restroom_outlined,
    accentColor: AppColors.accent,
  ),
  DemoAccount(
    label: 'Accountant',
    email: 'accountant@demoschool.edu',
    password: 'Demo@2026',
    hint: 'Fees, invoices, payments',
    icon: Icons.account_balance_wallet_outlined,
    accentColor: AppColors.secondary,
  ),
  DemoAccount(
    label: 'Super Admin',
    email: 'superadmin@demoschool.edu',
    password: 'Demo@2026',
    hint: 'Cross-tenant view, AI usage dashboard',
    icon: Icons.shield_outlined,
    accentColor: AppColors.error,
  ),
];

/// Compact panel of tap-to-fill demo accounts shown below the login form
/// when `AppEnvironment.showDemoCredentials` is true (dev/staging only).
///
/// Two affordances per row:
///   • Tap the row → fills the email + password fields via [onSelect].
///   • Tap the copy icon → copies `email / password` to the clipboard
///     and shows a confirmation snackbar.
///
/// The panel is intentionally **stateless and self-contained** — the
/// password is a constant on the const accounts list, never queried at
/// runtime, never logged. The widget is gated to non-production builds
/// at the call site, so it never ships to real users.
class DemoAccountsPanel extends StatelessWidget {
  final void Function(String email, String password) onSelect;

  const DemoAccountsPanel({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warningLight.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on_outlined,
                  size: 18, color: AppColors.warning),
              const SizedBox(width: 6),
              Text(
                'Demo accounts',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey900,
                ),
              ),
              const Spacer(),
              Text(
                'tap to fill',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.grey500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Universal password: Demo@2026',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.grey600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ...kDemoAccounts.map(
            (account) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DemoAccountRow(
                account: account,
                onFill: () => _handleFill(context, account),
                onCopy: () => _handleCopy(context, account),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleFill(BuildContext context, DemoAccount account) {
    onSelect(account.email, account.password);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Filled ${account.label}. Tap Sign In.'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _handleCopy(BuildContext context, DemoAccount account) async {
    final payload = '${account.email} / ${account.password}';
    await Clipboard.setData(ClipboardData(text: payload));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Copied: $payload'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _DemoAccountRow extends StatelessWidget {
  final DemoAccount account;
  final VoidCallback onFill;
  final VoidCallback onCopy;

  const _DemoAccountRow({
    required this.account,
    required this.onFill,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onFill,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: account.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(account.icon,
                    size: 18, color: account.accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.email,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.grey500,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded, size: 16),
                tooltip: 'Copy email / password',
                color: AppColors.grey500,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
