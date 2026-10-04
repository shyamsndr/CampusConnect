import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Reusable status chip for complaint status display.
class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: config.textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _StatusConfig _statusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return const _StatusConfig(
          background: Color(0xFFFEF3C7),
          textColor: Color(0xFFB45309),
        );
      case 'in progress':
        return const _StatusConfig(
          background: Color(0xFFEFF6FF),
          textColor: Color(0xFF1D4ED8),
        );
      case 'closed':
        return const _StatusConfig(
          background: Color(0xFFECFDF5),
          textColor: Color(0xFF047857),
        );
      default:
        return _StatusConfig(
          background: AppColors.borderGrey,
          textColor: AppColors.textGrey,
        );
    }
  }
}

class _StatusConfig {
  final Color background;
  final Color textColor;

  const _StatusConfig({required this.background, required this.textColor});
}
