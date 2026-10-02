import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single document from the Firestore NOTIFICATIONS collection.
///
/// Each document is scoped to one user via [userId] and describes an event
/// notification of [type] ('event_created', 'event_updated', 'event_cancelled').
class NotificationModel {
  final String notificationId;
  final String userId;
  final String type; // 'event_created' | 'event_updated' | 'event_cancelled'
  final String title;
  final String message;
  final String eventId;
  final DateTime createdAt;
  final bool isRead;

  const NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.eventId,
    required this.createdAt,
    required this.isRead,
  });

  /// Creates a [NotificationModel] from a Firestore document snapshot.
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime createdAt = DateTime.now();
    final raw = data['created_at'];
    if (raw is Timestamp) {
      createdAt = raw.toDate();
    }

    return NotificationModel(
      notificationId: (data['notification_id'] as String?)?.trim() ?? doc.id,
      userId: (data['user_id'] as String?)?.trim() ?? '',
      type: (data['type'] as String?)?.trim() ?? 'event_created',
      title: (data['title'] as String?)?.trim() ?? '',
      message: (data['message'] as String?)?.trim() ?? '',
      eventId: (data['event_id'] as String?)?.trim() ?? '',
      createdAt: createdAt,
      isRead: (data['is_read'] as bool?) ?? false,
    );
  }
}
