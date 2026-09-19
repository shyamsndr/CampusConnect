import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/services/admin_repository.dart';

/// Screen for creating and scheduling new campus events.
class AddEventScreen extends StatefulWidget {
  final AdminRepository repository;
  final VoidCallback onEventAdded;
  final VoidCallback onCancel;

  const AddEventScreen({
    super.key,
    required this.repository,
    required this.onEventAdded,
    required this.onCancel,
  });

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  final _timeController = TextEditingController(text: '10:00 AM - 01:00 PM');

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  String _selectedStatus = 'Published';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final newEvent = EventModel(
      id: 'EVT-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      date: _selectedDate,
      time: _timeController.text.trim(),
      venue: _venueController.text.trim(),
      status: _selectedStatus,
    );

    widget.repository.addEvent(newEvent);

    setState(() {
      _isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Event "${newEvent.title}" created successfully.'),
        backgroundColor: AppColors.statusResolvedText,
      ),
    );

    widget.onEventAdded();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                    onPressed: widget.onCancel,
                    tooltip: 'Back to Events',
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Campus Event',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Create and schedule a new college workshop or event.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Form Card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Event Title
                      const Text(
                        'Event Title *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. AI & Robotics Symposium 2026',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Event title is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // Description
                      const Text(
                        'Description *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText:
                              'Brief summary of the event, eligibility, and agenda...',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Description is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // Date & Time
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Picker Button
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Event Date *',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 18,
                                          color: AppColors.textGrey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Time input
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Time Duration *',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _timeController,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. 09:30 AM - 04:00 PM',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Time is required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Venue & Status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Venue / Location *',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _venueController,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. Main Auditorium',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Venue is required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Status *',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedStatus,
                                  decoration: const InputDecoration(),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Published',
                                      child: Text('Published'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Draft',
                                      child: Text('Draft'),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedStatus = val;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: widget.onCancel,
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check, size: 18),
                            label: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('Save Event'),
                            onPressed: _isSubmitting ? null : _handleSubmit,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
