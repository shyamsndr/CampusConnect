import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/image_utils.dart';

/// Reusable platform-aware poster image loader with loading, error, and placeholder states.
class EventPosterImage extends StatelessWidget {
  final String? posterUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double iconSize;
  final Color iconColor;
  final Color? backgroundColor;
  final String? label;

  const EventPosterImage({
    super.key,
    required this.posterUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.iconSize = 44.0,
    this.iconColor = AppColors.primaryBlue,
    this.backgroundColor,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final sanitizedUrl = sanitizeStorageUrl(posterUrl);
    final isValidUrl =
        sanitizedUrl.isNotEmpty &&
        (sanitizedUrl.startsWith('http://') ||
            sanitizedUrl.startsWith('https://'));

    final effectiveBgColor = backgroundColor ?? const Color(0xFFF1F5F9);

    Widget buildPlaceholder() {
      return Container(
        width: width,
        height: height,
        color: effectiveBgColor,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_rounded, size: iconSize, color: iconColor),
            if (label != null && label!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                label!,
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      );
    }

    Widget content;
    if (!isValidUrl) {
      content = buildPlaceholder();
    } else {
      content = Image.network(
        sanitizedUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: effectiveBgColor,
            alignment: Alignment.center,
            child: SizedBox(
              width: (iconSize * 0.6).clamp(16.0, 28.0),
              height: (iconSize * 0.6).clamp(16.0, 28.0),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: iconColor,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return buildPlaceholder();
        },
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: content);
    }

    return content;
  }
}
