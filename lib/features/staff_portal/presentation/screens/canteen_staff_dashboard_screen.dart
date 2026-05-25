import 'package:flutter/material.dart';

import '../../../../core/router/app_router.dart';
import '../widgets/staff_portal_scaffold.dart';

/// Apple-style canteen-staff portal.
class CanteenStaffDashboardScreen extends StatelessWidget {
  const CanteenStaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StaffPortalScaffold(
      greetingSubtitle: 'Orders, menu, and wallet.',
      sections: [
        StaffPortalSection(
          header: 'Canteen',
          cells: [
            StaffPortalCell(
              title: 'Menu',
              icon: Icons.restaurant_menu_outlined,
              route: AppRoutes.canteen,
            ),
            StaffPortalCell(
              title: 'Orders',
              icon: Icons.receipt_outlined,
              route: AppRoutes.canteenOrders,
            ),
            StaffPortalCell(
              title: 'Wallet',
              icon: Icons.account_balance_wallet_outlined,
              route: AppRoutes.canteenWallet,
            ),
          ],
        ),
        StaffPortalSection(
          header: 'Day',
          cells: [
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
