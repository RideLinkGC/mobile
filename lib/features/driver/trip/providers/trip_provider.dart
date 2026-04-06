import 'package:flutter/foundation.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
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

  TripProvider(this._apiClient, this._storage);

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

      final response =
          await _apiClient.get(ApiEndpoints.driverTrips(driverId));
      final list = response.data as List?;
      if (list != null) {
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

  Future<bool> createTrip({
    required String driverId,
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

    try {
      await _apiClient.post(ApiEndpoints.trips, data: {
        'driverId': driverId,
        'origin': origin,
        'destination': destination,
        'routeCoordinates': routeCoordinates,
        'distanceKm': distanceKm,
        'departureTime': departureTime.toIso8601String(),
        'availableSeats': availableSeats,
        'pricePerSeat': pricePerSeat,
      });
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to create trip: $e');
      _error = 'Failed to create trip';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTripStatus(String tripId, TripStatus status) async {
    try {
      await _apiClient.patch(
        ApiEndpoints.tripStatus(tripId),
        data: {'status': status.name},
      );
      return true;
    } catch (e) {
      debugPrint('Failed to update trip status: $e');
      return false;
    }
  }

  Future<bool> acceptBooking(String bookingId) async {
    try {
      await _apiClient.patch(ApiEndpoints.acceptBooking(bookingId));
      return true;
    } catch (e) {
      debugPrint('Failed to accept booking: $e');
      return false;
    }
  }

  Future<bool> declineBooking(String bookingId) async {
    try {
      await _apiClient.patch(ApiEndpoints.declineBooking(bookingId));
      return true;
    } catch (e) {
      debugPrint('Failed to decline booking: $e');
      return false;
    }
  }

  Future<List<BookingModel>> loadTripBookings(String tripId) async {
    try {
      final response =
          await _apiClient.get(ApiEndpoints.tripBookings(tripId));
      final list = response.data as List?;
      if (list != null) {
        _tripBookings = list
            .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
        return _tripBookings;
      }
    } catch (e) {
      debugPrint('Failed to load trip bookings: $e');
    }
    return [];
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
