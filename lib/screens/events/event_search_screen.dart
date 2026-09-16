import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/event_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/event_card.dart';

class EventSearchScreen extends StatefulWidget {
  const EventSearchScreen({Key? key}) : super(key: key);

  @override
  State<EventSearchScreen> createState() => _EventSearchScreenState();
}

class _EventSearchScreenState extends State<EventSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<EventProvider>(context, listen: false);
    _searchController.text = provider.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortBottomSheet(BuildContext context, EventProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Sort Events By',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...AppConstants.sortOptions.map((option) {
                  final isSelected = provider.sortBy == option;
                  return RadioListTile<String>(
                    title: Text(option),
                    value: option,
                    groupValue: provider.sortBy,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (val) {
                      if (val != null) {
                        provider.setSortBy(val);
                        Navigator.pop(ctx);
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventProvider = Provider.of<EventProvider>(context);
    final results = eventProvider.filteredEvents;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: (value) {
            eventProvider.setSearchQuery(value);
          },
          decoration: InputDecoration(
            hintText: 'Search by title, venue, or keyword...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      eventProvider.setSearchQuery('');
                    },
                  )
                : null,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sort Options',
            icon: const Icon(Icons.sort_rounded),
            onPressed: () => _showSortBottomSheet(context, eventProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
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
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),

          // Active Sort Info Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${results.length} result${results.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                InkWell(
                  onTap: () => _showSortBottomSheet(context, eventProvider),
                  child: Row(
                    children: [
                      Text(
                        eventProvider.sortBy,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 18, color: AppTheme.primaryColor),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Results Grid
          Expanded(
            child: results.isEmpty
                ? EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No Matching Events',
                    message:
                        'We could not find any events matching "${_searchController.text}". Try adjusting your search query or filters.',
                    actionText: 'Reset Filters',
                    onAction: () {
                      _searchController.clear();
                      eventProvider.clearFilters();
                    },
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth >= 600 ? 3 : 2;
                      final childAspectRatio =
                          constraints.maxWidth >= 600 ? 0.76 : 0.65;

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final event = results[index];
                          return EventCard(event: event);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
