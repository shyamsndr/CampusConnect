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

        // Build a UID -> display name map from the already-loaded users list.
        // This reuses the existing realtime USERS stream — no extra Firestore reads.
        final Map<String, String> userNames = {
          for (final u in repository.users)
            if (u.uid.isNotEmpty) u.uid: u.name,
        };

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                style: TextStyle(fontSize: 14, color: AppColors.textGrey),
              ),
              const SizedBox(height: 24),

              // -- Summary Cards --
              // All four values come from AdminRepository realtime Firestore listeners.
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  final isMedium = constraints.maxWidth >= 560;

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
                        const SizedBox(width: 14),
                        Expanded(
                          child: SummaryCard(
                            title: 'Total Complaints',
                            value: '${repository.totalComplaints}',
                            icon: Icons.report_problem_outlined,
                            iconColor: const Color(0xFF6366F1),
                            iconBgColor: const Color(0xFFEEF2FF),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: SummaryCard(
                            title: 'Pending Complaints',
                            value: '${repository.pendingComplaints}',
                            icon: Icons.hourglass_top_outlined,
                            iconColor: AppColors.statusPendingText,
                            iconBgColor: AppColors.statusPendingBg,
                          ),
                        ),
                        const SizedBox(width: 14),
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
                            const SizedBox(width: 14),
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
                        const SizedBox(height: 14),
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
                            const SizedBox(width: 14),
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

              // -- Recent Complaints --
              _SectionCard(
                title: 'Recent Complaints',
                actionLabel: 'View All Complaints',
                onAction: () => onNavigate(AdminNavDestination.complaints),
                child: recentComplaints.isEmpty
                    ? _EmptyRow(
                        loading: repository.isLoadingComplaints,
                        error: repository.complaintsError,
                        emptyText: 'No complaints yet.',
                      )
                    : _FullWidthTable(
                        tableBuilder: (minWidth) => DataTable(
                          showCheckboxColumn: false,
                          columnSpacing: 20,
                          horizontalMargin: 16,
                          dataRowMinHeight: 44,
                          dataRowMaxHeight: 52,
                          headingRowHeight: 44,
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
                                    c.id.length > 10
                                        ? c.id.substring(0, 10)
                                        : c.id,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minWidth: 140,
                                      maxWidth: 300,
                                    ),
                                    child: Text(
                                      c.title,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                 DataCell(
                                   SizedBox(
                                     width: 130,
                                     child: Text(
                                       userNames[c.submittedBy] ?? 'Unknown User',
                                       overflow: TextOverflow.ellipsis,
                                     ),
                                   ),
                                 ),
                                DataCell(
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      c.location,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(StatusBadge.fromStatus(c.status)),
                                DataCell(
                                  Text(
                                    _formatDate(c.reportedAt),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                DataCell(
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
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
              ),

              const SizedBox(height: 24),

              // -- Recent Users --
              _SectionCard(
                title: 'Recent Users',
                actionLabel: 'View All Users',
                onAction: () => onNavigate(AdminNavDestination.users),
                child: recentUsers.isEmpty
                    ? _EmptyRow(
                        loading: repository.isLoadingUsers,
                        error: repository.usersError,
                        emptyText: 'No users yet.',
                      )
                    : _FullWidthTable(
                        tableBuilder: (minWidth) => DataTable(
                          showCheckboxColumn: false,
                          columnSpacing: 20,
                          horizontalMargin: 16,
                          dataRowMinHeight: 44,
                          dataRowMaxHeight: 52,
                          headingRowHeight: 44,
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
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(StatusBadge.fromStatus(u.role)),
                                DataCell(Text(u.department)),
                                DataCell(
                                  SizedBox(
                                    width: 200,
                                    child: Text(
                                      u.email,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(StatusBadge.fromStatus(u.status)),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }
}

// ---------------------------------------------------------------------------
// Shared section card container
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                TextButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  label: Text(actionLabel),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full-width table wrapper
// Uses LayoutBuilder so the DataTable fills the card width on desktop and
// falls back to horizontal scroll on small screens.
// ---------------------------------------------------------------------------

class _FullWidthTable extends StatelessWidget {
  final DataTable Function(double minWidth) tableBuilder;

  const _FullWidthTable({required this.tableBuilder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final minWidth = available.isFinite ? available : 700.0;
        final table = tableBuilder(minWidth);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: minWidth),
            child: table,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Loading / empty / error placeholder row
// ---------------------------------------------------------------------------

class _EmptyRow extends StatelessWidget {
  final bool loading;
  final String? error;
  final String emptyText;

  const _EmptyRow({
    required this.loading,
    required this.error,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final message = loading
        ? 'Loading\u2026'
        : error != null
            ? error!
            : emptyText;
    final color =
        error != null ? AppColors.statusPendingText : AppColors.textGrey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: color, fontSize: 14),
        ),
      ),
    );
  }
}
