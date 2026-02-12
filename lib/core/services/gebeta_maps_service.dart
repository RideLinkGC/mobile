import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

class GeocodingResult {
  final String name;
  final double lat;
  final double lng;
  final String? type;

  const GeocodingResult({
    required this.name,
    required this.lat,
    required this.lng,
    this.type,
  });

  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    return GeocodingResult(
      name: json['name'] as String? ?? json['display_name'] as String? ?? '',
      lat: (json['latitude'] as num?)?.toDouble() ??
          (json['lat'] as num?)?.toDouble() ??
          0.0,
      lng: (json['longitude'] as num?)?.toDouble() ??
          (json['lon'] as num?)?.toDouble() ??
          (json['lng'] as num?)?.toDouble() ??
          0.0,
      type: json['type'] as String?,
    );
  }
}

class RouteResult {
  final List<List<double>> polylinePoints;
  final double distanceKm;
  final double durationMinutes;

  const RouteResult({
    required this.polylinePoints,
    required this.distanceKm,
    required this.durationMinutes,
  });
}

class GebetaMapsService {
  late final Dio _dio;

  GebetaMapsService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.gebetaMapsBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(responseBody: true));
    }
  }

  Future<List<GeocodingResult>> searchPlace(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await _dio.get(
        '/route/geocoding',
        queryParameters: {
          'name': query,
          'apiKey': AppConstants.gebetaMapsApiKey,
        },
      );

      final data = response.data;
      if (data is List) {
        return data
            .map((e) => GeocodingResult.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => GeocodingResult.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      debugPrint('Geocoding error: ${e.message}');
      return [];
    }
  }

  Future<GeocodingResult?> reverseGeocode(double lat, double lng) async {
    try {
      final response = await _dio.get(
        '/route/revgeocoding',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'apiKey': AppConstants.gebetaMapsApiKey,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
          return GeocodingResult.fromJson(data['data'] as Map<String, dynamic>);
        }
        return GeocodingResult.fromJson(data);
      }

      return null;
    } on DioException catch (e) {
      debugPrint('Reverse geocoding error: ${e.message}');
      return null;
    }
  }

  Future<RouteResult?> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final response = await _dio.get(
        '/route/direction/',
        queryParameters: {
          'origin': '$originLat,$originLng',
          'destination': '$destLat,$destLng',
          'apiKey': AppConstants.gebetaMapsApiKey,
        },
      );

      final data = response.data;
      if (data == null) return null;

      final Map<String, dynamic> routeData =
          data is Map<String, dynamic> ? data : {};

      final directionData = routeData['data'] as Map<String, dynamic>? ??
          routeData['direction'] as Map<String, dynamic>? ??
          routeData;

      final totalDistance =
          (directionData['totalDistance'] as num?)?.toDouble() ?? 0.0;
      final totalDuration =
          (directionData['msg'] as num?)?.toDouble() ?? 0.0;

      final List<List<double>> points = [];

      final geometry = directionData['direction'] as List?;
      if (geometry != null) {
        for (final point in geometry) {
          if (point is List && point.length >= 2) {
            points.add([
              (point[0] as num).toDouble(),
              (point[1] as num).toDouble(),
            ]);
          }
        }
      }

      if (points.isEmpty) {
        points.addAll([
          [originLat, originLng],
          [destLat, destLng],
        ]);
      }

      return RouteResult(
        polylinePoints: points,
        distanceKm: totalDistance / 1000,
        durationMinutes: totalDuration / 60,
      );
    } on DioException catch (e) {
      debugPrint('Directions error: ${e.message}');
      return null;
    }
  }
}
