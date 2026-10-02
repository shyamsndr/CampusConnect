import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/event_model.dart';
import '../../core/models/notification_model.dart';
import '../../core/services/auth_service.dart';
import '../events/event_details_screen.dart';

/// Displays the authenticated user's in-app notification list, streamed
/// from the Firestore NOTIFICATIONS collection.
///
/// Notifications are grouped by date section (Today / Yesterday / older
/// formatted dates). Tapping a notification marks it as read and navigates
/// to the corresponding Event Details screen (or shows a message when the
/// event no longer exists).
class NotificationsScreen extends StatelessWidget {
  final AuthService authService;

  const NotificationsScreen({super.key, required this.authService});

  // ─────────────────────────────────────────────────────────────
  // MARK NOTIFICATION AS READ
  // ─────────────────────────────────────────────────────────────

  Future<void> _markRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('NOTIFICATIONS')
          .doc(notificationId)
          .update({'is_read': true});
    } catch (e) {
      debugPrint('[Notifications] Failed to mark as read: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CLEAR ALL NOTIFICATIONS
  // ─────────────────────────────────────────────────────────────

  Future<void> _clearAll(BuildContext context, String uid) async {
    // Show confirmation dialog.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text('This will remove all your notifications.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      // Fetch only this user's notification documents.
      final snapshot = await FirebaseFirestore.instance
          .collection('NOTIFICATIONS')
          .where('user_id', isEqualTo: uid)
          .get();

      if (snapshot.docs.isEmpty) return; // nothing to delete

      // Delete in batches of 500 (Firestore batch limit).
      const batchSize = 500;
      final docs = snapshot.docs;
      for (var i = 0; i < docs.length; i += batchSize) {
        final batch = FirebaseFirestore.instance.batch();
        final chunk = docs.skip(i).take(batchSize);
        for (final doc in chunk) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications cleared.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('[Notifications] Failed to clear all: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to clear notifications. Please try again.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // NAVIGATE TO EVENT DETAILS
  // ─────────────────────────────────────────────────────────────

  Future<void> _openEvent(
    BuildContext context,
    NotificationModel notification,
  ) async {
    // Mark as read immediately (fire-and-forget; never awaited in UI path).
    _markRead(notification.notificationId);

    if (!context.mounted) return;

    if (notification.eventId.isEmpty) return;

    // Show a loading indicator while we fetch the event.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final doc = await FirebaseFirestore.instance
          .collection('EVENTS')
          .doc(notification.eventId)
          .get();

      if (!context.mounted) return;
      Navigator.pop(context); // dismiss loading dialog

      if (!doc.exists) {
        // Event was deleted after the notification was created.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This event is no longer available.',
              style: TextStyle(fontSize: 14),
            ),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      final event = EventModel.fromFirestore(doc);

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event)),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // dismiss loading dialog on error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load event details. Please try again.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // DATE LABEL HELPERS
  // ─────────────────────────────────────────────────────────────

  String _sectionLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';

    // e.g. "28 Sep 2026"
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? "" : "s"} ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  // ─────────────────────────────────────────────────────────────
  // ICON + COLOUR PER TYPE
  // ─────────────────────────────────────────────────────────────

  IconData _iconFor(String type) {
    return switch (type) {
      'event_created' => Icons.event_available_rounded,
      'event_updated' => Icons.edit_calendar_rounded,
      'event_cancelled' => Icons.event_busy_rounded,
      'event_republished' => Icons.event_repeat_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  Color _colorFor(String type) {
    return switch (type) {
      'event_created' => const Color(0xFF1769E0),
      'event_updated' => const Color(0xFF7C3AED),
      'event_cancelled' => Colors.redAccent,
      'event_republished' => const Color(0xFF059669),
      _ => AppColors.textGrey,
    };
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final uid = authService.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated.')),
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('NOTIFICATIONS')
        .where('user_id', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .snapshots();

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
          'Notifications',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _clearAll(context, uid),
            child: const Text(
              'Clear All',
              style: TextStyle(
                fontSize: 13,
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text(
                      'Unable to load notifications.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 64,
                    color: AppColors.textGrey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "You'll see event updates here.",
                    style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                  ),
                ],
              ),
            );
          }

          // Parse and group by date section label.
          final notifications = docs
              .map((d) {
                try {
                  return NotificationModel.fromFirestore(d);
                } catch (_) {
                  return null;
                }
              })
              .whereType<NotificationModel>()
              .toList();

          // Build ordered list of [label, NotificationModel] pairs.
          final List<Object> items = []; // String = section header, NotificationModel = row
          String? lastLabel;
          for (final n in notifications) {
            final label = _sectionLabel(n.createdAt);
            if (label != lastLabel) {
              items.add(label);
              lastLabel = label;
            }
            items.add(n);
          }

          return ScrollConfiguration(
            behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                // Section header
                if (item is String) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 6),
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textGrey,
                        letterSpacing: 0.5,
                      ),
                    ),
                  );
                }

                // Notification row
                final n = item as NotificationModel;
                final accent = _colorFor(n.type);

                return _NotificationTile(
                  notification: n,
                  accent: accent,
                  icon: _iconFor(n.type),
                  timeAgo: _timeAgo(n.createdAt),
                  onTap: () => _openEvent(context, n),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFICATION TILE
// ─────────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final Color accent;
  final IconData icon;
  final String timeAgo;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.accent,
    required this.icon,
    required this.timeAgo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isUnread
              ? accent.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnread
                ? accent.withValues(alpha: 0.25)
                : AppColors.borderGrey,
            width: isUnread ? 1.5 : 1,
          ),
          boxShadow: isUnread
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: accent),
              ),

              const SizedBox(width: 12),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        // Unread dot
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textGrey.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),

              // Tap chevron
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 6),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textGrey.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}