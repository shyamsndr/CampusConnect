import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/admin_repository.dart';

/// Clean top bar header for the content area.
class AdminTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onMenuPressed;
  final Widget? trailing;
  final AdminRepository repository;
  final VoidCallback? onProfilePressed;

  const AdminTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onMenuPressed,
    this.trailing,
    required this.repository,
    this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (onMenuPressed != null) ...[
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textDark),
              onPressed: onMenuPressed,
              tooltip: 'Open Menu',
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            trailing!,
            const SizedBox(width: 16),
          ],
          // Admin Profile Pill / Quick Menu
          InkWell(
            onTap: onProfilePressed,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      repository.adminName.isNotEmpty
                          ? repository.adminName[0]
                          : 'A',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        repository.adminName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const Text(
                        'Administrator',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: AppColors.textGrey,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
