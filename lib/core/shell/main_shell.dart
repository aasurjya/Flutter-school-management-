import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai_tutor/presentation/widgets/tutor_chat_overlay.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../router/app_router.dart';
import '../services/screen_capture_service.dart';
import '../theme/app_colors.dart';

/// Main shell with premium pill-style bottom navigation.
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
      body: RepaintBoundary(
        key: ScreenCaptureService.repaintKey,
        child: widget.child,
      ),
      floatingActionButton: const _AiTutorFab(),
      bottomNavigationBar: _PremiumBottomNav(role: primaryRole),
    );
  }
}

// ─── Premium bottom nav ────────────────────────────────────────────────────────

class _PremiumBottomNav extends ConsumerWidget {
  final String role;

  const _PremiumBottomNav({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final primaryItems = _getPrimaryItems(role);
    final moreItems = _getMoreItems(role);
    final primaryRoutes = _getPrimaryRoutes(role);

    int currentIndex = _getCurrentIndex(currentLocation, primaryRoutes);
    if (currentIndex == -1) currentIndex = 0;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.grey200, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // Primary nav items (max 4)
                ...primaryItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = index == currentIndex;
                  return Expanded(
                    child: _PillNavItem(
                      icon: item.icon,
                      activeIcon: item.activeIcon,
                      label: item.label,
                      isSelected: isSelected,
                      onTap: () {
                        if (index < primaryRoutes.length) {
                          context.go(primaryRoutes[index]);
                        }
                      },
                    ),
                  );
                }),
                // "More" overflow item
                if (moreItems.isNotEmpty)
                  Expanded(
                    child: _PillNavItem(
                      icon: Icons.grid_view_outlined,
                      activeIcon: Icons.grid_view,
                      label: 'More',
                      isSelected: false,
                      onTap: () =>
                          _showMoreSheet(context, moreItems, role),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getCurrentIndex(String location, List<String> routes) {
    for (int i = 0; i < routes.length; i++) {
      if (location.startsWith(routes[i])) return i;
    }
    return 0;
  }

  void _showMoreSheet(
    BuildContext context,
    List<_NavItemData> items,
    String role,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MoreSheet(items: items, role: role),
    );
  }

  // ── Item sets per role ────────────────────────────────────────────────────

  List<_NavItemData> _getPrimaryItems(String role) {
    switch (role) {
      case 'super_admin':
      case 'tenant_admin':
      case 'principal':
        return [
          _dashboardItem,
          _studentsItem,
          _attendanceItem,
          _feesItem,
        ];
      case 'teacher':
        return [
          _dashboardItem,
          _attendanceItem,
          _examsItem,
          _messagesItem,
        ];
      case 'student':
        return [
          _dashboardItem,
          _attendanceItem,
          _resultsItem,
          _messagesItem,
        ];
      case 'parent':
        return [
          _dashboardItem,
          _attendanceItem,
          _feesItem,
          _messagesItem,
        ];
      default:
        return [
          _dashboardItem,
          _attendanceItem,
          _resultsItem,
          _messagesItem,
        ];
    }
  }

  List<_NavItemData> _getMoreItems(String role) {
    return const [
      _NavItemData(
          icon: Icons.library_books_outlined,
          activeIcon: Icons.library_books,
          label: 'Library'),
      _NavItemData(
          icon: Icons.directions_bus_outlined,
          activeIcon: Icons.directions_bus,
          label: 'Transport'),
      _NavItemData(
          icon: Icons.apartment_outlined,
          activeIcon: Icons.apartment,
          label: 'Hostel'),
      _NavItemData(
          icon: Icons.restaurant_outlined,
          activeIcon: Icons.restaurant,
          label: 'Canteen'),
    ];
  }

  List<String> _getPrimaryRoutes(String role) {
    switch (role) {
      case 'super_admin':
      case 'tenant_admin':
      case 'principal':
        return [
          AppRoutes.adminDashboard,
          AppRoutes.studentManagement,
          AppRoutes.attendance,
          AppRoutes.fees,
        ];
      case 'teacher':
        return [
          AppRoutes.teacherDashboard,
          AppRoutes.attendance,
          AppRoutes.exams,
          AppRoutes.messages,
        ];
      case 'student':
        return [
          AppRoutes.studentDashboard,
          AppRoutes.attendance,
          AppRoutes.exams,
          AppRoutes.messages,
        ];
      case 'parent':
        return [
          AppRoutes.parentDashboard,
          AppRoutes.attendance,
          AppRoutes.fees,
          AppRoutes.messages,
        ];
      default:
        return [
          AppRoutes.studentDashboard,
          AppRoutes.attendance,
          AppRoutes.exams,
          AppRoutes.messages,
        ];
    }
  }
}

// ─── Pill nav item ─────────────────────────────────────────────────────────────

class _PillNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PillNavItem({
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
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: isSelected
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
              : const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
          ),
          child: isSelected
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(activeIcon, color: AppColors.primary, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                )
              : Icon(icon, color: AppColors.grey400, size: 24),
        ),
      ),
    );
  }
}

// ─── More overflow sheet ───────────────────────────────────────────────────────

class _MoreSheet extends StatelessWidget {
  final List<_NavItemData> items;
  final String role;

  const _MoreSheet({required this.items, required this.role});

  static const _moreRoutes = [
    AppRoutes.library,
    AppRoutes.transport,
    AppRoutes.hostel,
    AppRoutes.canteen,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'More',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey900,
                ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  if (index < _moreRoutes.length) {
                    context.go(_moreRoutes[index]);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(item.icon,
                          color: AppColors.grey700, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Data model ───────────────────────────────────────────────────────────────

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

// ─── Shared nav item constants ────────────────────────────────────────────────

const _dashboardItem = _NavItemData(
  icon: Icons.dashboard_outlined,
  activeIcon: Icons.dashboard,
  label: 'Home',
);
const _attendanceItem = _NavItemData(
  icon: Icons.fact_check_outlined,
  activeIcon: Icons.fact_check,
  label: 'Attendance',
);
const _studentsItem = _NavItemData(
  icon: Icons.people_outlined,
  activeIcon: Icons.people,
  label: 'Students',
);
const _feesItem = _NavItemData(
  icon: Icons.payment_outlined,
  activeIcon: Icons.payment,
  label: 'Fees',
);
const _examsItem = _NavItemData(
  icon: Icons.assignment_outlined,
  activeIcon: Icons.assignment,
  label: 'Exams',
);
const _resultsItem = _NavItemData(
  icon: Icons.bar_chart_outlined,
  activeIcon: Icons.bar_chart,
  label: 'Results',
);
const _messagesItem = _NavItemData(
  icon: Icons.chat_bubble_outline,
  activeIcon: Icons.chat_bubble,
  label: 'Messages',
);

// ─── AI Tutor FAB ─────────────────────────────────────────────────────────────

class _AiTutorFab extends StatelessWidget {
  const _AiTutorFab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'ai_tutor_fab',
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (_) => DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollController) => const TutorChatOverlay(),
          ),
        );
      },
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      mini: true,
      tooltip: 'AI Tutor',
      child: const Icon(Icons.auto_awesome, size: 20),
    );
  }
}
