import '../../../../core/constants/enums.dart';
import 'trip_model.dart';

/// Matches the Prisma TripSeries model from the backend.
class TripSeriesModel {
  final String id;
  final String driverId;
  final String origin;
  final String destination;
  final List<RouteCoordinate> routeCoordinates;
  final double distanceKm;
  final int availableSeats;
  final double pricePerSeat;

  // Recurrence
  final List<int> daysOfWeek;
  final String departureTimeOfDay;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String>? exceptions;
  final bool isActive;

  // Subscription config
  final List<SubscriptionType> subscriptionOptions;
  final Map<String, double>? subscriptionPricing;

  final DateTime? generatedUntil;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TripSeriesModel({
    required this.id,
    required this.driverId,
    required this.origin,
    required this.destination,
    this.routeCoordinates = const [],
    this.distanceKm = 0,
    required this.availableSeats,
    required this.pricePerSeat,
    this.daysOfWeek = const [],
    required this.departureTimeOfDay,
    required this.startDate,
    this.endDate,
    this.exceptions,
    this.isActive = true,
    this.subscriptionOptions = const [],
    this.subscriptionPricing,
    this.generatedUntil,
    this.createdAt,
    this.updatedAt,
  });

  factory TripSeriesModel.fromJson(Map<String, dynamic> json) {
    List<RouteCoordinate> coords = [];
    final rawCoords = json['routeCoordinates'];
    if (rawCoords is List) {
      coords = rawCoords
          .map((e) => RouteCoordinate.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<SubscriptionType> subOpts = [];
    final rawSubOpts = json['subscriptionOptions'] as List?;
    if (rawSubOpts != null) {
      subOpts = rawSubOpts
          .map((e) =>
              e == 'monthly' ? SubscriptionType.monthly : SubscriptionType.weekly)
          .toList();
    }

    Map<String, double>? pricing;
    final rawPricing = json['subscriptionPricing'] as Map<String, dynamic>?;
    if (rawPricing != null) {
      pricing = rawPricing
          .map((k, v) => MapEntry(k, (v as num).toDouble()));
    }

    return TripSeriesModel(
      id: json['id'] as String? ?? '',
      driverId: json['driverId'] as String? ?? '',
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      routeCoordinates: coords,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      availableSeats: json['availableSeats'] as int? ?? 0,
      pricePerSeat: (json['pricePerSeat'] as num?)?.toDouble() ?? 0,
      daysOfWeek: (json['daysOfWeek'] as List?)?.cast<int>() ?? [],
      departureTimeOfDay: json['departureTimeOfDay'] as String? ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      exceptions: (json['exceptions'] as List?)?.cast<String>(),
      isActive: json['isActive'] as bool? ?? true,
      subscriptionOptions: subOpts,
      subscriptionPricing: pricing,
      generatedUntil: json['generatedUntil'] != null
          ? DateTime.parse(json['generatedUntil'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'origin': origin,
      'destination': destination,
      'routeCoordinates': routeCoordinates.map((c) => c.toJson()).toList(),
      'distanceKm': distanceKm,
      'availableSeats': availableSeats,
      'pricePerSeat': pricePerSeat,
      'daysOfWeek': daysOfWeek,
      'departureTimeOfDay': departureTimeOfDay,
      'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      if (subscriptionOptions.isNotEmpty)
        'subscriptionOptions': subscriptionOptions.map((e) => e.name).toList(),
      if (subscriptionPricing != null) 'subscriptionPricing': subscriptionPricing,
    };
  }

  String get daysOfWeekDisplay {
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return daysOfWeek.map((d) => d < names.length ? names[d] : '?').join(', ');
  }
}
