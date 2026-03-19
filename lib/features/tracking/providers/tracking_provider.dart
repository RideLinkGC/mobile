import 'dart:async';
import 'dart:convert';

import 'package:convex_flutter/convex_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:gebeta_gl/gebeta_gl.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/convex_functions.dart';
import '../../../core/services/location_service.dart';

class TrackingProvider extends ChangeNotifier {
  final ConvexClient? _convex;
  final LocationService _locationService;

  SubscriptionHandle? _locationSubscription;
  StreamSubscription<Position>? _gpsSubscription;

  LatLng? _driverPosition;
  String? _activeTripId;
  bool _isTracking = false;
  String? _error;

  LatLng? get driverPosition => _driverPosition;
  bool get isTracking => _isTracking;
  String? get error => _error;
  String? get activeTripId => _activeTripId;

  TrackingProvider(this._convex, this._locationService);

  /// Passenger subscribes to driver location updates.
  Future<void> startListening(String tripId) async {
    _activeTripId = tripId;
    _isTracking = true;
    _error = null;
    notifyListeners();

    if (_convex == null) {
      _error = 'Real-time service not configured';
      _isTracking = false;
      notifyListeners();
      return;
    }

    try {
      _locationSubscription = await _convex.subscribe(
        name: ConvexFunctions.getLatestLocation,
        args: {'tripId': tripId},
        onUpdate: (value) {
          try {
            final data = jsonDecode(value) as Map<String, dynamic>?;
            if (data != null) {
              final lat = (data['latitude'] as num?)?.toDouble();
              final lng = (data['longitude'] as num?)?.toDouble();
              if (lat != null && lng != null) {
                _driverPosition = LatLng(lat, lng);
                notifyListeners();
              }
            }
          } catch (e) {
            debugPrint('Tracking parse error: $e');
          }
        },
        onError: (message, value) {
          debugPrint('Tracking subscription error: $message');
          _error = message;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Failed to subscribe to tracking: $e');
      _error = 'Failed to connect to tracking service';
      notifyListeners();
    }
  }

  /// Driver broadcasts their location.
  Future<void> startBroadcasting(String tripId, {required String driverId}) async {
    _activeTripId = tripId;
    _isTracking = true;
    _error = null;
    notifyListeners();

    if (_convex == null) {
      _error = 'Real-time service not configured';
      _isTracking = false;
      notifyListeners();
      return;
    }

    final position = await _locationService.getCurrentPosition();

    try {
      await _convex.mutation(
        name: ConvexFunctions.startTracking,
        args: {
          'tripId': tripId,
          'driverId': driverId,
          'latitude': position?.latitude ?? 0.0,
          'longitude': position?.longitude ?? 0.0,
        },
      );
    } catch (e) {
      debugPrint('Failed to start tracking: $e');
    }

    _gpsSubscription = _locationService.getPositionStream().listen(
      (pos) async {
        _driverPosition = LatLng(pos.latitude, pos.longitude);
        notifyListeners();

        try {
          await _convex.mutation(
            name: ConvexFunctions.updateLocation,
            args: {
              'tripId': tripId,
              'latitude': pos.latitude,
              'longitude': pos.longitude,
              'heading': pos.heading,
              'speed': pos.speed,
            },
          );
        } catch (e) {
          debugPrint('Failed to update location: $e');
        }
      },
      onError: (e) {
        debugPrint('GPS stream error: $e');
        _error = 'Location service error';
        notifyListeners();
      },
    );
  }

  Future<void> endTrip() async {
    if (_activeTripId == null) return;

    try {
      await _convex?.mutation(
        name: ConvexFunctions.stopTracking,
        args: {'tripId': _activeTripId!},
      );
    } catch (e) {
      debugPrint('Failed to stop tracking: $e');
    }

    stopTracking();
  }

  void stopTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
    _isTracking = false;
    _activeTripId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
