import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../../utils/constants.dart';
import '../../utils/routes.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/event_card.dart';
import '../../widgets/loading_widget.dart';

class EventListScreen extends StatelessWidget {
  const EventListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.eventSearch),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => eventProvider.loadEvents(),
        child: Column(
          children: [
            // Category horizontal filter chips
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: AppConstants.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = AppConstants.categories[index];
                    final isSelected = eventProvider.selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) => eventProvider.setSelectedCategory(cat),
                    );
                  },
                ),
              ),
            ),

            // Events List
            Expanded(
              child: _buildBody(context, eventProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, EventProvider provider) {
    if (provider.isLoading && provider.events.isEmpty) {
      return const LoadingWidget(message: 'Loading events...');
    }

    if (provider.errorMessage != null && provider.events.isEmpty) {
      return CustomErrorWidget(
        message: provider.errorMessage!,
        onRetry: () => provider.loadEvents(),
      );
    }

    final events = provider.filteredEvents;

    if (events.isEmpty) {
      return EmptyState(
        title: 'No Events Found',
        message: 'No events match your current filter selection.',
        actionText: 'Show All Events',
        onAction: () => provider.setSelectedCategory('All'),
      );
    }

    // Responsive Grid/List
    return LayoutBuilder(
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
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return EventCard(event: event);
          },
        );
      },
    );
  }
}
