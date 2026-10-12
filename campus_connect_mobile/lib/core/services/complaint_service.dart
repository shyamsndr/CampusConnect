import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/issue_model.dart';
import '../models/issue_status_history_model.dart';

/// Service for handling complaint-related Firestore operations (Phase 1).
class ComplaintService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  /// Submits a new complaint using a backend Cloud Function for AI Duplicate Detection.
  Future<void> submitComplaint({
    required String title,
    required String description,
    required String location,
    File? imageFile,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('You must be logged in to report an issue.');
    }

    String? imageUrl;

    // 1. Upload image if present
    if (imageFile != null) {
      try {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = _storage.ref().child('complaints').child(fileName);
        final uploadTask = await ref.putFile(
          imageFile,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        imageUrl = await uploadTask.ref.getDownloadURL();
      } catch (e) {
        debugPrint('[ComplaintService] Image upload failed: $e');
        throw Exception('Failed to upload image. Please try again.');
      }
    }

    // 2. Call Cloud Function
    try {
      final callable = _functions.httpsCallable('submitComplaint');
      await callable.call({
        'title': title,
        'description': description,
        'location': location,
        'imageUrl': imageUrl,
      });
    } catch (e) {
      debugPrint('[ComplaintService] Cloud Function call failed: $e');
      throw Exception('Failed to submit the complaint. Please try again.');
    }
  }

  /// Fetches the issues reported by a specific user.
  /// 
  /// In Phase 1, it queries `ISSUE_REPORTS` for the user, 
  /// then fetches the corresponding `ISSUES`.
  Stream<List<IssueModel>> getUserComplaintsStream(String userId) async* {
    final reportsStream = _firestore
        .collection('ISSUE_REPORTS')
        .where('user_id', isEqualTo: userId)
        .snapshots();

    await for (final reportSnapshot in reportsStream) {
      if (reportSnapshot.docs.isEmpty) {
        yield [];
        continue;
      }

      final issueIds = reportSnapshot.docs
          .map((doc) => doc.data()['issue_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      if (issueIds.isEmpty) {
        yield [];
        continue;
      }

      // Firestore 'whereIn' supports up to 10 items.
      // For Phase 1, chunking to 10 for simplicity.
      final List<IssueModel> issues = [];
      for (var i = 0; i < issueIds.length; i += 10) {
        final end = (i + 10 < issueIds.length) ? i + 10 : issueIds.length;
        final chunk = issueIds.sublist(i, end);

        final issueSnapshot = await _firestore
            .collection('ISSUES')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        issues.addAll(
            issueSnapshot.docs.map((doc) => IssueModel.fromFirestore(doc)));
      }

      // Sort newest first
      issues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      yield issues;
    }
  }

  /// Fetches the status history for a given issue.
  Stream<List<IssueStatusHistoryModel>> getIssueStatusHistory(String issueId) {
    return _firestore
        .collection('ISSUE_STATUS_HISTORY')
        .where('issue_id', isEqualTo: issueId)
        .orderBy('changed_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IssueStatusHistoryModel.fromFirestore(doc))
            .toList());
  }
}

