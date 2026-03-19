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

  static final _mockTrips = [
    TripModel(
      id: 't1',
      driverId: 'demo-driver-001',
      origin: 'Bole',
      destination: 'Megenagna',
      departureTime: DateTime.now().add(const Duration(hours: 1)),
      availableSeats: 4,
      pricePerSeat: 45,
      status: TripStatus.scheduled,
    ),
    TripModel(
      id: 't2',
      driverId: 'demo-driver-001',
      origin: 'Kazanchis',
      destination: 'CMC',
      departureTime: DateTime.now().add(const Duration(hours: 2)),
      availableSeats: 3,
      pricePerSeat: 35,
      status: TripStatus.scheduled,
    ),
  ];

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

  Future<TripModel?> getTripById(String id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.tripById(id));
      final data = response.data as Map<String, dynamic>?;
      if (data != null) {
        _selectedTrip = TripModel.fromJson(data);
        notifyListeners();
        return _selectedTrip;
      }
    } catch (e) {
      debugPrint('Failed to load trip: $e');
    }
    return null;
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
