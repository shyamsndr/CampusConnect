import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/admin_repository.dart';

/// Clean, simple Admin Profile page displaying credentials and logout action.
/// Strictly avoids unnecessary account settings.
class AdminProfileScreen extends StatelessWidget {
  final AdminRepository repository;
  final VoidCallback onLogout;

  const AdminProfileScreen({
    super.key,
    required this.repository,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Admin Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Campus administration credentials and active session info.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 24),

              // Profile Card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            repository.adminName.isNotEmpty
                                ? repository.adminName[0]
                                : 'A',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                repository.adminName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                repository.adminRole,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.statusResolvedBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Active Session',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.statusResolvedText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    const Divider(height: 1),
                    const SizedBox(height: 20),

                    // Details
                    _buildProfileField(
                      label: 'Administrator Name',
                      value: repository.adminName,
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildProfileField(
                      label: 'Email Address',
                      value: repository.adminEmail,
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildProfileField(
                      label: 'Assigned Role',
                      value: repository.adminRole,
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildProfileField(
                      label: 'Access Scope',
                      value:
                          'Full Administrator (Users, Complaints, Events, Approvals)',
                      icon: Icons.security_outlined,
                    ),

                    const SizedBox(height: 32),
                    const Divider(height: 1),
                    const SizedBox(height: 24),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout,
                            size: 18, color: Colors.redAccent),
                        label: const Text(
                          'Sign Out of Admin Portal',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _confirmLogout(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textGrey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Confirm Sign Out'),
          content: const Text(
            'Are you sure you want to log out of the CampusConnect Admin Portal?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                repository.logout();
                onLogout();
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }
}
