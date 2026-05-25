import 'package:flutter/material.dart';

import '../../../../core/router/app_router.dart';
import '../widgets/staff_portal_scaffold.dart';

/// Apple-style receptionist portal.
class ReceptionistDashboardScreen extends StatelessWidget {
  const ReceptionistDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StaffPortalScaffold(
      greetingSubtitle: 'Front desk and visitors.',
      sections: [
        StaffPortalSection(
          header: 'Visitors',
          cells: [
            StaffPortalCell(
              title: 'Check in',
              icon: Icons.qr_code_scanner_outlined,
              route: AppRoutes.visitorCheckIn,
            ),
            StaffPortalCell(
              title: 'Pre-register',
              icon: Icons.person_add_outlined,
              route: AppRoutes.visitorPreRegister,
            ),
            StaffPortalCell(
              title: 'Visitor log',
              icon: Icons.history_outlined,
              route: AppRoutes.visitorLog,
            ),
          ],
        ),
        StaffPortalSection(
          header: 'Day',
          cells: [
            StaffPortalCell(
              title: 'Calendar',
              icon: Icons.event_outlined,
              route: AppRoutes.calendar,
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
