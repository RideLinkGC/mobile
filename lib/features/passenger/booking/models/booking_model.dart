import '../../../../core/constants/enums.dart';
import '../../../driver/trip/models/trip_model.dart';

/// Matches the Prisma Booking model from the backend.
class BookingModel {
  final String id;
  final String tripId;
  final String passengerId;
  final int seatsBooked;
  final double totalPrice;
  final String? pickUpPoint;
  final String? dropOffPoint;
  final BookingStatus status;
  final bool isSubscription;
  final String? subscriptionId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Nested trip info (from backend includes)
  final String? tripOrigin;
  final String? tripDestination;
  final DateTime? tripDepartureTime;
  final String? tripDriverId;
  final List<RouteCoordinate> tripRouteCoordinates;
  final double? tripDistanceKm;
  final int? tripAvailableSeats;
  final double? tripPricePerSeat;
  final String? driverName;
  final String? passengerName;
  final String? passengerPhone;
  final String? passengerUserId;

  const BookingModel({
    required this.id,
    required this.tripId,
    required this.passengerId,
    this.seatsBooked = 1,
    required this.totalPrice,
    this.pickUpPoint,
    this.dropOffPoint,
    required this.status,
    this.isSubscription = false,
    this.subscriptionId,
    this.createdAt,
    this.updatedAt,
    this.tripOrigin,
    this.tripDestination,
    this.tripDepartureTime,
    this.tripDriverId,
    this.tripRouteCoordinates = const [],
    this.tripDistanceKm,
    this.tripAvailableSeats,
    this.tripPricePerSeat,
    this.driverName,
    this.passengerName,
    this.passengerPhone,
    this.passengerUserId,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final trip = json['trip'] as Map<String, dynamic>?;
    final driver = trip?['driver'] as Map<String, dynamic>?;
    final driverUser = driver?['user'] as Map<String, dynamic>?;
    final passenger = json['passenger'] as Map<String, dynamic>?;
    final passengerUser = passenger?['user'] as Map<String, dynamic>?;
    List<RouteCoordinate> tripCoords = const [];
    final rawTripCoords = trip?['routeCoordinates'];
    if (rawTripCoords is List) {
      tripCoords = rawTripCoords
          .whereType<Map<String, dynamic>>()
          .map(RouteCoordinate.fromJson)
          .toList();
    }

    return BookingModel(
      id: json['id'] as String? ?? '',
      tripId: json['tripId'] as String? ?? '',
      passengerId: json['passengerId'] as String? ?? '',
      seatsBooked: json['seatsBooked'] as int? ?? 1,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      pickUpPoint: json['pickUpPoint'] as String?,
      dropOffPoint: json['dropOffPoint'] as String?,
      status: _parseStatus(json['status'] as String?),
      isSubscription: json['isSubscription'] as bool? ?? false,
      subscriptionId: json['subscriptionId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      tripOrigin: trip?['origin'] as String?,
      tripDestination: trip?['destination'] as String?,
      tripDepartureTime: trip?['departureTime'] != null
          ? DateTime.parse(trip!['departureTime'] as String)
          : null,
      tripDriverId: trip?['driverId'] as String?,
      tripRouteCoordinates: tripCoords,
      tripDistanceKm: (trip?['distanceKm'] as num?)?.toDouble(),
      tripAvailableSeats: trip?['availableSeats'] as int?,
      tripPricePerSeat: (trip?['pricePerSeat'] as num?)?.toDouble(),
      driverName: driverUser?['name'] as String?,
      passengerName: passengerUser?['name'] as String?,
      passengerPhone: passengerUser?['phone'] as String?,
      passengerUserId: passengerUser?['id'] as String?,
    );
  }

  static BookingStatus _parseStatus(String? s) {
    switch (s) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'cancelled':
      case 'canceled':
        return BookingStatus.canceled;
      case 'completed':
        return BookingStatus.completed;
      default:
        return BookingStatus.pending;
    }
  }
}
