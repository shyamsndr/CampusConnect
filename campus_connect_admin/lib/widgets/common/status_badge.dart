import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Reusable status badge with subtle background and crisp text.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color? textColor;
  final Color? backgroundColor;

  const StatusBadge({
    super.key,
    required this.label,
    this.textColor,
    this.backgroundColor,
  });

  factory StatusBadge.fromStatus(String status) {
    Color text;
    Color bg;

    switch (status.toLowerCase()) {
      case 'pending':
        text = AppColors.statusPendingText;
        bg = AppColors.statusPendingBg;
        break;
      case 'in progress':
      case 'inprogress':
        text = AppColors.statusInProgressText;
        bg = AppColors.statusInProgressBg;
        break;
      case 'resolved':
      case 'published':
      case 'active':
        text = AppColors.statusResolvedText;
        bg = AppColors.statusResolvedBg;
        break;
      case 'draft':
      case 'inactive':
        text = AppColors.statusDraftText;
        bg = AppColors.statusDraftBg;
        break;
      case 'high':
        text = AppColors.priorityHighText;
        bg = AppColors.priorityHighBg;
        break;
      case 'medium':
        text = AppColors.priorityMediumText;
        bg = AppColors.priorityMediumBg;
        break;
      case 'low':
        text = AppColors.priorityLowText;
        bg = AppColors.priorityLowBg;
        break;
      case 'student':
        text = const Color(0xFF1D4ED8);
        bg = const Color(0xFFEFF6FF);
        break;
      case 'staff':
        text = const Color(0xFF7C3AED);
        bg = const Color(0xFFF5F3FF);
        break;
      case 'admin':
        text = const Color(0xFF0F766E);
        bg = const Color(0xFFF0FDFA);
        break;
      default:
        text = AppColors.textGrey;
        bg = const Color(0xFFF3F4F6);
    }

    return StatusBadge(
      label: status,
      textColor: text,
      backgroundColor: bg,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? AppColors.textDark,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
