import 'package:intl/intl.dart';
import '../utils/constants.dart';

class BookingModel {
  final String id;
  final String userId;
  final String eventId;
  final String eventName;
  final int seats;
  final double totalPrice;
  final String status; // 'Confirmed', 'Cancelled', 'Completed'
  final String bookingRef;
  final String specialRequests;
  final DateTime bookedAt;
  final String eventDate; // Format: YYYY-MM-DD
  final String? eventImageUrl;
  final String? eventLocation;
  final String? userName;
  final String? userEmail;
  final String? userPhone;

  const BookingModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.eventName,
    required this.seats,
    required this.totalPrice,
    required this.status,
    required this.bookingRef,
    required this.specialRequests,
    required this.bookedAt,
    required this.eventDate,
    this.eventImageUrl,
    this.eventLocation,
    this.userName,
    this.userEmail,
    this.userPhone,
  });

  bool get isConfirmed => status == AppConstants.bookingConfirmed;
  bool get isCancelled => status == AppConstants.bookingCancelled;
  bool get isCompleted => status == AppConstants.bookingCompleted;

  DateTime? get parsedEventDate {
    try {
      return DateTime.parse(eventDate);
    } catch (_) {
      return null;
    }
  }

  bool get isFutureEvent {
    final date = parsedEventDate;
    if (date == null) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !date.isBefore(today);
  }

  // Can only cancel if confirmed and event is in the future
  bool get canCancel => isConfirmed && isFutureEvent;

  String get formattedBookedDate {
    return DateFormat('MMM d, yyyy • hh:mm a').format(bookedAt);
  }

  String get formattedEventDisplayDate {
    final parsed = parsedEventDate;
    if (parsed == null) return eventDate;
    return DateFormat('EEE, MMM d, yyyy').format(parsed);
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      eventId: json['eventId']?.toString() ?? '',
      eventName: json['eventName'] as String? ?? 'Event',
      seats: json['seats'] != null ? (json['seats'] as num).toInt() : 1,
      totalPrice: json['totalPrice'] != null
          ? (json['totalPrice'] as num).toDouble()
          : 0.0,
      status: json['status'] as String? ?? AppConstants.bookingConfirmed,
      bookingRef: json['bookingRef'] as String? ?? '',
      specialRequests: json['specialRequests'] as String? ?? '',
      bookedAt: json['bookedAt'] != null
          ? DateTime.tryParse(json['bookedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      eventDate: json['eventDate'] as String? ?? '',
      eventImageUrl: json['eventImageUrl'] as String?,
      eventLocation: json['eventLocation'] as String?,
      userName: json['userName'] as String?,
      userEmail: json['userEmail'] as String?,
      userPhone: json['userPhone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'eventId': eventId,
      'eventName': eventName,
      'seats': seats,
      'totalPrice': totalPrice,
      'status': status,
      'bookingRef': bookingRef,
      'specialRequests': specialRequests,
      'bookedAt': bookedAt.toIso8601String(),
      'eventDate': eventDate,
      if (eventImageUrl != null) 'eventImageUrl': eventImageUrl,
      if (eventLocation != null) 'eventLocation': eventLocation,
      if (userName != null) 'userName': userName,
      if (userEmail != null) 'userEmail': userEmail,
      if (userPhone != null) 'userPhone': userPhone,
    };
  }

  BookingModel copyWith({
    String? id,
    String? userId,
    String? eventId,
    String? eventName,
    int? seats,
    double? totalPrice,
    String? status,
    String? bookingRef,
    String? specialRequests,
    DateTime? bookedAt,
    String? eventDate,
    String? eventImageUrl,
    String? eventLocation,
    String? userName,
    String? userEmail,
    String? userPhone,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      seats: seats ?? this.seats,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      bookingRef: bookingRef ?? this.bookingRef,
      specialRequests: specialRequests ?? this.specialRequests,
      bookedAt: bookedAt ?? this.bookedAt,
      eventDate: eventDate ?? this.eventDate,
      eventImageUrl: eventImageUrl ?? this.eventImageUrl,
      eventLocation: eventLocation ?? this.eventLocation,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookingModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
