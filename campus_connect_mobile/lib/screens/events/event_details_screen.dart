import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/event_model.dart';
import '../../widgets/common/event_poster_image.dart';
import 'event_poster_viewer_screen.dart';

class EventDetailsScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${event.eventDate.day.toString().padLeft(2, '0')}/${event.eventDate.month.toString().padLeft(2, '0')}/${event.eventDate.year}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
            color: AppColors.textDark,
          ),
        ),
        title: const Text(
          'Event Details',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        // Disable the Material overscroll stretch indicator locally —
        // only for this screen, not app-wide.
        child: ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Tappable Poster ──────────────────────────────────────
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EventPosterViewerScreen(posterUrl: event.posterUrl),
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 240,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderGrey),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        EventPosterImage(
                          posterUrl: event.posterUrl,
                          height: 240,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(15),
                          iconSize: 54,
                          label: 'Campus Event Poster',
                        ),
                        // Tap-to-zoom hint badge
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.zoom_in_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Tap to view',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Title and Status ──────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: event.status.toLowerCase() == 'published'
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: event.status.toLowerCase() == 'published'
                              ? const Color(0xFF15803D)
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ── Date, Time, Venue Info Cards ──────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Date',
                        value: formattedDate,
                      ),
                      const Divider(height: 20),
                      _InfoRow(
                        icon: Icons.access_time_rounded,
                        label: 'Time',
                        value: event.eventTime,
                      ),
                      const Divider(height: 20),
                      _InfoRow(
                        icon: Icons.location_on_rounded,
                        label: 'Venue',
                        value: event.venue,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Description Section ───────────────────────────────────
                const Text(
                  'About Event',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.primaryBlue),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
