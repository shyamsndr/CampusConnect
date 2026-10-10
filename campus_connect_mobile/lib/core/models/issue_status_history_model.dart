import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a status change entry from the Firestore ISSUE_STATUS_HISTORY collection.
///
/// Each time an issue's status is changed (by user creation or admin action),
/// a new history record is created.
class IssueStatusHistoryModel {
  final String historyId;
  final String issueId;
  final String? oldStatus;
  final String newStatus;
  final String changedBy;
  final DateTime changedAt;

  const IssueStatusHistoryModel({
    required this.historyId,
    required this.issueId,
    this.oldStatus,
    required this.newStatus,
    required this.changedBy,
    required this.changedAt,
  });

  /// Creates an [IssueStatusHistoryModel] from a Firestore document snapshot.
  factory IssueStatusHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final now = DateTime.now();

    DateTime changedAt = now;
    final rawChangedAt = data['changed_at'];
    if (rawChangedAt is Timestamp) {
      changedAt = rawChangedAt.toDate();
    }

    return IssueStatusHistoryModel(
      historyId: doc.id,
      issueId: (data['issue_id'] as String?) ?? '',
      oldStatus: data['old_status'] as String?,
      newStatus: (data['new_status'] as String?) ?? 'Open',
      changedBy: (data['changed_by'] as String?) ?? '',
      changedAt: changedAt,
    );
  }

  /// Generates a human-readable note from the status transition.
  String get displayNote {
    if (oldStatus == null) return 'Complaint submitted';
    return 'Status changed to $newStatus';
  }
}
