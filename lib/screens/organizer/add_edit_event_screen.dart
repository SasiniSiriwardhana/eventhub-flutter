import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AddEditEventScreen extends StatefulWidget {
  final EventModel? event;

  const AddEditEventScreen({Key? key, this.event}) : super(key: key);

  @override
  State<AddEditEventScreen> createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends State<AddEditEventScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _imageUrlController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late TextEditingController _totalSeatsController;
  late TextEditingController _latController;
  late TextEditingController _lngController;

  late String _selectedCategory;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _previewImageUrl;

  bool get isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final e = widget.event;

    _nameController = TextEditingController(text: e?.name ?? '');
    _imageUrlController = TextEditingController(text: e?.imageUrl ?? '');
    _descriptionController =
        TextEditingController(text: e?.description ?? '');
    _locationController = TextEditingController(text: e?.location ?? '');
    _priceController =
        TextEditingController(text: e != null ? e.price.toString() : '');
    _totalSeatsController =
        TextEditingController(text: e != null ? e.totalSeats.toString() : '');
    _latController =
        TextEditingController(text: e?.latitude != null ? e!.latitude.toString() : '');
    _lngController =
        TextEditingController(text: e?.longitude != null ? e!.longitude.toString() : '');

    _selectedCategory = e?.category ?? AppConstants.eventCategories.first;
    _previewImageUrl = e?.imageUrl;

    if (e != null) {
      _selectedDate = e.parsedDate;
      // Parse time string e.g. "09:00 AM"
      try {
        final parsed = DateFormat('hh:mm a').parse(e.time);
        _selectedTime = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
      } catch (_) {
        _selectedTime = const TimeOfDay(hour: 18, minute: 0);
      }
    } else {
      _selectedDate = DateTime.now().add(const Duration(days: 7));
      _selectedTime = const TimeOfDay(hour: 18, minute: 0);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _totalSeatsController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an event date.'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an event start time.'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final eventProvider = Provider.of<EventProvider>(context, listen: false);

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final now = DateTime.now();
    final timeDate = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    final formattedTime = DateFormat('hh:mm a').format(timeDate);

    final totalSeats = int.parse(_totalSeatsController.text.trim());
    final price = double.parse(_priceController.text.trim());
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());

    if (isEditing) {
      final current = widget.event!;
      // Calculate available seats difference if total seats changed
      final seatsBooked = current.totalSeats - current.availableSeats;
      final newAvailableSeats = (totalSeats - seatsBooked).clamp(0, totalSeats);

      final updatedEvent = current.copyWith(
        name: _nameController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        category: _selectedCategory,
        price: price,
        totalSeats: totalSeats,
        availableSeats: newAvailableSeats,
        date: formattedDate,
        time: formattedTime,
        latitude: lat,
        longitude: lng,
        updatedAt: DateTime.now(),
      );

      final success = await eventProvider.updateEvent(updatedEvent);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Event updated successfully.'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(eventProvider.errorMessage ?? 'Update failed.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } else {
      // Create new event
      final newEvent = EventModel(
        id: 'e_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isNotEmpty
            ? _imageUrlController.text.trim()
            : AppConstants.placeholderEventImage,
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        category: _selectedCategory,
        price: price,
        totalSeats: totalSeats,
        availableSeats: totalSeats,
        date: formattedDate,
        time: formattedTime,
        latitude: lat,
        longitude: lng,
        organizerId: auth.currentUser?.id ?? 'u_org',
        organizerName: auth.currentUser?.name ?? 'Event Organizer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await eventProvider.createEvent(newEvent);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Event published successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(eventProvider.errorMessage ?? 'Publish failed.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final eventProvider = Provider.of<EventProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Event' : 'Publish New Event'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Name
              CustomTextField(
                controller: _nameController,
                label: 'Event Title',
                hint: 'e.g. Neon Dreams Music Festival',
                prefixIcon: Icons.title_rounded,
                validator: (val) => AppValidators.validateRequired(val, 'Event title'),
              ),
              const SizedBox(height: 18),

              // Category Dropdown
              Text(
                'Category',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined, size: 20),
                ),
                items: AppConstants.eventCategories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCategory = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 18),

              // Image URL & Live Preview
              CustomTextField(
                controller: _imageUrlController,
                label: 'Event Cover Image URL',
                hint: 'https://images.unsplash.com/...',
                prefixIcon: Icons.image_outlined,
                validator: (val) => AppValidators.validateUrl(val, optional: true),
                onChanged: (val) {
                  setState(() {
                    _previewImageUrl = val.trim();
                  });
                },
              ),
              const SizedBox(height: 10),

              // Live Image Preview Box
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceElevated : Colors.grey[200],
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _previewImageUrl != null && _previewImageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: _previewImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (ctx, url, err) => const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image_rounded, size: 36, color: Colors.grey),
                              SizedBox(height: 4),
                              Text('Invalid image URL', style: TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                      )
                    : const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_size_select_actual_outlined,
                                size: 36, color: Colors.grey),
                            SizedBox(height: 4),
                            Text('Image Preview',
                                style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 18),

              // Date & Time Picker Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Event Date',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: theme.inputDecorationTheme.fillColor,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMedium),
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.darkBorder
                                    : AppTheme.lightBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month,
                                    size: 18, color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedDate != null
                                      ? DateFormat('MMM d, yyyy')
                                          .format(_selectedDate!)
                                      : 'Select Date',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Start Time',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: theme.inputDecorationTheme.fillColor,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMedium),
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.darkBorder
                                    : AppTheme.lightBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded,
                                    size: 18, color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedTime != null
                                      ? _selectedTime!.format(context)
                                      : 'Select Time',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Location Venue
              CustomTextField(
                controller: _locationController,
                label: 'Venue Location',
                hint: 'e.g. Bayfront Park, Miami, FL',
                prefixIcon: Icons.location_on_outlined,
                validator: (val) =>
                    AppValidators.validateRequired(val, 'Venue location'),
              ),
              const SizedBox(height: 18),

              // Price & Total Seats Row
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _priceController,
                      label: 'Price per Ticket (\$) ',
                      hint: '0 for Free',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.attach_money_rounded,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Price required';
                        }
                        if (double.tryParse(val.trim()) == null) {
                          return 'Invalid price';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _totalSeatsController,
                      label: 'Total Seats',
                      hint: 'e.g. 150',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.event_seat_outlined,
                      validator: (val) =>
                          AppValidators.validatePositiveNumber(val, 'Seats'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Description
              CustomTextField(
                controller: _descriptionController,
                label: 'Event Description',
                hint: 'Provide a detailed overview of the event, itinerary, and rules...',
                maxLines: 4,
                prefixIcon: Icons.description_outlined,
                validator: (val) =>
                    AppValidators.validateRequired(val, 'Description'),
              ),
              const SizedBox(height: 18),

              // Optional Geo-coordinates (Latitude & Longitude)
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _latController,
                      label: 'Latitude (Optional)',
                      hint: 'e.g. 25.7753',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) =>
                          AppValidators.validateCoordinate(val, 'Latitude'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _lngController,
                      label: 'Longitude (Optional)',
                      hint: 'e.g. -80.1862',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) =>
                          AppValidators.validateCoordinate(val, 'Longitude'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Save Button
              CustomButton(
                text: isEditing ? 'Update Event' : 'Publish Event',
                isLoading: eventProvider.isLoading,
                onPressed: _saveEvent,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
