import '../../../../core/constants/enums.dart';

class RouteCoordinate {
  final double lat;
  final double lng;

  const RouteCoordinate({required this.lat, required this.lng});

  factory RouteCoordinate.fromJson(Map<String, dynamic> json) {
    return RouteCoordinate(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}

/// Matches the Prisma Trip model from the backend.
class TripModel {
  final String id;
  final String driverId;
  final String origin;
  final String destination;
  final List<RouteCoordinate> routeCoordinates;
  final double distanceKm;
  final DateTime departureTime;
  final int availableSeats;
  final double pricePerSeat;
  final TripStatus status;
  final String? seriesId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Nested driver info (included from backend joins)
  final String? driverName;
  final String? driverEmail;
  final String? driverPhone;
  final double? driverRating;
  final String? driverImage;
  final String? vehicleModel;
  final String? vehiclePlate;
  final int? vehicleSeats;

  // Nested bookings count
  final int bookedSeats;

  const TripModel({
    required this.id,
    required this.driverId,
    required this.origin,
    required this.destination,
    this.routeCoordinates = const [],
    this.distanceKm = 0,
    required this.departureTime,
    required this.availableSeats,
    required this.pricePerSeat,
    required this.status,
    this.seriesId,
    this.createdAt,
    this.updatedAt,
    this.driverName,
    this.driverEmail,
    this.driverPhone,
    this.driverRating,
    this.driverImage,
    this.vehicleModel,
    this.vehiclePlate,
    this.vehicleSeats,
    this.bookedSeats = 0,
  });

  int get seatsLeft => availableSeats - bookedSeats;

  String get departureTimeFormatted {
    final h = departureTime.hour.toString().padLeft(2, '0');
    final m = departureTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  factory TripModel.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'] as Map<String, dynamic>?;
    final driverUser = driver?['user'] as Map<String, dynamic>?;

    List<RouteCoordinate> coords = [];
    final rawCoords = json['routeCoordinates'];
    if (rawCoords is List) {
      coords = rawCoords
          .map((e) => RouteCoordinate.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    int booked = 0;
    final bookings = json['bookings'] as List?;
    if (bookings != null) {
      for (final b in bookings) {
        final status = (b as Map<String, dynamic>)['status'] as String?;
        if (status == 'confirmed' || status == 'pending') {
          booked += (b['seatsBooked'] as int?) ?? 1;
        }
      }
    }
    if (json['_bookedSeats'] != null) {
      booked = json['_bookedSeats'] as int;
    }
    final count = json['_count'] as Map<String, dynamic>?;
    final countBookings = count?['bookings'];
    if (booked == 0 && countBookings is int) {
      booked = countBookings;
    }

    return TripModel(
      id: json['id'] as String? ?? '',
      driverId: json['driverId'] as String? ?? '',
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      routeCoordinates: coords,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      departureTime: json['departureTime'] != null
          ? DateTime.parse(json['departureTime'] as String)
          : DateTime.now(),
      availableSeats: json['availableSeats'] as int? ?? 0,
      pricePerSeat: (json['pricePerSeat'] as num?)?.toDouble() ?? 0,
      status: _parseStatus(json['status'] as String?),
      seriesId: json['seriesId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      driverName: driverUser?['name'] as String?,
      driverEmail: driverUser?['email'] as String?,
      driverPhone: driverUser?['phone'] as String?,
      driverRating: (driverUser?['rating'] as num?)?.toDouble(),
      driverImage: driverUser?['image'] as String?,
      vehicleModel: driver?['vehicleModel'] as String?,
      vehiclePlate: driver?['vehiclePlate'] as String?,
      vehicleSeats: driver?['vehicleSeats'] as int?,
      bookedSeats: booked,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'origin': origin,
      'destination': destination,
      'routeCoordinates':
          routeCoordinates.map((c) => c.toJson()).toList(),
      'distanceKm': distanceKm,
      'departureTime': departureTime.toIso8601String(),
      'availableSeats': availableSeats,
      'pricePerSeat': pricePerSeat,
    };
  }

  static TripStatus _parseStatus(String? status) {
    switch (status) {
      case 'scheduled':
        return TripStatus.scheduled;
      case 'inProgress':
        return TripStatus.inProgress;
      case 'completed':
        return TripStatus.completed;
      case 'cancelled':
      case 'canceled':
        return TripStatus.canceled;
      default:
        return TripStatus.scheduled;
    }
  }
}
