import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';

class AffectedUsersScreen extends StatelessWidget {
  final List<AffectedUser> affectedUsers;
  final String complaintId;
  final VoidCallback onBack;

  const AffectedUsersScreen({
    super.key,
    required this.affectedUsers,
    required this.complaintId,
    required this.onBack,
  });

  void _showImageOverlay(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.black.withValues(alpha: 0.9),
          body: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 24,
                right: 24,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header (Back & Title) ──────────────────────────────────
              Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back to Details',
                    color: AppColors.textDark,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Linked Reports: $complaintId',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // ── Main Content Area ──────────────────────────────────────
              ...affectedUsers.map((user) => _buildReportCard(context, user)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, AffectedUser user) {
    final date =
        '${user.reportDate.day.toString().padLeft(2, '0')}/'
        '${user.reportDate.month.toString().padLeft(2, '0')}/'
        '${user.reportDate.year}';
    final time =
        '${user.reportDate.hour.toString().padLeft(2, '0')}:'
        '${user.reportDate.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  user.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${user.type} • ${user.department}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                user.memberCode,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // Report Content Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  user.reportTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$date at $time',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user.reportDescription,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textDark,
              height: 1.5,
            ),
          ),

          if (user.photoUrl != null) ...[
            const SizedBox(height: 20),
            InkWell(
              onTap: () => _showImageOverlay(context, user.photoUrl!.replaceAll('10.0.2.2', '127.0.0.1')),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  user.photoUrl!.replaceAll('10.0.2.2', '127.0.0.1'),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FBFE),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 32, color: AppColors.textLight),
                        SizedBox(height: 8),
                        Text('Image failed to load', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
                      ],
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FBFE),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
