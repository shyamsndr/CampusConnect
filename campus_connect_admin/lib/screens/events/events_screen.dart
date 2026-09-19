import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/services/admin_repository.dart';
import '../../widgets/common/status_badge.dart';

/// Screen displaying campus events with options to add, publish, and manage events.
class EventsScreen extends StatelessWidget {
  final AdminRepository repository;
  final VoidCallback onAddEvent;

  const EventsScreen({
    super.key,
    required this.repository,
    required this.onAddEvent,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final events = repository.events;

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
                          horizontal: 16, vertical: 11),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Events List Container
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: events.isEmpty
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
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Event Name')),
                            DataColumn(label: Text('Date & Time')),
                            DataColumn(label: Text('Venue')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: events.map((event) {
                            final isPublished = event.status == 'Published';

                            return DataRow(
                              cells: [
                                DataCell(
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 240),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          event.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
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
                                  ),
                                ),
                                DataCell(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${event.date.day.toString().padLeft(2, '0')}/${event.date.month.toString().padLeft(2, '0')}/${event.date.year}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        event.time,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 180),
                                    child: Text(
                                      event.venue,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(StatusBadge.fromStatus(event.status)),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () {
                                          final nextStatus = isPublished
                                              ? 'Draft'
                                              : 'Published';
                                          repository.updateEventStatus(
                                              event.id, nextStatus);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Event "${event.title}" marked as $nextStatus.',
                                              ),
                                              duration:
                                                  const Duration(seconds: 2),
                                              backgroundColor: isPublished
                                                  ? AppColors.textDark
                                                  : AppColors
                                                      .statusResolvedText,
                                            ),
                                          );
                                        },
                                        child: Text(
                                          isPublished ? 'Unpublish' : 'Publish',
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Colors.redAccent,
                                        ),
                                        tooltip: 'Delete Event',
                                        onPressed: () {
                                          _confirmDeleteEvent(
                                              context, event, repository);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteEvent(
      BuildContext context, EventModel event, AdminRepository repository) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Event'),
          content: Text(
              'Are you sure you want to remove "${event.title}" from campus events?'),
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
                repository.deleteEvent(event.id);
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
