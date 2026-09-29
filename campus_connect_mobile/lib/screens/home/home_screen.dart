import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/event_model.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/common/event_poster_image.dart';
import '../complaints/report_issue_screen.dart';
import '../events/event_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final AuthService authService;

  const HomeScreen({super.key, required this.authService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  double _scrollOffset = 0;

  static const double headerHeight = 300;
  static const double panelTop = 245;
  static const double contentTop = 273;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (!mounted) return;

      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // DYNAMIC GREETING
  // ============================================================

  /// Returns a time-appropriate greeting based on the device's local time.
  ///
  /// 05:00 – 11:59 → Good Morning
  /// 12:00 – 16:59 → Good Afternoon
  /// 17:00 – 20:59 → Good Evening
  /// 21:00 – 04:59 → Good Night
  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  @override
  Widget build(BuildContext context) {
    // Once the white panel reaches the top,
    // keep its background pinned there.
    final double panelMovement = _scrollOffset > panelTop
        ? _scrollOffset - panelTop
        : 0;

    // Gradually remove the rounded corners as the panel reaches the top.
    final double radius = (30 - ((_scrollOffset / panelTop) * 30)).clamp(0, 30);

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          height: 1120,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // =====================================================
              // BLUE HEADER
              // =====================================================
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: headerHeight,
                child: _buildBlueHeader(),
              ),

              // =====================================================
              // WHITE PANEL BACKGROUND
              // =====================================================
              Positioned(
                top: panelTop,
                left: 0,
                right: 0,
                bottom: 0,
                child: Transform.translate(
                  offset: Offset(0, panelMovement),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(radius),
                        topRight: Radius.circular(radius),
                      ),
                    ),
                  ),
                ),
              ),

              // =====================================================
              // CONTENT
              // =====================================================
              Positioned(
                top: contentTop,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(17, 28, 17, 40),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // BLUE HEADER
  // ===============================================================

  Widget _buildBlueHeader() {
    final greeting = _getGreeting();
    final userName = widget.authService.currentUser?.name ?? '';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryBlue, AppColors.lightBlue],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(55),
          bottomRight: Radius.circular(55),
        ),
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            top: 38,
            right: 28,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Decorative circle
          Positioned(
            top: 98,
            right: 70,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Dynamic greeting and user name from Firestore
          Positioned(
            top: 34,
            left: 26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting 👋',
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Campus Connected
          Positioned(
            left: 28,
            right: 28,
            bottom: 72,
            child: Container(
              height: 82,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.primaryBlue,
                      size: 29,
                    ),
                  ),

                  const SizedBox(width: 14),

                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Campus is connected',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Everything in one place',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // CONTENT
  // ===============================================================

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.add_rounded,
                title: 'Report',
                subtitle: 'Issue',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ReportIssueScreen(authService: widget.authService),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: _QuickActionCard(
                icon: Icons.remove_rounded,
                title: 'My',
                subtitle: 'Complaints',
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        const Text(
          'Upcoming Events',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 14),

        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('EVENTS')
              .where('status', isEqualTo: 'published')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                  ),
                ),
              );
            }

            final now = DateTime.now();
            final todayStart = DateTime(now.year, now.month, now.day);
            final docs = snapshot.data?.docs ?? [];
            final events = <EventModel>[];

            for (final doc in docs) {
              try {
                final event = EventModel.fromFirestore(doc);
                if (!event.eventDate.isBefore(todayStart)) {
                  events.add(event);
                }
              } catch (_) {}
            }

            events.sort((a, b) => a.eventDate.compareTo(b.eventDate));

            if (events.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE0E5EA)),
                ),
                child: const Text(
                  'No upcoming campus events scheduled right now.',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                ),
              );
            }

            final topEvents = events.take(3).toList();

            return Column(
              children: topEvents.map((event) {
                final formattedDate =
                    '${event.eventDate.day.toString().padLeft(2, '0')}/${event.eventDate.month.toString().padLeft(2, '0')}/${event.eventDate.year}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventDetailsScreen(event: event),
                        ),
                      );
                    },
                    child: _EventCard(
                      icon: Icons.event,
                      posterUrl: event.posterUrl,
                      title: event.title,
                      date: formattedDate,
                      venue: event.venue,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 40),
      ],
    );
  }
}

// =============================================================
// QUICK ACTION CARD
// =============================================================

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 125,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF6FD),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 38),
            ),

            const SizedBox(height: 11),

            Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// EVENT CARD
// =============================================================

class _EventCard extends StatelessWidget {
  final IconData icon;
  final String? posterUrl;
  final String title;
  final String date;
  final String venue;

  const _EventCard({
    required this.icon,
    this.posterUrl,
    required this.title,
    required this.date,
    required this.venue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE0E5EA)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: EventPosterImage(
              posterUrl: posterUrl,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(11),
              iconSize: 21,
              backgroundColor: Colors.transparent,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 11,
                      color: AppColors.textGrey,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      date,
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 3),

                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 11,
                      color: AppColors.textGrey,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      venue,
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
