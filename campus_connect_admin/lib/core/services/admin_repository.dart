import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:firebase_storage/firebase_storage.dart';

/// Central state management and repository for the CampusConnect Admin portal.
///
/// Handles:
/// - Firebase Authentication
/// - Admin authorization using Firestore
/// - Admin session restoration after browser refresh
/// - Realtime Firestore listener for USERS collection
/// - Realtime Firestore listener for EVENTS collection
/// - In-memory complaints data
class AdminRepository extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  // ============================================================
  // AUTHENTICATION STATE
  // ============================================================

  bool _isAuthenticated = false;
  bool _isInitializing = true;

  String _adminName = '';
  String _adminEmail = '';
  String _adminRole = '';

  bool get isAuthenticated => _isAuthenticated;
  bool get isInitializing => _isInitializing;
  String get adminName => _adminName;
  String get adminEmail => _adminEmail;
  String get adminRole => _adminRole;

  /// Starts Firebase session restoration.
  ///
  /// Future.microtask ensures that the UI has time to attach
  /// its listener before the initialization state changes.
  AdminRepository() {
    Future.microtask(_restoreSession);
  }

  /// Restores the Firebase authentication session after
  /// a browser refresh or reopening the application.
  Future<void> _restoreSession() async {
    try {
      final user = _auth.currentUser;

      // No Firebase user means the admin is logged out.
      if (user == null) {
        _isAuthenticated = false;
        return;
      }

      // Get the corresponding Firestore user document.
      final userDocument = await _firestore
          .collection('USERS')
          .doc(user.uid)
          .get();

      // Firebase account exists but there is no matching
      // Firestore profile.
      if (!userDocument.exists) {
        await _auth.signOut();
        _isAuthenticated = false;
        return;
      }

      final data = userDocument.data();

      // Only users with the Admin role can access
      // the administration portal.
      if (data == null || data['role'] != 'Admin') {
        await _auth.signOut();
        _isAuthenticated = false;
        return;
      }

      // Restore admin profile information from Firestore.
      _adminName = data['name']?.toString() ?? 'Administrator';
      _adminEmail = data['email']?.toString() ?? user.email ?? '';
      _adminRole = data['role']?.toString() ?? 'Admin';

      _isAuthenticated = true;

      // Start listening to USERS & EVENTS collections once admin session is confirmed.
      subscribeToUsers();
      subscribeToEvents();
    } catch (_) {
      // If session restoration fails, keep the user logged out.
      _isAuthenticated = false;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Signs in using Firebase Authentication and verifies that
  /// the authenticated account has the Admin role in Firestore.
  ///
  /// Returns:
  /// - null when login succeeds
  /// - error message when login fails
  Future<String?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        return 'Unable to sign in. Please try again.';
      }

      // Get the user's Firestore profile using the Firebase UID.
      final userDocument = await _firestore
          .collection('USERS')
          .doc(user.uid)
          .get();

      // Firebase account exists, but there is no corresponding
      // USERS document.
      if (!userDocument.exists) {
        await _auth.signOut();
        return 'Admin profile not found.';
      }

      final data = userDocument.data();

      // Only Admin accounts are allowed into the Admin portal.
      if (data == null || data['role'] != 'Admin') {
        await _auth.signOut();
        return 'Access denied. This account is not an administrator.';
      }

      // Store profile information from Firestore.
      _isAuthenticated = true;
      _adminName = data['name']?.toString() ?? 'Administrator';
      _adminEmail = data['email']?.toString() ?? user.email ?? email.trim();
      _adminRole = data['role']?.toString() ?? 'Admin';

      notifyListeners();

      // Start listening to USERS & EVENTS collections once admin is authenticated.
      subscribeToUsers();
      subscribeToEvents();

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-credential':
        case 'invalid-login-credentials':
          return 'Invalid email or password.';

        case 'user-disabled':
          return 'This account has been disabled.';

        case 'too-many-requests':
          return 'Too many login attempts. Please try again later.';

        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';

        case 'user-not-found':
          return 'No account found with this email.';

        case 'wrong-password':
          return 'Invalid email or password.';

        default:
          return 'Unable to sign in. Please try again.';
      }
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  /// Signs the administrator out from Firebase Authentication
  /// and clears the local admin session.
  Future<void> logout() async {
    _cancelUsersSubscription();
    _cancelEventsSubscription();
    await _auth.signOut();

    _isAuthenticated = false;
    _adminName = '';
    _adminEmail = '';
    _adminRole = '';

    // Clear user and event state on logout.
    _users.clear();
    _events.clear();
    _isLoadingUsers = false;
    _usersError = null;

    notifyListeners();
  }

  // ============================================================
  // USERS — FIRESTORE REALTIME STATE
  // ============================================================

  final List<UserModel> _users = [];
  bool _isLoadingUsers = false;
  String? _usersError;

  /// Active Firestore snapshot subscription for the USERS collection.
  /// Cancelled when the admin logs out or the repository is disposed.
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSubscription;

  bool get isLoadingUsers => _isLoadingUsers;
  String? get usersError => _usersError;

  /// Starts (or restarts) a realtime Firestore listener on the USERS collection.
  void subscribeToUsers() {
    _cancelUsersSubscription();

    _isLoadingUsers = true;
    _usersError = null;
    notifyListeners();

    _usersSubscription = _firestore
        .collection('USERS')
        .orderBy('created_at', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final loaded = <UserModel>[];

            for (final doc in snapshot.docs) {
              try {
                loaded.add(UserModel.fromFirestore(doc));
              } catch (e) {
                debugPrint(
                  '[AdminRepository] Skipped malformed USERS doc ${doc.id}: $e',
                );
              }
            }

            _users
              ..clear()
              ..addAll(loaded);

            _isLoadingUsers = false;
            _usersError = null;
            notifyListeners();
          },
          onError: (Object error) {
            debugPrint('[AdminRepository] USERS snapshot error: $error');
            _isLoadingUsers = false;
            _usersError =
                'Unable to load members. Please check your connection.';
            notifyListeners();
          },
        );
  }

  /// Cancels the active USERS Firestore subscription.
  void _cancelUsersSubscription() {
    _usersSubscription?.cancel();
    _usersSubscription = null;
  }

  // ============================================================
  // INITIAL REALISTIC CAMPUS COMPLAINTS (Phase 0 — Mock Data)
  // ONE ROW = ONE ISSUE (possibly multiple reporters)
  // ============================================================

  final List<ComplaintModel> _complaints = [
    ComplaintModel(
      id: 'ISS-2026-001',
      title: 'Fan not working',
      description:
          'The ceiling fan in F06 classroom has stopped working completely. Multiple students and the class teacher have reported discomfort due to extreme heat during lectures.',
      submittedBy: 'Rahul S',
      submittedByRole: 'Student',
      location: 'F06 Classroom',
      priority: 'High',
      status: 'Open',
      reportedAt: DateTime(2026, 10, 4, 10, 30),
      affectedUsers: [
        AffectedUser(name: 'Rahul S', memberCode: 'MCA001', type: 'Student', department: 'MCA', reportTitle: 'Fan not working', reportDescription: 'The fan in F06 classroom is not turning on.', reportDate: DateTime(2026, 10, 4, 10, 30), photoUrl: 'Photo A'),
        AffectedUser(name: 'Anjali P', memberCode: 'MCA014', type: 'Student', department: 'MCA', reportTitle: 'Classroom fan problem', reportDescription: 'The ceiling fan near the last bench is not working.', reportDate: DateTime(2026, 10, 4, 10, 42), photoUrl: 'Photo B'),
        AffectedUser(name: 'Sreenath K', memberCode: 'MBA021', type: 'Student', department: 'MBA', reportTitle: 'No air circulation', reportDescription: 'One of the fans in F06 has stopped working.', reportDate: DateTime(2026, 10, 4, 11, 05), photoUrl: 'Photo C'),
        AffectedUser(name: 'Staff 1', memberCode: 'ST004', type: 'Staff', department: 'Maintenance', reportTitle: 'F06 Fan replacement needed', reportDescription: 'Confirmed fan motor is burnt.', reportDate: DateTime(2026, 10, 4, 11, 30)),
        AffectedUser(name: 'Divya R', memberCode: 'MCA032', type: 'Student', department: 'MCA', reportTitle: 'Fan issue F06', reportDescription: 'Too hot in class', reportDate: DateTime(2026, 10, 4, 12, 00)),
      ],
      statusHistory: [
        AdminComplaintStatusEntry(
          status: 'Open',
          timestamp: DateTime(2026, 10, 4, 10, 30),
          note: 'Complaint submitted',
        ),
      ],
    ),
    ComplaintModel(
      id: 'ISS-2026-002',
      title: 'Water leakage near staircase',
      description:
          'Continuous water dripping from overhead pipe near the Block A staircase. Floor is wet and poses a safety hazard. Reported by multiple students.',
      submittedBy: 'Meera K',
      submittedByRole: 'Student',
      location: 'Block A',
      priority: 'Medium',
      status: 'In Progress',
      reportedAt: DateTime(2026, 9, 28, 9, 15),
      affectedUsers: [
        AffectedUser(name: 'Meera K', memberCode: 'BCA008', type: 'Student', department: 'BCA', reportTitle: 'Leakage', reportDescription: 'Water leaking.', reportDate: DateTime(2026, 9, 28, 9, 15)),
        AffectedUser(name: 'Arjun T', memberCode: 'BCA012', type: 'Student', department: 'BCA', reportTitle: 'Pipe break', reportDescription: 'Pipe broken.', reportDate: DateTime(2026, 9, 28, 9, 20)),
      ],
      statusHistory: [
        AdminComplaintStatusEntry(
          status: 'Open',
          timestamp: DateTime(2026, 9, 28, 9, 15),
          note: 'Complaint submitted',
        ),
        AdminComplaintStatusEntry(
          status: 'In Progress',
          timestamp: DateTime(2026, 9, 30, 11, 20),
          note: 'Work started by maintenance team',
        ),
      ],
    ),
    ComplaintModel(
      id: 'ISS-2026-003',
      title: 'AC not working in Computer Lab',
      description:
          'The air conditioning unit in the Computer Lab is not cooling. Temperature is rising, causing discomfort and equipment heat issues during lab sessions.',
      submittedBy: 'Dr. Vikram J',
      submittedByRole: 'Staff',
      location: 'Computer Lab',
      priority: 'High',
      status: 'Open',
      reportedAt: DateTime(2026, 10, 2, 8, 0),
      affectedUsers: [
        AffectedUser(name: 'Dr. Vikram J', memberCode: 'ST003', type: 'Staff', department: 'CS', reportTitle: 'AC issue', reportDescription: 'AC is not working.', reportDate: DateTime(2026, 10, 2, 8, 0)),
        AffectedUser(name: 'Priya M', memberCode: 'MCA007', type: 'Student', department: 'MCA', reportTitle: 'Hot lab', reportDescription: 'Lab is hot.', reportDate: DateTime(2026, 10, 2, 8, 30)),
        AffectedUser(name: 'Karan R', memberCode: 'MCA019', type: 'Student', department: 'MCA', reportTitle: 'AC', reportDescription: 'Fix AC please.', reportDate: DateTime(2026, 10, 2, 9, 0)),
      ],
      statusHistory: [
        AdminComplaintStatusEntry(
          status: 'Open',
          timestamp: DateTime(2026, 10, 2, 8, 0),
          note: 'Complaint submitted',
        ),
      ],
    ),
    ComplaintModel(
      id: 'ISS-2026-004',
      title: 'Projector not working in Seminar Hall',
      description:
          'The ceiling-mounted projector in Seminar Hall B turns off intermittently every 10 minutes. This is disrupting guest lectures and presentations.',
      submittedBy: 'Prof. Ananya S',
      submittedByRole: 'Staff',
      location: 'Seminar Hall B',
      priority: 'Medium',
      status: 'Open',
      reportedAt: DateTime(2026, 9, 12, 14, 15),
      affectedUsers: [
        AffectedUser(name: 'Prof. Ananya S', memberCode: 'ST007', type: 'Staff', department: 'MBA', reportTitle: 'Projector', reportDescription: 'Projector is off.', reportDate: DateTime(2026, 9, 12, 14, 15)),
        AffectedUser(name: 'Rohan V', memberCode: 'MBA003', type: 'Student', department: 'MBA', reportTitle: 'No display', reportDescription: 'Display off.', reportDate: DateTime(2026, 9, 12, 14, 20)),
      ],
      statusHistory: [
        AdminComplaintStatusEntry(
          status: 'Open',
          timestamp: DateTime(2026, 9, 12, 14, 15),
          note: 'Complaint submitted',
        ),
      ],
    ),
    // ── CLOSED ISSUES ──────────────────────────────────────────────────────
    ComplaintModel(
      id: 'ISS-2026-005',
      title: 'Light not working in Library',
      description:
          'Two tube lights in the library reading area on the 1st floor are not functioning. Poor lighting is affecting student study sessions significantly.',
      submittedBy: 'Priya Sundaram',
      submittedByRole: 'Student',
      location: 'Central Library, 1st Floor',
      priority: 'Low',
      status: 'Closed',
      reportedAt: DateTime(2026, 9, 20, 14, 45),
      affectedUsers: [
        AffectedUser(name: 'Priya Sundaram', memberCode: 'BCA022', type: 'Student', department: 'BCA', reportTitle: 'Light off', reportDescription: 'Light is off.', reportDate: DateTime(2026, 9, 20, 14, 45)),
      ],
      statusHistory: [
        AdminComplaintStatusEntry(
          status: 'Open',
          timestamp: DateTime(2026, 9, 20, 14, 45),
          note: 'Complaint submitted',
        ),
        AdminComplaintStatusEntry(
          status: 'In Progress',
          timestamp: DateTime(2026, 9, 22, 10, 0),
          note: 'Electrician assigned and work in progress',
        ),
        AdminComplaintStatusEntry(
          status: 'Closed',
          timestamp: DateTime(2026, 9, 23, 16, 30),
          note: 'Lights replaced and issue resolved',
        ),
      ],
    ),
    ComplaintModel(
      id: 'ISS-2026-006',
      title: 'Cafeteria water dispenser filter clogged',
      description:
          'Water flow rate from the dispenser in the cafeteria is extremely low. The filter cartridge requires replacement immediately.',
      submittedBy: 'Aarav Patel',
      submittedByRole: 'Student',
      location: 'Student Activity Center, Cafeteria',
      priority: 'Low',
      status: 'Closed',
      reportedAt: DateTime(2026, 9, 8, 13, 20),
      affectedUsers: [
        AffectedUser(name: 'Aarav Patel', memberCode: 'MBA009', type: 'Student', department: 'MBA', reportTitle: 'Filter', reportDescription: 'Filter clogged.', reportDate: DateTime(2026, 9, 8, 13, 20)),
        AffectedUser(name: 'Sneha L', memberCode: 'BCA031', type: 'Student', department: 'BCA', reportTitle: 'Water flow', reportDescription: 'Low water flow.', reportDate: DateTime(2026, 9, 8, 13, 25)),
      ],
      statusHistory: [
        AdminComplaintStatusEntry(
          status: 'Open',
          timestamp: DateTime(2026, 9, 8, 13, 20),
          note: 'Complaint submitted',
        ),
        AdminComplaintStatusEntry(
          status: 'In Progress',
          timestamp: DateTime(2026, 9, 9, 9, 0),
          note: 'Maintenance team scheduled for replacement',
        ),
        AdminComplaintStatusEntry(
          status: 'Closed',
          timestamp: DateTime(2026, 9, 10, 11, 45),
          note: 'Filter cartridge replaced and dispenser restored',
        ),
      ],
    ),
  ];

  // ============================================================
  // GETTERS & DASHBOARD METRICS
  // ============================================================

  List<UserModel> get users => List.unmodifiable(_users);
  List<ComplaintModel> get complaints => List.unmodifiable(_complaints);
  List<EventModel> get events => List.unmodifiable(_events);

  int get totalUsers => _users.length;
  int get totalComplaints => _complaints.length;

  int get pendingComplaints =>
      _complaints.where((c) => c.status == 'Open').length;

  int get resolvedComplaints =>
      _complaints.where((c) => c.status == 'Closed').length;

  List<ComplaintModel> get openComplaints =>
      _complaints.where((c) => c.status != 'Closed').toList();

  List<ComplaintModel> get closedComplaints =>
      _complaints.where((c) => c.status == 'Closed').toList();

  List<ComplaintModel> get recentComplaints {
    final sorted = List<ComplaintModel>.from(_complaints)
      ..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));

    return sorted.take(5).toList();
  }

  List<UserModel> get recentUsers {
    if (_users.isEmpty) return [];

    final sorted = List<UserModel>.from(_users)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return sorted.take(5).toList();
  }

  // ============================================================
  // USER ACTIONS
  // ============================================================

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

  Future<String?> addUser(UserModel user) async {
    try {
      final callable = _functions.httpsCallable('createUser');

      await callable.call({
        'memberCode': user.memberCode,
        'name': user.name,
        'email': user.email,
        'role': user.role,
        'department': user.department,
        'phone': user.phone,
      });

      return null;
    } on FirebaseFunctionsException catch (e) {
      final code = (e.details is Map ? e.details['code'] : null) as String?;

      switch (code) {
        case 'EMAIL_ALREADY_EXISTS':
          return 'Sorry, an account with this email already exists.';
        case 'MEMBER_CODE_ALREADY_EXISTS':
          return 'Sorry, this member code is already registered.';
        case 'EMAIL_SEND_FAILED':
          return 'User could not be added because the welcome email could not be sent.';
        case 'UNAUTHORIZED':
        case 'FORBIDDEN':
          return 'You are not authorized to add users.';
        case 'INVALID_DATA':
          return e.message ??
              'Some fields are invalid. Please check your input.';
        default:
          return e.message ?? 'Unable to add user. Please try again.';
      }
    } catch (_) {
      return 'Unable to add user. Please try again.';
    }
  }

  List<UserModel> searchUsers(String query) {
    if (query.trim().isEmpty) {
      return _users;
    }

    final q = query.trim().toLowerCase();

    return _users.where((user) {
      return user.name.toLowerCase().contains(q) ||
          user.memberCode.toLowerCase().contains(q) ||
          user.email.toLowerCase().contains(q) ||
          user.department.toLowerCase().contains(q) ||
          user.role.toLowerCase().contains(q) ||
          user.phone.toLowerCase().contains(q);
    }).toList();
  }

  // ============================================================
  // COMPLAINT ACTIONS
  // ============================================================

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

  // ============================================================
  // EVENTS — FIRESTORE REALTIME STATE
  // ============================================================

  final List<EventModel> _events = [];
  bool _isLoadingEvents = false;
  String? _eventsError;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _eventsSubscription;

  bool get isLoadingEvents => _isLoadingEvents;
  String? get eventsError => _eventsError;

  /// Starts (or restarts) a realtime Firestore listener on the EVENTS collection.
  void subscribeToEvents() {
    _cancelEventsSubscription();

    _isLoadingEvents = true;
    _eventsError = null;
    notifyListeners();

    _eventsSubscription = _firestore
        .collection('EVENTS')
        .orderBy('event_date', descending: false)
        .snapshots()
        .listen(
          (snapshot) {
            final loaded = <EventModel>[];

            for (final doc in snapshot.docs) {
              try {
                loaded.add(EventModel.fromFirestore(doc));
              } catch (e) {
                debugPrint(
                  '[AdminRepository] Skipped malformed EVENTS doc ${doc.id}: $e',
                );
              }
            }

            _events
              ..clear()
              ..addAll(loaded);

            _isLoadingEvents = false;
            _eventsError = null;
            notifyListeners();
          },
          onError: (Object error) {
            debugPrint('[AdminRepository] EVENTS snapshot error: $error');
            _isLoadingEvents = false;
            _eventsError =
                'Unable to load events. Please check your connection.';
            notifyListeners();
          },
        );
  }

  void _cancelEventsSubscription() {
    _eventsSubscription?.cancel();
    _eventsSubscription = null;
  }

  @override
  void dispose() {
    _cancelUsersSubscription();
    _cancelEventsSubscription();
    super.dispose();
  }

  // ============================================================
  // EVENT ACTIONS & STORAGE UPLOAD
  // ============================================================

  /// Uploads poster bytes to Firebase Storage under `events/posters/{eventId}_{timestamp}.jpg`.
  /// Returns the download URL.
  Future<String> uploadPoster(Uint8List imageBytes, String filename) async {
    debugPrint(
      '[EventSubmit] [3/7] Poster upload started (filename: $filename, bytes: ${imageBytes.length})',
    );
    try {
      final ref = _storage
          .ref()
          .child('events')
          .child('posters')
          .child('${DateTime.now().millisecondsSinceEpoch}_$filename');

      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint(
        '[EventSubmit] [4/7] Poster upload completed successfully. Download URL: $downloadUrl',
      );
      return downloadUrl;
    } catch (e, stackTrace) {
      debugPrint(
        '[EventSubmit] Poster upload failed with error: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  /// Adds a new event to Firestore and creates in-app notifications for
  /// all Student and Staff users.
  Future<String?> saveEventToFirestore(EventModel event) async {
    debugPrint(
      '[EventSubmit] [5/7] Firestore write started for event_id: ${event.eventId}',
    );
    try {
      final docRef = _firestore.collection('EVENTS').doc(event.eventId);
      await docRef.set(event.toFirestore());
      debugPrint(
        '[EventSubmit] [6/7] Firestore write completed successfully for event_id: ${event.eventId}',
      );
      // Create in-app notifications for all Student / Staff users.
      await _createEventNotifications(
        eventId: event.eventId,
        eventTitle: event.title,
        type: 'event_created',
      );
      return null;
    } catch (e, stackTrace) {
      debugPrint(
        '[EventSubmit] Firestore write failed with error: $e\n$stackTrace',
      );
      return 'Failed to save event: ${e.toString()}';
    }
  }

  /// Updates an existing event in Firestore and creates in-app notifications
  /// for all Student and Staff users.
  Future<String?> updateEventInFirestore(EventModel event) async {
    debugPrint(
      '[EventSubmit] [5/7] Firestore update started for event_id: ${event.eventId}',
    );
    try {
      final docRef = _firestore.collection('EVENTS').doc(event.eventId);
      await docRef.update(event.toFirestore());
      debugPrint(
        '[EventSubmit] [6/7] Firestore update completed successfully for event_id: ${event.eventId}',
      );
      // Create in-app notifications for all Student / Staff users.
      await _createEventNotifications(
        eventId: event.eventId,
        eventTitle: event.title,
        type: 'event_updated',
      );
      return null;
    } catch (e, stackTrace) {
      debugPrint(
        '[EventSubmit] Firestore update failed with error: $e\n$stackTrace',
      );
      return 'Failed to update event: ${e.toString()}';
    }
  }

  /// Deletes poster from Storage by URL safely.
  Future<void> safeDeletePoster(String posterUrl) async {
    if (posterUrl.isNotEmpty && posterUrl.startsWith('http')) {
      try {
        final storageRef = _storage.refFromURL(posterUrl);
        await storageRef.delete();
        debugPrint('[EventSubmit] Cleaned up orphaned poster: $posterUrl');
      } catch (e) {
        debugPrint(
          '[EventSubmit] Warning: Failed to clean up poster $posterUrl: $e',
        );
      }
    }
  }

  /// Updates status of an event in Firestore ('published' or 'cancelled').
  /// When the new status is 'cancelled', creates an event_cancelled notification
  /// for all Student and Staff users.
  /// When the new status is 'published' and the current status is 'cancelled',
  /// creates an event_republished notification instead.
  /// No notification is created if the status is unchanged.
  Future<void> updateEventStatus(String id, String newStatus) async {
    try {
      // Capture the current status before updating Firestore.
      final event = _events.where((e) => e.eventId == id).firstOrNull;
      final currentStatus = event?.status.toLowerCase() ?? '';

      // Avoid duplicate notifications when status has not changed.
      if (currentStatus == newStatus.toLowerCase()) return;

      await _firestore.collection('EVENTS').doc(id).update({
        'status': newStatus,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });

      if (event != null) {
        if (newStatus == 'cancelled') {
          // cancelled notification when publishing → cancelling.
          await _createEventNotifications(
            eventId: event.eventId,
            eventTitle: event.title,
            type: 'event_cancelled',
          );
        } else if (newStatus == 'published' && currentStatus == 'cancelled') {
          // re-published notification when cancelling → publishing.
          await _createEventNotifications(
            eventId: event.eventId,
            eventTitle: event.title,
            type: 'event_republished',
          );
        }
      }
    } catch (e) {
      debugPrint('[AdminRepository] Update status error: $e');
      // Local fallback if offline
      final index = _events.indexWhere((e) => e.eventId == id);
      if (index != -1) {
        _events[index] = _events[index].copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
    }
  }

  /// Deletes an event document from Firestore and safely deletes poster from Storage if present.
  Future<void> deleteEvent(String id) async {
    try {
      final index = _events.indexWhere((e) => e.eventId == id);
      String? posterUrl;
      if (index != -1) {
        posterUrl = _events[index].posterUrl;
      }

      await _firestore.collection('EVENTS').doc(id).delete();

      if (posterUrl != null) {
        await safeDeletePoster(posterUrl);
      }
    } catch (e) {
      debugPrint('[AdminRepository] Delete event error: $e');
      _events.removeWhere((e) => e.eventId == id);
      notifyListeners();
    }
  }

  // ============================================================
  // NOTIFICATION HELPERS
  // ============================================================

  /// Batch-writes one NOTIFICATIONS document per Student/Staff user.
  ///
  /// [type] must be one of:
  ///   'event_created', 'event_updated', 'event_cancelled', 'event_republished'.
  /// Admin users are excluded from receiving event notifications.
  /// Firestore batches are capped at 500 writes; for a campus with < 500
  /// users this single batch is sufficient.
  Future<void> _createEventNotifications({
    required String eventId,
    required String eventTitle,
    required String type,
  }) async {
    try {
      // Determine human-readable title and message from type.
      final String notifTitle;
      final String notifMessage;
      switch (type) {
        case 'event_created':
          notifTitle = 'New Event Added';
          notifMessage = '$eventTitle has been added.';
        case 'event_updated':
          notifTitle = 'Event Updated';
          notifMessage = '$eventTitle details have been updated.';
        case 'event_cancelled':
          notifTitle = 'Event Cancelled';
          notifMessage = '$eventTitle has been cancelled.';
        case 'event_republished':
          notifTitle = 'Event Re-published';
          notifMessage = '$eventTitle has been re-published and is now available.';
        default:
          notifTitle = 'Event Notification';
          notifMessage = eventTitle;
      }

      // Only target Student and Staff users (never Admin).
      final recipients = _users
          .where((u) => u.role == 'Student' || u.role == 'Staff')
          .toList();

      if (recipients.isEmpty) {
        debugPrint('[Notifications] No Student/Staff users found; skipping.');
        return;
      }

      final batch = _firestore.batch();
      final now = Timestamp.fromDate(DateTime.now());

      for (final user in recipients) {
        final notifRef = _firestore.collection('NOTIFICATIONS').doc();
        batch.set(notifRef, {
          'notification_id': notifRef.id,
          'user_id': user.uid,
          'type': type,
          'title': notifTitle,
          'message': notifMessage,
          'event_id': eventId,
          'created_at': now,
          'is_read': false,
        });
      }

      await batch.commit();
      debugPrint(
        '[Notifications] Created $type notification for '
        '${recipients.length} user(s). Event: $eventId',
      );
    } catch (e) {
      // Notification failure must never crash the main event flow.
      debugPrint('[Notifications] Failed to create notifications: $e');
    }
  }
}
