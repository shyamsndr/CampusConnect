import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/services/admin_repository.dart';
import '../../widgets/common/status_badge.dart';

/// Authorized Members / Users screen.
///
/// Displays users loaded from Firestore in real time.
/// Supports loading, error, empty, search, and data states.
/// Table stretches to fill the available content width using LayoutBuilder.
class UsersScreen extends StatefulWidget {
  final AdminRepository repository;
  final VoidCallback onAddUser;

  const UsersScreen({
    super.key,
    required this.repository,
    required this.onAddUser,
  });

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── helpers ────────────────────────────────────────────────────────────────

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  // ─── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.repository,
      builder: (context, _) {
        final isLoading = widget.repository.isLoadingUsers;
        final error = widget.repository.usersError;
        final displayedUsers = widget.repository.searchUsers(_searchQuery);
        final totalUsers = widget.repository.totalUsers;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Row ────────────────────────────────────────────────
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Authorized Members',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isLoading
                            ? 'Loading members...'
                            : 'Total $totalUsers registered students, staff and administrators.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Search field — only shown when data is available.
                      if (!isLoading && error == null)
                        SizedBox(
                          width: 240,
                          height: 40,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _searchQuery = value),
                            decoration: InputDecoration(
                              hintText: 'Search members...',
                              prefixIcon: const Icon(Icons.search, size: 18),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: _clearSearch,
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      if (!isLoading && error == null)
                        const SizedBox(width: 12),
                      // Add User button.
                      ElevatedButton.icon(
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('Add User'),
                        onPressed: widget.onAddUser,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Content Area ─────────────────────────────────────────────
              if (isLoading)
                _buildLoadingState()
              else if (error != null)
                _buildErrorState(error)
              else
                _buildTable(displayedUsers),
            ],
          ),
        );
      },
    );
  }

  // ─── Loading state ───────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(strokeWidth: 2.5),
          SizedBox(height: 16),
          Text(
            'Loading members...',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Error state ─────────────────────────────────────────────────────────

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 44,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            onPressed: () => widget.repository.subscribeToUsers(),
          ),
        ],
      ),
    );
  }

  // ─── Table ───────────────────────────────────────────────────────────────

  Widget _buildTable(List<UserModel> users) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: users.isEmpty ? _buildEmptyState() : _buildDataTable(users),
    );
  }

  // ─── Empty state ─────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.people_outline_rounded,
            size: 44,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isEmpty
                ? 'No members registered yet.'
                : 'No members match "$_searchQuery".',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _clearSearch,
              child: const Text('Clear search'),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Responsive data table ───────────────────────────────────────────────

  /// Columns and their relative flex weights.
  static const _columns = [
    ('Member Code', 2),
    ('Name', 3),
    ('Email', 4),
    ('Role', 2),
    ('Department', 3),
    ('Phone', 2),
    ('Status', 2),
  ];

  /// Minimum table width before horizontal scrolling kicks in.
  static const double _minTableWidth = 760;

  Widget _buildDataTable(List<UserModel> users) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use the full available width, but never below the min.
        final tableWidth = constraints.maxWidth > _minTableWidth
            ? constraints.maxWidth
            : _minTableWidth;

        // Compute column widths from flex weights.
        final totalFlex = _columns.fold<int>(0, (sum, col) => sum + col.$2);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header row ───────────────────────────────────────────
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(7),
                    ),
                  ),
                  child: Row(
                    children: _columns.map((col) {
                      final width = (tableWidth * col.$2) / totalFlex;
                      return _HeaderCell(label: col.$1, width: width);
                    }).toList(),
                  ),
                ),

                // ── Divider ──────────────────────────────────────────────
                const Divider(height: 1, color: AppColors.border),

                // ── Data rows ────────────────────────────────────────────
                ...users.asMap().entries.map((entry) {
                  final index = entry.key;
                  final user = entry.value;
                  final isLast = index == users.length - 1;

                  return _buildDataRow(
                    user: user,
                    tableWidth: tableWidth,
                    totalFlex: totalFlex,
                    isLast: isLast,
                    isEven: index.isEven,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataRow({
    required UserModel user,
    required double tableWidth,
    required int totalFlex,
    required bool isLast,
    required bool isEven,
  }) {
    Widget cell(Widget child, int flex) {
      return SizedBox(
        width: (tableWidth * flex) / totalFlex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: child,
        ),
      );
    }

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Member Code
        cell(
          Text(
            user.memberCode.isNotEmpty ? user.memberCode : '—',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: AppColors.textDark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          2,
        ),
        // Name (avatar + text)
        cell(
          Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  user.name.isNotEmpty ? user.name : '—',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          3,
        ),
        // Email
        cell(
          Text(
            user.email.isNotEmpty ? user.email : '—',
            style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            overflow: TextOverflow.ellipsis,
          ),
          4,
        ),
        // Role badge
        cell(StatusBadge.fromStatus(user.role), 2),
        // Department
        cell(
          Text(
            user.department.isNotEmpty ? user.department : '—',
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
          3,
        ),
        // Phone
        cell(
          Text(
            user.phone.isNotEmpty ? user.phone : '—',
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
          2,
        ),
        // Status badge
        cell(StatusBadge.fromStatus(user.status), 2),
      ],
    );

    return Column(
      children: [
        Container(
          color: isEven ? AppColors.surface : AppColors.background,
          child: row,
        ),
        if (!isLast) const Divider(height: 1, color: AppColors.borderLight),
      ],
    );
  }
}

// ─── Header cell widget ──────────────────────────────────────────────────────

class _HeaderCell extends StatelessWidget {
  final String label;
  final double width;

  const _HeaderCell({required this.label, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textGrey,
            letterSpacing: 0.3,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
