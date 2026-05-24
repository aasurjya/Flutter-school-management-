import 'package:flutter/material.dart';

import '../../../../core/router/app_router.dart';
import '../widgets/staff_portal_scaffold.dart';

/// Apple-style librarian portal.
class LibrarianDashboardScreen extends StatelessWidget {
  const LibrarianDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StaffPortalScaffold(
      greetingSubtitle: 'Books, loans, and returns.',
      sections: [
        StaffPortalSection(
          header: 'Library',
          cells: [
            StaffPortalCell(
              title: 'Catalogue',
              icon: Icons.library_books_outlined,
              route: AppRoutes.library,
            ),
            StaffPortalCell(
              title: 'Loans',
              icon: Icons.book_outlined,
              route: AppRoutes.library,
            ),
            StaffPortalCell(
              title: 'My loans',
              icon: Icons.menu_book_outlined,
              route: AppRoutes.libraryMyBooks,
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
