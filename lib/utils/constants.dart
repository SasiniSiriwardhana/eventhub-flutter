import 'package:flutter/foundation.dart';

class AppConstants {
  // Application Information
  static const String appName = 'EventHub';
  static const String appTagline = 'Discover & Book Unforgettable Experiences';
  static const String appVersion = '1.0.0';

  // API Configuration
  // Android emulator uses 10.0.2.2, while Web/iOS/Desktop uses localhost
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return 'http://localhost:3000';
    }
  }

  // Network Timeout in milliseconds
  static const int connectTimeout = 10000;
  static const int receiveTimeout = 10000;

  // Categories
  static const List<String> categories = [
    'All',
    'Music',
    'Sports',
    'Tech',
    'Food',
    'Art',
    'Education',
    'Other',
  ];

  // Organizer Event Form Categories (excluding 'All')
  static const List<String> eventCategories = [
    'Music',
    'Sports',
    'Tech',
    'Food',
    'Art',
    'Education',
    'Other',
  ];

  // Sorting Options
  static const String sortDateAsc = 'Date: Earliest First';
  static const String sortDateDesc = 'Date: Latest First';
  static const String sortPriceLow = 'Price: Low to High';
  static const String sortPriceHigh = 'Price: High to Low';
  static const String sortPopularity = 'Popularity (Available Seats)';

  static const List<String> sortOptions = [
    sortDateAsc,
    sortDateDesc,
    sortPriceLow,
    sortPriceHigh,
    sortPopularity,
  ];

  // SharedPreferences Keys
  static const String keyUserId = 'sp_user_id';
  static const String keyUserEmail = 'sp_user_email';
  static const String keyUserRole = 'sp_user_role';
  static const String keyUserName = 'sp_user_name';
  static const String keyUserPhone = 'sp_user_phone';
  static const String keyUserProfileImage = 'sp_user_profile_image';
  static const String keyToken = 'sp_auth_token';
  static const String keyIsLoggedIn = 'sp_is_logged_in';
  static const String keyThemeMode = 'sp_theme_mode';
  static const String keyNotificationHistory = 'sp_notification_history';
  static const String keyUserPreferences = 'sp_user_preferences';
  static const String keyCustomBaseUrl = 'sp_custom_base_url';

  // Hive Box Names
  static const String hiveFavouritesBox = 'favourites_box';
  static const String hiveCachedBookingsBox = 'cached_bookings_box';
  static const String hiveCachedEventsBox = 'cached_events_box';

  // Booking Status Values
  static const String bookingConfirmed = 'Confirmed';
  static const String bookingCancelled = 'Cancelled';
  static const String bookingCompleted = 'Completed';

  // User Roles
  static const String roleUser = 'User';
  static const String roleOrganizer = 'Organizer';

  // Default Asset / Web Placeholders
  static const String placeholderEventImage =
      'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&auto=format&fit=crop&q=80';
  static const String placeholderAvatar =
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80';
}
