import 'package:flutter/material.dart';

import '../../../../core/router/app_router.dart';
import '../widgets/staff_portal_scaffold.dart';

/// Apple-style accountant portal.
class AccountantDashboardScreen extends StatelessWidget {
  const AccountantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StaffPortalScaffold(
      greetingSubtitle: 'Fees, collections, and reports.',
      sections: [
        StaffPortalSection(
          header: 'Fees',
          cells: [
            StaffPortalCell(
              title: 'All invoices',
              icon: Icons.receipt_long_outlined,
              route: AppRoutes.fees,
            ),
            StaffPortalCell(
              title: 'Collections',
              icon: Icons.account_balance_wallet_outlined,
              route: AppRoutes.fees,
            ),
            StaffPortalCell(
              title: 'Reminders',
              icon: Icons.notifications_active_outlined,
              route: AppRoutes.fees,
            ),
          ],
        ),
        StaffPortalSection(
          header: 'Reports',
          cells: [
            StaffPortalCell(
              title: 'Financial reports',
              icon: Icons.assessment_outlined,
              route: AppRoutes.reports,
            ),
            StaffPortalCell(
              title: 'My ID card',
              icon: Icons.badge_outlined,
              route: AppRoutes.staffIdCard,
            ),
          ],
        ),
      ],
    );
  }
}
