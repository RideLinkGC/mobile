import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'gebeta_maps_service.dart';

/// Persists geocode API cache + route search history + recent query strings.
class PlaceSearchStorage {
  PlaceSearchStorage();

  static const _geocodeCacheKey = 'place_geocode_cache_v1';
  static const _routeHistoryKey = 'place_route_history_v1';
  static const _queryHistoryKey = 'place_query_history_v1';

  static const int _maxRouteHistory = 15;
  static const int _maxQueryHistory = 12;
  static const int _maxCacheKeys = 40;
  static const Duration _cacheTtl = Duration(hours: 24);

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  String normalizeQuery(String q) => q.trim().toLowerCase();

  // —— Geocode cache (per normalized query) ——

  Future<List<GeocodingResult>?> getGeocodeCache(String query) async {
    final norm = normalizeQuery(query);
    if (norm.length < 2) return null;

    final prefs = await _prefs;
    final raw = prefs.getString(_geocodeCacheKey);
    if (raw == null) return null;

    Map<String, dynamic> root;
    try {
      root = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }

    final entry = root[norm];
    if (entry is! Map) return null;

    final expiresStr = entry['expires'] as String?;
    if (expiresStr == null) return null;
    final expires = DateTime.tryParse(expiresStr);
    if (expires == null || DateTime.now().isAfter(expires)) {
      root.remove(norm);
      await prefs.setString(_geocodeCacheKey, jsonEncode(root));
      return null;
    }

    final list = entry['results'];
    if (list is! List) return null;

    try {
      return list
          .map((e) =>
              GeocodingResult.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> putGeocodeCache(String query, List<GeocodingResult> results) async {
    final norm = normalizeQuery(query);
    if (norm.length < 2 || results.isEmpty) return;

    final prefs = await _prefs;
    Map<String, dynamic> root = {};
    final raw = prefs.getString(_geocodeCacheKey);
    if (raw != null) {
      try {
        root = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {}
    }

    root[norm] = {
      'expires': DateTime.now().add(_cacheTtl).toIso8601String(),
      'results': results.map((e) => e.toJson()).toList(),
    };

    while (root.length > _maxCacheKeys) {
      final firstKey = root.keys.first;
      root.remove(firstKey);
    }

    await prefs.setString(_geocodeCacheKey, jsonEncode(root));
  }

  // —— Recent typed queries (for chips / suggestions) ——

  Future<List<String>> getRecentQueries() async {
    final prefs = await _prefs;
    return prefs.getStringList(_queryHistoryKey) ?? [];
  }

  Future<void> addRecentQuery(String query) async {
    final q = query.trim();
    if (q.length < 2) return;

    final prefs = await _prefs;
    var list = List<String>.from(prefs.getStringList(_queryHistoryKey) ?? []);
    list.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
    list.insert(0, q);
    if (list.length > _maxQueryHistory) {
      list = list.sublist(0, _maxQueryHistory);
    }
    await prefs.setStringList(_queryHistoryKey, list);
  }

  Future<void> clearRecentQueries() async {
    final prefs = await _prefs;
    await prefs.remove(_queryHistoryKey);
  }

  // —— Route search history (origin + destination with coords) ——

  Future<List<RouteSearchHistoryEntry>> getRouteHistory() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_routeHistoryKey);
    if (raw == null) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => RouteSearchHistoryEntry.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    } catch (e, st) {
      debugPrint('Route history parse: $e\n$st');
      return [];
    }
  }

  Future<void> addRouteSearch(GeocodingResult origin, GeocodingResult dest) async {
    final prefs = await _prefs;
    var list = await getRouteHistory();

    final entry = RouteSearchHistoryEntry(origin: origin, destination: dest);
    list.removeWhere((e) => e.sameRouteAs(entry));
    list.insert(0, entry);
    if (list.length > _maxRouteHistory) {
      list = list.sublist(0, _maxRouteHistory);
    }

    await prefs.setString(
      _routeHistoryKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clearRouteHistory() async {
    final prefs = await _prefs;
    await prefs.remove(_routeHistoryKey);
  }
}

/// One saved "Plan a ride" search with coordinates (fixes 0,0 from string-only history).
class RouteSearchHistoryEntry {
  final GeocodingResult origin;
  final GeocodingResult destination;

  const RouteSearchHistoryEntry({
    required this.origin,
    required this.destination,
  });

  String get label =>
      '${origin.shortLabel} → ${destination.shortLabel}';

  bool sameRouteAs(RouteSearchHistoryEntry other) {
    return (origin.lat - other.origin.lat).abs() < 1e-5 &&
        (origin.lng - other.origin.lng).abs() < 1e-5 &&
        (destination.lat - other.destination.lat).abs() < 1e-5 &&
        (destination.lng - other.destination.lng).abs() < 1e-5;
  }

  Map<String, dynamic> toJson() => {
        'origin': origin.toJson(),
        'destination': destination.toJson(),
      };

  factory RouteSearchHistoryEntry.fromJson(Map<String, dynamic> json) {
    return RouteSearchHistoryEntry(
      origin: GeocodingResult.fromJson(
        Map<String, dynamic>.from(json['origin'] as Map),
      ),
      destination: GeocodingResult.fromJson(
        Map<String, dynamic>.from(json['destination'] as Map),
      ),
    );
  }
}
