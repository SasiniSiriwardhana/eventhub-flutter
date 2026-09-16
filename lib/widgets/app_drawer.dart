import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import '../utils/theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout Confirmation'),
        content: const Text('Are you sure you want to sign out from EventHub?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close drawer
              await auth.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showBecomeOrganizerDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.campaign_rounded, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Become an Organizer'),
          ],
        ),
        content: const Text(
          'As an Event Organizer, you will be able to publish new events, manage attendee lists, track seat bookings, and access the Organizer Dashboard.\n\nWould you like to upgrade your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              final success = await auth.becomeOrganizer();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '🎉 You are now an Event Organizer!'
                          : (auth.errorMessage ?? 'Failed to upgrade role.'),
                    ),
                    backgroundColor:
                        success ? AppTheme.successColor : AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Drawer(
      child: Column(
        children: [
          // Drawer Header with User Profile
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [AppTheme.darkSurfaceElevated, AppTheme.darkSurface]
                    : [AppTheme.primaryColor, AppTheme.primaryLightColor],
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: (user?.profileImage != null &&
                          user!.profileImage!.isNotEmpty)
                      ? user.profileImage!
                      : AppConstants.placeholderAvatar,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.person,
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            accountName: Row(
              children: [
                Flexible(
                  child: Text(
                    user?.name ?? 'Guest User',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    user?.role.toUpperCase() ?? 'USER',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            accountEmail: Text(
              user?.email ?? 'Sign in to access all features',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
              ),
            ),
          ),

          // Drawer Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.explore_outlined),
                  title: const Text('Discover Events'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.home);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.confirmation_num_outlined),
                  title: const Text('My Bookings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.myBookings);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.favorite_border_rounded),
                  title: const Text('Favourites'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.favourites);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/notifications-history');
                  },
                ),
                const Divider(),

                // Organizer Section / Become Organizer
                if (authProvider.isOrganizer)
                  ListTile(
                    leading: const Icon(
                      Icons.dashboard_customize_outlined,
                      color: AppTheme.primaryColor,
                    ),
                    title: const Text(
                      'Organizer Dashboard',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.organizerDashboard);
                    },
                  )
                else
                  ListTile(
                    leading: const Icon(
                      Icons.campaign_outlined,
                      color: AppTheme.accentDark,
                    ),
                    title: const Text(
                      'Become an Organizer',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      _showBecomeOrganizerDialog(context, authProvider);
                    },
                  ),

                const Divider(),

                // Profile
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('My Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.profile);
                  },
                ),

                // Settings
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/settings');
                  },
                ),

                // About
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('About EventHub'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/about');
                  },
                ),
              ],
            ),
          ),

          // Drawer Footer with Theme Toggle & Logout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return Row(
                      children: [
                        Icon(
                          themeProvider.isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          themeProvider.isDarkMode ? 'Dark' : 'Light',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Switch(
                          value: themeProvider.isDarkMode,
                          onChanged: (val) => themeProvider.toggleTheme(),
                        ),
                      ],
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Logout',
                  icon: const Icon(Icons.logout, color: AppTheme.errorColor),
                  onPressed: () => _showLogoutDialog(context, authProvider),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
