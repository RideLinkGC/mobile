import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/services/storage_service.dart';
import '../models/booking_model.dart';

export '../models/booking_model.dart';

class BookingProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final StorageService _storage;

  List<BookingModel> _bookings = [];
  BookingModel? _activeBooking;
  bool _loading = false;
  String? _error;

  List<BookingModel> get bookings => _bookings;
  BookingModel? get activeBooking => _activeBooking;
  bool get loading => _loading;
  String? get error => _error;

  BookingProvider(this._apiClient, this._storage);

  Future<void> loadBookings() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final passengerId = await _storage.getPassengerId();
      if (passengerId == null || passengerId.startsWith('demo')) {
        _bookings = [];
        _loading = false;
        notifyListeners();
        return;
      }

      final response =
          await _apiClient.get(ApiEndpoints.passengerBookings(passengerId));
      final list = response.data as List?;
      if (list != null) {
        _bookings = list
            .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to load bookings: $e');
      _error = 'Failed to load bookings';
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> requestBooking({
    required String tripId,
    required String passengerId,
    int seatsBooked = 1,
    required double totalPrice,
    String? pickUpPoint,
    String? dropOffPoint,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiEndpoints.createBooking,
        data: {
          'tripId': tripId,
          'passengerId': passengerId,
          'seatsBooked': seatsBooked,
          'totalPrice': totalPrice,
          if (pickUpPoint != null) 'pickUpPoint': pickUpPoint,
          if (dropOffPoint != null) 'dropOffPoint': dropOffPoint,
        },
      );
      final data = response.data as Map<String, dynamic>?;
      if (data != null) {
        _activeBooking = BookingModel.fromJson(data);
      }
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to request booking: $e');
      _error = 'Failed to request booking';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final response =
          await _apiClient.get(ApiEndpoints.bookingById(bookingId));
      final data = response.data as Map<String, dynamic>?;
      if (data != null) {
        _activeBooking = BookingModel.fromJson(data);
        notifyListeners();
        return _activeBooking;
      }
    } catch (e) {
      debugPrint('Failed to load booking: $e');
    }
    return null;
  }

  Future<bool> cancelBooking(String bookingId) async {
    try {
      await _apiClient.patch(ApiEndpoints.cancelBooking(bookingId));
      _bookings.removeWhere((b) => b.id == bookingId);
      if (_activeBooking?.id == bookingId) _activeBooking = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to cancel booking: $e');
      return false;
    }
  }
}
