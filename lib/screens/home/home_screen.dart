import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../utils/constants.dart';
import '../../utils/routes.dart';
import '../../utils/theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/event_card.dart';
import '../../widgets/loading_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final eventProvider = Provider.of<EventProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.celebration, color: AppTheme.primaryColor, size: 22),
            const SizedBox(width: 8),
            Text(
              AppConstants.appName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Search Events',
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.eventSearch);
            },
          ),
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications-history');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => eventProvider.loadEvents(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Welcome Header & Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    Text(
                      'Hello, ${auth.currentUser?.name ?? 'Explorer'} 👋',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Find Amazing Experiences',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Visible Search Bar Trigger
                    InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.eventSearch);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: AppTheme.primaryColor,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Search concerts, sports, meetups...',
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.tune_rounded,
                                size: 16,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Category Filter Chips
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
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
                      onSelected: (selected) {
                        eventProvider.setSelectedCategory(cat);
                      },
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Section Title: Explore Events
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      eventProvider.selectedCategory == 'All'
                          ? 'Upcoming Events'
                          : '${eventProvider.selectedCategory} Events',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${eventProvider.filteredEvents.length} found',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            // Events List / Grid Area
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: _buildEventsContent(context, eventProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsContent(BuildContext context, EventProvider provider) {
    if (provider.isLoading && provider.events.isEmpty) {
      return const SliverFillRemaining(
        child: LoadingWidget(message: 'Discovering events near you...'),
      );
    }

    if (provider.errorMessage != null && provider.events.isEmpty) {
      return SliverFillRemaining(
        child: CustomErrorWidget(
          message: provider.errorMessage!,
          onRetry: () => provider.loadEvents(),
        ),
      );
    }

    final events = provider.filteredEvents;

    if (events.isEmpty) {
      return SliverFillRemaining(
        child: EmptyState(
          title: 'No Events Found',
          message:
              'No events found for category "${provider.selectedCategory}". Try choosing another category.',
          actionText: 'View All Events',
          onAction: () => provider.setSelectedCategory('All'),
        ),
      );
    }

    // Responsive Grid: 2 columns on phone, 3 on tablet/desktop
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.crossAxisExtent >= 600 ? 3 : 2;
        // Aspect ratio dynamically adjusted for responsive card heights
        final childAspectRatio = constraints.crossAxisExtent >= 600 ? 0.76 : 0.65;

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final event = events[index];
              return EventCard(event: event);
            },
            childCount: events.length,
          ),
        );
      },
    );
  }
}
