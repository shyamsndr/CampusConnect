// Data models for CampusConnect Admin
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String memberCode;
  final String name;
  final String email;
  final String role; // 'Student', 'Staff', 'Admin'
  final String department;
  final String phone;
  final String status; // 'Active', 'Inactive'
  final DateTime createdAt;

  const UserModel({
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

class ComplaintModel {
  final String id;
  final String title;
  final String description;
  final String submittedBy;
  final String submittedByRole;
  final String location;
  final String priority; // 'Low', 'Medium', 'High'
  final String status; // 'Pending', 'In Progress', 'Resolved'
  final DateTime reportedAt;
  final String? photoUrl;

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
    );
  }
}

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final String venue;
  final String status; // 'Draft', 'Published'
  final String? poster;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.venue,
    required this.status,
    this.poster,
  });

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? time,
    String? venue,
    String? status,
    String? poster,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      venue: venue ?? this.venue,
      status: status ?? this.status,
      poster: poster ?? this.poster,
    );
  }
}
