import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/services/admin_repository.dart';

/// Screen for creating and editing campus events with Firebase Storage poster upload.
class AddEventScreen extends StatefulWidget {
  final AdminRepository repository;
  final EventModel? eventToEdit;
  final VoidCallback onEventAdded;
  final VoidCallback onCancel;

  const AddEventScreen({
    super.key,
    required this.repository,
    this.eventToEdit,
    required this.onEventAdded,
    required this.onCancel,
  });

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _venueController;
  late TextEditingController _timeController;

  late DateTime _selectedDate;
  late String _selectedStatus;

  Uint8List? _selectedPosterBytes;
  String? _selectedPosterName;
  String? _existingPosterUrl;

  bool _isSubmitting = false;
  String? _posterError;

  bool get _isEditing => widget.eventToEdit != null;

  @override
  void initState() {
    super.initState();
    final event = widget.eventToEdit;

    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    _venueController = TextEditingController(text: event?.venue ?? '');
    _timeController = TextEditingController(
      text: event?.eventTime.isNotEmpty == true
          ? event!.eventTime
          : '10:00 AM - 01:00 PM',
    );

    _selectedDate =
        event?.eventDate ?? DateTime.now().add(const Duration(days: 7));
    _selectedStatus = (event?.status.toLowerCase() == 'cancelled')
        ? 'cancelled'
        : 'published';
    _existingPosterUrl = event?.posterUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _pickPoster() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedPosterBytes = bytes;
          _selectedPosterName = pickedFile.name;
          _posterError = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
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

  Future<void> _pickTime() async {
    final TimeOfDay? start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      helpText: 'SELECT START TIME',
    );
    if (start == null || !mounted) return;

    final TimeOfDay? end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (start.hour + 3) % 24, minute: start.minute),
      helpText: 'SELECT END TIME',
    );
    if (end == null || !mounted) return;

    final formattedStart = start.format(context);
    final formattedEnd = end.format(context);

    setState(() {
      _timeController.text = '$formattedStart - $formattedEnd';
    });
  }

  Future<void> _handleSubmit() async {
    debugPrint('[EventSubmit] [1/7] Submit button clicked');

    // Check poster requirement
    if (!_isEditing && _selectedPosterBytes == null) {
      setState(() {
        _posterError = 'Event poster is required for new events';
      });
    }

    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      debugPrint('[EventSubmit] Validation failed');
      return;
    }

    if (!_isEditing && _selectedPosterBytes == null) {
      debugPrint(
        '[EventSubmit] Validation failed: Poster required for new event',
      );
      return;
    }

    debugPrint('[EventSubmit] [2/7] Validation completed successfully');

    setState(() {
      _isSubmitting = true;
    });

    String? newlyUploadedPosterUrl;

    try {
      String posterUrl = _existingPosterUrl ?? '';

      // Upload poster if a new one was selected
      if (_selectedPosterBytes != null) {
        final filename =
            _selectedPosterName ??
            'poster_${DateTime.now().millisecondsSinceEpoch}.jpg';
        posterUrl = await widget.repository.uploadPoster(
          _selectedPosterBytes!,
          filename,
        );
        newlyUploadedPosterUrl = posterUrl;
      }

      final now = DateTime.now();
      final eventId =
          widget.eventToEdit?.eventId ??
          'EVT-2026-${now.millisecondsSinceEpoch.toString().substring(8)}';

      final eventToSave = EventModel(
        eventId: eventId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        eventDate: _selectedDate,
        eventTime: _timeController.text.trim(),
        venue: _venueController.text.trim(),
        posterUrl: posterUrl,
        createdAt: widget.eventToEdit?.createdAt ?? now,
        updatedAt: now,
        createdBy:
            widget.eventToEdit?.createdBy ??
            widget.repository.adminName.ifEmpty('Admin'),
        status: _selectedStatus,
      );

      String? error;
      if (_isEditing) {
        error = await widget.repository.updateEventInFirestore(eventToSave);
      } else {
        error = await widget.repository.saveEventToFirestore(eventToSave);
      }

      if (!mounted) return;

      if (error != null) {
        debugPrint(
          '[EventSubmit] [8/7] Submit failed with Firestore error: $error',
        );
        // Handle partial upload: clean up uploaded poster if firestore document creation failed
        if (newlyUploadedPosterUrl != null) {
          widget.repository.safeDeletePoster(newlyUploadedPosterUrl);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
        );
      } else {
        debugPrint('[EventSubmit] [7/7] Submit completed successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Event "${eventToSave.title}" updated successfully.'
                  : 'Event "${eventToSave.title}" created successfully.',
            ),
            backgroundColor: AppColors.statusResolvedText,
          ),
        );
        widget.onEventAdded();
      }
    } catch (e, stackTrace) {
      debugPrint(
        '[EventSubmit] [8/7] Submit failed with exception: $e\n$stackTrace',
      );
      // Clean up partial upload if present
      if (newlyUploadedPosterUrl != null) {
        widget.repository.safeDeletePoster(newlyUploadedPosterUrl);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving event: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textDark,
                    ),
                    onPressed: widget.onCancel,
                    tooltip: 'Back to Events',
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? 'Edit Campus Event' : 'Add Campus Event',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isEditing
                            ? 'Update details or poster for this campus event.'
                            : 'Create and schedule a new college workshop or event.',
                        style: const TextStyle(
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
                      // Event Poster Picker
                      const Text(
                        'Event Poster *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickPoster,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _posterError != null
                                  ? Colors.red
                                  : AppColors.border,
                            ),
                          ),
                          child: _selectedPosterBytes != null
                              ? Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          _selectedPosterBytes!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: CircleAvatar(
                                        backgroundColor: Colors.black54,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          onPressed: _pickPoster,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : (_existingPosterUrl != null &&
                                    _existingPosterUrl!.isNotEmpty)
                              ? Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          _existingPosterUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              const Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  size: 40,
                                                  color: AppColors.textLight,
                                                ),
                                              ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: CircleAvatar(
                                        backgroundColor: Colors.black54,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          onPressed: _pickPoster,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 40,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Click to select event poster image',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'JPG, PNG images recommended',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      if (_posterError != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _posterError!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

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
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
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
                                  decoration: InputDecoration(
                                    hintText: 'e.g. 09:30 AM - 04:00 PM',
                                    suffixIcon: IconButton(
                                      icon: const Icon(
                                        Icons.access_time,
                                        size: 18,
                                      ),
                                      onPressed: _pickTime,
                                    ),
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
                                      value: 'published',
                                      child: Text('Published'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'cancelled',
                                      child: Text('Cancelled'),
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
                            onPressed: _isSubmitting ? null : widget.onCancel,
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: _isSubmitting
                                ? const SizedBox.shrink()
                                : const Icon(Icons.check, size: 18),
                            label: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _isEditing ? 'Update Event' : 'Save Event',
                                  ),
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

extension StringExtension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
