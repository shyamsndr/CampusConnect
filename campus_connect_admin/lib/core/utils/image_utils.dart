import 'package:flutter/foundation.dart';

/// Sanitizes Firebase Storage image URLs for web and local emulator environments.
///
/// In the local web emulator environment (`useFirebaseEmulator` or web debug mode),
/// replaces the Android emulator loopback host `10.0.2.2` with `127.0.0.1` so that
/// posters and attachments uploaded from the Android emulator load properly in Chrome.
/// In production or for non-emulator URLs, returns the original URL unchanged.
String sanitizeAdminImageUrl(String? url) {
  if (url == null || url.trim().isEmpty) return '';
  final trimmed = url.trim();

  // Only rewrite when running on Web and referencing the Android emulator virtual host
  if (kIsWeb && trimmed.contains('10.0.2.2')) {
    return trimmed.replaceAll('10.0.2.2', '127.0.0.1');
  }

  return trimmed;
}
