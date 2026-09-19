import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/admin_repository.dart';

/// Navigation indices for top-level admin pages.
enum AdminNavDestination {
  dashboard,
  users,
  addUser,
  complaints,
  events,
  profile,
}

/// Fixed left sidebar for web/desktop and drawer content for mobile/tablet.
class AdminSidebar extends StatelessWidget {
  final AdminNavDestination currentDestination;
  final ValueChanged<AdminNavDestination> onDestinationSelected;
  final AdminRepository repository;

  const AdminSidebar({
    super.key,
    required this.currentDestination,
    required this.onDestinationSelected,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CampusConnect',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Admin Portal',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Main Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildNavItem(
                  destination: AdminNavDestination.dashboard,
                  title: 'Dashboard',
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  destination: AdminNavDestination.users,
                  title: 'Users',
                  icon: Icons.people_outline,
                  selectedIcon: Icons.people,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  destination: AdminNavDestination.addUser,
                  title: 'Add User',
                  icon: Icons.person_add_outlined,
                  selectedIcon: Icons.person_add,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  destination: AdminNavDestination.complaints,
                  title: 'Complaints',
                  icon: Icons.report_problem_outlined,
                  selectedIcon: Icons.report_problem,
                  badgeCount: repository.pendingComplaints > 0
                      ? repository.pendingComplaints
                      : null,
                ),
                const SizedBox(height: 4),
                _buildNavItem(
                  destination: AdminNavDestination.events,
                  title: 'Events',
                  icon: Icons.event_outlined,
                  selectedIcon: Icons.event,
                ),
              ],
            ),
          ),

          // Bottom Admin Profile snippet
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: InkWell(
              onTap: () =>
                  onDestinationSelected(AdminNavDestination.profile),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary,
                      child: const Icon(
                        Icons.person,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            'Administrator',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.settings_outlined,
                      size: 18,
                      color: AppColors.textGrey,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required AdminNavDestination destination,
    required String title,
    required IconData icon,
    required IconData selectedIcon,
    int? badgeCount,
  }) {
    final isSelected = currentDestination == destination;

    return InkWell(
      onTap: () => onDestinationSelected(destination),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textGrey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textDark,
                ),
              ),
            ),
            if (badgeCount != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.statusPendingBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : AppColors.statusPendingText,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
