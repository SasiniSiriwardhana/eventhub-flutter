import 'package:flutter/material.dart';

import '../models/event_model.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/main_navigation.dart';
import '../screens/events/event_list_screen.dart';
import '../screens/events/event_detail_screen.dart';
import '../screens/events/event_search_screen.dart';
import '../screens/bookings/booking_form_screen.dart';
import '../screens/bookings/my_bookings_screen.dart';
import '../screens/organizer/organizer_dashboard.dart';
import '../screens/organizer/add_edit_event_screen.dart';
import '../screens/organizer/event_bookings_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/favourites/favourites_screen.dart';
import '../screens/notifications/notification_history_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/about/about_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String eventList = '/events';
  static const String eventDetail = '/event-detail';
  static const String eventSearch = '/event-search';
  static const String bookingForm = '/booking-form';
  static const String myBookings = '/my-bookings';
  static const String organizerDashboard = '/organizer-dashboard';
  static const String addEditEvent = '/add-edit-event';
  static const String eventBookings = '/event-bookings';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String favourites = '/favourites';
  static const String notificationHistory = '/notifications-history';
  static const String settings = '/settings';
  static const String about = '/about';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);
      case login:
        return _buildRoute(const LoginScreen(), settings);
      case register:
        return _buildRoute(const RegisterScreen(), settings);
      case home:
        return _buildRoute(const MainNavigation(), settings);
      case eventList:
        return _buildRoute(const EventListScreen(), settings);
      case eventDetail:
        final event = settings.arguments as EventModel;
        return _buildRoute(EventDetailScreen(event: event), settings);
      case eventSearch:
        return _buildRoute(const EventSearchScreen(), settings);
      case bookingForm:
        final event = settings.arguments as EventModel;
        return _buildRoute(BookingFormScreen(event: event), settings);
      case myBookings:
        return _buildRoute(const MyBookingsScreen(), settings);
      case organizerDashboard:
        return _buildRoute(const OrganizerDashboard(), settings);
      case addEditEvent:
        final event = settings.arguments as EventModel?;
        return _buildRoute(AddEditEventScreen(event: event), settings);
      case eventBookings:
        final event = settings.arguments as EventModel;
        return _buildRoute(EventBookingsScreen(event: event), settings);
      case profile:
        return _buildRoute(const ProfileScreen(), settings);
      case editProfile:
        return _buildRoute(const EditProfileScreen(), settings);
      case favourites:
        return _buildRoute(const FavouritesScreen(), settings);
      case notificationHistory:
        return _buildRoute(const NotificationHistoryScreen(), settings);
      case AppRoutes.settings:
        return _buildRoute(const SettingsScreen(), settings);
      case about:
        return _buildRoute(const AboutScreen(), settings);
      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          settings,
        );
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.05, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        final offsetAnimation = animation.drive(tween);
        final fadeAnimation = CurvedAnimation(parent: animation, curve: Curves.easeIn);

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}
