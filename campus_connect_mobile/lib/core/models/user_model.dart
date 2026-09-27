import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single document from the Firestore USERS collection.
///
/// Field names match the snake_case schema written by the Admin Cloud Function:
///   member_code, name, email, role, department, phone, status, created_at
class UserModel {
  final String uid;
  final String memberCode;
  final String name;
  final String email;
  final String role;
  final String department;
  final String phone;
  final String status;
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
  /// The [uid] is taken from [doc.id] because the Admin Cloud Function
  /// uses the Firebase UID as the Firestore document ID.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

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
}
