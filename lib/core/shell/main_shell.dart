import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';

/// Main shell with bottom navigation
class MainShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final primaryRole = currentUser?.primaryRole ?? 'student';

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _buildBottomNav(context, primaryRole),
    );
  }

  Widget _buildBottomNav(BuildContext context, String role) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final items = _getNavItems(role);
    
    int currentIndex = _getCurrentIndex(currentLocation, role);
    if (currentIndex == -1) currentIndex = 0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == currentIndex;

              return _NavItem(
                icon: item.icon,
                activeIcon: item.activeIcon,
                label: item.label,
                isSelected: isSelected,
                onTap: () => _onItemTapped(context, index, role),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  List<_NavItemData> _getNavItems(String role) {
    switch (role) {
      case 'super_admin':
      case 'tenant_admin':
      case 'principal':
        return _adminNavItems;
      case 'teacher':
        return _teacherNavItems;
      case 'student':
        return _studentNavItems;
      case 'parent':
        return _parentNavItems;
      default:
        return _studentNavItems;
    }
  }

  int _getCurrentIndex(String location, String role) {
    final routes = _getRoutes(role);
    for (int i = 0; i < routes.length; i++) {
      if (location.startsWith(routes[i])) {
        return i;
      }
    }
    return 0;
  }

  List<String> _getRoutes(String role) {
    switch (role) {
      case 'super_admin':
      case 'tenant_admin':
      case 'principal':
        return [
          AppRoutes.adminDashboard,
          AppRoutes.studentManagement,
          AppRoutes.attendance,
          AppRoutes.fees,
          AppRoutes.library,
          AppRoutes.transport,
          AppRoutes.hostel,
          AppRoutes.canteen,
          AppRoutes.messages,
        ];
      case 'teacher':
        return [
          AppRoutes.teacherDashboard,
          AppRoutes.attendance,
          AppRoutes.exams,
          AppRoutes.library,
          AppRoutes.transport,
          AppRoutes.hostel,
          AppRoutes.canteen,
          AppRoutes.messages,
        ];
      case 'student':
        return [
          AppRoutes.studentDashboard,
          AppRoutes.attendance,
          AppRoutes.exams,
          AppRoutes.library,
          AppRoutes.transport,
          AppRoutes.hostel,
          AppRoutes.canteen,
          AppRoutes.messages,
        ];
      case 'parent':
        return [
          AppRoutes.parentDashboard,
          AppRoutes.attendance,
          AppRoutes.fees,
          AppRoutes.library,
          AppRoutes.transport,
          AppRoutes.hostel,
          AppRoutes.canteen,
          AppRoutes.messages,
        ];
      default:
        return [AppRoutes.studentDashboard];
    }
  }

  void _onItemTapped(BuildContext context, int index, String role) {
    final routes = _getRoutes(role);
    if (index < routes.length) {
      context.go(routes[index]);
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// Navigation items for each role
const _adminNavItems = [
  _NavItemData(
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
    label: 'Dashboard',
  ),
  _NavItemData(
    icon: Icons.people_outlined,
    activeIcon: Icons.people,
    label: 'Students',
  ),
  _NavItemData(
    icon: Icons.fact_check_outlined,
    activeIcon: Icons.fact_check,
    label: 'Attendance',
  ),
  _NavItemData(
    icon: Icons.payment_outlined,
    activeIcon: Icons.payment,
    label: 'Fees',
  ),
  _NavItemData(
    icon: Icons.library_books_outlined,
    activeIcon: Icons.library_books,
    label: 'Library',
  ),
  _NavItemData(
    icon: Icons.directions_bus_outlined,
    activeIcon: Icons.directions_bus,
    label: 'Transport',
  ),
  _NavItemData(
    icon: Icons.apartment_outlined,
    activeIcon: Icons.apartment,
    label: 'Hostel',
  ),
  _NavItemData(
    icon: Icons.restaurant_outlined,
    activeIcon: Icons.restaurant,
    label: 'Canteen',
  ),
  _NavItemData(
    icon: Icons.message_outlined,
    activeIcon: Icons.message,
    label: 'Messages',
  ),
];

const _teacherNavItems = [
  _NavItemData(
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
    label: 'Dashboard',
  ),
  _NavItemData(
    icon: Icons.fact_check_outlined,
    activeIcon: Icons.fact_check,
    label: 'Attendance',
  ),
  _NavItemData(
    icon: Icons.assignment_outlined,
    activeIcon: Icons.assignment,
    label: 'Exams',
  ),
  _NavItemData(
    icon: Icons.library_books_outlined,
    activeIcon: Icons.library_books,
    label: 'Library',
  ),
  _NavItemData(
    icon: Icons.directions_bus_outlined,
    activeIcon: Icons.directions_bus,
    label: 'Transport',
  ),
  _NavItemData(
    icon: Icons.apartment_outlined,
    activeIcon: Icons.apartment,
    label: 'Hostel',
  ),
  _NavItemData(
    icon: Icons.restaurant_outlined,
    activeIcon: Icons.restaurant,
    label: 'Canteen',
  ),
  _NavItemData(
    icon: Icons.message_outlined,
    activeIcon: Icons.message,
    label: 'Messages',
  ),
];

const _studentNavItems = [
  _NavItemData(
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
    label: 'Dashboard',
  ),
  _NavItemData(
    icon: Icons.fact_check_outlined,
    activeIcon: Icons.fact_check,
    label: 'Attendance',
  ),
  _NavItemData(
    icon: Icons.assignment_outlined,
    activeIcon: Icons.assignment,
    label: 'Results',
  ),
  _NavItemData(
    icon: Icons.library_books_outlined,
    activeIcon: Icons.library_books,
    label: 'Library',
  ),
  _NavItemData(
    icon: Icons.directions_bus_outlined,
    activeIcon: Icons.directions_bus,
    label: 'Transport',
  ),
  _NavItemData(
    icon: Icons.apartment_outlined,
    activeIcon: Icons.apartment,
    label: 'Hostel',
  ),
  _NavItemData(
    icon: Icons.restaurant_outlined,
    activeIcon: Icons.restaurant,
    label: 'Canteen',
  ),
  _NavItemData(
    icon: Icons.message_outlined,
    activeIcon: Icons.message,
    label: 'Messages',
  ),
];

const _parentNavItems = [
  _NavItemData(
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
    label: 'Dashboard',
  ),
  _NavItemData(
    icon: Icons.fact_check_outlined,
    activeIcon: Icons.fact_check,
    label: 'Attendance',
  ),
  _NavItemData(
    icon: Icons.payment_outlined,
    activeIcon: Icons.payment,
    label: 'Fees',
  ),
  _NavItemData(
    icon: Icons.library_books_outlined,
    activeIcon: Icons.library_books,
    label: 'Library',
  ),
  _NavItemData(
    icon: Icons.directions_bus_outlined,
    activeIcon: Icons.directions_bus,
    label: 'Transport',
  ),
  _NavItemData(
    icon: Icons.apartment_outlined,
    activeIcon: Icons.apartment,
    label: 'Hostel',
  ),
  _NavItemData(
    icon: Icons.restaurant_outlined,
    activeIcon: Icons.restaurant,
    label: 'Canteen',
  ),
  _NavItemData(
    icon: Icons.message_outlined,
    activeIcon: Icons.message,
    label: 'Messages',
  ),
];
