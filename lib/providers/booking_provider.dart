import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/booking_service.dart';
import '../services/event_service.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();
  final EventService _eventService = EventService();
  final LocalStorageService _storage = LocalStorageService();
  final NotificationService _notificationService = NotificationService();

  List<BookingModel> _bookings = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Upcoming bookings: event is in the future AND status != Cancelled
  List<BookingModel> get upcomingBookings {
    return _bookings.where((b) {
      return b.isFutureEvent && !b.isCancelled;
    }).toList();
  }

  // Past bookings: event is in the past OR status == Cancelled
  List<BookingModel> get pastBookings {
    return _bookings.where((b) {
      return !b.isFutureEvent || b.isCancelled;
    }).toList();
  }

  // Load user bookings
  Future<void> loadUserBookings(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _bookingService.getUserBookings(userId);
      _bookings = fetched;
      await _storage.cacheBookings(fetched);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Offline fallback: load cached bookings from Hive
      final cached = _storage.getCachedBookings();
      if (cached.isNotEmpty) {
        _bookings = cached.where((b) => b.userId == userId).toList();
        _errorMessage = 'Showing offline cached bookings.';
      } else {
        _errorMessage = e.toString();
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to generate reference: EVH-{YYYYMMDD}-{4-digit-random}
  String _generateBookingReference() {
    final now = DateTime.now();
    final datePart = DateFormat('yyyyMMdd').format(now);
    final randomDigits = (1000 + Random().nextInt(9000)).toString();
    return 'EVH-$datePart-$randomDigits';
  }

  // Step 4 & 5: Create Booking flow
  // 1. Re-check availability via GET /events/:id
  // 2. If available, POST /bookings
  // 3. Update event availableSeats via PUT /events/:id
  // 4. Send local notification
  // 5. Store in local cache
  Future<BookingModel?> createBooking({
    required EventModel event,
    required UserModel user,
    required int seats,
    required String specialRequests,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 4: Re-check availability via API before confirming
      final freshEvent = await _eventService.getEventById(event.id);
      if (freshEvent.availableSeats < seats) {
        throw ApiException(
          message:
              'Seats availability changed! Only ${freshEvent.availableSeats} seat(s) left. Please update your selection.',
          statusCode: 409,
        );
      }

      // Generate booking reference
      final bookingRef = _generateBookingReference();
      final totalPrice = seats * freshEvent.price;

      final newBooking = BookingModel(
        id: 'b_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.id,
        eventId: freshEvent.id,
        eventName: freshEvent.name,
        seats: seats,
        totalPrice: totalPrice,
        status: AppConstants.bookingConfirmed,
        bookingRef: bookingRef,
        specialRequests: specialRequests.trim(),
        bookedAt: DateTime.now(),
        eventDate: freshEvent.date,
        eventImageUrl: freshEvent.imageUrl,
        eventLocation: freshEvent.location,
        userName: user.name,
        userEmail: user.email,
        userPhone: user.phone,
      );

      // Step 5: POST /bookings
      final createdBooking = await _bookingService.createBooking(newBooking);

      // Update event available seats via PUT /events/:id
      final updatedRemainingSeats = freshEvent.availableSeats - seats;
      await _eventService.updateAvailableSeats(freshEvent.id, updatedRemainingSeats);

      // Step 7: Send local notification "Booking Confirmed"
      await _notificationService.showBookingConfirmation(
        eventName: freshEvent.name,
        bookingRef: bookingRef,
        seats: seats,
      );

      // Schedule reminder if event date is in the future
      if (freshEvent.parsedDate != null) {
        await _notificationService.scheduleEventReminder(
          eventName: freshEvent.name,
          eventDateTime: freshEvent.parsedDate!,
        );
      }

      // Add to local state
      _bookings.insert(0, createdBooking);
      await _storage.cacheBookings(_bookings);

      _isLoading = false;
      notifyListeners();
      return createdBooking;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Cancel flow:
  // 1. PUT /bookings/:id with status "Cancelled"
  // 2. Restore seats to event via PUT /events/:id
  // 3. Send cancellation notification
  // 4. Update UI
  Future<bool> cancelBooking(BookingModel booking) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Update booking status
      final cancelled = await _bookingService.cancelBooking(booking.id);

      // 2. Restore seats to event
      try {
        final currentEvent = await _eventService.getEventById(booking.eventId);
        final restoredSeats = currentEvent.availableSeats + booking.seats;
        await _eventService.updateAvailableSeats(booking.eventId, restoredSeats);
      } catch (e) {
        debugPrint('Warning: Could not restore seats on server: $e');
      }

      // 3. Send cancellation notification
      await _notificationService.showBookingCancellation(
        eventName: booking.eventName,
        bookingRef: booking.bookingRef,
      );

      // 4. Update local list
      final index = _bookings.indexWhere((b) => b.id == booking.id);
      if (index != -1) {
        _bookings[index] = cancelled;
      }
      await _storage.cacheBookings(_bookings);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
