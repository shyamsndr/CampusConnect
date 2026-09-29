import 'package:flutter/foundation.dart';

/// Sanitizes Firebase Storage URLs for platform compatibility.
///
/// Converts local emulator loopback hosts (`127.0.0.1` or `localhost`)
/// to `10.0.2.2` when running on the Android emulator.
String sanitizeStorageUrl(String? url) {
  if (url == null || url.trim().isEmpty) return '';
  final trimmed = url.trim();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    if (trimmed.contains('127.0.0.1')) {
      return trimmed.replaceAll('127.0.0.1', '10.0.2.2');
    }
    if (trimmed.contains('localhost')) {
      return trimmed.replaceAll('localhost', '10.0.2.2');
    }
  }

  return trimmed;
}
