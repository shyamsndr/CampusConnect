import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/services/admin_repository.dart';
import '../../widgets/common/status_badge.dart';

/// Admin screen listing all CLOSED campus issues.
///
/// Phase 0 — uses static mock data only.
class ClosedComplaintsScreen extends StatefulWidget {
  final AdminRepository repository;
  final ValueChanged<ComplaintModel> onSelectComplaint;

  const ClosedComplaintsScreen({
    super.key,
    required this.repository,
    required this.onSelectComplaint,
  });

  @override
  State<ClosedComplaintsScreen> createState() => _ClosedComplaintsScreenState();
}

class _ClosedComplaintsScreenState extends State<ClosedComplaintsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _priorityFilter = 'All';
  String _sortOrder = 'Newest First';

  final List<String> _priorityOptions = ['All', 'High', 'Medium', 'Low'];
  final List<String> _sortOptions = [
    'Newest First',
    'Oldest First',
    'Priority High → Low',
    'Priority Low → High',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _priorityWeight(String priority) {
    switch (priority) {
      case 'High':
        return 3;
      case 'Medium':
        return 2;
      case 'Low':
        return 1;
      default:
        return 0;
    }
  }

  List<ComplaintModel> _applyFilters(List<ComplaintModel> source) {
    var list = source.where((c) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!c.title.toLowerCase().contains(q) &&
            !c.location.toLowerCase().contains(q) &&
            !c.id.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (_priorityFilter != 'All' && c.priority != _priorityFilter) {
        return false;
      }
      return true;
    }).toList();

    switch (_sortOrder) {
      case 'Newest First':
        list.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
        break;
      case 'Oldest First':
        list.sort((a, b) => a.reportedAt.compareTo(b.reportedAt));
        break;
      case 'Priority High → Low':
        list.sort(
          (a, b) => _priorityWeight(b.priority).compareTo(
            _priorityWeight(a.priority),
          ),
        );
        break;
      case 'Priority Low → High':
        list.sort(
          (a, b) => _priorityWeight(a.priority).compareTo(
            _priorityWeight(b.priority),
          ),
        );
        break;
    }

    return list;
  }

  /// Returns the closing date from the status history (last 'Closed' entry).
  DateTime _closedDate(ComplaintModel c) {
    try {
      return c.statusHistory
          .lastWhere((e) => e.status == 'Closed')
          .timestamp;
    } catch (_) {
      return c.reportedAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.repository,
      builder: (context, _) {
        final closedIssues = widget.repository.closedComplaints;
        final filtered = _applyFilters(closedIssues);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(closedIssues.length),
              const SizedBox(height: 20),
              _buildControlsBar(),
              const SizedBox(height: 16),
              _buildTable(filtered),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(int total) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Closed Complaints',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Resolved and closed campus issues. These have been fully addressed by the maintenance team.',
                style: TextStyle(fontSize: 13, color: AppColors.textGrey),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$total Closed',
            style: const TextStyle(
              color: Color(0xFF047857),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlsBar() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          height: 38,
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: 'Search closed complaints…',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: AppColors.textGrey,
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 18,
                color: AppColors.textGrey,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        _buildDropdown(
          value: _priorityFilter,
          items: _priorityOptions,
          onChanged: (v) => setState(() => _priorityFilter = v!),
          hint: 'Priority',
        ),
        _buildDropdown(
          value: _sortOrder,
          items: _sortOptions,
          onChanged: (v) => setState(() => _sortOrder = v!),
          hint: 'Sort',
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.unfold_more, size: 16, color: AppColors.textGrey),
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textDark,
          fontFamily: 'Roboto',
        ),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
      ),
    );
  }

  Widget _buildTable(List<ComplaintModel> complaints) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: complaints.isEmpty
          ? Container(
              padding: const EdgeInsets.all(48),
              alignment: Alignment.center,
              child: const Text(
                'No closed complaints match your filters.',
                style: TextStyle(fontSize: 14, color: AppColors.textGrey),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      showCheckboxColumn: false,
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF8FAFC),
                ),
                dividerThickness: 1,
                columns: const [
                  DataColumn(
                    label: Text(
                      '#',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Title',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Priority',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Affected',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Closed Date',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Action',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                ],
                rows: List.generate(complaints.length, (i) {
                  final c = complaints[i];
                  final closedDt = _closedDate(c);
                  final closedDate =
                      '${closedDt.day.toString().padLeft(2, '0')}/'
                      '${closedDt.month.toString().padLeft(2, '0')}/'
                      '${closedDt.year}';
                  return DataRow(
                    onSelectChanged: (_) => widget.onSelectComplaint(c),
                    cells: [
                      DataCell(
                        Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                c.title,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                c.id,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(
                            c.location,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      DataCell(StatusBadge.fromStatus(c.priority)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${c.affectedUsers.length} affected',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(closedDate, style: const TextStyle(fontSize: 13)),
                      ),
                      DataCell(
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => widget.onSelectComplaint(c),
                          child: const Text(
                            'View',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }
}
