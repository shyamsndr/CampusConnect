// Data models for CampusConnect Admin
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid; // Firestore document ID (Firebase Auth UID)
  final String memberCode;
  final String name;
  final String email;
  final String role; // 'Student', 'Staff', 'Admin'
  final String department;
  final String phone;
  final String status; // 'Active', 'Inactive'
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.memberCode,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.phone,
    required this.status,
    required this.createdAt,
  });

  /// Creates a [UserModel] from a Firestore document snapshot.
  ///
  /// Firestore field names use snake_case (member_code, created_at).
  /// All fields are safely handled with null-fallback defaults.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Convert Firestore Timestamp -> DateTime, fallback to epoch if missing.
    DateTime createdAt = DateTime(2000);
    final rawCreatedAt = data['created_at'];
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    }

    return UserModel(
      uid: doc.id,
      memberCode: (data['member_code'] as String?)?.trim() ?? '',
      name: (data['name'] as String?)?.trim() ?? '',
      email: (data['email'] as String?)?.trim() ?? '',
      role: (data['role'] as String?)?.trim() ?? 'Unknown',
      department: (data['department'] as String?)?.trim() ?? '',
      phone: (data['phone'] as String?)?.trim() ?? '-',
      status: (data['status'] as String?)?.trim() ?? 'Unknown',
      createdAt: createdAt,
    );
  }

  UserModel copyWith({
    String? uid,
    String? memberCode,
    String? name,
    String? email,
    String? role,
    String? department,
    String? phone,
    String? status,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      memberCode: memberCode ?? this.memberCode,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AffectedUser {
  final String name;
  final String memberCode;
  final String type; // 'Student', 'Staff'
  final String department;
  final String reportTitle;
  final String reportDescription;
  final DateTime reportDate;
  final String? photoUrl;

  const AffectedUser({
    required this.name,
    required this.memberCode,
    required this.type,
    required this.department,
    required this.reportTitle,
    required this.reportDescription,
    required this.reportDate,
    this.photoUrl,
  });
}

class AdminComplaintStatusEntry {
  final String status;
  final DateTime timestamp;
  final String note;

  const AdminComplaintStatusEntry({
    required this.status,
    required this.timestamp,
    required this.note,
  });
}

class ComplaintModel {
  final String id;
  final String title;
  final String description;
  final String submittedBy;
  final String submittedByRole;
  final String location;
  final String priority; // 'Low', 'Medium', 'High'
  final String status; // 'Open', 'In Progress', 'Closed'  (was: Pending/In Progress/Resolved)
  final DateTime reportedAt;
  final String? photoUrl;
  final List<AffectedUser> affectedUsers;
  final List<AdminComplaintStatusEntry> statusHistory;

  const ComplaintModel({
    required this.id,
    required this.title,
    required this.description,
    required this.submittedBy,
    required this.submittedByRole,
    required this.location,
    required this.priority,
    required this.status,
    required this.reportedAt,
    this.photoUrl,
    this.affectedUsers = const [],
    this.statusHistory = const [],
  });

  ComplaintModel copyWith({
    String? id,
    String? title,
    String? description,
    String? submittedBy,
    String? submittedByRole,
    String? location,
    String? priority,
    String? status,
    DateTime? reportedAt,
    String? photoUrl,
    List<AffectedUser>? affectedUsers,
    List<AdminComplaintStatusEntry>? statusHistory,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      submittedBy: submittedBy ?? this.submittedBy,
      submittedByRole: submittedByRole ?? this.submittedByRole,
      location: location ?? this.location,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      reportedAt: reportedAt ?? this.reportedAt,
      photoUrl: photoUrl ?? this.photoUrl,
      affectedUsers: affectedUsers ?? this.affectedUsers,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }
}

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

  /// Compatibility getters for existing UI
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
