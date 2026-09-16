import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking_model.dart';
import '../models/event_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  late SharedPreferences _prefs;
  late Box _favouritesBox;
  late Box _cachedBookingsBox;
  late Box _cachedEventsBox;

  // Initialize SharedPreferences & Hive
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    await Hive.initFlutter();
    _favouritesBox = await Hive.openBox(AppConstants.hiveFavouritesBox);
    _cachedBookingsBox = await Hive.openBox(AppConstants.hiveCachedBookingsBox);
    _cachedEventsBox = await Hive.openBox(AppConstants.hiveCachedEventsBox);
  }

  // ==========================================
  // SESSION MANAGEMENT (shared_preferences)
  // ==========================================

  Future<void> saveUserSession(UserModel user, {String? token}) async {
    await _prefs.setString(AppConstants.keyUserId, user.id);
    await _prefs.setString(AppConstants.keyUserEmail, user.email);
    await _prefs.setString(AppConstants.keyUserRole, user.role);
    await _prefs.setString(AppConstants.keyUserName, user.name);
    await _prefs.setString(AppConstants.keyUserPhone, user.phone);
    if (user.profileImage != null) {
      await _prefs.setString(AppConstants.keyUserProfileImage, user.profileImage!);
    }
    await _prefs.setString(AppConstants.keyToken, token ?? 'mock_token_${user.id}');
    await _prefs.setBool(AppConstants.keyIsLoggedIn, true);
  }

  UserModel? getSavedUser() {
    final isLoggedIn = _prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
    if (!isLoggedIn) return null;

    final id = _prefs.getString(AppConstants.keyUserId);
    final email = _prefs.getString(AppConstants.keyUserEmail);
    final role = _prefs.getString(AppConstants.keyUserRole);
    final name = _prefs.getString(AppConstants.keyUserName);
    final phone = _prefs.getString(AppConstants.keyUserPhone);
    final profileImage = _prefs.getString(AppConstants.keyUserProfileImage);

    if (id == null || email == null) return null;

    return UserModel(
      id: id,
      name: name ?? 'User',
      email: email,
      phone: phone ?? '',
      role: role ?? 'User',
      profileImage: profileImage,
      createdAt: DateTime.now(),
    );
  }

  bool get isLoggedIn => _prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
  String? get userRole => _prefs.getString(AppConstants.keyUserRole);
  String? get userId => _prefs.getString(AppConstants.keyUserId);
  String? get token => _prefs.getString(AppConstants.keyToken);

  Future<void> clearUserSession() async {
    await _prefs.remove(AppConstants.keyUserId);
    await _prefs.remove(AppConstants.keyUserEmail);
    await _prefs.remove(AppConstants.keyUserRole);
    await _prefs.remove(AppConstants.keyUserName);
    await _prefs.remove(AppConstants.keyUserPhone);
    await _prefs.remove(AppConstants.keyUserProfileImage);
    await _prefs.remove(AppConstants.keyToken);
    await _prefs.setBool(AppConstants.keyIsLoggedIn, false);
  }

  // ==========================================
  // THEME PREFERENCES (shared_preferences)
  // ==========================================

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _prefs.setString(AppConstants.keyThemeMode, mode.name);
  }

  ThemeMode getThemeMode() {
    final modeString = _prefs.getString(AppConstants.keyThemeMode);
    if (modeString == ThemeMode.dark.name) {
      return ThemeMode.dark;
    } else if (modeString == ThemeMode.light.name) {
      return ThemeMode.light;
    }
    return ThemeMode.system;
  }

  // ==========================================
  // NOTIFICATION HISTORY (shared_preferences)
  // ==========================================

  Future<void> saveNotifications(List<AppNotificationModel> notifications) async {
    final encoded = jsonEncode(notifications.map((n) => n.toJson()).toList());
    await _prefs.setString(AppConstants.keyNotificationHistory, encoded);
  }

  List<AppNotificationModel> getNotifications() {
    final raw = _prefs.getString(AppConstants.keyNotificationHistory);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map((item) => AppNotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ==========================================
  // HIVE: FAVOURITES
  // ==========================================

  Set<String> getFavouriteEventIds() {
    final keys = _favouritesBox.keys.map((e) => e.toString()).toSet();
    return keys;
  }

  Future<void> toggleFavourite(String eventId) async {
    if (_favouritesBox.containsKey(eventId)) {
      await _favouritesBox.delete(eventId);
    } else {
      await _favouritesBox.put(eventId, true);
    }
  }

  bool isFavourite(String eventId) {
    return _favouritesBox.containsKey(eventId);
  }

  // ==========================================
  // HIVE: OFFLINE CACHE (Events & Bookings)
  // ==========================================

  Future<void> cacheEvents(List<EventModel> events) async {
    await _cachedEventsBox.clear();
    for (final event in events) {
      await _cachedEventsBox.put(event.id, jsonEncode(event.toJson()));
    }
  }

  List<EventModel> getCachedEvents() {
    final List<EventModel> events = [];
    for (final key in _cachedEventsBox.keys) {
      final raw = _cachedEventsBox.get(key);
      if (raw != null) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          events.add(EventModel.fromJson(map));
        } catch (_) {}
      }
    }
    return events;
  }

  Future<void> cacheBookings(List<BookingModel> bookings) async {
    await _cachedBookingsBox.clear();
    for (final booking in bookings) {
      await _cachedBookingsBox.put(booking.id, jsonEncode(booking.toJson()));
    }
  }

  List<BookingModel> getCachedBookings() {
    final List<BookingModel> bookings = [];
    for (final key in _cachedBookingsBox.keys) {
      final raw = _cachedBookingsBox.get(key);
      if (raw != null) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          bookings.add(BookingModel.fromJson(map));
        } catch (_) {}
      }
    }
    return bookings;
  }

  // ==========================================
  // CUSTOM BASE URL (For testing on phone/emulator)
  // ==========================================

  String? getCustomBaseUrl() {
    return _prefs.getString(AppConstants.keyCustomBaseUrl);
  }

  Future<void> setCustomBaseUrl(String url) async {
    await _prefs.setString(AppConstants.keyCustomBaseUrl, url);
  }
}
