import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single document from the Firestore EVENTS collection.
class EventModel {
  final String eventId;
  final String title;
  final String description;
  final DateTime eventDate;
  final String eventTime;
  final String venue;
  final String posterUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String status; // 'published', 'cancelled'

  const EventModel({
    required this.eventId,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.eventTime,
    required this.venue,
    required this.posterUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.status,
  });

  /// Getter aliases for compatibility with pre-existing UI properties
  String get id => eventId;
  DateTime get date => eventDate;
  String get time => eventTime;
  String? get poster => posterUrl.isNotEmpty ? posterUrl : null;

  /// Creates an [EventModel] from a Firestore document snapshot.
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDateTime(dynamic field, DateTime fallback) {
      if (field is Timestamp) return field.toDate();
      if (field is String) {
        final parsed = DateTime.tryParse(field);
        if (parsed != null) return parsed;
      }
      return fallback;
    }

    final now = DateTime.now();

    return EventModel(
      eventId: (data['event_id'] as String?)?.trim() ?? doc.id,
      title: (data['title'] as String?)?.trim() ?? '',
      description: (data['description'] as String?)?.trim() ?? '',
      eventDate: parseDateTime(data['event_date'], now),
      eventTime: (data['event_time'] as String?)?.trim() ?? '',
      venue: (data['venue'] as String?)?.trim() ?? '',
      posterUrl: (data['poster_url'] as String?)?.trim() ?? '',
      createdAt: parseDateTime(data['created_at'], now),
      updatedAt: parseDateTime(data['updated_at'], now),
      createdBy: (data['created_by'] as String?)?.trim() ?? 'Admin',
      status: (data['status'] as String?)?.trim() ?? 'published',
    );
  }

  /// Converts this [EventModel] to a Firestore map payload.
  Map<String, dynamic> toFirestore() {
    return {
      'event_id': eventId,
      'title': title,
      'description': description,
      'event_date': Timestamp.fromDate(eventDate),
      'event_time': eventTime,
      'venue': venue,
      'poster_url': posterUrl,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'created_by': createdBy,
      'status': status,
    };
  }

  EventModel copyWith({
    String? eventId,
    String? title,
    String? description,
    DateTime? eventDate,
    String? eventTime,
    String? venue,
    String? posterUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? status,
  }) {
    return EventModel(
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      venue: venue ?? this.venue,
      posterUrl: posterUrl ?? this.posterUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
    );
  }
}
