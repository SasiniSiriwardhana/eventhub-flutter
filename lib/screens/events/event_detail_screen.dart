import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../../utils/constants.dart';
import '../../utils/routes.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/event_card.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailScreen({
    Key? key,
    required this.event,
  }) : super(key: key);

  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.share_rounded, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Share Event'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invite your friends to "${event.name}"!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                'Join me at ${event.name} on ${event.formattedDisplayDate} at ${event.location}!\nBook tickets on EventHub: https://eventhub.app/events/${event.id}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Link'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Event link copied to clipboard!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
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
    final eventProvider = Provider.of<EventProvider>(context);
    final isFav = eventProvider.isFavourite(event.id);

    // Related events in same category excluding this event
    final relatedEvents = eventProvider.events
        .where((e) => e.category == event.category && e.id != event.id)
        .take(4)
        .toList();

    final canBook = !event.isSoldOut && !event.isPastEvent;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Image AppBar with Back, Favorite, and Share buttons
          SliverAppBar(
            expandedHeight: 280.0,
            pinned: true,
            leading: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.4),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.4),
                child: IconButton(
                  tooltip: 'Share',
                  icon: const Icon(Icons.share_outlined, color: Colors.white),
                  onPressed: () => _showShareDialog(context),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.4),
                child: IconButton(
                  tooltip: 'Save to favourites',
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.redAccent : Colors.white,
                  ),
                  onPressed: () => eventProvider.toggleFavourite(event.id),
                ),
              ),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'event_image_${event.id}',
                    child: CachedNetworkImage(
                      imageUrl: event.imageUrl.isNotEmpty
                          ? event.imageUrl
                          : AppConstants.placeholderEventImage,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.event, size: 64),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Category tag overlay
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Title
                  Text(
                    event.name,
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date & Time Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurfaceElevated : Colors.grey[100],
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.formattedDisplayDate,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                event.time,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Location Box with Map Placeholder
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurfaceElevated : Colors.grey[100],
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: AppTheme.accentDark,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Venue Location',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    event.location,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Interactive Map Placeholder
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            color: isDark ? const Color(0xFF202B38) : const Color(0xFFE8EEF5),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Map grid simulation
                                Opacity(
                                  opacity: 0.25,
                                  child: Icon(
                                    Icons.map_rounded,
                                    size: 100,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.place,
                                      color: AppTheme.errorColor,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${event.latitude ?? 37.7749}, ${event.longitude ?? -122.4194}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Text(
                                      'Interactive Map Preview',
                                      style: TextStyle(fontSize: 10, color: Colors.grey),
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
                  const SizedBox(height: 20),

                  // Organizer Info Tile
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                        child: const Icon(Icons.person, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Organized by',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            Text(
                              event.organizerName.isNotEmpty
                                  ? event.organizerName
                                  : 'Verified Host',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified, size: 14, color: AppTheme.successColor),
                            SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.successColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // About Event Description
                  Text(
                    'About Event',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Related Events Section
                  if (relatedEvents.isNotEmpty) ...[
                    Text(
                      'More in ${event.category}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 230,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: relatedEvents.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final rel = relatedEvents[index];
                          return SizedBox(
                            width: 180,
                            child: EventCard(
                              event: rel,
                              onTap: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.eventDetail,
                                  arguments: rel,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Booking Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Price and Availability
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ticket Price',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    event.isFree ? 'FREE' : '\$${event.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Text(
                    event.isSoldOut
                        ? 'Sold Out'
                        : '${event.availableSeats} seats remaining',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: event.isSoldOut
                          ? AppTheme.errorColor
                          : (event.isFewSeatsLeft
                              ? AppTheme.warningColor
                              : Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),

              // Book Now Button
              Expanded(
                child: CustomButton(
                  text: event.isSoldOut
                      ? 'Sold Out'
                      : (event.isPastEvent ? 'Event Ended' : 'Book Now'),
                  backgroundColor: canBook ? AppTheme.primaryColor : Colors.grey,
                  onPressed: canBook
                      ? () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.bookingForm,
                            arguments: event,
                          );
                        }
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
