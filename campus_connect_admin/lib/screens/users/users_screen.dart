import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/services/admin_repository.dart';
import '../../widgets/common/status_badge.dart';

/// Clean, responsive Users table with search and Add User action.
/// Strictly no category filters as requested.
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.repository,
      builder: (context, _) {
        final List<UserModel> displayedUsers =
            widget.repository.searchUsers(_searchQuery);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Action Header
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
                        'Total ${widget.repository.totalUsers} registered students, staff and administrators.',
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
                      // Search field
                      SizedBox(
                        width: 240,
                        height: 40,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search members...',
                            prefixIcon:
                                const Icon(Icons.search, size: 18),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Add User button
                      ElevatedButton.icon(
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('Add User'),
                        onPressed: widget.onAddUser,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Users Table Container
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: displayedUsers.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(48),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.search_off,
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
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Member Code')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Role')),
                            DataColumn(label: Text('Department')),
                            DataColumn(label: Text('Phone')),
                            DataColumn(label: Text('Status')),
                          ],
                          rows: displayedUsers.map((user) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    user.memberCode,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 13,
                                        backgroundColor: AppColors.primaryLight,
                                        child: Text(
                                          user.name.isNotEmpty
                                              ? user.name[0]
                                              : 'U',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        user.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(Text(user.email)),
                                DataCell(StatusBadge.fromStatus(user.role)),
                                DataCell(Text(user.department)),
                                DataCell(Text(user.phone)),
                                DataCell(StatusBadge.fromStatus(user.status)),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
