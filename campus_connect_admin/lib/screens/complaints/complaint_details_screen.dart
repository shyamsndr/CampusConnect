import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/services/admin_repository.dart';
import '../../widgets/common/status_badge.dart';

/// Screen displaying comprehensive details of a campus complaint.
/// Allows the administrator to update the complaint status (Pending, In Progress, Resolved).
class ComplaintDetailsScreen extends StatefulWidget {
  final ComplaintModel complaint;
  final AdminRepository repository;
  final VoidCallback onBack;

  const ComplaintDetailsScreen({
    super.key,
    required this.complaint,
    required this.repository,
    required this.onBack,
  });

  @override
  State<ComplaintDetailsScreen> createState() => _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState extends State<ComplaintDetailsScreen> {
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.complaint.status;
  }

  void _handleStatusChange(String newStatus) {
    setState(() {
      _currentStatus = newStatus;
    });
    widget.repository.updateComplaintStatus(widget.complaint.id, newStatus);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Complaint ${widget.complaint.id} status updated to "$newStatus".',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.statusResolvedText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final complaint = widget.repository.getComplaintById(widget.complaint.id) ??
        widget.complaint;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Back Action & ID Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.textDark),
                    onPressed: widget.onBack,
                    tooltip: 'Back to Complaints',
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            complaint.id,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          StatusBadge.fromStatus(complaint.priority),
                          const SizedBox(width: 8),
                          StatusBadge.fromStatus(complaint.status),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Complaint Details & Action',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Main Details Card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text(
                      complaint.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Key Meta Grid
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Wrap(
                        spacing: 32,
                        runSpacing: 16,
                        children: [
                          _buildMetaItem(
                            icon: Icons.person_outline,
                            label: 'Submitted By',
                            value:
                                '${complaint.submittedBy} (${complaint.submittedByRole})',
                          ),
                          _buildMetaItem(
                            icon: Icons.location_on_outlined,
                            label: 'Location',
                            value: complaint.location,
                          ),
                          _buildMetaItem(
                            icon: Icons.calendar_today_outlined,
                            label: 'Reported Date',
                            value:
                                '${complaint.reportedAt.day.toString().padLeft(2, '0')}/${complaint.reportedAt.month.toString().padLeft(2, '0')}/${complaint.reportedAt.year} at ${complaint.reportedAt.hour.toString().padLeft(2, '0')}:${complaint.reportedAt.minute.toString().padLeft(2, '0')}',
                          ),
                          _buildMetaItem(
                            icon: Icons.flag_outlined,
                            label: 'Priority',
                            value: complaint.priority,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        complaint.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textDark,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Photo Attachment Area
                    const Text(
                      'Photo Attachment',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FBFE),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.border,
                          style: BorderStyle.solid,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            complaint.photoUrl != null
                                ? Icons.image
                                : Icons.image_not_supported_outlined,
                            size: 36,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            complaint.photoUrl != null
                                ? 'Photo attached: ${complaint.photoUrl}'
                                : 'No photo was attached by the reporter.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    const Divider(height: 1),
                    const SizedBox(height: 24),

                    // Status Update Action Section
                    const Text(
                      'Update Complaint Status',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Change the current resolution phase to notify the reporting student or staff member.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        _buildStatusOptionButton(
                          status: 'Pending',
                          icon: Icons.hourglass_top_outlined,
                          isSelected: _currentStatus == 'Pending',
                          activeColor: AppColors.statusPendingText,
                          activeBg: AppColors.statusPendingBg,
                        ),
                        _buildStatusOptionButton(
                          status: 'In Progress',
                          icon: Icons.engineering_outlined,
                          isSelected: _currentStatus == 'In Progress',
                          activeColor: AppColors.statusInProgressText,
                          activeBg: AppColors.statusInProgressBg,
                        ),
                        _buildStatusOptionButton(
                          status: 'Resolved',
                          icon: Icons.check_circle_outline,
                          isSelected: _currentStatus == 'Resolved',
                          activeColor: AppColors.statusResolvedText,
                          activeBg: AppColors.statusResolvedBg,
                        ),
                      ],
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

  Widget _buildMetaItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textGrey),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusOptionButton({
    required String status,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required Color activeBg,
  }) {
    return InkWell(
      onTap: () => _handleStatusChange(status),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? activeColor : AppColors.textGrey,
            ),
            const SizedBox(width: 8),
            Text(
              status,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : AppColors.textDark,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check, size: 16, color: activeColor),
            ],
          ],
        ),
      ),
    );
  }
}
