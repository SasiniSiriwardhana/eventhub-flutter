import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';
import '../bookings/my_bookings_screen.dart';
import '../favourites/favourites_screen.dart';
import '../organizer/organizer_dashboard.dart';
import '../profile/profile_screen.dart';
import 'home_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isOrganizer = authProvider.isOrganizer;

    // Role-based screen list
    final List<Widget> screens = isOrganizer
        ? [
            const HomeScreen(),
            const OrganizerDashboard(),
            const MyBookingsScreen(),
            const ProfileScreen(),
          ]
        : [
            const HomeScreen(),
            const MyBookingsScreen(),
            const FavouritesScreen(),
            const ProfileScreen(),
          ];

    // Role-based Navigation Destinations
    final List<NavigationDestination> destinations = isOrganizer
        ? const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.dashboard_customize_outlined),
              selectedIcon: Icon(Icons.dashboard_customize),
              label: 'My Events',
            ),
            NavigationDestination(
              icon: Icon(Icons.confirmation_num_outlined),
              selectedIcon: Icon(Icons.confirmation_num),
              label: 'Bookings',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.confirmation_num_outlined),
              selectedIcon: Icon(Icons.confirmation_num),
              label: 'My Bookings',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border_rounded),
              selectedIcon: Icon(Icons.favorite_rounded),
              label: 'Favourites',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ];

    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletOrLarger = screenWidth >= 600;

    // Adjust index if out of range on role swap
    final safeIndex = _currentIndex >= screens.length ? 0 : _currentIndex;

    if (isTabletOrLarger) {
      return Scaffold(
        drawer: const AppDrawer(),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: safeIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              destinations: destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: d.icon,
                      selectedIcon: d.selectedIcon,
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: IndexedStack(
                index: safeIndex,
                children: screens,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: safeIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: destinations,
      ),
    );
  }
}
