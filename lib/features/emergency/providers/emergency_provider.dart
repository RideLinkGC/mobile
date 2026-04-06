import 'package:convex_flutter/convex_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/convex_functions.dart';
import '../../../core/services/location_service.dart';

class EmergencyProvider extends ChangeNotifier {
  final ConvexClient? _convex;
  final LocationService _locationService;

  bool _isSending = false;
  bool _sent = false;
  String? _error;
  String? _alertId;

  bool get isSending => _isSending;
  bool get sent => _sent;
  String? get error => _error;
  String? get alertId => _alertId;

  EmergencyProvider(this._convex, this._locationService);

  Future<bool> triggerSOS(String tripId, {String? reason}) async {
    _isSending = true;
    _error = null;
    _sent = false;
    notifyListeners();

    final position = await _locationService.getCurrentPosition();
    final lat = position?.latitude ?? 0.0;
    final lng = position?.longitude ?? 0.0;

    if (_convex == null) {
      _error = 'Emergency service is not configured for this build.';
      _isSending = false;
      notifyListeners();
      return false;
    }

    try {
      final result = await _convex.mutation(
        name: ConvexFunctions.triggerSOS,
        args: {
          'tripId': tripId,
          'latitude': lat,
          'longitude': lng,
          if (reason != null) 'reason': reason,
        },
      );
      _alertId = result as String?;
      if (_alertId == null || _alertId!.isEmpty) {
        _error = 'Failed to send SOS alert. Please try again.';
        _isSending = false;
        notifyListeners();
        return false;
      }
      _isSending = false;
      _sent = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('SOS failed: $e');
      _error = 'Failed to send SOS alert. Please call emergency services.';
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> cancelSOS() async {
    if (_alertId == null) return;
    try {
      await _convex?.mutation(
        name: ConvexFunctions.cancelSOS,
        args: {'alertId': _alertId!},
      );
    } catch (e) {
      debugPrint('Failed to cancel SOS: $e');
    }
    reset();
  }

  void reset() {
    _isSending = false;
    _sent = false;
    _error = null;
    _alertId = null;
    notifyListeners();
  }
}
