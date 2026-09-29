import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/event_model.dart';
import '../../widgets/common/event_poster_image.dart';
import 'event_details_screen.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Current date set to start of today for comparing upcoming event dates
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Campus Events',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        // Disable Material overscroll stretch indicator for this screen only.
        child: ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('EVENTS')
                .where('status', isEqualTo: 'published')
                .snapshots(),
            builder: (context, snapshot) {
              // Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                  ),
                );
              }

              // Error state
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Unable to load events',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              final events = <EventModel>[];

              for (final doc in docs) {
                try {
                  final event = EventModel.fromFirestore(doc);
                  // Filter upcoming events (eventDate >= todayStart)
                  if (!event.eventDate.isBefore(todayStart)) {
                    events.add(event);
                  }
                } catch (_) {}
              }

              // Sort upcoming events by eventDate ascending (nearest first)
              events.sort((a, b) => a.eventDate.compareTo(b.eventDate));

              // Empty state
              if (events.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.event_busy_rounded,
                        size: 60,
                        color: AppColors.textGrey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No Upcoming Events',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Check back later for new college activities.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                itemCount: events.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _MobileEventCard(
                    event: event,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventDetailsScreen(event: event),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MobileEventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const _MobileEventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${event.eventDate.day.toString().padLeft(2, '0')}/${event.eventDate.month.toString().padLeft(2, '0')}/${event.eventDate.year}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGrey),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Poster Banner
            EventPosterImage(
              posterUrl: event.posterUrl,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              iconSize: 48,
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.eventTime,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.venue,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
