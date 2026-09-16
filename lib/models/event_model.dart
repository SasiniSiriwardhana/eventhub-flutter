import 'package:intl/intl.dart';

class EventModel {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final String date; // Format: YYYY-MM-DD
  final String time; // Format: hh:mm AM/PM
  final String location;
  final double? latitude;
  final double? longitude;
  final String category;
  final double price;
  final int totalSeats;
  final int availableSeats;
  final String organizerId;
  final String organizerName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    this.latitude,
    this.longitude,
    required this.category,
    required this.price,
    required this.totalSeats,
    required this.availableSeats,
    required this.organizerId,
    required this.organizerName,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isSoldOut => availableSeats <= 0;
  bool get isFewSeatsLeft => availableSeats > 0 && availableSeats <= 5;
  bool get isFree => price == 0;

  DateTime? get parsedDate {
    try {
      return DateTime.parse(date);
    } catch (_) {
      return null;
    }
  }

  bool get isPastEvent {
    final eventDate = parsedDate;
    if (eventDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return eventDate.isBefore(today);
  }

  String get formattedDisplayDate {
    final parsed = parsedDate;
    if (parsed == null) return date;
    return DateFormat('EEE, MMM d, yyyy').format(parsed);
  }

  String get formattedShortDate {
    final parsed = parsedDate;
    if (parsed == null) return date;
    return DateFormat('MMM d').format(parsed);
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      description: json['description'] as String? ?? '',
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      location: json['location'] as String? ?? '',
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      category: json['category'] as String? ?? 'Other',
      price: json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
      totalSeats: json['totalSeats'] != null
          ? (json['totalSeats'] as num).toInt()
          : 0,
      availableSeats: json['availableSeats'] != null
          ? (json['availableSeats'] as num).toInt()
          : 0,
      organizerId: json['organizerId']?.toString() ?? '',
      organizerName: json['organizerName'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'date': date,
      'time': time,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'price': price,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  EventModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? description,
    String? date,
    String? time,
    String? location,
    double? latitude,
    double? longitude,
    String? category,
    double? price,
    int? totalSeats,
    int? availableSeats,
    String? organizerId,
    String? organizerName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      price: price ?? this.price,
      totalSeats: totalSeats ?? this.totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
