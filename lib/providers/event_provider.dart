import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';

class EventProvider extends ChangeNotifier {
  final EventService _eventService = EventService();
  final LocalStorageService _storage = LocalStorageService();
  final NotificationService _notificationService = NotificationService();

  List<EventModel> _events = [];
  List<EventModel> _organizerEvents = [];
  Set<String> _favouriteIds = {};

  bool _isLoading = false;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = AppConstants.sortDateAsc;

  // Getters
  List<EventModel> get events => _events;
  List<EventModel> get organizerEvents => _organizerEvents;
  Set<String> get favouriteIds => _favouriteIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;

  // Favourites list
  List<EventModel> get favouriteEvents {
    return _events.where((e) => _favouriteIds.contains(e.id)).toList();
  }

  // Filtered & Sorted Events
  List<EventModel> get filteredEvents {
    List<EventModel> list = List.from(_events);

    // 1. Filter by category
    if (_selectedCategory != 'All') {
      list = list.where((e) => e.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }

    // 2. Filter by search query (name, location, description)
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((e) {
        return e.name.toLowerCase().contains(q) ||
            e.location.toLowerCase().contains(q) ||
            e.description.toLowerCase().contains(q) ||
            e.category.toLowerCase().contains(q);
      }).toList();
    }

    // 3. Sort
    switch (_sortBy) {
      case AppConstants.sortDateAsc:
        list.sort((a, b) => (a.parsedDate ?? DateTime(2099))
            .compareTo(b.parsedDate ?? DateTime(2099)));
        break;
      case AppConstants.sortDateDesc:
        list.sort((a, b) => (b.parsedDate ?? DateTime(1970))
            .compareTo(a.parsedDate ?? DateTime(1970)));
        break;
      case AppConstants.sortPriceLow:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case AppConstants.sortPriceHigh:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case AppConstants.sortPopularity:
        // More booked seats = totalSeats - availableSeats
        list.sort((a, b) {
          final bookedA = a.totalSeats - a.availableSeats;
          final bookedB = b.totalSeats - b.availableSeats;
          return bookedB.compareTo(bookedA);
        });
        break;
    }

    return list;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _sortBy = AppConstants.sortDateAsc;
    notifyListeners();
  }

  // Initialize and load
  Future<void> loadEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Load favourites from Hive
    _favouriteIds = _storage.getFavouriteEventIds();

    try {
      final fetched = await _eventService.getEvents();
      _events = fetched;
      await _storage.cacheEvents(fetched);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Offline fallback: load cached events
      final cached = _storage.getCachedEvents();
      if (cached.isNotEmpty) {
        _events = cached;
        _errorMessage = 'Showing offline cached events.';
      } else {
        _errorMessage = e.toString();
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load Organizer Events
  Future<void> loadOrganizerEvents(String organizerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _eventService.getEvents(organizerId: organizerId);
      _organizerEvents = fetched;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle Favourite
  Future<void> toggleFavourite(String eventId) async {
    await _storage.toggleFavourite(eventId);
    if (_favouriteIds.contains(eventId)) {
      _favouriteIds.remove(eventId);
    } else {
      _favouriteIds.add(eventId);
    }
    notifyListeners();
  }

  bool isFavourite(String eventId) => _favouriteIds.contains(eventId);

  // Create Event (Organizer)
  Future<bool> createEvent(EventModel event) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _eventService.createEvent(event);
      _events.insert(0, created);
      _organizerEvents.insert(0, created);
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

  // Update Event (Organizer)
  Future<bool> updateEvent(EventModel event) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _eventService.updateEvent(event);

      final index = _events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _events[index] = updated;
      }

      final orgIndex = _organizerEvents.indexWhere((e) => e.id == event.id);
      if (orgIndex != -1) {
        _organizerEvents[orgIndex] = updated;
      }

      // Notify attendees of changes
      await _notificationService.showEventUpdateNotification(
        eventName: updated.name,
        updateMessage: 'Event details for "${updated.name}" have been updated by the organizer.',
      );

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

  // Delete Event (Organizer)
  Future<bool> deleteEvent(String eventId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _eventService.deleteEvent(eventId);
      _events.removeWhere((e) => e.id == eventId);
      _organizerEvents.removeWhere((e) => e.id == eventId);
      _favouriteIds.remove(eventId);
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

  // Update Seats in local state
  void updateLocalSeats(String eventId, int remainingSeats) {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      _events[index] = _events[index].copyWith(availableSeats: remainingSeats);
      notifyListeners();
    }
  }
}
