import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a campus issue from the Firestore ISSUES collection.
///
/// Each issue is a distinct campus problem (e.g. "Fan not working in F06").
/// Multiple ISSUE_REPORTS may be linked to one issue (Phase 3 duplicate detection).
/// In Phase 1, every submission creates exactly one issue + one report.
class IssueModel {
  final String issueId;
  final String title;
  final String description;
  final String location;
  final String? primaryImageUrl;
  final String primaryReportId;
  final String primaryReporterId;
  final String status; // 'Open', 'In Progress', 'Closed'
  final String priority; // 'Low', 'Medium', 'High'
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;

  const IssueModel({
    required this.issueId,
    required this.title,
    required this.description,
    required this.location,
    this.primaryImageUrl,
    required this.primaryReportId,
    required this.primaryReporterId,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
  });

  /// Creates an [IssueModel] from a Firestore document snapshot.
  factory IssueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final now = DateTime.now();

    DateTime parseTimestamp(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      return now;
    }

    return IssueModel(
      issueId: doc.id,
      title: (data['title'] as String?)?.trim() ?? '',
      description: (data['description'] as String?)?.trim() ?? '',
      location: (data['location'] as String?)?.trim() ?? '',
      primaryImageUrl: data['primary_image_url'] as String?,
      primaryReportId: (data['primary_report_id'] as String?) ?? '',
      primaryReporterId: (data['primary_reporter_id'] as String?) ?? '',
      status: (data['status'] as String?)?.trim() ?? 'Open',
      priority: (data['priority'] as String?)?.trim() ?? 'Medium',
      createdAt: parseTimestamp(data['created_at']),
      updatedAt: parseTimestamp(data['updated_at']),
      closedAt: data['closed_at'] != null
          ? parseTimestamp(data['closed_at'])
          : null,
    );
  }
}
