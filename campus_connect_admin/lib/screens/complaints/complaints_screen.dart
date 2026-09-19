import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/services/admin_repository.dart';
import '../../widgets/common/status_badge.dart';

/// Screen listing all campus reported complaints in a clean, professional table.
class ComplaintsScreen extends StatefulWidget {
  final AdminRepository repository;
  final ValueChanged<ComplaintModel> onSelectComplaint;

  const ComplaintsScreen({
    super.key,
    required this.repository,
    required this.onSelectComplaint,
  });

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.repository,
      builder: (context, _) {
        final allComplaints = widget.repository.complaints;
        final filteredComplaints = _statusFilter == 'All'
            ? allComplaints
            : allComplaints.where((c) => c.status == _statusFilter).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header & Status Filter Tabs
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
                        'Reported Complaints',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Review campus maintenance, facility and IT issues submitted by students and staff.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                  // Status Segmented Filter
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: ['All', 'Pending', 'In Progress', 'Resolved']
                          .map((status) {
                        final isSelected = _statusFilter == status;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _statusFilter = status;
                            });
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryLight
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textDark,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Table Container
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: filteredComplaints.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(48),
                        alignment: Alignment.center,
                        child: Text(
                          'No complaints found under "$_statusFilter".',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textGrey,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          showCheckboxColumn: false,
                          columns: const [
                            DataColumn(label: Text('Issue ID')),
                            DataColumn(label: Text('Title')),
                            DataColumn(label: Text('Submitted By')),
                            DataColumn(label: Text('Location')),
                            DataColumn(label: Text('Priority')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Reported At')),
                            DataColumn(label: Text('Action')),
                          ],
                          rows: filteredComplaints.map((c) {
                            return DataRow(
                              onSelectChanged: (_) =>
                                  widget.onSelectComplaint(c),
                              cells: [
                                DataCell(
                                  Text(
                                    c.id,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 220),
                                    child: Text(
                                      c.title,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        c.submittedBy,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        c.submittedByRole,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 180),
                                    child: Text(
                                      c.location,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(StatusBadge.fromStatus(c.priority)),
                                DataCell(StatusBadge.fromStatus(c.status)),
                                DataCell(
                                  Text(
                                    '${c.reportedAt.day.toString().padLeft(2, '0')}/${c.reportedAt.month.toString().padLeft(2, '0')}/${c.reportedAt.year}',
                                  ),
                                ),
                                DataCell(
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () =>
                                        widget.onSelectComplaint(c),
                                    child: const Text('View'),
                                  ),
                                ),
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
