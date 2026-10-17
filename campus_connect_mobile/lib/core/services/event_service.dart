import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/event_model.dart';

/// Service responsible for managing events and poster uploads on mobile.
class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Uploads poster image file to Firebase Storage under `events/posters/`.
  Future<String> uploadPoster(File imageFile) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('You must be logged in to upload an event poster.');
    }

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_poster.jpg';
      final ref = _storage
          .ref()
          .child('events')
          .child('posters')
          .child(currentUser.uid)
          .child(fileName);
      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('[EventService] Poster upload failed: $e');
      throw Exception('Failed to upload event poster. Please try again.');
    }
  }

  /// Deletes a poster from Firebase Storage safely.
  Future<void> safeDeletePoster(String posterUrl) async {
    if (posterUrl.isNotEmpty && posterUrl.startsWith('http')) {
      try {
        final storageRef = _storage.refFromURL(posterUrl);
        await storageRef.delete();
      } catch (e) {
        debugPrint('[EventService] Poster cleanup warning: $e');
      }
    }
  }

  /// Creates a new event in Firestore.
  Future<void> createEvent(EventModel event) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('You must be logged in to create an event.');
    }

    final docRef = _firestore.collection('EVENTS').doc(event.eventId);
    await docRef.set(event.toFirestore());
  }

  /// Updates an existing event in Firestore.
  Future<void> updateEvent(EventModel event) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('You must be logged in to edit this event.');
    }

    final docRef = _firestore.collection('EVENTS').doc(event.eventId);
    await docRef.update(event.toFirestore());
  }

  /// Deletes an event document from Firestore and removes its poster if present.
  Future<void> deleteEvent(String eventId, String? posterUrl) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('You must be logged in to delete this event.');
    }

    await _firestore.collection('EVENTS').doc(eventId).delete();

    if (posterUrl != null && posterUrl.isNotEmpty) {
      await safeDeletePoster(posterUrl);
    }
  }
}
