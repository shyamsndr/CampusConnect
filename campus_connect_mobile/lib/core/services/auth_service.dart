import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

/// Central authentication service for the CampusConnect mobile app.
///
/// Responsibilities:
/// - Sign in with email OR member code + password
/// - Load the authenticated user's Firestore profile (USERS/{uid})
/// - Expose the current user profile
/// - Sign out
///
/// Firebase Authentication always handles password verification.
/// Passwords are never read from or stored in Firestore.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // STATE
  // ============================================================

  bool _isInitializing = true;
  UserModel? _currentUser;

  bool get isInitializing => _isInitializing;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    Future.microtask(_restoreSession);
  }

  // ============================================================
  // SESSION RESTORATION
  // ============================================================

  /// Called once at startup.
  ///
  /// If Firebase already has an authenticated user, loads the Firestore
  /// profile and navigates straight to Home. Otherwise shows Login.
  Future<void> _restoreSession() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        _currentUser = null;
        return;
      }

      await _loadUserProfile(user.uid);
    } catch (e) {
      debugPrint('[AuthService] Session restore failed: $e');
      _currentUser = null;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  /// Signs in the user with [identifier] (email or member code) and [password].
  ///
  /// Returns `null` on success, or a user-facing error message on failure.
  ///
  /// Flow:
  ///   If identifier looks like an email  → signInWithEmailAndPassword directly
  ///   If identifier looks like a code    → Firestore lookup → get email → signIn
  Future<String?> login(String identifier, String password) async {
    try {
      final trimmed = identifier.trim();

      // Determine whether the identifier is an email or a member code.
      final String emailToUse;

      if (_looksLikeEmail(trimmed)) {
        // A. Direct email login.
        emailToUse = trimmed;
      } else {
        // B. Member code login — look up the email from Firestore.
        final lookedUpEmail = await _emailFromMemberCode(trimmed);

        if (lookedUpEmail == null) {
          return 'Invalid email or member code.';
        }

        emailToUse = lookedUpEmail;
      }

      // Always authenticate via Firebase Auth (password is verified here).
      final credential = await _auth.signInWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        return 'Unable to sign in. Please try again.';
      }

      // Load the Firestore profile using the Firebase UID.
      await _loadUserProfile(firebaseUser.uid);

      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (e) {
      debugPrint('[AuthService] Login error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  /// Signs the user out of Firebase Authentication and clears local state.
  ///
  /// Does NOT delete any Firestore data, complaints, events, or notifications.
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /// Returns true if [value] looks like an email address.
  ///
  /// Both "shyam@example.com" (email) and "MCA001" (member code) must be
  /// accepted as login identifiers. A simple check for the "@" character is
  /// sufficient to distinguish the two cases.
  bool _looksLikeEmail(String value) => value.contains('@');

  /// Queries Firestore USERS for a document whose member_code matches
  /// [memberCode] and returns the associated email address.
  ///
  /// Returns `null` when no matching document is found.
  /// Uses a targeted Firestore query — never downloads the full collection.
  Future<String?> _emailFromMemberCode(String memberCode) async {
    try {
      final snapshot = await _firestore
          .collection('USERS')
          .where('member_code', isEqualTo: memberCode)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data();
      final email = (data['email'] as String?)?.trim();

      if (email == null || email.isEmpty) return null;

      return email;
    } catch (e) {
      debugPrint('[AuthService] Member code lookup failed: $e');
      return null;
    }
  }

  /// Loads the Firestore USERS/{uid} document and stores it as [_currentUser].
  ///
  /// If the document is missing or malformed, [_currentUser] remains null.
  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('USERS').doc(uid).get();

      if (!doc.exists) {
        debugPrint('[AuthService] No Firestore profile for UID: $uid');
        _currentUser = null;
        return;
      }

      _currentUser = UserModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('[AuthService] Failed to load user profile: $e');
      _currentUser = null;
    }
  }

  /// Maps a [FirebaseAuthException] to a clean, user-facing error message.
  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'invalid-login-credentials':
      case 'wrong-password':
      case 'user-not-found':
        return 'Invalid email or member code or password.';

      case 'user-disabled':
        return 'This account has been disabled. Please contact the administrator.';

      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      default:
        return 'Unable to sign in. Please try again.';
    }
  }
}
