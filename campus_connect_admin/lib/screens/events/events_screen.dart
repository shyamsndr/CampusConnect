import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/services/admin_repository.dart';
import '../../widgets/common/status_badge.dart';

/// Screen displaying campus events with options to add, edit, unpublish/publish, and delete events.
class EventsScreen extends StatelessWidget {
  final AdminRepository repository;
  final VoidCallback onAddEvent;
  final ValueChanged<EventModel>? onEditEvent;

  const EventsScreen({
    super.key,
    required this.repository,
    required this.onAddEvent,
    this.onEditEvent,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final events = repository.events;
        final isLoading = repository.isLoadingEvents;
        final error = repository.eventsError;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header & Add Event button
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Campus Events',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Schedule and publish workshops, symposiums, and college activities.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Event'),
                    onPressed: onAddEvent,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              if (error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    error,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: isLoading
                    ? Container(
                        padding: const EdgeInsets.all(48),
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      )
                    : events.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(48),
                        alignment: Alignment.center,
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 44,
                              color: AppColors.textLight,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No events created yet.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildEventTable(context, events),
              ),
            ],
          ),
        );
      },
    );
  }

  // Proportional column definitions for Admin Events Table
  static const _columns = [
    ('Poster', 8),
    ('Event Name', 30),
    ('Date & Time', 20),
    ('Venue', 15),
    ('Status', 10),
    ('Actions', 17),
  ];

  static const double _minTableWidth = 850;

  Widget _buildEventTable(BuildContext context, List<EventModel> events) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth > _minTableWidth
            ? constraints.maxWidth
            : _minTableWidth;

        final totalFlex = _columns.fold<int>(0, (sum, col) => sum + col.$2);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header row
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(7),
                    ),
                  ),
                  child: Row(
                    children: _columns.map((col) {
                      final width = (tableWidth * col.$2) / totalFlex;
                      return SizedBox(
                        width: width,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Text(
                            col.$1,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textGrey,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const Divider(height: 1, color: AppColors.border),

                // Data rows
                ...events.asMap().entries.map((entry) {
                  final index = entry.key;
                  final event = entry.value;
                  final isLast = index == events.length - 1;
                  final isEven = index.isEven;
                  final isPublished = event.status.toLowerCase() == 'published';

                  Widget cell(Widget child, int flex) {
                    return SizedBox(
                      width: (tableWidth * flex) / totalFlex,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: child,
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Container(
                        color: isEven
                            ? AppColors.surface
                            : AppColors.background,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Poster Thumbnail (8%)
                            cell(
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: (event.posterUrl.isNotEmpty)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(5),
                                        child: Image.network(
                                          event.posterUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => const Icon(
                                            Icons.event,
                                            size: 22,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.event,
                                        size: 22,
                                        color: AppColors.primary,
                                      ),
                              ),
                              8,
                            ),

                            // Event Name & Description (30%)
                            cell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppColors.textDark,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (event.description.isNotEmpty)
                                    Text(
                                      event.description,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textGrey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                              30,
                            ),

                            // Date & Time (20%)
                            cell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${event.eventDate.day.toString().padLeft(2, '0')}/${event.eventDate.month.toString().padLeft(2, '0')}/${event.eventDate.year}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    event.eventTime,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                ],
                              ),
                              20,
                            ),

                            // Venue (15%)
                            cell(
                              Text(
                                event.venue,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                              15,
                            ),

                            // Status (10%)
                            cell(
                              Align(
                                alignment: Alignment.centerLeft,
                                child: StatusBadge.fromStatus(
                                  isPublished ? 'published' : 'cancelled',
                                ),
                              ),
                              10,
                            ),

                            // Actions (17%)
                            cell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                    tooltip: 'Edit Event',
                                    onPressed: () {
                                      if (onEditEvent != null) {
                                        onEditEvent!(event);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 2),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {
                                      final nextStatus = isPublished
                                          ? 'cancelled'
                                          : 'published';
                                      repository.updateEventStatus(
                                        event.eventId,
                                        nextStatus,
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Event "${event.title}" status changed to $nextStatus.',
                                          ),
                                          duration: const Duration(seconds: 2),
                                          backgroundColor: isPublished
                                              ? AppColors.textDark
                                              : AppColors.statusResolvedText,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      isPublished ? 'Cancel Event' : 'Publish',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.redAccent,
                                    ),
                                    tooltip: 'Delete Event',
                                    onPressed: () {
                                      _confirmDeleteEvent(
                                        context,
                                        event,
                                        repository,
                                      );
                                    },
                                  ),
                                ],
                              ),
                              17,
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        const Divider(height: 1, color: AppColors.borderLight),
                    ],
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteEvent(
    BuildContext context,
    EventModel event,
    AdminRepository repository,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Event'),
          content: Text(
            'Are you sure you want to remove "${event.title}" from campus events?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                repository.deleteEvent(event.eventId);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted event "${event.title}".'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
