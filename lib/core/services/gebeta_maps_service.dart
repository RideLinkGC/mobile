import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

/// Gebeta geocoding: `GET /api/v1/route/geocoding?name=…&apiKey=…`
/// Response shape: `{ "msg": "ok", "data": [ { "name", "lat", "lng", "type", "city", "country" } ] }`
class GeocodingResult {
  final String name;
  final double lat;
  final double lng;
  final String? type;
  final String? city;
  final String? country;

  const GeocodingResult({
    required this.name,
    required this.lat,
    required this.lng,
    this.type,
    this.city,
    this.country,
  });

  /// Short label for lists (name + locality when available).
  String get shortLabel {
    final c = city?.trim();
    if (c != null && c.isNotEmpty && name.trim().isNotEmpty) {
      return '$name, $c';
    }
    return name;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'lat': lat,
        'lng': lng,
        if (type != null) 'type': type,
        if (city != null) 'city': city,
        if (country != null) 'country': country,
      };

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
      city: json['city'] as String?,
      country: json['country'] as String?,
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
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
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
        // add headers
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'origin': "https://docs.gebeta.app",
            'referer': "https://docs.gebeta.app/"
          },
        ),
        queryParameters: {
          'name': query,
          'apiKey': AppConstants.gebetaMapsApiKey,
        },
      );

      final data = response.data;
      List<dynamic> raw = const [];
      if (data is Map) {
        final inner = data['data'];
        if (inner is List) raw = inner;
      } else if (data is List) {
        raw = data;
      }
      if (raw.isEmpty) return [];

      return raw
          .map((e) {
            if (e is Map) {
              return GeocodingResult.fromJson(
                Map<String, dynamic>.from(e),
              );
            }
            return const GeocodingResult(name: '', lat: 0, lng: 0);
          })
          .where((r) => r.name.isNotEmpty && r.lat != 0 && r.lng != 0)
          .toList();
    } on DioException catch (e) {
      debugPrint('Geocoding error: ${e.message}');
      return [];
    }
  }

  Future<GeocodingResult?> reverseGeocode(double lat, double lng) async {
    try {
      final response = await _dio.get(
        '/route/revgeocoding',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'origin': "https://docs.gebeta.app",
            'referer': "https://docs.gebeta.app/"
          },
        ),
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

  /// Directions from Gebeta: `GET /api/route/direction/?origin=lat,lng&destination=lat,lng&apiKey=…`
  /// Optional [waypoints]: each entry `"lat,lng"`; joined with `;` per API docs.
  Future<RouteResult?> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    List<String>? waypoints,
  }) async {
    final query = <String, dynamic>{
      'origin': '$originLat,$originLng',
      'destination': '$destLat,$destLng',
      'apiKey': AppConstants.gebetaMapsApiKey,
    };
    if (waypoints != null && waypoints.isNotEmpty) {
      query['waypoints'] = waypoints.join(';');
    }

    try {
      final response = await _dio.get(
        AppConstants.gebetaDirectionsUrl,
        queryParameters: query,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'origin': "https://docs.gebeta.app",
            'referer': "https://docs.gebeta.app/"
          },
        ),
      );

      final raw = response.data;
      if (raw == null) {
        return _fallbackRoute(originLat, originLng, destLat, destLng);
      }

      // Prefer Gebeta's documented shape (avoids generic walker duplicating `direction`).
      final points =
          _parseGebetaDirectionArray(raw) ?? _extractPolylinePoints(raw);
      final distanceKm = _readDistanceKmFromResponse(raw);
      final durationMin = _readDurationMinutesFromResponse(raw);

      if (points.length < 2) {
        debugPrint('Gebeta direction: no polyline in response, using straight line');
        return _fallbackRoute(originLat, originLng, destLat, destLng,
            distanceKm: distanceKm, durationMinutes: durationMin);
      }

      return RouteResult(
        polylinePoints: points,
        distanceKm: distanceKm,
        durationMinutes: durationMin,
      );
    } on DioException catch (e) {
      debugPrint('Directions error: ${e.message}');
      return _fallbackRoute(originLat, originLng, destLat, destLng);
    }
  }

  RouteResult _fallbackRoute(
    double originLat,
    double originLng,
    double destLat,
    double destLng, {
    double distanceKm = 0,
    double durationMinutes = 0,
  }) {
    return RouteResult(
      polylinePoints: [
        [originLat, originLng],
        [destLat, destLng],
      ],
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
    );
  }

  static double? _asDouble(dynamic raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw.trim());
    return null;
  }

  static double _readDistanceKmFromResponse(dynamic root) {
    double? v;
    void pick(Map map) {
      for (final key in [
        'totalDistance',
        'distance',
        'total_distance',
        'length',
      ]) {
        final parsed = _asDouble(map[key]);
        if (parsed != null) {
          v = parsed;
          return;
        }
      }
    }

    if (root is Map) {
      pick(root);
      final data = root['data'];
      if (data is Map) pick(data);
    }
    if (v == null) return 0;
    // Meters from OSRM-style APIs; Gebeta may return km already (< ~1000).
    if (v! > 1000) return v! / 1000;
    return v!;
  }

  static double _readDurationMinutesFromResponse(dynamic root) {
    double? value;
    void pick(Map map) {
      for (final key in [
        'timetaken',
        'totalDuration',
        'duration',
        'total_time',
        'time',
      ]) {
        final parsed = _asDouble(map[key]);
        if (parsed != null) {
          value = parsed;
          return;
        }
      }
    }

    if (root is Map) {
      pick(root);
      final data = root['data'];
      if (data is Map) pick(data);
    }
    if (value == null) return 0;
    final v = value!;
    // `timetaken` from Gebeta is typically travel time in minutes (e.g. 51.9).
    // Raw seconds are usually large (hundreds+).
    if (v > 180) return v / 60;
    return v;
  }

  /// Gebeta Directions success body: `{ "msg":"Ok", "timetaken":..., "totalDistance":..., "direction":[[lat,lng],...] }`
  static List<List<double>>? _parseGebetaDirectionArray(dynamic raw) {
    for (final candidate in _mapsToTry(raw)) {
      final dir = candidate['direction'];
      if (dir is! List || dir.isEmpty) continue;

      final out = <List<double>>[];
      for (final item in dir) {
        if (item is List &&
            item.length >= 2 &&
            item[0] is num &&
            item[1] is num) {
          final a = (item[0] as num).toDouble();
          final b = (item[1] as num).toDouble();
          out.add(_pairAsLatLng(a, b));
        }
      }
      if (out.length >= 2) return out;
    }
    return null;
  }

  static Iterable<Map<String, dynamic>> _mapsToTry(dynamic raw) sync* {
    if (raw is Map<String, dynamic>) {
      yield raw;
    } else if (raw is Map) {
      yield Map<String, dynamic>.from(raw);
    }
    if (raw is Map && raw['data'] is Map) {
      yield Map<String, dynamic>.from(raw['data'] as Map);
    }
  }

  /// API docs: origin/destination are `lat,lon`. Sample responses use `[lat, lng]` per point.
  static List<double> _pairAsLatLng(double a, double b) =>
      _normalizeLatLngPair(a, b);

  /// Fallback: nested JSON without double-walking the same `direction` array.
  static List<List<double>> _extractPolylinePoints(dynamic root) {
    final out = <List<double>>[];

    void addLatLng(double a, double b) {
      final pair = _normalizeLatLngPair(a, b);
      if (out.isEmpty ||
          (out.last[0] - pair[0]).abs() > 1e-7 ||
          (out.last[1] - pair[1]).abs() > 1e-7) {
        out.add(pair);
      }
    }

    void walk(dynamic node, {int depth = 0}) {
      if (node == null || depth > 40) return;

      if (node is List) {
        if (node.isEmpty) return;

        if (node.length >= 2 &&
            node[0] is num &&
            node[1] is num &&
            (node.length == 2 || node[2] is! List)) {
          final n0 = (node[0] as num).toDouble();
          final n1 = (node[1] as num).toDouble();
          if (node.length == 2) {
            addLatLng(n0, n1);
            return;
          }
        }

        for (final e in node) {
          walk(e, depth: depth + 1);
        }
        return;
      }

      if (node is Map) {
        for (final key in const [
          'direction',
          'coordinates',
          'geometry',
          'path',
          'points',
          'route',
          'polyline',
          'locations',
        ]) {
          if (node.containsKey(key)) {
            walk(node[key], depth: depth + 1);
          }
        }
        if (node['type'] == 'LineString' && node['coordinates'] is List) {
          walk(node['coordinates'], depth: depth + 1);
        }
      }
    }

    walk(root);
    if (out.length >= 2) return out;

    out.clear();
    final inner = root is Map ? root['data'] : null;
    if (inner != null) walk(inner);
    return out;
  }

  /// Docs use `lat,lon`. GeoJSON often uses `[lng, lat]`. Fix using Ethiopia-ish bounds.
  static List<double> _normalizeLatLngPair(double x, double y) {
    if (x.abs() > 180 || y.abs() > 180) return [x, y];

    final latLngLike = x >= 3 && x <= 18 && y >= 30 && y <= 50;
    final lngLatLike = y >= 3 && y <= 18 && x >= 30 && x <= 50;
    if (latLngLike) return [x, y];
    if (lngLatLike) return [y, x];
    return [x, y];
  }
}
