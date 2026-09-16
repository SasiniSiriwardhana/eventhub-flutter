import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/event_provider.dart';
import '../../utils/routes.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/event_card.dart';

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final favEvents = eventProvider.favouriteEvents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Favourites'),
        actions: [
          if (favEvents.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  '${favEvents.length} saved',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
      body: favEvents.isEmpty
          ? EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'No Favourites Saved',
              message:
                  'You have not added any events to your favourites yet. Tap the heart icon on any event card to save it here for quick access.',
              actionText: 'Discover Events',
              onAction: () {
                Navigator.pushNamed(context, AppRoutes.home);
              },
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 600 ? 3 : 2;
                final childAspectRatio = constraints.maxWidth >= 600 ? 0.76 : 0.65;

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: favEvents.length,
                  itemBuilder: (context, index) {
                    final event = favEvents[index];
                    return EventCard(event: event);
                  },
                );
              },
            ),
    );
  }
}
