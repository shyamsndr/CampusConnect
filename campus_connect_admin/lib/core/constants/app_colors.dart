import 'package:flutter/material.dart';

/// App-wide color constants following the clean white + blue college admin design.
class AppColors {
  AppColors._();

  // Core Brand Colors
  static const Color primary = Color(0xFF1769E0);
  static const Color primaryHover = Color(0xFF1358BE);
  static const Color primaryLight = Color(0xFFE8F1FC);

  // Backgrounds & Surface
  static const Color background = Color(0xFFF5F9FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color sidebarBackground = Color(0xFFFFFFFF);

  // Typography
  static const Color textDark = Color(0xFF172033);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);

  // Structural & Borders
  static const Color border = Color(0xFFE3EAF4);
  static const Color borderLight = Color(0xFFEEF3FA);
  static const Color divider = Color(0xFFE3EAF4);

  // Status & Priority Colors (Subtle backgrounds with solid text)
  // Pending
  static const Color statusPendingText = Color(0xFFB45309);
  static const Color statusPendingBg = Color(0xFFFEF3C7);

  // In Progress
  static const Color statusInProgressText = Color(0xFF1D4ED8);
  static const Color statusInProgressBg = Color(0xFFEFF6FF);

  // Resolved / Active / Published
  static const Color statusResolvedText = Color(0xFF047857);
  static const Color statusResolvedBg = Color(0xFFECFDF5);

  // Draft / Inactive
  static const Color statusDraftText = Color(0xFF4B5563);
  static const Color statusDraftBg = Color(0xFFF3F4F6);

  // Priority - High
  static const Color priorityHighText = Color(0xFFB91C1C);
  static const Color priorityHighBg = Color(0xFFFEE2E2);

  // Priority - Medium
  static const Color priorityMediumText = Color(0xFFB45309);
  static const Color priorityMediumBg = Color(0xFFFEF3C7);

  // Priority - Low
  static const Color priorityLowText = Color(0xFF4B5563);
  static const Color priorityLowBg = Color(0xFFF1F5F9);
}
