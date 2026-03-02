import '../../../../core/constants/enums.dart';

/// Matches the Prisma TripSubscription model from the backend.
class TripSubscriptionModel {
  final String id;
  final String seriesId;
  final String passengerId;
  final SubscriptionType subscriptionType;
  final int seatsSubscribed;
  final double pricePerPeriod;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Nested series info
  final String? seriesOrigin;
  final String? seriesDestination;
  final String? seriesDepartureTime;

  const TripSubscriptionModel({
    required this.id,
    required this.seriesId,
    required this.passengerId,
    required this.subscriptionType,
    this.seatsSubscribed = 1,
    required this.pricePerPeriod,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.seriesOrigin,
    this.seriesDestination,
    this.seriesDepartureTime,
  });

  factory TripSubscriptionModel.fromJson(Map<String, dynamic> json) {
    final series = json['series'] as Map<String, dynamic>?;

    return TripSubscriptionModel(
      id: json['id'] as String? ?? '',
      seriesId: json['seriesId'] as String? ?? '',
      passengerId: json['passengerId'] as String? ?? '',
      subscriptionType: json['subscriptionType'] == 'monthly'
          ? SubscriptionType.monthly
          : SubscriptionType.weekly,
      seatsSubscribed: json['seatsSubscribed'] as int? ?? 1,
      pricePerPeriod: (json['pricePerPeriod'] as num?)?.toDouble() ?? 0,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      seriesOrigin: series?['origin'] as String?,
      seriesDestination: series?['destination'] as String?,
      seriesDepartureTime: series?['departureTimeOfDay'] as String?,
    );
  }
}
