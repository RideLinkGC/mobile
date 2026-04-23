import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/services/storage_service.dart';
import '../models/trip_series_model.dart';
import '../../../passenger/booking/models/trip_subscription_model.dart';

class TripSeriesProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final StorageService _storage;

  List<TripSeriesModel> _series = [];
  List<TripSubscriptionModel> _subscriptions = [];
  bool _loading = false;
  String? _error;

  List<TripSeriesModel> get series => _series;
  List<TripSubscriptionModel> get subscriptions => _subscriptions;
  bool get loading => _loading;
  String? get error => _error;

  TripSeriesProvider(this._apiClient, this._storage);

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

  Future<void> loadDriverSeries() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final driverId = await _storage.getDriverId();
      final response = await _apiClient.get(
        ApiEndpoints.series,
        queryParameters: {
          if (driverId != null) 'driverId': driverId,
        },
      );
      final list = _extractList(response.data, keys: const ['series', 'items']);
      if (list.isNotEmpty) {
        _series = list
            .map((e) => TripSeriesModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to load series: $e');
      _error = 'Failed to load trip series';
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> createSeries(TripSeriesModel seriesData) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiClient.post(
        ApiEndpoints.series,
        data: seriesData.toCreateJson(),
      );
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to create series: $e');
      _error = 'Failed to create trip series';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deactivateSeries(String seriesId) async {
    try {
      await _apiClient.patch(ApiEndpoints.deactivateSeries(seriesId));
      _series.removeWhere((s) => s.id == seriesId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to deactivate series: $e');
      return false;
    }
  }

  Future<bool> generateTrips(String seriesId) async {
    try {
      await _apiClient.post(ApiEndpoints.generateTrips(seriesId));
      return true;
    } catch (e) {
      debugPrint('Failed to generate trips: $e');
      return false;
    }
  }

  Future<void> loadPassengerSubscriptions() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final passengerId = await _storage.getPassengerId();
      if (passengerId == null || passengerId.startsWith('demo')) {
        _subscriptions = [];
        _loading = false;
        notifyListeners();
        return;
      }

      final response =
          await _apiClient.get(ApiEndpoints.passengerSubscriptions(passengerId));
      final list =
          _extractList(response.data, keys: const ['subscriptions', 'items']);
      if (list.isNotEmpty) {
        _subscriptions = list
            .map((e) =>
                TripSubscriptionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to load subscriptions: $e');
      _error = 'Failed to load subscriptions';
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> subscribe({
    required String seriesId,
    String? passengerId,
    required String subscriptionType,
    int seatsSubscribed = 1,
    required double pricePerPeriod,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final resolvedPassengerId = passengerId ?? await _storage.getPassengerId();
      if (resolvedPassengerId == null || resolvedPassengerId.isEmpty) {
        _error = 'Passenger profile not found';
        _loading = false;
        notifyListeners();
        return false;
      }
      await _apiClient.post(
        ApiEndpoints.createSubscription,
        data: {
          'seriesId': seriesId,
          'passengerId': resolvedPassengerId,
          'subscriptionType': subscriptionType,
          'seatsSubscribed': seatsSubscribed,
          'pricePerPeriod': pricePerPeriod,
          'startDate': DateTime.now().toIso8601String(),
        },
      );
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      debugPrint('Failed to subscribe: $e');
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelSubscription(String subscriptionId) async {
    try {
      await _apiClient.patch(ApiEndpoints.cancelSubscription(subscriptionId));
      _subscriptions.removeWhere((s) => s.id == subscriptionId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to cancel subscription: $e');
      return false;
    }
  }
}
