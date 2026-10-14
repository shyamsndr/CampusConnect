import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/services/admin_repository.dart';
import '../../widgets/common/status_badge.dart';

/// Full screen detail view for a specific complaint from the admin side.
/// Phase 1 — connected to real Firestore data via AdminRepository streams.
class ComplaintDetailsScreen extends StatefulWidget {
  final ComplaintModel complaint;
  final AdminRepository repository;
  final VoidCallback onBack;
  final void Function(List<AffectedUser>, String) onViewAffectedUsers;

  const ComplaintDetailsScreen({
    super.key,
    required this.complaint,
    required this.repository,
    required this.onBack,
    required this.onViewAffectedUsers,
  });

  @override
  State<ComplaintDetailsScreen> createState() => _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState extends State<ComplaintDetailsScreen> {
  void _handleStatusChange(String currentStatus, String newStatus) {
    if (currentStatus == newStatus) return;
    // Guard: do not allow reopening a Closed complaint.
    if (currentStatus == 'Closed') return;

    widget.repository.updateComplaintStatus(widget.complaint.id, newStatus);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status updated to $newStatus successfully.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade800,
        duration: const Duration(seconds: 2),
      ),
    );
  }

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
    // Always use the latest data from the in-memory repository snapshot
    // (kept up to date by the ISSUES realtime stream) so status changes
    // are reflected immediately without any local state.
    final complaint =
        widget.repository.getComplaintById(widget.complaint.id) ??
        widget.complaint;
    final currentStatus = complaint.status;

    UserModel? reporter;
    try {
      reporter = widget.repository.users.firstWhere((u) => u.uid == complaint.submittedBy);
    } catch (_) {}

    final reporterName = reporter?.name ?? complaint.submittedBy;
    final reporterRole = reporter != null && reporter.memberCode.isNotEmpty
        ? '${reporter.role} - ${reporter.memberCode}'
        : complaint.submittedByRole;

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
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back to List',
                    color: AppColors.textDark,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Issue Details: ${complaint.id}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  StatusBadge.fromStatus(complaint.status),
                ],
              ),
              const SizedBox(height: 24),

              // ── Main Content Area ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      complaint.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Meta Info Grid
                    Wrap(
                      spacing: 40,
                      runSpacing: 20,
                      children: [
                        _buildMetaItem(
                          icon: Icons.person_outline,
                          label: 'Primary Reporter',
                          value: '$reporterName${reporterRole.isNotEmpty ? ' ($reporterRole)' : ''}',
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

                    const SizedBox(height: 32),
                    const Divider(height: 1),
                    const SizedBox(height: 24),

                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      complaint.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textDark,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Affected Users Section
                    const Text(
                      'Affected Users',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<List<AffectedUser>>(
                      stream: widget.repository.getAffectedUsers(complaint.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                        }
                        return _buildAffectedUsersCompact(snapshot.data ?? [], complaint.id);
                      },
                    ),

                    const SizedBox(height: 32),

                    // Photo Attachment Area
                    const Text(
                      'Photo Attachment',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (complaint.photoUrl != null)
                      InkWell(
                        onTap: () => _showImageOverlay(context, complaint.photoUrl!.replaceAll('10.0.2.2', '127.0.0.1')),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            complaint.photoUrl!.replaceAll('10.0.2.2', '127.0.0.1'),
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildNoPhotoPlaceholder(),
                          ),
                        ),
                      )
                    else
                      _buildNoPhotoPlaceholder(),

                    const SizedBox(height: 32),
                    const Divider(height: 1),
                    const SizedBox(height: 24),

                    // Status History Timeline
                    const Text(
                      'Status History',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<List<AdminComplaintStatusEntry>>(
                      stream: widget.repository.getComplaintStatusHistory(complaint.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                        }
                        return _buildStatusTimeline(snapshot.data ?? []);
                      },
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
                      'Change the current resolution phase. This will update the status for all affected users.',
                      style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        _buildStatusOptionButton(
                          currentStatus: currentStatus,
                          status: 'Open',
                          icon: Icons.hourglass_top_outlined,
                          activeColor: const Color(0xFFB45309),
                          activeBg: const Color(0xFFFEF3C7),
                        ),
                        _buildStatusOptionButton(
                          currentStatus: currentStatus,
                          status: 'In Progress',
                          icon: Icons.engineering_outlined,
                          activeColor: AppColors.statusInProgressText,
                          activeBg: AppColors.statusInProgressBg,
                        ),
                        _buildStatusOptionButton(
                          currentStatus: currentStatus,
                          status: 'Closed',
                          icon: Icons.check_circle_outline,
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
        Icon(icon, size: 18, color: AppColors.textGrey),
        const SizedBox(width: 8),
        Column(
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
            const SizedBox(height: 4),
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
      ],
    );
  }

  Widget _buildAffectedUsersCompact(List<AffectedUser> users, String complaintId) {
    if (users.isEmpty) {
      return const Text(
        'No additional users affected.',
        style: TextStyle(fontSize: 14, color: AppColors.textGrey),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
        title: Text(
          '${users.length} affected users',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        trailing: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'View',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
          ],
        ),
        onTap: () {
          widget.onViewAffectedUsers(users, complaintId);
        },
      ),
      ),
    );
  }

  Widget _buildStatusTimeline(List<AdminComplaintStatusEntry> history) {
    if (history.isEmpty) {
      return const Text(
        'No status history available.',
        style: TextStyle(fontSize: 14, color: AppColors.textGrey),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        final isLast = index == history.length - 1;

        final date =
            '${entry.timestamp.day.toString().padLeft(2, '0')}/'
            '${entry.timestamp.month.toString().padLeft(2, '0')}/'
            '${entry.timestamp.year}';
        final time =
            '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
            '${entry.timestamp.minute.toString().padLeft(2, '0')}';

        Color dotColor;
        switch (entry.status) {
          case 'Open':
            dotColor = const Color(0xFFB45309);
            break;
          case 'In Progress':
            dotColor = AppColors.statusInProgressText;
            break;
          case 'Closed':
            dotColor = AppColors.statusResolvedText;
            break;
          default:
            dotColor = AppColors.textGrey;
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppColors.border,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: dotColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$date at $time',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.note,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoPhotoPlaceholder() {
    return Container(
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
          Icon(
            Icons.image_not_supported_outlined,
            size: 36,
            color: AppColors.textLight,
          ),
          SizedBox(height: 8),
          Text(
            'No photo was attached for this issue.',
            style: TextStyle(fontSize: 13, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOptionButton({
    required String currentStatus,
    required String status,
    required IconData icon,
    required Color activeColor,
    required Color activeBg,
  }) {
    final isSelected = currentStatus == status;
    // Buttons are disabled when the complaint is already Closed.
    final isClosed = currentStatus == 'Closed';
    final effectiveColor = isClosed ? AppColors.textGrey : (isSelected ? activeColor : AppColors.textGrey);
    final effectiveBg    = isClosed ? AppColors.surface  : (isSelected ? activeBg    : AppColors.surface);

    return InkWell(
      onTap: isClosed ? null : () => _handleStatusChange(currentStatus, status),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected && !isClosed ? activeColor : AppColors.border,
            width: isSelected && !isClosed ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: effectiveColor),
            const SizedBox(width: 8),
            Text(
              status,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isClosed ? AppColors.textGrey : (isSelected ? activeColor : AppColors.textDark),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check, size: 16, color: effectiveColor),
            ],
          ],
        ),
      ),
    );
  }
}
