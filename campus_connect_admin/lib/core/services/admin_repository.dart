import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// Central state management and repository for the CampusConnect Admin portal.
/// Handles in-memory data for users, complaints, and events without external dependencies.
class AdminRepository extends ChangeNotifier {
  // Auth state
  bool _isAuthenticated = true;
  final String _adminName = 'Dr. Rajesh Sharma';
  String _adminEmail = 'admin@campusconnect.edu';
  final String _adminRole = 'Chief Campus Administrator';

  bool get isAuthenticated => _isAuthenticated;
  String get adminName => _adminName;
  String get adminEmail => _adminEmail;
  String get adminRole => _adminRole;

  bool login(String email, String password) {
    // Simple local credential check for administration portal
    if (email.trim().isNotEmpty && password.trim().isNotEmpty) {
      _isAuthenticated = true;
      _adminEmail = email.trim();
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }

  // Initial realistic college users
  final List<UserModel> _users = [
    UserModel(
      memberCode: 'ADM-001',
      name: 'Dr. Rajesh Sharma',
      email: 'admin@campusconnect.edu',
      role: 'Admin',
      department: 'Administration',
      phone: '+91 98765 43210',
      status: 'Active',
      createdAt: DateTime(2026, 1, 10),
    ),
    UserModel(
      memberCode: 'STU-2024-042',
      name: 'Aarav Patel',
      email: 'aarav.p@student.college.edu',
      role: 'Student',
      department: 'Computer Science',
      phone: '+91 98112 34567',
      status: 'Active',
      createdAt: DateTime(2026, 2, 14),
    ),
    UserModel(
      memberCode: 'STF-108',
      name: 'Prof. Ananya Sen',
      email: 'ananya.sen@college.edu',
      role: 'Staff',
      department: 'Electronics & Comm.',
      phone: '+91 98223 45678',
      status: 'Active',
      createdAt: DateTime(2026, 2, 18),
    ),
    UserModel(
      memberCode: 'STU-2024-089',
      name: 'Priya Sundaram',
      email: 'priya.s@student.college.edu',
      role: 'Student',
      department: 'Information Tech',
      phone: '+91 98334 56789',
      status: 'Active',
      createdAt: DateTime(2026, 3, 1),
    ),
    UserModel(
      memberCode: 'STF-214',
      name: 'Dr. Vikram Joshi',
      email: 'v.joshi@college.edu',
      role: 'Staff',
      department: 'Mechanical Engg',
      phone: '+91 98445 67890',
      status: 'Active',
      createdAt: DateTime(2026, 3, 5),
    ),
    UserModel(
      memberCode: 'STU-2024-115',
      name: 'Rohan Mehra',
      email: 'rohan.m@student.college.edu',
      role: 'Student',
      department: 'Civil Engineering',
      phone: '+91 98556 78901',
      status: 'Active',
      createdAt: DateTime(2026, 3, 8),
    ),
  ];

  // Initial realistic campus complaints
  final List<ComplaintModel> _complaints = [
    ComplaintModel(
      id: 'CMP-2026-101',
      title: 'Lab 3 Air Conditioning Failure',
      description:
          'AC unit #2 in Computer Lab 3 (Block B) stopped cooling during practical exams. Temperature in the lab is exceeding 34°C, causing systems to overheat.',
      submittedBy: 'Prof. Ananya Sen',
      submittedByRole: 'Staff',
      location: 'Block B, 2nd Floor, Lab 3',
      priority: 'High',
      status: 'In Progress',
      reportedAt: DateTime(2026, 9, 13, 10, 30),
    ),
    ComplaintModel(
      id: 'CMP-2026-102',
      title: 'Projector Bulb Flickering in Seminar Hall B',
      description:
          'The ceiling-mounted HDMI projector turns off intermittently every 10 minutes during guest lectures.',
      submittedBy: 'Dr. Vikram Joshi',
      submittedByRole: 'Staff',
      location: 'Main Block, Seminar Hall B',
      priority: 'Medium',
      status: 'Pending',
      reportedAt: DateTime(2026, 9, 12, 14, 15),
    ),
    ComplaintModel(
      id: 'CMP-2026-103',
      title: 'Water Leakage Near Restroom Corridor',
      description:
          'Continuous dripping from the overhead pipe joint near the 3rd-floor boy restroom. Floor is wet and slippery.',
      submittedBy: 'Aarav Patel',
      submittedByRole: 'Student',
      location: 'Academic Block C, 3rd Floor',
      priority: 'High',
      status: 'Pending',
      reportedAt: DateTime(2026, 9, 12, 11, 00),
    ),
    ComplaintModel(
      id: 'CMP-2026-104',
      title: 'Broken Bench in Reading Room 2',
      description:
          'Wooden support plank cracked on study table #8. Needs carpenter inspection.',
      submittedBy: 'Priya Sundaram',
      submittedByRole: 'Student',
      location: 'Central Library, 1st Floor',
      priority: 'Low',
      status: 'Resolved',
      reportedAt: DateTime(2026, 9, 10, 16, 45),
    ),
    ComplaintModel(
      id: 'CMP-2026-105',
      title: 'Wi-Fi Access Point Offline in Hostel Block 4',
      description:
          'Hostel wing students unable to connect to campus network; access point router shows red power LED.',
      submittedBy: 'Rohan Mehra',
      submittedByRole: 'Student',
      location: 'Boys Hostel Block 4, Ground Floor',
      priority: 'Medium',
      status: 'In Progress',
      reportedAt: DateTime(2026, 9, 9, 20, 10),
    ),
    ComplaintModel(
      id: 'CMP-2026-106',
      title: 'Cafeteria Water Dispenser Filter Clogged',
      description:
          'Water flow rate is extremely low and requires cartridge replacement.',
      submittedBy: 'Aarav Patel',
      submittedByRole: 'Student',
      location: 'Student Activity Center, Cafeteria',
      priority: 'Low',
      status: 'Resolved',
      reportedAt: DateTime(2026, 9, 8, 13, 20),
    ),
  ];

  // Initial realistic campus events
  final List<EventModel> _events = [
    EventModel(
      id: 'EVT-2026-01',
      title: 'Annual Technical Symposium: InnovateX 2026',
      description:
          'Inter-college hackathon, paper presentation, and robotics exhibition for engineering students.',
      date: DateTime(2026, 9, 25),
      time: '09:00 AM - 05:00 PM',
      venue: 'Main Auditorium & CS Labs',
      status: 'Published',
    ),
    EventModel(
      id: 'EVT-2026-02',
      title: 'Campus Placement Readiness & Mock Interviews',
      description:
          'Alumni-led interview preparation, resume building, and technical assessment workshop for final-year students.',
      date: DateTime(2026, 9, 28),
      time: '10:00 AM - 01:00 PM',
      venue: 'Placement Cell & Seminar Hall A',
      status: 'Published',
    ),
    EventModel(
      id: 'EVT-2026-03',
      title: 'Inter-Department Cricket Tournament',
      description:
          'Annual sports league matches between student batches and faculty teams.',
      date: DateTime(2026, 10, 5),
      time: '08:00 AM - 04:00 PM',
      venue: 'College Sports Ground',
      status: 'Draft',
    ),
  ];

  // Getters
  List<UserModel> get users => List.unmodifiable(_users);
  List<ComplaintModel> get complaints => List.unmodifiable(_complaints);
  List<EventModel> get events => List.unmodifiable(_events);

  // Dashboard Metrics
  int get totalUsers => _users.length;
  int get totalComplaints => _complaints.length;
  int get pendingComplaints =>
      _complaints.where((c) => c.status == 'Pending').length;
  int get resolvedComplaints =>
      _complaints.where((c) => c.status == 'Resolved').length;

  List<ComplaintModel> get recentComplaints {
    final sorted = List<ComplaintModel>.from(_complaints)
      ..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    return sorted.take(5).toList();
  }

  List<UserModel> get recentUsers {
    final sorted = List<UserModel>.from(_users)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(5).toList();
  }

  // User Actions
  bool isMemberCodeExists(String code) {
    return _users.any(
      (u) => u.memberCode.trim().toLowerCase() == code.trim().toLowerCase(),
    );
  }

  bool isEmailExists(String email) {
    return _users.any(
      (u) => u.email.trim().toLowerCase() == email.trim().toLowerCase(),
    );
  }

  void addUser(UserModel user) {
    _users.insert(0, user);
    notifyListeners();
  }

  List<UserModel> searchUsers(String query) {
    if (query.trim().isEmpty) return _users;
    final q = query.trim().toLowerCase();
    return _users.where((user) {
      return user.name.toLowerCase().contains(q) ||
          user.memberCode.toLowerCase().contains(q) ||
          user.email.toLowerCase().contains(q) ||
          user.department.toLowerCase().contains(q) ||
          user.role.toLowerCase().contains(q);
    }).toList();
  }

  // Complaint Actions
  ComplaintModel? getComplaintById(String id) {
    try {
      return _complaints.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void updateComplaintStatus(String id, String newStatus) {
    final index = _complaints.indexWhere((c) => c.id == id);
    if (index != -1) {
      _complaints[index] = _complaints[index].copyWith(status: newStatus);
      notifyListeners();
    }
  }

  // Event Actions
  void addEvent(EventModel event) {
    _events.insert(0, event);
    notifyListeners();
  }

  void updateEventStatus(String id, String newStatus) {
    final index = _events.indexWhere((e) => e.id == id);
    if (index != -1) {
      _events[index] = _events[index].copyWith(status: newStatus);
      notifyListeners();
    }
  }

  void editEvent(EventModel updatedEvent) {
    final index = _events.indexWhere((e) => e.id == updatedEvent.id);
    if (index != -1) {
      _events[index] = updatedEvent;
      notifyListeners();
    }
  }

  void deleteEvent(String id) {
    _events.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
