import 'package:flutter/material.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/services/gebeta_maps_service.dart';
import '../../../driver/trip/models/trip_model.dart';

enum SortMode { recommended, price, rating, time, seats }

/// Sort order for the passenger ride-search browse list (name, price, rating only).
enum BrowseSortMode { name, price, rating }

/// Service tier filter for browse (price bands in ETB per seat).
enum BrowseServiceTier { any, budget, standard, premium }

class SearchProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final GebetaMapsService _mapsService;

  List<TripModel> _searchResults = [];
  List<TripModel> _sortedResults = [];
  List<TripModel> _browseDriverTrips = [];
  bool _loading = false;
  bool _browseLoading = false;
  String? _error;
  String? _browseError;
  SortMode _sortMode = SortMode.recommended;
  BrowseSortMode _browseSortMode = BrowseSortMode.rating;
  bool _browseRecommendedOnly = false;
  BrowseServiceTier _browseServiceTier = BrowseServiceTier.any;
  double? _browseMinRating;
  double _browsePriceFilterMin = 10;
  double _browsePriceFilterMax = 200;

  static const double browsePriceSliderMin = 10;
  static const double browsePriceSliderMax = 200;

  double? _maxPrice;
  int? _minSeats;
  TimeOfDay? _preferredTime;
  String? _browseOriginQuery;
  String? _browseDestinationQuery;
  String _browseStatusQuery = 'scheduled';
  DateTime? _browseDepartureTimeFromQuery;
  DateTime? _browseDepartureTimeToQuery;
  int? _browseMinSeatsQuery;
  double? _browseMaxPriceQuery;
  String? _browseSeriesIdQuery;
  int _browsePageQuery = 1;
  int _browseLimitQuery = 20;

  List<TripModel> get searchResults => _sortedResults;
  List<TripModel> get browseDriverTrips => _browseDriverTrips;
  BrowseSortMode get browseSortMode => _browseSortMode;
  bool get browseRecommendedOnly => _browseRecommendedOnly;
  BrowseServiceTier get browseServiceTier => _browseServiceTier;
  double? get browseMinRating => _browseMinRating;
  double get browsePriceFilterMin => _browsePriceFilterMin;
  double get browsePriceFilterMax => _browsePriceFilterMax;

  /// Browse list after filters and sort (does not mutate stored browse data).
  List<TripModel> get browseDriverTripsSorted {
    var copy = List<TripModel>.from(_browseDriverTrips);

    if (_browseRecommendedOnly) {
      copy = copy
          .where((t) => (t.driverRating ?? 0) >= 4.5 && t.seatsLeft >= 1)
          .toList();
    }
    if (_browseMinRating != null) {
      copy = copy
          .where((t) => (t.driverRating ?? 0) >= _browseMinRating!)
          .toList();
    }
    copy = copy
        .where((t) =>
            t.pricePerSeat >= _browsePriceFilterMin &&
            t.pricePerSeat <= _browsePriceFilterMax)
        .toList();

    switch (_browseServiceTier) {
      case BrowseServiceTier.budget:
        copy = copy.where((t) => t.pricePerSeat < 45).toList();
        break;
      case BrowseServiceTier.standard:
        copy = copy
            .where((t) => t.pricePerSeat >= 45 && t.pricePerSeat <= 70)
            .toList();
        break;
      case BrowseServiceTier.premium:
        copy = copy.where((t) => t.pricePerSeat > 70).toList();
        break;
      case BrowseServiceTier.any:
        break;
    }

    switch (_browseSortMode) {
      case BrowseSortMode.name:
        copy.sort((a, b) => (a.driverName ?? '')
            .toLowerCase()
            .compareTo((b.driverName ?? '').toLowerCase()));
        break;
      case BrowseSortMode.price:
        copy.sort((a, b) => a.pricePerSeat.compareTo(b.pricePerSeat));
        break;
      case BrowseSortMode.rating:
        copy.sort(
            (a, b) => (b.driverRating ?? 0).compareTo(a.driverRating ?? 0));
        break;
    }
    return copy;
  }

  /// Top picks for the horizontal "Recommended" strip.
  List<TripModel> get recommendedBrowseTrips {
    final sorted = browseDriverTripsSorted;
    return sorted.take(8).toList();
  }

  bool get loading => _loading;
  bool get browseLoading => _browseLoading;
  String? get error => _error;
  String? get browseError => _browseError;
  SortMode get sortMode => _sortMode;
  double? get maxPrice => _maxPrice;
  int? get minSeats => _minSeats;
  TimeOfDay? get preferredTime => _preferredTime;

  int get totalResults => _searchResults.length;

  SearchProvider(this._apiClient, this._mapsService);

  List<Map<String, dynamic>> _extractTripMaps(dynamic data) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map<String, dynamic>) {
      final trips = data['trips'];
      if (trips is List) {
        return trips.whereType<Map<String, dynamic>>().toList();
      }
      final items = data['items'];
      if (items is List) {
        return items.whereType<Map<String, dynamic>>().toList();
      }
      final nestedData = data['data'];
      if (nestedData is List) {
        return nestedData.whereType<Map<String, dynamic>>().toList();
      }
      if (nestedData is Map<String, dynamic>) {
        final nestedTrips = nestedData['trips'];
        if (nestedTrips is List) {
          return nestedTrips.whereType<Map<String, dynamic>>().toList();
        }
      }
    }
    return const [];
  }

  Future<void> setBrowseBackendFilters({
    String? origin,
    String? destination,
    String? status,
    DateTime? departureTimeFrom,
    DateTime? departureTimeTo,
    int? minSeats,
    double? maxPrice,
    String? seriesId,
    int? page,
    int? limit,
  }) async {
    _browseOriginQuery = origin?.trim().isNotEmpty == true ? origin!.trim() : null;
    _browseDestinationQuery =
        destination?.trim().isNotEmpty == true ? destination!.trim() : null;
    _browseStatusQuery = status?.trim().isNotEmpty == true ? status!.trim() : 'scheduled';
    _browseDepartureTimeFromQuery = departureTimeFrom;
    _browseDepartureTimeToQuery = departureTimeTo;
    _browseMinSeatsQuery = minSeats;
    _browseMaxPriceQuery = maxPrice;
    _browseSeriesIdQuery = seriesId?.trim().isNotEmpty == true ? seriesId!.trim() : null;
    _browsePageQuery = page ?? 1;
    _browseLimitQuery = limit ?? 20;
    await loadBrowseDrivers();
  }

  /// Loads browse trips from backend (no per-driver dedupe).
  Future<void> loadBrowseDrivers() async {
    _browseLoading = true;
    _browseError = null;
    notifyListeners();

    try {
      final query = <String, dynamic>{
        'status': _browseStatusQuery,
        'page': _browsePageQuery,
        'limit': _browseLimitQuery,
        if (_browseOriginQuery != null) 'origin': _browseOriginQuery,
        if (_browseDestinationQuery != null)
          'destination': _browseDestinationQuery,
        if (_browseDepartureTimeFromQuery != null)
          'departureTimeFrom': _browseDepartureTimeFromQuery!.toIso8601String(),
        if (_browseDepartureTimeToQuery != null)
          'departureTimeTo': _browseDepartureTimeToQuery!.toIso8601String(),
        if (_browseMinSeatsQuery != null) 'minSeats': _browseMinSeatsQuery,
        if (_browseMaxPriceQuery != null) 'maxPrice': _browseMaxPriceQuery,
        if (_browseSeriesIdQuery != null) 'seriesId': _browseSeriesIdQuery,
      };
      final response = await _apiClient.get(
        ApiEndpoints.trips,
        queryParameters: query,
      );
      final tripMaps = _extractTripMaps(response.data);
      if (tripMaps.isNotEmpty) {
        final trips = tripMaps.map(TripModel.fromJson).toList();
        // Keep all backend trips; users may want to see multiple rides by same driver.
        trips.sort((a, b) {
          final ra = a.driverRating ?? 0;
          final rb = b.driverRating ?? 0;
          final c = rb.compareTo(ra);
          if (c != 0) return c;
          return a.departureTime.compareTo(b.departureTime);
        });
        _browseDriverTrips = trips;
      } else {
        _browseDriverTrips = [];
      }
      _browseError = null;
    } catch (e) {
      debugPrint('Browse drivers failed: $e');
      _browseError = 'Could not refresh driver list.';
      _browseDriverTrips = [];
    }

    _browseLoading = false;
    notifyListeners();
  }

  void applyBrowseFilters({
    required BrowseSortMode sort,
    required bool recommendedOnly,
    required BrowseServiceTier serviceTier,
    double? minRating,
    required double priceMin,
    required double priceMax,
  }) {
    _browseSortMode = sort;
    _browseRecommendedOnly = recommendedOnly;
    _browseServiceTier = serviceTier;
    _browseMinRating = minRating;
    final lo = priceMin.clamp(browsePriceSliderMin, browsePriceSliderMax);
    final hi = priceMax.clamp(browsePriceSliderMin, browsePriceSliderMax);
    _browsePriceFilterMin = lo <= hi ? lo : hi;
    _browsePriceFilterMax = lo <= hi ? hi : lo;
    _browseMaxPriceQuery = _browsePriceFilterMax;
    loadBrowseDrivers();
    notifyListeners();
  }

  void resetBrowseFilters() {
    _browseSortMode = BrowseSortMode.rating;
    _browseRecommendedOnly = false;
    _browseServiceTier = BrowseServiceTier.any;
    _browseMinRating = null;
    _browsePriceFilterMin = browsePriceSliderMin;
    _browsePriceFilterMax = browsePriceSliderMax;
    _browseMaxPriceQuery = null;
    loadBrowseDrivers();
    notifyListeners();
  }

  Future<void> searchTrips({
    required String origin,
    required String destination,
    double? originLat,
    double? originLng,
    double? destLat,
    double? destLng,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    double? oLat = originLat;
    double? oLng = originLng;
    double? dLat = destLat;
    double? dLng = destLng;

    if (oLat == null || oLng == null) {
      final results = await _mapsService.searchPlace(origin);
      if (results.isNotEmpty) {
        oLat = results.first.lat;
        oLng = results.first.lng;
      }
    }

    if (dLat == null || dLng == null) {
      final results = await _mapsService.searchPlace(destination);
      if (results.isNotEmpty) {
        dLat = results.first.lat;
        dLng = results.first.lng;
      }
    }

    try {
      final response = await _apiClient.get(
        ApiEndpoints.trips,
        queryParameters: {
          'origin': origin,
          'destination': destination,
          'status': 'scheduled',
          if (oLat != null) 'originLat': oLat,
          if (oLng != null) 'originLng': oLng,
          if (dLat != null) 'destLat': dLat,
          if (dLng != null) 'destLng': dLng,
        },
      );
      final tripMaps = _extractTripMaps(response.data);
      _searchResults = tripMaps.map(TripModel.fromJson).toList();
      _error = null;
    } catch (e) {
      debugPrint('Search failed: $e');
      _error = 'Could not load trips. Showing sample results.';
      _searchResults = _fallbackResults;
    }

    _applyFiltersAndSort();
    _loading = false;
    notifyListeners();
  }

  void setSortMode(SortMode mode) {
    _sortMode = mode;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setMaxPrice(double? price) {
    _maxPrice = price;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setMinSeats(int? seats) {
    _minSeats = seats;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setPreferredTime(TimeOfDay? time) {
    _preferredTime = time;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void clearFilters() {
    _maxPrice = null;
    _minSeats = null;
    _preferredTime = null;
    _sortMode = SortMode.recommended;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void _applyFiltersAndSort() {
    var filtered = List<TripModel>.from(_searchResults);

    if (_maxPrice != null) {
      filtered =
          filtered.where((t) => t.pricePerSeat <= _maxPrice!).toList();
    }
    if (_minSeats != null) {
      filtered =
          filtered.where((t) => t.seatsLeft >= _minSeats!).toList();
    }

    switch (_sortMode) {
      case SortMode.recommended:
        _sortByRecommendation(filtered);
        break;
      case SortMode.price:
        filtered.sort((a, b) => a.pricePerSeat.compareTo(b.pricePerSeat));
        break;
      case SortMode.rating:
        filtered.sort(
            (a, b) => (b.driverRating ?? 0).compareTo(a.driverRating ?? 0));
        break;
      case SortMode.time:
        filtered.sort((a, b) => a.departureTime.compareTo(b.departureTime));
        break;
      case SortMode.seats:
        filtered.sort((a, b) => b.seatsLeft.compareTo(a.seatsLeft));
        break;
    }

    _sortedResults = filtered;
  }

  /// Multi-factor scoring that weighs driver rating, price competitiveness,
  /// departure proximity, and seat availability to surface the best options.
  void _sortByRecommendation(List<TripModel> trips) {
    if (trips.isEmpty) return;

    final now = DateTime.now();

    final prices = trips.map((t) => t.pricePerSeat).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;

    final scores = <TripModel, double>{};

    for (final trip in trips) {
      double score = 0;

      // Rating factor (0-40 points): higher is better
      final rating = trip.driverRating ?? 3.0;
      score += (rating / 5.0) * 40;

      // Price factor (0-25 points): lower is better
      if (priceRange > 0) {
        score += (1 - (trip.pricePerSeat - minPrice) / priceRange) * 25;
      } else {
        score += 25;
      }

      // Time proximity factor (0-20 points): closer departures score higher,
      // but penalise trips departing in under 15 minutes (too soon to reach)
      final minutesUntil =
          trip.departureTime.difference(now).inMinutes.toDouble();
      if (minutesUntil < 15) {
        score += 5;
      } else if (minutesUntil <= 60) {
        score += 20;
      } else if (minutesUntil <= 180) {
        score += 15;
      } else {
        score += 8;
      }

      // If user set a preferred time, bonus for trips near that time
      if (_preferredTime != null) {
        final prefMinutes =
            _preferredTime!.hour * 60 + _preferredTime!.minute;
        final tripMinutes =
            trip.departureTime.hour * 60 + trip.departureTime.minute;
        final diff = (prefMinutes - tripMinutes).abs();
        if (diff <= 30) {
          score += 10;
        } else if (diff <= 60) {
          score += 5;
        }
      }

      // Seat availability factor (0-15 points)
      final seatRatio = trip.seatsLeft / (trip.availableSeats.clamp(1, 100));
      score += seatRatio * 15;

      scores[trip] = score;
    }

    trips.sort((a, b) => (scores[b] ?? 0).compareTo(scores[a] ?? 0));
  }

  void clearResults() {
    _searchResults = [];
    _sortedResults = [];
    notifyListeners();
  }

  static final _fallbackResults = [
    TripModel(
      id: 't1',
      driverId: 'd1',
      origin: 'Bole',
      destination: 'Megenagna',
      departureTime: DateTime.now().add(const Duration(hours: 1)),
      availableSeats: 4,
      pricePerSeat: 45,
      status: TripStatus.scheduled,
      driverName: 'Abebe Kebede',
      driverRating: 4.8,
    ),
    TripModel(
      id: 't2',
      driverId: 'd2',
      origin: 'Bole',
      destination: 'Megenagna',
      departureTime: DateTime.now().add(const Duration(hours: 2)),
      availableSeats: 3,
      pricePerSeat: 40,
      status: TripStatus.scheduled,
      driverName: 'Tigist Hailu',
      driverRating: 4.5,
    ),
  ];
}
