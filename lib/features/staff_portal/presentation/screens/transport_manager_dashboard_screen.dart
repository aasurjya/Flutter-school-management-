import 'package:flutter/material.dart';

import '../../../../core/router/app_router.dart';
import '../widgets/staff_portal_scaffold.dart';

/// Apple-style transport-manager portal.
class TransportManagerDashboardScreen extends StatelessWidget {
  const TransportManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StaffPortalScaffold(
      greetingSubtitle: 'Routes, buses, and tracking.',
      sections: [
        StaffPortalSection(
          header: 'Transport',
          cells: [
            StaffPortalCell(
              title: 'All routes',
              icon: Icons.directions_bus_outlined,
              route: AppRoutes.transport,
            ),
            StaffPortalCell(
              title: 'Live tracking',
              icon: Icons.location_on_outlined,
              route: AppRoutes.transport,
            ),
            StaffPortalCell(
              title: 'My route',
              icon: Icons.alt_route_outlined,
              route: AppRoutes.transportMyRoute,
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
