import 'package:flutter/foundation.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/services/storage_service.dart';
import '../../../passenger/booking/models/booking_model.dart';
import '../models/trip_model.dart';

export '../models/trip_model.dart';

class TripProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final StorageService _storage;

  List<TripModel> _driverTrips = [];
  TripModel? _selectedTrip;
  List<BookingModel> _tripBookings = [];
  bool _loading = false;
  String? _error;

  List<TripModel> get driverTrips => _driverTrips;
  TripModel? get selectedTrip => _selectedTrip;
  List<BookingModel> get tripBookings => _tripBookings;
  bool get loading => _loading;
  String? get error => _error;

  /// Rich mock trips for passenger browse + driver demo (IDs must match search fallbacks).
  static final List<TripModel> _mockTripCatalog = [
    TripModel(
      id: 't1',
      driverId: 'd1',
      origin: 'Bole, Airport Main Gate Area',
      destination: 'Megenagna, Megenagna Square',
      routeCoordinates: const [
        RouteCoordinate(lat: 9.0192, lng: 38.7525),
        RouteCoordinate(lat: 9.0300, lng: 38.7800),
      ],
      departureTime: DateTime.now().add(const Duration(hours: 1)),
      availableSeats: 4,
      pricePerSeat: 45,
      status: TripStatus.scheduled,
      distanceKm: 11.2,
      driverName: 'Abebe Kebede',
      driverRating: 4.8,
      vehicleModel: 'Silver Toyota Corolla',
      vehiclePlate: 'AA-3-45231',
      vehicleSeats: 4,
      bookedSeats: 1,
    ),
    TripModel(
      id: 't2',
      driverId: 'd2',
      origin: 'Bole, Bole Medhanialem',
      destination: 'Kazanchis, Inter Luxury Hotel Hub',
      departureTime: DateTime.now().add(const Duration(hours: 2)),
      availableSeats: 3,
      pricePerSeat: 40,
      status: TripStatus.scheduled,
      distanceKm: 9.5,
      driverName: 'Tigist Hailu',
      driverRating: 4.5,
      vehicleModel: 'Hyundai Tucson',
      vehiclePlate: 'AA-1-88902',
      vehicleSeats: 4,
      bookedSeats: 0,
    ),
    TripModel(
      id: 't3',
      driverId: 'demo-driver-001',
      origin: 'Kazanchis',
      destination: 'CMC',
      departureTime: DateTime.now().add(const Duration(hours: 2)),
      availableSeats: 3,
      pricePerSeat: 35,
      status: TripStatus.scheduled,
      distanceKm: 14,
      driverName: 'Demo Driver',
      driverRating: 4.6,
      vehicleModel: 'Toyota Vitz',
      vehiclePlate: 'DD-9-10001',
      vehicleSeats: 3,
      bookedSeats: 0,
    ),
  ];

  static final _mockTrips = _mockTripCatalog;
  static final RegExp _uuidV4Like = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  TripProvider(this._apiClient, this._storage);

  List<dynamic> _extractList(dynamic data, {List<String> keys = const []}) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in keys) {
        final value = data[key];
        if (value is List) return value;
      }
      for (final value in data.values) {
        if (value is List) return value;
      }
    }
    return const [];
  }

  Future<void> loadDriverTrips() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final driverId = await _storage.getDriverId();
      if (driverId == null || driverId.startsWith('demo')) {
        _driverTrips = _mockTrips;
        _loading = false;
        notifyListeners();
        return;
      }

      final response = await _apiClient.get(ApiEndpoints.driverTrips(driverId));
      final list = _extractList(response.data, keys: const ['trips', 'items']);
      if (list.isNotEmpty) {
        _driverTrips = list
            .map((e) => TripModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to load trips: $e');
      _driverTrips = _mockTrips;
    }

    _loading = false;
    notifyListeners();
  }

  /// Resolves a trip for the driver-details flow. Uses the API when available;
  /// otherwise falls back to catalog mocks (t1, t2, …) or a synthetic trip for any id.
  Future<TripModel?> getTripById(String id) async {
    _loading = true;
    _error = null;
    _selectedTrip = null;
    notifyListeners();

    TripModel? resolved;

    try {
      final response = await _apiClient.get(ApiEndpoints.tripById(id));
      final data = response.data as Map<String, dynamic>?;
      if (data != null && data.isNotEmpty) {
        resolved = TripModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('Trip by id API failed (using mock): $e');
    }

    resolved ??= _mockTripFromCatalog(id) ?? _syntheticMockTrip(id);

    _selectedTrip = resolved;
    _loading = false;
    notifyListeners();
    return _selectedTrip;
  }

  static TripModel? _mockTripFromCatalog(String id) {
    for (final t in _mockTripCatalog) {
      if (t.id == id) return t;
    }
    return null;
  }

  static TripModel _syntheticMockTrip(String id) {
    final h = id.hashCode.abs();
    final names = [
      'Elias Yosef',
      'Abebe Kebede',
      'Tigist Hailu',
      'Solomon Bekele',
    ];
    final origins = [
      'Bole, Airport Main Gate Area',
      'Piassa, Historic District',
      'CMC, Atlas Area',
    ];
    final dests = [
      'Kazanchis, Inter Luxury Hotel Hub',
      'Megenagna, Ring Road',
      'Bole, Edna Mall',
    ];
    return TripModel(
      id: id,
      driverId: 'mock-driver-$h',
      origin: origins[h % origins.length],
      destination: dests[h % dests.length],
      departureTime: DateTime.now().add(Duration(minutes: 20 + h % 180)),
      availableSeats: 4,
      pricePerSeat: 38 + (h % 6) * 4.0,
      status: TripStatus.scheduled,
      distanceKm: 6 + (h % 18).toDouble(),
      driverName: names[h % names.length],
      driverRating: 4.2 + (h % 8) / 10,
      vehicleModel: 'Toyota Corolla',
      vehiclePlate: 'AA-${(1000 + h % 8999).toString()}',
      vehicleSeats: 4,
      bookedSeats: h % 3,
    );
  }

  String _readError(Object e, {required String fallback}) {
    if (e is ApiException && e.message.isNotEmpty) {
      return e.message;
    }
    return fallback;
  }

  List<Map<String, dynamic>> _extractBookingMaps(dynamic data) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map<String, dynamic>) {
      final bookings = data['bookings'];
      if (bookings is List) {
        return bookings.whereType<Map<String, dynamic>>().toList();
      }
      final items = data['items'];
      if (items is List) {
        return items.whereType<Map<String, dynamic>>().toList();
      }
      final nested = data['data'];
      if (nested is List) {
        return nested.whereType<Map<String, dynamic>>().toList();
      }
      if (nested is Map<String, dynamic>) {
        final nestedBookings = nested['bookings'];
        if (nestedBookings is List) {
          return nestedBookings.whereType<Map<String, dynamic>>().toList();
        }
      }
    }
    return const [];
  }

  String _formatIsoZuluFromSelectedLocalClock(DateTime dateTime) {
    final zulu = DateTime.utc(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
      dateTime.millisecond,
    );
    return zulu.toIso8601String();
  }

  Future<String?> createTrip({
    String? driverId,
    required String origin,
    required String destination,
    required List<Map<String, double>> routeCoordinates,
    required double distanceKm,
    required DateTime departureTime,
    required int availableSeats,
    required double pricePerSeat,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final trimmedDriverId = driverId?.trim();
    if (trimmedDriverId == null || !_uuidV4Like.hasMatch(trimmedDriverId)) {
      _error = 'Invalid driver profile. Please sign in again as a driver.';
      _loading = false;
      notifyListeners();
      return null;
    }

    try {
      final resolvedDriverId = driverId ?? await _storage.getDriverId();
      if (resolvedDriverId == null || resolvedDriverId.isEmpty) {
        _error = 'Driver profile not found';
        _loading = false;
        notifyListeners();
        return null;
      }
      final response = await _apiClient.post(ApiEndpoints.trips, data: {
        'driverId': trimmedDriverId,
        'origin': origin,
        'destination': destination,
        'routeCoordinates': routeCoordinates,
        'distanceKm': distanceKm,
        // Backend expects strict ISO datetime; send Zulu ISO while preserving
        // selected local clock components (e.g. 06:51 -> 06:51Z).
        'departureTime': _formatIsoZuluFromSelectedLocalClock(departureTime),
        'availableSeats': availableSeats,
        'pricePerSeat': pricePerSeat,
      });
      final data = response.data as Map<String, dynamic>?;
      final createdId = data?['id'] as String?;
      _loading = false;
      notifyListeners();
      return createdId;
    } catch (e) {
      debugPrint('Failed to create trip: $e');
      _error = _readError(e, fallback: 'Failed to create trip');
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateTripStatus(String tripId, TripStatus status) async {
    _error = null;
    try {
      await _apiClient.patch(
        ApiEndpoints.tripStatus(tripId),
        data: {'status': status.name},
      );
      return true;
    } catch (e) {
      debugPrint('Failed to update trip status: $e');
      _error = _readError(e, fallback: 'Failed to update trip status');
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeTrip(String tripId) async {
    final ok = await updateTripStatus(tripId, TripStatus.completed);
    if (ok) {
      await getTripById(tripId);
      await loadDriverTrips();
    }
    return ok;
  }

  Future<bool> acceptBooking(String bookingId) async {
    _error = null;
    try {
      await _apiClient.patch(ApiEndpoints.acceptBooking(bookingId));
      return true;
    } catch (e) {
      debugPrint('Failed to accept booking: $e');
      _error = _readError(e, fallback: 'Failed to accept booking');
      notifyListeners();
      return false;
    }
  }

  Future<bool> declineBooking(String bookingId) async {
    _error = null;
    try {
      await _apiClient.patch(ApiEndpoints.declineBooking(bookingId));
      return true;
    } catch (e) {
      debugPrint('Failed to decline booking: $e');
      _error = _readError(e, fallback: 'Failed to decline booking');
      notifyListeners();
      return false;
    }
  }

  Future<List<BookingModel>> loadTripBookings(String tripId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiClient.get(ApiEndpoints.tripBookings(tripId));
      final bookingMaps = _extractBookingMaps(response.data);
      _tripBookings = bookingMaps.map(BookingModel.fromJson).toList();
      _loading = false;
      notifyListeners();
      return _tripBookings;
    } catch (e) {
      debugPrint('Failed to load trip bookings: $e');
      _error = _readError(e, fallback: 'Failed to load trip bookings');
    }
    _tripBookings = [];
    _loading = false;
    notifyListeners();
    return _tripBookings;
  }

  /// Loads all bookings for the signed-in passenger profile.
  Future<List<BookingModel>> loadPassengerBookings() async {
    try {
      final passengerId = await _storage.getPassengerId();
      if (passengerId == null || passengerId.trim().isEmpty) {
        return const [];
      }

      final response =
          await _apiClient.get(ApiEndpoints.passengerBookings(passengerId));
      final bookingMaps = _extractBookingMaps(response.data);
      if (bookingMaps.isEmpty) return const [];
      return bookingMaps.map(BookingModel.fromJson).toList();
    } catch (e) {
      debugPrint('Failed to load passenger bookings: $e');
      return const [];
    }
  }

  Future<bool> updateTrip(String tripId, Map<String, dynamic> data) async {
    try {
      await _apiClient.patch(ApiEndpoints.tripById(tripId), data: data);
      return true;
    } catch (e) {
      debugPrint('Failed to update trip: $e');
      return false;
    }
  }

  Future<bool> deleteTrip(String tripId) async {
    try {
      await _apiClient.delete(ApiEndpoints.tripById(tripId));
      _driverTrips.removeWhere((t) => t.id == tripId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to delete trip: $e');
      return false;
    }
  }
}
