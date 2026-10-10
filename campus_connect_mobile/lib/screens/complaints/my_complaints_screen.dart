import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/issue_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/complaint_service.dart';
import '../../widgets/complaints/complaint_card.dart';
import 'complaint_detail_screen.dart';

/// Displays the current user's submitted complaints.
/// Supports filtering by status: All | Open | In Progress | Closed.
class MyComplaintsScreen extends StatefulWidget {
  final AuthService authService;
  
  const MyComplaintsScreen({super.key, required this.authService});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  final ComplaintService _complaintService = ComplaintService();
  final List<String> _filters = ['All', 'Open', 'In Progress', 'Closed'];
  String _selectedFilter = 'All';

  List<IssueModel> _filterComplaints(List<IssueModel> all) {
    if (_selectedFilter == 'All') return all;
    return all.where((c) => c.status == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser;
    final uid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'My Complaints',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filter Tabs ──────────────────────────────────────────
          _buildFilterTabs(),

          // ── Complaint List ────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<IssueModel>>(
              stream: _complaintService.getUserComplaintsStream(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  );
                }

                final complaints = snapshot.data ?? [];
                final filtered = _filterComplaints(complaints);

                return _buildComplaintList(filtered);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: ScrollConfiguration(
        behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _filters.map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : AppColors.borderGrey,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primaryBlue.withValues(
                                  alpha: 0.22,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintList(List<IssueModel> complaints) {
    if (complaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 52,
              color: AppColors.textGrey.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 14),
            Text(
              'No "$_selectedFilter" complaints',
              style: const TextStyle(
                color: AppColors.textGrey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ScrollConfiguration(
      behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: complaints.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final complaint = complaints[index];
          return ComplaintCard(
            complaint: complaint,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ComplaintDetailScreen(complaint: complaint),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

