import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/services/admin_repository.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/summary_card.dart';
import '../../widgets/navigation/admin_sidebar.dart';

/// Dashboard screen with strictly requested summary cards and recent activity tables.
/// No graphs, no charts, no fake analytics.
class DashboardScreen extends StatelessWidget {
  final AdminRepository repository;
  final ValueChanged<AdminNavDestination> onNavigate;
  final ValueChanged<ComplaintModel>? onSelectComplaint;

  const DashboardScreen({
    super.key,
    required this.repository,
    required this.onNavigate,
    this.onSelectComplaint,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final recentComplaints = repository.recentComplaints;
        final recentUsers = repository.recentUsers;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              const Text(
                'Welcome back, Admin',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage campus users, complaints and events from one place.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 24),

              // Summary Cards (Responsive Layout)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1000;
                  final isMedium = constraints.maxWidth >= 600;

                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            title: 'Total Users',
                            value: '${repository.totalUsers}',
                            icon: Icons.people_outline,
                            iconColor: AppColors.primary,
                            iconBgColor: AppColors.primaryLight,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SummaryCard(
                            title: 'Total Complaints',
                            value: '${repository.totalComplaints}',
                            icon: Icons.report_problem_outlined,
                            iconColor: const Color(0xFF6366F1),
                            iconBgColor: const Color(0xFFEEF2FF),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SummaryCard(
                            title: 'Pending Complaints',
                            value: '${repository.pendingComplaints}',
                            icon: Icons.hourglass_top_outlined,
                            iconColor: AppColors.statusPendingText,
                            iconBgColor: AppColors.statusPendingBg,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SummaryCard(
                            title: 'Resolved Complaints',
                            value: '${repository.resolvedComplaints}',
                            icon: Icons.check_circle_outline,
                            iconColor: AppColors.statusResolvedText,
                            iconBgColor: AppColors.statusResolvedBg,
                          ),
                        ),
                      ],
                    );
                  } else if (isMedium) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SummaryCard(
                                title: 'Total Users',
                                value: '${repository.totalUsers}',
                                icon: Icons.people_outline,
                                iconColor: AppColors.primary,
                                iconBgColor: AppColors.primaryLight,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SummaryCard(
                                title: 'Total Complaints',
                                value: '${repository.totalComplaints}',
                                icon: Icons.report_problem_outlined,
                                iconColor: const Color(0xFF6366F1),
                                iconBgColor: const Color(0xFFEEF2FF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: SummaryCard(
                                title: 'Pending Complaints',
                                value: '${repository.pendingComplaints}',
                                icon: Icons.hourglass_top_outlined,
                                iconColor: AppColors.statusPendingText,
                                iconBgColor: AppColors.statusPendingBg,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SummaryCard(
                                title: 'Resolved Complaints',
                                value: '${repository.resolvedComplaints}',
                                icon: Icons.check_circle_outline,
                                iconColor: AppColors.statusResolvedText,
                                iconBgColor: AppColors.statusResolvedBg,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        SummaryCard(
                          title: 'Total Users',
                          value: '${repository.totalUsers}',
                          icon: Icons.people_outline,
                          iconColor: AppColors.primary,
                          iconBgColor: AppColors.primaryLight,
                        ),
                        const SizedBox(height: 12),
                        SummaryCard(
                          title: 'Total Complaints',
                          value: '${repository.totalComplaints}',
                          icon: Icons.report_problem_outlined,
                          iconColor: const Color(0xFF6366F1),
                          iconBgColor: const Color(0xFFEEF2FF),
                        ),
                        const SizedBox(height: 12),
                        SummaryCard(
                          title: 'Pending Complaints',
                          value: '${repository.pendingComplaints}',
                          icon: Icons.hourglass_top_outlined,
                          iconColor: AppColors.statusPendingText,
                          iconBgColor: AppColors.statusPendingBg,
                        ),
                        const SizedBox(height: 12),
                        SummaryCard(
                          title: 'Resolved Complaints',
                          value: '${repository.resolvedComplaints}',
                          icon: Icons.check_circle_outline,
                          iconColor: AppColors.statusResolvedText,
                          iconBgColor: AppColors.statusResolvedBg,
                        ),
                      ],
                    );
                  }
                },
              ),

              const SizedBox(height: 28),

              // Recent Complaints Section
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Complaints',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                onNavigate(AdminNavDestination.complaints),
                            child: const Row(
                              children: [
                                Text('View All Complaints'),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward, size: 14),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        showCheckboxColumn: false,
                        columns: const [
                          DataColumn(label: Text('Complaint ID')),
                          DataColumn(label: Text('Title')),
                          DataColumn(label: Text('Submitted By')),
                          DataColumn(label: Text('Location')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Action')),
                        ],
                        rows: recentComplaints.map((c) {
                          return DataRow(
                            onSelectChanged: (_) {
                              if (onSelectComplaint != null) {
                                onSelectComplaint!(c);
                              }
                            },
                            cells: [
                              DataCell(
                                Text(
                                  c.id,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              DataCell(
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 240),
                                  child: Text(
                                    c.title,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                              DataCell(Text(c.submittedBy)),
                              DataCell(
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 180),
                                  child: Text(
                                    c.location,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(StatusBadge.fromStatus(c.status)),
                              DataCell(
                                Text(
                                  '${c.reportedAt.day.toString().padLeft(2, '0')}/${c.reportedAt.month.toString().padLeft(2, '0')}/${c.reportedAt.year}',
                                ),
                              ),
                              DataCell(
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () {
                                    if (onSelectComplaint != null) {
                                      onSelectComplaint!(c);
                                    }
                                  },
                                  child: const Text('View'),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Recent Users Section
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Users',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                onNavigate(AdminNavDestination.users),
                            child: const Row(
                              children: [
                                Text('View All Users'),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward, size: 14),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Role')),
                          DataColumn(label: Text('Department')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Status')),
                        ],
                        rows: recentUsers.map((u) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 13,
                                      backgroundColor: AppColors.primaryLight,
                                      child: Text(
                                        u.name.isNotEmpty ? u.name[0] : 'U',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      u.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(StatusBadge.fromStatus(u.role)),
                              DataCell(Text(u.department)),
                              DataCell(Text(u.email)),
                              DataCell(StatusBadge.fromStatus(u.status)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
