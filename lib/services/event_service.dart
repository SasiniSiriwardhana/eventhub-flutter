import '../models/event_model.dart';
import 'api_service.dart';

class EventService {
  final ApiService _apiService = ApiService();

  // Get all events
  Future<List<EventModel>> getEvents({
    String? category,
    String? organizerId,
    String? searchQuery,
  }) async {
    final Map<String, dynamic> queryParams = {};
    if (category != null && category != 'All' && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (organizerId != null && organizerId.isNotEmpty) {
      queryParams['organizerId'] = organizerId;
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      queryParams['q'] = searchQuery.trim();
    }

    final response = await _apiService.get(
      '/events',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response is List) {
      return response
          .map((item) => EventModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // Get event by ID
  Future<EventModel> getEventById(String eventId) async {
    final response = await _apiService.get('/events/$eventId');
    if (response is Map<String, dynamic>) {
      return EventModel.fromJson(response);
    }
    throw ApiException(message: 'Event with ID $eventId not found.');
  }

  // Create new event
  Future<EventModel> createEvent(EventModel event) async {
    final response = await _apiService.post('/events', data: event.toJson());
    if (response is Map<String, dynamic>) {
      return EventModel.fromJson(response);
    }
    throw ApiException(message: 'Failed to create event.');
  }

  // Update existing event
  Future<EventModel> updateEvent(EventModel event) async {
    final updatedPayload = event.toJson();
    updatedPayload['updatedAt'] = DateTime.now().toIso8601String();

    final response = await _apiService.put(
      '/events/${event.id}',
      data: updatedPayload,
    );
    if (response is Map<String, dynamic>) {
      return EventModel.fromJson(response);
    }
    throw ApiException(message: 'Failed to update event.');
  }

  // Update available seat count
  Future<EventModel> updateAvailableSeats(String eventId, int newAvailableSeats) async {
    final currentEvent = await getEventById(eventId);
    final updatedEvent = currentEvent.copyWith(
      availableSeats: newAvailableSeats < 0 ? 0 : newAvailableSeats,
      updatedAt: DateTime.now(),
    );
    return await updateEvent(updatedEvent);
  }

  // Delete event
  Future<void> deleteEvent(String eventId) async {
    await _apiService.delete('/events/$eventId');
  }
}
