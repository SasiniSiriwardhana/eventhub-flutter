import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../services/booking_service.dart';
import '../../utils/constants.dart';
import '../../utils/routes.dart';
import '../../utils/theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';

class OrganizerDashboard extends StatefulWidget {
  const OrganizerDashboard({Key? key}) : super(key: key);

  @override
  State<OrganizerDashboard> createState() => _OrganizerDashboardState();
}

class _OrganizerDashboardState extends State<OrganizerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BookingService _bookingService = BookingService();

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
      Provider.of<EventProvider>(context, listen: false)
          .loadOrganizerEvents(auth.currentUser!.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleDeleteEvent(EventModel event) async {
    // Check if bookings exist first
    int bookingCount = 0;
    try {
      final bookings = await _bookingService.getEventBookings(event.id);
      bookingCount = bookings.where((b) => b.isConfirmed).length;
    } catch (_) {}

    if (!mounted) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor),
            SizedBox(width: 8),
            Text('Delete Event?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to permanently delete "${event.name}"?'),
            if (bookingCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: AppTheme.errorColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Warning: $bookingCount active booking(s) exist for this event!',
                        style: const TextStyle(
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Event'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final success = await eventProvider.deleteEvent(event.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '✓ Event successfully deleted.'
                  : (eventProvider.errorMessage ?? 'Failed to delete event.'),
            ),
            backgroundColor:
                success ? AppTheme.successColor : AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final eventProvider = Provider.of<EventProvider>(context);

    final orgEvents = eventProvider.organizerEvents;
    final activeEvents = orgEvents.where((e) => !e.isPastEvent).toList();
    final pastEvents = orgEvents.where((e) => e.isPastEvent).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizer Studio'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          tabs: [
            Tab(text: 'Active Events (${activeEvents.length})'),
            Tab(text: 'Past Events (${pastEvents.length})'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: eventProvider.isLoading && orgEvents.isEmpty
            ? const LoadingWidget(message: 'Loading your published events...')
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildEventList(activeEvents, isActiveTab: true),
                  _buildEventList(pastEvents, isActiveTab: false),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Publish Event'),
        onPressed: () async {
          final created = await Navigator.pushNamed(
            context,
            AppRoutes.addEditEvent,
          );
          if (created == true) {
            _loadData();
          }
        },
      ),
    );
  }

  Widget _buildEventList(List<EventModel> events, {required bool isActiveTab}) {
    if (events.isEmpty) {
      return EmptyState(
        icon: Icons.campaign_outlined,
        title: isActiveTab ? 'No Active Events' : 'No Past Events',
        message: isActiveTab
            ? 'You have not published any upcoming events. Tap the button below to create your first event!'
            : 'Completed events will appear here once their dates have passed.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final bookedSeats = event.totalSeats - event.availableSeats;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: event.imageUrl.isNotEmpty
                            ? event.imageUrl
                            : AppConstants.placeholderEventImage,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              event.category,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${event.formattedShortDate} • ${event.time}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '\$${event.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$bookedSeats/${event.totalSeats} booked',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18),

                // Actions: Attendees, Edit, Delete
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.people_outline, size: 16),
                      label: const Text(
                        'View Attendees',
                        style: TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.eventBookings,
                          arguments: event,
                        );
                      },
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Edit Event',
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: AppTheme.primaryColor,
                          ),
                          onPressed: () async {
                            final updated = await Navigator.pushNamed(
                              context,
                              AppRoutes.addEditEvent,
                              arguments: event,
                            );
                            if (updated == true) {
                              _loadData();
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Delete Event',
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: AppTheme.errorColor,
                          ),
                          onPressed: () => _handleDeleteEvent(event),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
