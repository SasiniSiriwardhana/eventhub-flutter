import '../models/booking_model.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class BookingService {
  final ApiService _apiService = ApiService();

  // Get bookings for a specific user
  Future<List<BookingModel>> getUserBookings(String userId) async {
    final response = await _apiService.get(
      '/bookings',
      queryParameters: {'userId': userId},
    );

    if (response is List) {
      return response
          .map((item) => BookingModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // Get bookings for a specific event (for organizer)
  Future<List<BookingModel>> getEventBookings(String eventId) async {
    final response = await _apiService.get(
      '/bookings',
      queryParameters: {'eventId': eventId},
    );

    if (response is List) {
      return response
          .map((item) => BookingModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // Create a new booking
  Future<BookingModel> createBooking(BookingModel booking) async {
    final response = await _apiService.post(
      '/bookings',
      data: booking.toJson(),
    );

    if (response is Map<String, dynamic>) {
      return BookingModel.fromJson(response);
    }
    throw ApiException(message: 'Failed to complete booking.');
  }

  // Cancel booking
  Future<BookingModel> cancelBooking(String bookingId) async {
    final currentBookingData = await _apiService.get('/bookings/$bookingId');
    if (currentBookingData is! Map<String, dynamic>) {
      throw ApiException(message: 'Booking not found.');
    }

    final updated = Map<String, dynamic>.from(currentBookingData);
    updated['status'] = AppConstants.bookingCancelled;

    final response = await _apiService.put(
      '/bookings/$bookingId',
      data: updated,
    );

    if (response is Map<String, dynamic>) {
      return BookingModel.fromJson(response);
    }
    throw ApiException(message: 'Failed to cancel booking.');
  }

  // Delete booking (for cleanup if needed)
  Future<void> deleteBooking(String bookingId) async {
    await _apiService.delete('/bookings/$bookingId');
  }
}
