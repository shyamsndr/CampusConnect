import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/image_utils.dart';

/// Full-screen interactive poster viewer.
///
/// Supports pinch-to-zoom and pan via [InteractiveViewer].
/// Android system back and the close button both dismiss this screen.
class EventPosterViewerScreen extends StatelessWidget {
  final String? posterUrl;

  const EventPosterViewerScreen({super.key, required this.posterUrl});

  @override
  Widget build(BuildContext context) {
    final sanitizedUrl = sanitizeStorageUrl(posterUrl);
    final isValidUrl =
        sanitizedUrl.isNotEmpty &&
        (sanitizedUrl.startsWith('http://') ||
            sanitizedUrl.startsWith('https://'));

    return Scaffold(
      backgroundColor: Colors.black,
      // Transparent app bar so the close button floats over the dark background
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: isValidUrl
              ? InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5.0,
                  child: Image.network(
                    sanitizedUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryBlue,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholder(),
                  ),
                )
              : _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.event_rounded, size: 72, color: AppColors.textGrey),
        SizedBox(height: 12),
        Text(
          'Poster unavailable',
          style: TextStyle(color: AppColors.textGrey, fontSize: 14),
        ),
      ],
    );
  }
}
