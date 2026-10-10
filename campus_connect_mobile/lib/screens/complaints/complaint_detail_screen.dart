import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/issue_model.dart';
import '../../core/models/issue_status_history_model.dart';
import '../../core/services/complaint_service.dart';
import '../../widgets/complaints/status_chip.dart';

/// Shows the full detail of a single user complaint including
/// complaint info, optional photo, and a vertical status timeline.
class ComplaintDetailScreen extends StatefulWidget {
  final IssueModel complaint;

  const ComplaintDetailScreen({super.key, required this.complaint});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  final ComplaintService _complaintService = ComplaintService();

  @override
  Widget build(BuildContext context) {
    final complaint = widget.complaint;
    final createdDate =
        '${complaint.createdAt.day.toString().padLeft(2, '0')}/'
        '${complaint.createdAt.month.toString().padLeft(2, '0')}/'
        '${complaint.createdAt.year}';

    final createdTime =
        '${complaint.createdAt.hour.toString().padLeft(2, '0')}:'
        '${complaint.createdAt.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
            color: AppColors.textDark,
          ),
        ),
        title: const Text(
          'Complaint Details',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Complaint Image Placeholder ──────────────────────
                _buildImageSection(),
  
                const SizedBox(height: 20),
  
                // ── Complaint Info Card ──────────────────────────────
                _buildInfoCard(
                  context,
                  createdDate: createdDate,
                  createdTime: createdTime,
                ),
  
                const SizedBox(height: 20),
  
                // ── Description Card ─────────────────────────────────
                _buildDescriptionCard(),
  
                const SizedBox(height: 20),
  
                // ── Status History Timeline ───────────────────────────
                _buildStatusTimeline(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: widget.complaint.primaryImageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.network(
                widget.complaint.primaryImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_outlined, size: 38, color: AppColors.textGrey),
                      SizedBox(height: 8),
                      Text('Error loading photo', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                    ],
                  );
                },
              ),
            )
          : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 38,
                  color: AppColors.textGrey,
                ),
                SizedBox(height: 8),
                Text(
                  'No photo attached',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String createdDate,
    required String createdTime,
  }) {
    final complaint = widget.complaint;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
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
          // Title + Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  complaint.title,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              StatusChip(status: complaint.status),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEF3FA)),
          const SizedBox(height: 16),

          // Meta items
          _buildMetaRow(
            icon: Icons.tag_outlined,
            label: 'Complaint ID',
            value: complaint.issueId,
          ),
          const SizedBox(height: 12),
          _buildMetaRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: complaint.location,
          ),
          const SizedBox(height: 12),
          _buildMetaRow(
            icon: Icons.calendar_today_outlined,
            label: 'Submitted On',
            value: '$createdDate at $createdTime',
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textGrey),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textGrey,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
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
          const Text(
            'Description',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.complaint.description,
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    return StreamBuilder<List<IssueStatusHistoryModel>>(
      stream: _complaintService.getIssueStatusHistory(widget.complaint.issueId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading history: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
          );
        }

        final history = snapshot.data ?? [];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderGrey),
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
              const Text(
                'Status History',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              if (history.isEmpty)
                const Text('No status history available.', style: TextStyle(color: AppColors.textGrey, fontSize: 13))
              else
                ...List.generate(history.length, (index) {
                  final entry = history[index];
                  final isLast = index == history.length - 1;
                  return _buildTimelineEntry(entry, isLast: isLast);
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineEntry(
    IssueStatusHistoryModel entry, {
    required bool isLast,
  }) {
    final config = _timelineConfig(entry.newStatus);

    final date =
        '${entry.changedAt.day.toString().padLeft(2, '0')}/'
        '${entry.changedAt.month.toString().padLeft(2, '0')}/'
        '${entry.changedAt.year}';

    final hour = entry.changedAt.hour;
    final minute = entry.changedAt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final time = '$hour12:$minute $period';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: config.dotBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(config.icon, size: 16, color: config.dotColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.borderGrey,
                  ),
                ),
            ],
          ),

          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Text(
                    entry.newStatus.toUpperCase(),
                    style: TextStyle(
                      color: config.dotColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$date $time',
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.displayNote,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _TimelineConfig _timelineConfig(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return _TimelineConfig(
          dotColor: const Color(0xFFB45309),
          dotBackground: const Color(0xFFFEF3C7),
          icon: Icons.hourglass_top_outlined,
        );
      case 'in progress':
        return _TimelineConfig(
          dotColor: const Color(0xFF1D4ED8),
          dotBackground: const Color(0xFFEFF6FF),
          icon: Icons.engineering_outlined,
        );
      case 'closed':
        return _TimelineConfig(
          dotColor: const Color(0xFF047857),
          dotBackground: const Color(0xFFECFDF5),
          icon: Icons.check_circle_outline,
        );
      default:
        return _TimelineConfig(
          dotColor: AppColors.textGrey,
          dotBackground: AppColors.borderGrey,
          icon: Icons.info_outline,
        );
    }
  }
}

class _TimelineConfig {
  final Color dotColor;
  final Color dotBackground;
  final IconData icon;

  _TimelineConfig({
    required this.dotColor,
    required this.dotBackground,
    required this.icon,
  });
}
