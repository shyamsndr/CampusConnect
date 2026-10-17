import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/event_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/event_service.dart';
import '../../widgets/common/event_poster_image.dart';

/// Screen for Staff and Admins to create or edit campus events on mobile.
class MobileEventFormScreen extends StatefulWidget {
  final AuthService authService;
  final EventModel? eventToEdit;

  const MobileEventFormScreen({
    super.key,
    required this.authService,
    this.eventToEdit,
  });

  @override
  State<MobileEventFormScreen> createState() => _MobileEventFormScreenState();
}

class _MobileEventFormScreenState extends State<MobileEventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final EventService _eventService = EventService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _venueController;
  late TextEditingController _timeController;

  late DateTime _selectedDate;
  late String _selectedStatus;

  File? _selectedImageFile;
  String? _existingPosterUrl;

  bool _isSubmitting = false;
  String? _posterError;

  bool get _isEditing => widget.eventToEdit != null;

  @override
  void initState() {
    super.initState();
    final event = widget.eventToEdit;

    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(text: event?.description ?? '');
    _venueController = TextEditingController(text: event?.venue ?? '');
    _timeController = TextEditingController(
      text: event != null && event.eventTime.isNotEmpty
          ? event.eventTime
          : '10:00 AM - 01:00 PM',
    );

    _selectedDate = event?.eventDate ?? DateTime.now().add(const Duration(days: 7));
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

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _selectedImageFile = File(picked.path);
          _posterError = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
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
    if (!_isEditing && _selectedImageFile == null) {
      setState(() {
        _posterError = 'Event poster is required for new events';
      });
    }

    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    if (!_isEditing && _selectedImageFile == null) return;

    setState(() {
      _isSubmitting = true;
    });

    String? newlyUploadedPosterUrl;

    try {
      String posterUrl = _existingPosterUrl ?? '';

      if (_selectedImageFile != null) {
        posterUrl = await _eventService.uploadPoster(_selectedImageFile!);
        newlyUploadedPosterUrl = posterUrl;
      }

      final currentUser = widget.authService.currentUser;
      final currentUid = currentUser?.uid ?? '';
      final currentName = currentUser?.name.isNotEmpty == true
          ? currentUser!.name
          : 'Staff';

      final now = DateTime.now();
      final eventId = widget.eventToEdit?.eventId ??
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
        createdBy: widget.eventToEdit?.createdBy ?? currentName,
        creatorId: (widget.eventToEdit != null && widget.eventToEdit!.creatorId.isNotEmpty)
            ? widget.eventToEdit!.creatorId
            : currentUid,
        status: _selectedStatus,
      );

      if (_isEditing) {
        await _eventService.updateEvent(eventToSave);
      } else {
        await _eventService.createEvent(eventToSave);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Event "${eventToSave.title}" updated successfully.'
                : 'Event "${eventToSave.title}" created successfully.',
          ),
          backgroundColor: const Color(0xFF059669),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (newlyUploadedPosterUrl != null) {
        _eventService.safeDeletePoster(newlyUploadedPosterUrl);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save event: $e'),
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
    final formattedDate =
        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';

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
        title: Text(
          _isEditing ? 'Edit Event' : 'Create Event',
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Poster Picker Card
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _posterError != null
                            ? Colors.redAccent
                            : AppColors.borderGrey,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _selectedImageFile != null
                        ? Image.file(
                            _selectedImageFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : (_existingPosterUrl != null &&
                                _existingPosterUrl!.isNotEmpty)
                            ? EventPosterImage(
                                posterUrl: _existingPosterUrl!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(15),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 48,
                                    color: AppColors.primaryBlue,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Upload Event Poster',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'JPG, PNG up to 5MB',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),
                if (_posterError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _posterError!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Event Title
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Event Title *',
                    hintText: 'e.g. Annual Tech Symposium 2026',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderGrey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderGrey),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Title is required' : null,
                ),

                const SizedBox(height: 16),

                // Date Picker Row
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: AppColors.primaryBlue,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppColors.textGrey,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Time Field
                TextFormField(
                  controller: _timeController,
                  readOnly: true,
                  onTap: _pickTime,
                  decoration: InputDecoration(
                    labelText: 'Event Time *',
                    hintText: 'Select time range',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.access_time_rounded,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderGrey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderGrey),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Time is required' : null,
                ),

                const SizedBox(height: 16),

                // Venue Field
                TextFormField(
                  controller: _venueController,
                  decoration: InputDecoration(
                    labelText: 'Venue *',
                    hintText: 'e.g. Main Auditorium, Block B',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderGrey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderGrey),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Venue is required' : null,
                ),

                const SizedBox(height: 16),

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Provide details about the event schedule and topics...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderGrey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderGrey),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Description is required'
                      : null,
                ),

                const SizedBox(height: 16),

                // Status Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderGrey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderGrey),
                    ),
                  ),
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

                const SizedBox(height: 28),

                // Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Save Changes' : 'Create Event',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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
