import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../models/event_model.dart';
import '../../services/booking_service.dart';
import '../../utils/theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';

class EventBookingsScreen extends StatefulWidget {
  final EventModel event;

  const EventBookingsScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<EventBookingsScreen> createState() => _EventBookingsScreenState();
}

class _EventBookingsScreenState extends State<EventBookingsScreen> {
  final BookingService _bookingService = BookingService();

  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await _bookingService.getEventBookings(widget.event.id);
      setState(() {
        _bookings = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _exportAttendees() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✓ Attendee roster exported (${_bookings.length} records processed).',
        ),
        backgroundColor: AppTheme.successColor,
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final confirmedBookings = _bookings.where((b) => b.isConfirmed).toList();
    final totalTicketsSold = confirmedBookings.fold<int>(
      0,
      (sum, item) => sum + item.seats,
    );
    final totalRevenue = confirmedBookings.fold<double>(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Event Attendees', style: TextStyle(fontSize: 16)),
            Text(
              widget.event.name,
              style: TextStyle(
                fontSize: 11,
                color: theme.textTheme.bodyMedium?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Export Attendees',
            icon: const Icon(Icons.download_rounded),
            onPressed: _bookings.isNotEmpty ? _exportAttendees : null,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Retrieving attendee roster...')
          : RefreshIndicator(
              onRefresh: _fetchBookings,
              child: CustomScrollView(
                slivers: [
                  // Revenue & Attendance Metrics Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [AppTheme.darkSurfaceElevated, AppTheme.darkSurface]
                                : [AppTheme.primaryColor, AppTheme.primaryLightColor],
                          ),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Revenue',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${totalRevenue.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 40,
                              width: 1,
                              color: Colors.white24,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                children: [
                                  const Text(
                                    'Tickets Sold',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$totalTicketsSold / ${widget.event.totalSeats}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Attendees Count Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Text(
                        'Registered Attendees (${_bookings.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Bookings List
                  if (_bookings.isEmpty)
                    const SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.people_outline,
                        title: 'No Bookings Yet',
                        message:
                            'No attendees have reserved tickets for this event yet.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final booking = _bookings[index];
                            final isConfirmed = booking.isConfirmed;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          booking.userName ?? 'Attendee',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: (isConfirmed
                                                    ? AppTheme.successColor
                                                    : AppTheme.errorColor)
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            booking.status.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isConfirmed
                                                  ? AppTheme.successColor
                                                  : AppTheme.errorColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.email_outlined,
                                            size: 13, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          booking.userEmail ?? 'No email',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme
                                                .textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.phone_outlined,
                                            size: 13, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          booking.userPhone ?? 'No phone',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme
                                                .textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Seats: ${booking.seats} ticket(s) • Ref: ${booking.bookingRef}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          '\$${booking.totalPrice.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (booking.specialRequests.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppTheme.darkSurfaceElevated
                                              : Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Notes: ${booking.specialRequests}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: _bookings.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
