import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
import 'local_storage_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final LocalStorageService _storage = LocalStorageService();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // Request permission on Android 13+
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Notification service initialization error: $e');
    }
  }

  NotificationDetails _notificationDetails() {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'eventhub_channel',
      'EventHub Notifications',
      channelDescription: 'Notifications for event updates, bookings, and alerts',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  // Record into local history
  Future<void> _recordNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    final notification = AppNotificationModel(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
    );

    final currentHistory = _storage.getNotifications();
    currentHistory.insert(0, notification);
    await _storage.saveNotifications(currentHistory);
  }

  // 1. Booking Confirmation Notification
  Future<void> showBookingConfirmation({
    required String eventName,
    required String bookingRef,
    required int seats,
  }) async {
    const title = '🎉 Booking Confirmed!';
    final body =
        'Your booking for "$eventName" ($seats seat${seats > 1 ? 's' : ''}) is confirmed. Ref: $bookingRef';

    await _recordNotification(
      title: title,
      body: body,
      type: 'booking_confirmed',
    );

    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _notificationsPlugin.show(
        id,
        title,
        body,
        _notificationDetails(),
        payload: 'booking_$bookingRef',
      );
    } catch (e) {
      debugPrint('Failed to display native notification: $e');
    }
  }

  // 2. Booking Cancellation Notification
  Future<void> showBookingCancellation({
    required String eventName,
    required String bookingRef,
  }) async {
    const title = '⚠️ Booking Cancelled';
    final body =
        'Your booking ($bookingRef) for "$eventName" has been successfully cancelled and refunded.';

    await _recordNotification(
      title: title,
      body: body,
      type: 'booking_cancelled',
    );

    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _notificationsPlugin.show(
        id,
        title,
        body,
        _notificationDetails(),
        payload: 'cancel_$bookingRef',
      );
    } catch (e) {
      debugPrint('Failed to display native notification: $e');
    }
  }

  // 3. Welcome Notification
  Future<void> showWelcomeNotification({required String userName}) async {
    final title = 'Welcome to EventHub, $userName! 👋';
    const body = 'Discover amazing concerts, sports, tech summits, and more in your city.';

    await _recordNotification(
      title: title,
      body: body,
      type: 'welcome',
    );

    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _notificationsPlugin.show(
        id,
        title,
        body,
        _notificationDetails(),
      );
    } catch (e) {
      debugPrint('Failed to display native notification: $e');
    }
  }

  // 4. Event Update Notification
  Future<void> showEventUpdateNotification({
    required String eventName,
    required String updateMessage,
  }) async {
    final title = '📢 Update: $eventName';
    final body = updateMessage;

    await _recordNotification(
      title: title,
      body: body,
      type: 'event_update',
    );

    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _notificationsPlugin.show(
        id,
        title,
        body,
        _notificationDetails(),
      );
    } catch (e) {
      debugPrint('Failed to display native notification: $e');
    }
  }

  // 5. Scheduled Event Reminder (24h before event)
  Future<void> scheduleEventReminder({
    required String eventName,
    required DateTime eventDateTime,
  }) async {
    final title = '⏰ Event Reminder: $eventName';
    const body = 'Your event is happening tomorrow! Get ready for an awesome experience.';

    await _recordNotification(
      title: title,
      body: body,
      type: 'reminder',
    );
  }

  // Fetch in-app notification history
  List<AppNotificationModel> getHistory() {
    return _storage.getNotifications();
  }

  // Clear all notifications
  Future<void> clearHistory() async {
    await _storage.saveNotifications([]);
  }
}
