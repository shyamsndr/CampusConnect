import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an individual user's original complaint submission
/// from the Firestore ISSUE_REPORTS collection.
///
/// The user's original report text is NEVER rewritten or summarized.
/// Each report is linked to an ISSUE via [issueId].
class IssueReportModel {
  final String reportId;
  final String issueId;
  final String userId;
  final String title;
  final String description;
  final String location;
  final String? imageUrl;
  final DateTime createdAt;

  const IssueReportModel({
    required this.reportId,
    required this.issueId,
    required this.userId,
    required this.title,
    required this.description,
    required this.location,
    this.imageUrl,
    required this.createdAt,
  });

  /// Creates an [IssueReportModel] from a Firestore document snapshot.
  factory IssueReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final now = DateTime.now();

    DateTime createdAt = now;
    final rawCreatedAt = data['created_at'];
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    }

    return IssueReportModel(
      reportId: doc.id,
      issueId: (data['issue_id'] as String?) ?? '',
      userId: (data['user_id'] as String?) ?? '',
      title: (data['title'] as String?)?.trim() ?? '',
      description: (data['description'] as String?)?.trim() ?? '',
      location: (data['location'] as String?)?.trim() ?? '',
      imageUrl: data['image_url'] as String?,
      createdAt: createdAt,
    );
  }
}
