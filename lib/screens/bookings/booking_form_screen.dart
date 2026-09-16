import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/event_provider.dart';
import '../../utils/constants.dart';
import '../../utils/routes.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class BookingFormScreen extends StatefulWidget {
  final EventModel event;

  const BookingFormScreen({
    Key? key,
    required this.event,
  }) : super(key: key);

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();

  int _selectedSeats = 1;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  final TextEditingController _specialRequestsController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;

    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  void _incrementSeats() {
    if (_selectedSeats < widget.event.availableSeats) {
      setState(() {
        _selectedSeats++;
      });
    }
  }

  void _decrementSeats() {
    if (_selectedSeats > 1) {
      setState(() {
        _selectedSeats--;
      });
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final eventProvider = Provider.of<EventProvider>(context, listen: false);

    if (auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to complete your booking.'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    // Step 4 & 5: Check availability and create booking
    final createdBooking = await bookingProvider.createBooking(
      event: widget.event,
      user: auth.currentUser!,
      seats: _selectedSeats,
      specialRequests: _specialRequestsController.text,
    );

    if (!mounted) return;

    if (createdBooking != null) {
      // Update local event seat count in EventProvider
      eventProvider.updateLocalSeats(
        widget.event.id,
        widget.event.availableSeats - _selectedSeats,
      );

      // Step 6: Show Confirmation Dialog
      _showConfirmationDialog(createdBooking);
    } else {
      // Step 4 error handling: seats changed or network error
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: AppTheme.errorColor),
              SizedBox(width: 8),
              Text('Booking Failed'),
            ],
          ),
          content: Text(
            bookingProvider.errorMessage ??
                'Seat availability has changed. Please refresh and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                eventProvider.loadEvents();
              },
              child: const Text('Refresh & Try Again'),
            ),
          ],
        ),
      );
    }
  }

  void _showConfirmationDialog(BookingModel booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: const Column(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppTheme.successColor,
              size: 56,
            ),
            SizedBox(height: 12),
            Text(
              'Booking Confirmed!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your seats have been reserved successfully. A confirmation push notification was sent to your device.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'BOOKING REFERENCE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    booking.bookingRef,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Seats Reserved:'),
                Text(
                  '${booking.seats}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount Paid:'),
                Text(
                  '\$${booking.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          CustomButton(
            text: 'View in My Bookings',
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              );
              Navigator.pushNamed(context, AppRoutes.myBookings);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bookingProvider = Provider.of<BookingProvider>(context);

    final totalPrice = _selectedSeats * widget.event.price;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Event'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Summary Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkSurfaceElevated
                        : Colors.white,
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
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                        child: CachedNetworkImage(
                          imageUrl: widget.event.imageUrl.isNotEmpty
                              ? widget.event.imageUrl
                              : AppConstants.placeholderEventImage,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.event.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.event.formattedDisplayDate} • ${widget.event.time}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '\$${widget.event.price.toStringAsFixed(2)} per ticket',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Step 2: Seats Stepper
                Text(
                  'Select Number of Seats',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkSurfaceElevated
                        : Colors.grey[100],
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Seats',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Max available: ${widget.event.availableSeats}',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: _selectedSeats > 1
                                ? AppTheme.primaryColor
                                : Colors.grey,
                            onPressed:
                                _selectedSeats > 1 ? _decrementSeats : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.cardTheme.color,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.darkBorder
                                    : AppTheme.lightBorder,
                              ),
                            ),
                            child: Text(
                              '$_selectedSeats',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            color: _selectedSeats < widget.event.availableSeats
                                ? AppTheme.primaryColor
                                : Colors.grey,
                            onPressed: _selectedSeats <
                                    widget.event.availableSeats
                                ? _incrementSeats
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Attendee Contact Details
                Text(
                  'Attendee Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  prefixIcon: Icons.person_outline,
                  validator: AppValidators.validateName,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: AppValidators.validateEmail,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: AppValidators.validatePhone,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _specialRequestsController,
                  label: 'Special Requests (Optional)',
                  hint: 'e.g. Dietary preferences, wheelchair seating...',
                  maxLines: 3,
                  prefixIcon: Icons.notes_rounded,
                ),
                const SizedBox(height: 28),

                // Price Summary Breakdown
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkSurfaceElevated
                        : Colors.grey[100],
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tickets ($_selectedSeats × \$${widget.event.price.toStringAsFixed(2)})',
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                          Text('\$${totalPrice.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Booking & Processing Fee',
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                          const Text(
                            'FREE',
                            style: TextStyle(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Price',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '\$${totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Button
                CustomButton(
                  text: 'Confirm & Reserve Ticket(s)',
                  isLoading: bookingProvider.isLoading,
                  onPressed: _submitBooking,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
