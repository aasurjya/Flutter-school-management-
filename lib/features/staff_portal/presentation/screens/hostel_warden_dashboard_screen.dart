import 'package:flutter/material.dart';

import '../../../../core/router/app_router.dart';
import '../widgets/staff_portal_scaffold.dart';

/// Apple-style hostel-warden portal.
class HostelWardenDashboardScreen extends StatelessWidget {
  const HostelWardenDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StaffPortalScaffold(
      greetingSubtitle: 'Rooms, residents, and visits.',
      sections: [
        StaffPortalSection(
          header: 'Hostel',
          cells: [
            StaffPortalCell(
              title: 'All rooms',
              icon: Icons.meeting_room_outlined,
              route: AppRoutes.hostel,
            ),
            StaffPortalCell(
              title: 'Residents',
              icon: Icons.people_outline,
              route: AppRoutes.hostel,
            ),
            StaffPortalCell(
              title: 'My room',
              icon: Icons.hotel_outlined,
              route: AppRoutes.hostelMyRoom,
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
