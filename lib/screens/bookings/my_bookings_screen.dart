import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/event_provider.dart';
import '../../utils/routes.dart';
import '../../utils/theme.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser != null) {
      Provider.of<BookingProvider>(context, listen: false)
          .loadUserBookings(auth.currentUser!.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCancelDialog(BookingModel booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor),
            SizedBox(width: 8),
            Text('Cancel Booking?'),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel your reservation for "${booking.eventName}" (${booking.seats} seat(s))?\n\nThis action cannot be undone and your tickets will be released back to the general pool.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Tickets'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final provider =
                  Provider.of<BookingProvider>(context, listen: false);
              final eventProvider =
                  Provider.of<EventProvider>(context, listen: false);

              final success = await provider.cancelBooking(booking);

              if (mounted) {
                if (success) {
                  // Reload events to reflect restored seats
                  eventProvider.loadEvents();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Booking successfully cancelled.'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.errorMessage ??
                            'Failed to cancel booking. Please try again.',
                      ),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm Cancellation'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final bookingProvider = Provider.of<BookingProvider>(context);

    if (auth.currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Bookings')),
        body: EmptyState(
          icon: Icons.lock_outline,
          title: 'Sign In Required',
          message: 'Please sign in to view and manage your booked tickets.',
          actionText: 'Sign In',
          onAction: () => Navigator.pushNamed(context, AppRoutes.login),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          tabs: [
            Tab(
              text: 'Upcoming (${bookingProvider.upcomingBookings.length})',
            ),
            Tab(
              text: 'Past (${bookingProvider.pastBookings.length})',
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: bookingProvider.isLoading && bookingProvider.bookings.isEmpty
            ? const LoadingWidget(message: 'Loading your tickets...')
            : TabBarView(
                controller: _tabController,
                children: [
                  // Upcoming Bookings Tab
                  _buildBookingsList(
                    bookingProvider.upcomingBookings,
                    isUpcoming: true,
                  ),

                  // Past Bookings Tab
                  _buildBookingsList(
                    bookingProvider.pastBookings,
                    isUpcoming: false,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBookingsList(
    List<BookingModel> bookings, {
    required bool isUpcoming,
  }) {
    if (bookings.isEmpty) {
      return EmptyState(
        icon: Icons.confirmation_num_outlined,
        title: isUpcoming ? 'No Upcoming Bookings' : 'No Past Bookings',
        message: isUpcoming
            ? 'You have no upcoming events booked. Explore what is happening in your area!'
            : 'You have no completed or cancelled bookings yet.',
        actionText: isUpcoming ? 'Browse Events' : null,
        onAction: isUpcoming
            ? () {
                Navigator.pushNamed(context, AppRoutes.home);
              }
            : null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return BookingCard(
          booking: booking,
          onCancel: booking.canCancel ? () => _showCancelDialog(booking) : null,
        );
      },
    );
  }
}
